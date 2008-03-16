--[[
**********************************************************************
MagicMarker - your best friend for raid marking. See README.txt for
more details.
**********************************************************************
]]


MagicMarker = LibStub("AceAddon-3.0"):NewAddon("MagicMarker", "AceConsole-3.0",
					       "AceEvent-3.0", "AceTimer-3.0",
					       "AceComm-3.0", "AceSerializer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)


-- Upvalue of global functions
local GetRaidTargetIndex = GetRaidTargetIndex
local GetRealZoneText = GetRealZoneText
local GetTime = GetTime
local IsAltKeyDown = IsAltKeyDown
local InCombatLockdown = InCombatLockdown
local SetRaidTarget = SetRaidTarget
local UnitGUID = UnitGUID
local UnitIsDead = UnitIsDead
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitSex = UnitSex
local format = string.format
local strfind = strfind
local strlen = strlen
local sub = string.sub

-- Parameters
local markedTargets = {}
local recentlyAdded = {}
local numCcTargets = {}

-- Number of CC used for each crowd control method
local ccUsed = {}

local networkData = {}

-- class makeup of the party/raid
local raidClassList = {}

-- Cached "raid marks" - i.e if you set up marks on illidan you can
-- reset after phase 2 and then recall them if you need later on.
-- When "loading" cached marks it will also avoid using those marks
-- for NPC's
local raidMarkCache = {}

-- log method upvalues
local log


-- More upvalues
local MagicMarker = MagicMarker
local mobdata
local targetdata
local db
-- CC Classes, matches CC_LIST in Config.lua. Tank/kite has no classes specified for it
local CC_CLASS = { false, "MAGE", "WARLOCK", "PRIEST", "DRUID", "HUNTER", false , "PRIEST", "WARLOCK", "ROGUE", "WARLOCK", "DRUIDS" }

local defaultConfigDB = {
   profile = {
      logLevel = 3,
      remarkDelay = 0.75,
      honorMarks = false,
      honorRaidMarks = true,
      battleMarking = true,
      resetRaidIcons = true,
      acceptMobData = false,
      mobDataBehavior = 1,
      acceptRaidMarks = false, 
   }
}

local function LowSetTarget(id, uid, val, ccid, guid)
   markedTargets[id].guid  = guid
   markedTargets[id].uid  = uid 
   markedTargets[id].ccid  = ccid
   markedTargets[id].value = val
end

function MagicMarker:OnInitialize()
   -- Set up the config database
   self.db = LibStub("AceDB-3.0"):New("MagicMarkerConfigDB", defaultConfigDB, "Default")
   self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
   self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
   self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
   
   -- this is the mob database
   MagicMarkerDB = MagicMarkerDB or { }
   MagicMarkerDB.frameStatusTable = MagicMarkerDB.frameStatusTable or {}
   MagicMarkerDB.mobdata = MagicMarkerDB.mobdata or {} 
   MagicMarkerDB.targetdata = MagicMarkerDB.targetdata or { ["TANK"]={ 8, 1, 2, 3, 4, 5, 6, 7 } }

   MagicMarkerDB.unitCategoryMap = nil -- Delete old data, no way to convert since it's missing zone info

   self:UpgradeDatabase()
   
   mobdata = MagicMarkerDB.mobdata
   targetdata = MagicMarkerDB.targetdata

   log = self:GetLoggers()

   db = self.db.profile

   self:SetLogLevel(db.logLevel)
   self.commPrefix = "MagicMarker"
   self.commPrefixRT = "MagicMarkerRT"
   
   -- no longer used
   MagicMarkerDB.debug = nil   
   MagicMarkerDB.logLevel = nil

   for id = 1,8 do
      markedTargets[id] = {}
   end
end

local function CmdRedirect()
   MagicMarker:Print("This command is deprected. Use |cffdfa9cf/mm tmpl|r instead.") 
end
function MagicMarker:OnEnable()
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")
   self:ZoneChangedNewArea()
   self:GenerateOptions()
   self:RegisterChatCommand("magic", CmdRedirect, false, true)
   self:RegisterChatCommand("mmtmpl", CmdRedirect, false, true)
   self:ScanGroupMembers()
   self:RegisterComm(self.commPrefix, "BulkReceive")
   self:RegisterComm(self.commPrefixRT, "UrgentReceive")
end

function MagicMarker:OnDisable()
   self:UnregisterComm(self.commPrefix)
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterChatCommand("magic")
   self:DisableEvents()
end

function MagicMarker:UrgentReceive(prefix, encmsg, dist, sender)
   if sender == UnitName("player") then
      return -- don't want my own messages!
   end
   local _, message = self:Deserialize(encmsg)
   
   if not message then return end
   if message.cmd == "MARK" then
      -- data = UID
      -- misc1 = mark
      -- misc2 = value
      -- misc3 = ccid
      -- misc4 = guid
      local ccid = message.misc3
      if log.debug then
	 local hash = self:GetUnitHash(message.data)
	 log.debug("[Net] Marked %s as %s with %s",
		   (hash and hash.name) or message.data,
		   (ccid and self:GetCCName(ccid)) or "unknown", self:GetTargetName(message.misc1))
      end
      
      if ccid and ccid > 1 then
	 numCcTargets[ message.data ] = (numCcTargets[ message.data ] or 0) + 1
      end
      self:ReserveMark(message.misc1, message.data, message.misc2, message.misc4, ccid, false, true)
   elseif message.cmd == "UNMARK" then
      -- data = UID
      -- misc1 = mark
      if log.debug then
	 local hash = self:GetUnitHash(message.data)
	 log.debug("[Net] Unmarking %s from %s.", self:GetTargetName(message.misc1), (hash and hash.name) or message.data)
      end
      self:ReleaseMark(message.misc1, message.data, nil, true) 
   elseif message.cmd == "CLEAR" then
      -- data = { mark = uid }
      if log.debug then
	 log.debug("[Net] Raid cache clear received.")
      end
      numCcTargets = {}
      for mark,uid in pairs(message.data) do
	 self:ReleaseMark(mark, uid, nil, true)
      end
   end
end

function MagicMarker:BulkReceive(prefix, encmsg, dist, sender)
   if sender == UnitName("player") then
      return -- don't want my own messages!
   end
   local _, message = self:Deserialize(encmsg)
   if message then
      if message.cmd == "MOBDATA" then
	 if db.acceptMobData then
	    if log.debug then log.debug("[Net] Received mob data for %s from %s.", message.data.name, sender) end
	    self:MergeZoneData(message.zone, message.data)
	 end
      elseif message.cmd == "TARGETS" then
	 if log.debug then log.debug("[Net] Received raid mark configuration from %s.", sender) end
	 MagicMarkerDB.targetdata = message.data
	 targetdata = message.data
      end
      self:NotifyChange()
   end
end


function MagicMarker:MergeZoneData(zone,zoneData)
   local localData = mobdata[zone]
   local localMob, simpleName
   if not localData or db.mobDataBehavior == 3 then  -- replace
      mobdata[zone] = zoneData
   else 
      localData = localData.mobs
      for mob, data in pairs(zoneData.mobs) do
	 -- Enable me for 2.4 to handle numeric ID keys
	 --	 simpleName = self:SimplifyName(mob.name)
	 --	 if simpleName ~= mob then
	 --	    -- mob is a 2.4 numeric ID
	 --	    if localData[simpleName] then
	 --	       localData[mob] = localData[simpleName]
	 --	       localData[simpleName] = nil
	 --	    end
	 --	 else
	 --	    for lm, ld in pairs(localData) do
	 --	       simpleName = self:SimplifyName(ld.name)
	 --	       if simpleName == mob then
	 --		  -- We found a numeric id locally, use that instead
	 --		  mob = lm
	 --		  break
	 --	       end
	 --	    end
	 --	 end
	 if not localData[mob] or db.mobDataBehavior == 2 then
	    if log.trace then log.trace("Replacing entry for %s from remote data.", data.name) end
	    localData[mob] = data
	 end
      end
   end
   
   self:AddZoneConfig(zone, zoneData)
end

local function SetNetworkData(cmd, data, misc1, misc2, misc3, misc4)
   networkData.cmd = cmd
   networkData.data = data
   networkData.misc1 = misc1
   networkData.misc2 = misc2
   networkData.misc3 = misc3
   networkData.misc4 = misc4
end

function MagicMarker:BroadcastZoneData(zone)
   zone = MagicMarker:SimplifyName(zone)
   if mobdata[zone] then
      SetNetworkData("MOBDATA", mobdata[zone], zone)
      self:SendBulkMessage()
   end
end

function MagicMarker:BroadcastAllZones()
   for zone, data in pairs(mobdata) do 
      SetNetworkData("MOBDATA", data, zone)
      self:SendBulkMessage()
   end
end

function MagicMarker:BroadcastRaidTargets()
   if log.trace then log.trace("Broadcast raid target data to the raid.") end
   SetNetworkData("TARGETS", targetData)
   self:SendBulkMessage()
end

-- Returns [GUID, UID, Name]
-- UID is mob name minus spaces in 2.3 and the
-- mob ID in 2.4 
function MagicMarker:GetUnitID(unit)
   local guid, uid
   local unitName = UnitName(unit)
   if UnitGUID then
      guid = UnitGUID(unit)
      uid = tonumber(sub(guid, 7, 12), 16)
      if uid == 0 then uid = nil end
   else
      unitName = UnitName(unit)
      guid = format("%s:%d:%d",
		    unitName, UnitLevel(unit), UnitSex(unit))
   end
   return guid, tostring(uid or MagicMarker:SimplifyName(unitName)), unitName
end

function MagicMarker:PossiblyReleaseMark(unit, noTarget)
   local unitID = (noTarget == true and unit) or unit.."target"
   if UnitExists(unitID) and UnitIsDead(unitID) then
      local unitName = UnitName(unitID)
      local raidMark = GetRaidTargetIndex(unitID)
      
      if raidMark then
	 if log.trace then log.trace("  => found mark %d on dead mob %s ...", raidMark, unitName) end
	 if self:ReleaseMark(raidMark, unitID, true) then
	    if log.debug then log.debug("Released target %s for %s", self:GetTargetName(raidMark), unitName) end
	    return true;
	 end
      end
   end
end


-- 2.3 version
function MagicMarker:UnitDeath()
   if log.trace then log.trace("Something died, checking for marks to free") end
   self:IterateGroup(self.PossiblyReleaseMark, true)
end

-- 2.4 version
local handledCombatEvents = { UNIT_DIED = true, PARTY_KILL = true }
function MagicMarker:UnitDeath24(_, _, event, _, _, _, guid, name)
   if handledCombatEvents[event] then
      for mark,data in pairs(markedTargets) do
	 if data.guid == guid then
	    if log.debug then log.debug("Releasing %s from dead mob %s.", self:GetTargetName(mark), name) end
	    MagicMarker:ReleaseMark(mark, data.uid)
	    break
	 end
      end
   end
end

function MagicMarker:ZoneChangedNewArea()
   local zone,name = self:GetZoneName()
   
   if zone == nil or zone == "" then
      self:ScheduleTimer(self.ZoneChangedNewArea,5,self)
   else
      local zoneData = mobdata[zone]
      local enableLogging
      if not zoneData or zoneData.mm == nil then
	 enableLogging = IsInInstance()
      else
	 enableLogging = zoneData.mm 
      end

      if enableLogging then
	 self:EnableEvents(zoneData and zoneData.targetMark)
      else
	 self:DisableEvents()
      end
   end
end

function MagicMarker:EnableEvents(markOnTarget)
   if not self.addonEnabled then
      self.addonEnabled = true
      if log.info then log.info(L["Magic Marker enabled."]) end
      if markOnTarget then
	 self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMarkUnit", "target")
      end
      self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "SmartMarkUnit", "mouseover")   
      self:RegisterEvent("RAID_ROSTER_UPDATE", "ScheduleGroupScan")
      self:RegisterEvent("PARTY_MEMBERS_CHANGED", "ScheduleGroupScan")
      if UnitGUID then
	 self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "UnitDeath24")
      else
	 self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "UnitDeath")
      end
      self:ScheduleGroupScan()
   end
end

function MagicMarker:DisableEvents()
   if self.addonEnabled then
      self.addonEnabled = false
      if log.info then log.info(L["Magic Marker disabled."]) end
      self:UnregisterEvent("PLAYER_TARGET_CHANGED")
      self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")   
      self:UnregisterEvent("RAID_ROSTER_UPDATE")
      self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
      if UnitGUID then
	 self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      else
	 self:UnregisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
      end
   end
end

local party_idx = { "party1", "party2", "party3", "party4" }

function MagicMarker:MarkRaidTargets()
   if log.debug then log.debug("Making all targets of the raid.") end
   self:IterateGroup(function (self, unit) self:SmartMarkUnit(unit.."target") end, true)
end

local groupScanTimer

function MagicMarker:LogClassInformation(unitName, class)
   if not class then _,class = UnitClass(unitName) end
   if class then 
      raidClassList[class] = (raidClassList[class] or 0) + 1
      if log.trace then log.trace("  found %s => %s.", unitName, class) end
   elseif log.warn then
      log.warn(L["Unable to determine the class for %s."], unitName)
   end
end

function MagicMarker:ScanGroupMembers()
   for id,_ in pairs(raidClassList) do raidClassList[id] = 0 end
   if UnitClass("player") then
      if log.trace then log.trace("Rescanning raid/party member classes.") end
      self:IterateGroup(self.LogClassInformation)
   end
end


function MagicMarker:CacheRaidMarkForUnit(unit)
   local id = GetRaidTargetIndex(unit)
   if id then
      raidMarkCache[unit] = id
      if log.debug then log.debug("Cached "..id.." for "..unit); end
   end
end

function MagicMarker:CacheRaidMarks()
   raidMarkCache = {}   
   if log.debug then log.debug("Caching raid / party marks.") end
   self:IterateGroup(self.CacheRaidMarkForUnit)
end

function MagicMarker:MarkRaidFromCache()
   for unit,id in pairs(raidMarkCache) do
      self:ReserveMark(id, unit, -1, unit, nil, true)
   end
end

function MagicMarker:IterateGroup(callback, useID, ...)
   local id, name, class

   if log.trace then log.trace("Iterating group...") end
   
   if GetNumRaidMembers() > 0 then
      for id = 1,GetNumRaidMembers() do
	 name, _, _, _, _, class = GetRaidRosterInfo(id)
	 callback(self, (useID and "raid"..id) or name, class, ...)
      end
   else
      if GetNumPartyMembers() > 0 then
	 for id = 1,GetNumPartyMembers() do
	    callback(self, (useID and party_idx[id]) or UnitName(party_idx[id]), nil, ...)
	 end
      end
      callback(self, (useID and "player") or UnitName("player"), nil, ...);
   end   
end

function MagicMarker:MarkRaidFromTemplate(template)
   if log.debug then log.debug("Marking from template: "..template) end
   if template == "arch" or template == "archimonde" then
      self:IterateGroup(MagicMarker.MarkTemplates.decursers.func)
      self:IterateGroup(MagicMarker.MarkTemplates.shamans.func)
   elseif MagicMarker.MarkTemplates[template] and MagicMarker.MarkTemplates[template].func then
      self:IterateGroup(MagicMarker.MarkTemplates[template].func)
   else
      if log.warn then log.warn(L["Unknown raid template: %s"], template) end
   end
end

function MagicMarker:ScheduleGroupScan()
   if groupScanTimer then self:CancelTimer(groupScanTimer, true) end
   groupScanTimer = self:ScheduleTimer("ScanGroupMembers", 5)
end


-- Return whether a target is eligable for marking
local function UnitIsEligable (unit)
   return UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) and
      UnitCreatureType(unit) ~= "Critter" and not UnitIsPlayer(unit)
end

-- Return the hash for the unit of NIL if it's not available
function MagicMarker:GetUnitHash(unit, currentZone)
   if currentZone then
      local zone = MagicMarker:GetZoneName()
      local tmpHash = mobdata[zone]
      if tmpHash then
	 local _,uid,name = MagicMarker:GetUnitID(unit)
	 return tmpHash.mobs[uid] or tmpHash.mpbs[MagicMarker:SimplifyName(name)]
      end
   else
      for _, data in pairs(mobdata) do
	 if data.mobs[unit] then
	    return data.mobs[unit]
	 end
      end
   end
end

local function LowFindMark(list, value)
   local id, markedValue
   for _,id in ipairs(list) do
      if id > 0 and id < 9 then
	 markedValue = markedTargets[id].value
	 if not markedValue or (value > markedValue and (db.battleMarking or not InCombatLockdown())) then
	    -- This will return the first free target or an already used target
	    -- if the value of the new target is higher.
	    if log.trace then log.trace("LowFindMark => "..tostring(id).." value "..tostring(value)) end
	    markedTargets[id].value = nil
	    return id, value
	 end
      end
   end
end

-- Return the next mark for the unit
function MagicMarker:GetNextUnitMark(unit,unitName) 
   local unitHash = self:GetUnitHash(unit, true)
   local unitValue = 0
   local cc, tankFirst, cc_list_used

   tankFirst = true
   cc_list_used = 1 -- Tank
   
   if db.honorRaidMarks then
      -- Update list of marks used on the raid
      for id,data in pairs(markedTargets) do
	 if data.value and  data.value > 100 then -- reserved player mark
	    LowSetTarget(id)
	 end
      end
      self:IterateGroup(function(self, unit)
			   local id = GetRaidTargetIndex(unit)
			   if id then LowSetTarget(id, unit, 300, nil, unit) end
			end)
   end
   
   if unitHash then
      if self:IsUnitIgnored(unitHash.priority) then return -1 end
      unitValue = self:UnitValue(unitName, unitHash)
      cc = unitHash.cc
      if numCcTargets[ unitName ] and numCcTargets[ unitName ] >= unitHash.ccnum then
	 tankFirst = true
      elseif unitHash.category ~= cc_list_used then
	 tankFirst = false
      end
   end
   if log.trace then log.trace("  NextUnitMark for "..unitName..": tankFirst="..tostring(tankFirst)..", unitValue="..unitValue) end

   local raidMarkList, raidMarkID, raidMarkValue
   
   if tankFirst or not cc then
      raidMarkList = self:GetMarkForCategory(1) 
      raidMarkID, raidMarkValue = LowFindMark(raidMarkList, unitValue)
      if raidMarkID and log.debug then log.debug("Marked %s as tank with %s", unitName, self:GetTargetName(raidMarkID)) end
   end -- tank marks

   if not raidMarkID then 
      for _,category in ipairs(cc) do
	 local class = CC_CLASS[category]
	 local cc_used_count = ccUsed[category] or 0
	 if not class or cc_used_count < (raidClassList[class] or 0) then
	    raidMarkList = self:GetMarkForCategory(category)
	    raidMarkID, raidMarkValue = LowFindMark(raidMarkList, unitValue)
	    if raidMarkID then
	       ccUsed[category] = cc_used_count + 1
	       cc_list_used = category
	       numCcTargets[ unitName ] = (numCcTargets[ unitName ] or 0) + 1
	       if log.debug then
		  log.debug("Marked %s as cc (%s) with %s", unitName, self:GetCCName(category) or "none",
			    self:GetTargetName(raidMarkID) or "none?!")
	       end
	       break
	    end
	 end
      end
   end
      
   -- no mark found, fall back to tank list for default
   if not raidMarkID then
      raidMarkList = self:GetMarkForCategory(1)
      raidMarkID, raidMarkValue = LowFindMark(raidMarkList, unitValue)
      if raidMarkID and log.debug then
	 log.debug("Marked %s tank (fallback) with %s", unitName, self:GetTargetName(raidMarkID))
      end 
   end
   
   return raidMarkID or 0, cc_list_used, raidMarkValue
end

local unitValueCache = {}

function MagicMarker:UnitValue(uid, hash)
   --   if unitValueCache[unit] then return unitValueCache[unit] end
   local unitData = hash or GetUnitHash(uid)
   local value = 0
   
   if unitData then
      value = 10-unitData.priority
      if value > 0 then
	 value = value * 2 + 2-unitData.category -- Tank > CC
      end
   end
   if log.trace then log.trace("Unit Value for %s = %d", uid, value) end
--   unitValueCache[unit]  = value
   return value
end
   
local function unitValueSortser(unit1, unit2) 
   return MagicMarker:UnitValue(unit1) >  MagicMarker:UnitValue(unit2)
end


function MagicMarker:SmartMarkUnit(unit)
   if not UnitExists(unit) then return end
   if log.trace then log.trace("Unit => "..unit) end
   local unitName = UnitName(unit)
   local altKey = IsAltKeyDown()
   if UnitIsDead(unit) then
      if log.trace then log.trace("Unit %s is dead...", unit) end
      self:PossiblyReleaseMark(unit, true)
   elseif UnitIsEligable(unit) then
      local unitTarget = GetRaidTargetIndex(unit)
      local guid, uid = MagicMarker:GetUnitID(unit)
      -- This will insert the unit into the database if it's missing
      self:InsertNewUnit(uid, unitName)
      if not IsRaidLeader() and not IsRaidOfficer() and not IsPartyLeader() then
	 return
      end
      if unitTarget then
	 if markedTargets[unitTarget].uid == uid then
	    if log.trace then log.trace("  already marked.") end
	    return
	 elseif db.honorMarks then
	    self:ReserveMark(unitTarget, uid, 50, guid, nil, nil)
	    if log.debug then
	       log.debug(L["Added third party mark (%s) for mob %s."],
			 self:GetTargetName(unitTarget), unitName)
	    end
	    return
	 end
      end
            
      if (IsAltKeyDown() or unit ~= "mouseover") then	 	 
	 if log.trace then log.trace("Marking "..guid.." ("..(unitTarget or "N/A")..")") end

	 if recentlyAdded[guid] then 
	    if log.trace then log.trace("  marked / reserved") end
	    return
	 end
	 
	 local newTarget, ccID, value = self:GetNextUnitMark(unit, unitName)
	 
	 if newTarget == 0 then
	    if log.trace then log.trace("  No more raid targets available -- disabling marking.") end
	    if markingEnabled then
	       self:ToggleMarkingMode()
	    end
	 elseif newTarget == -1 then
	    if log.trace then log.trace("  Target on ignore list") end
	 else
	    if not UnitGUID then
	       self:ScheduleTimer(function(arg) recentlyAdded[arg] = nil end, db.remarkDelay, guid) -- To clear it up
	    end
	    recentlyAdded[guid] = newTarget
	    if log.trace then log.trace("  => %s -- %s -- %s -- %s -- %s", guid, tostring(uid), tostring(newTarget), tostring(value), tostring(ccID)) end
	    self:ReserveMark(newTarget, uid, value, guid, ccID)
	    SetRaidTarget(unit, newTarget)
	 end
      end
   elseif unitName and log.trace then
      log.trace("Ignoring "..unitName) 
   end
end

function MagicMarker:ReleaseMark(mark, unit, setTarget, fromNetwork)
   if log.trace then log.trace("Releasing mark %d from %s.", mark, unit) end
   if setTarget then SetRaidTarget(unit, 0) end
   local olduid = markedTargets[mark].uid 
   if olduid then
      recentlyAdded[markedTargets[mark].guid] = nil
      local ccid = markedTargets[mark].ccid
      if ccid and ccUsed[ccid] then
	 ccUsed[ ccid ] = ccUsed[ ccid ] - 1
	 if ccid > 1 then
	    if numCcTargets[ olduid ] > 1 then
	       numCcTargets[ olduid ] = numCcTargets[ olduid ] - 1
	    else
	       numCcTargets[ olduid ] = nil
	    end
	 end
      end
      LowSetTarget(mark)
      if not fromNetwork then
	 SetNetworkData("UNMARK", olduid, mark)
	 self:SendUrgentMessage()
      end
      return true
   end
end

function MagicMarker:ReserveMark(mark, unit, value, guid, ccID, setTarget, fromNetwork)
   if IsRaidLeader() or IsRaidOfficer() or IsPartyLeader() then
      if log.trace then log.trace("Reserving mark %d for %s with value %d, ccid=%s, set=%s.", mark, unit, value, tostring(ccID), tostring(setTarget)) end
      local olduid = markedTargets[mark].uid
      if not olduid or value == -1 or ( markedTargets[mark].value or 0) < value then
	 if olduid then
	    self:ReleaseMark(mark, olduid, setTarget, fromNetwork)
	 end
	 
	 LowSetTarget(mark, unit, (value == -1 and 2000) or value, ccID, guid)
	 
	 if ccID then
	    ccUsed[ ccID ] = (ccUsed[ ccid ] or 0) + 1
	 end
	 
	 if setTarget then
	    SetRaidTarget(unit, mark)
	 end
	 
	 if not fromNetwork then
	    SetNetworkData("MARK", unit, mark, value, ccID, guid)
	    self:SendUrgentMessage()
	 end
	 return true
      end
   else
   end
   return false
end

function MagicMarker:SendUrgentMessage(msg)
   self:SendCommMessage(self.commPrefixRT, self:Serialize(networkData), "RAID", nil, "ALERT")
end

function MagicMarker:SendBulkMessage(msg)
   if IsRaidLeader() or IsRaidOfficer() or IsPartyLeader() then
      self:SendCommMessage(self.commPrefix, self:Serialize(networkData), "RAID", nil, "BULK")
   end
end

function MagicMarker:MarkSingle()
   self:SmartMarkUnit("target")
end

function MagicMarker:UnmarkSingle()
   if UnitExists("target") then
      local mark = GetRaidTargetIndex("target")
      if mark then self:ReleaseMark(mark, "target", true) end
   end
end


-- Disable memoried marksdata
function MagicMarker:ResetMarkData()
   local id
   local usedRaidIcons
   local playerIcon
   local playerName = UnitName("player")
   local targets 

   for id,_ in pairs(ccUsed) do ccUsed[id] = nil end
   for id,_ in pairs(recentlyAdded) do recentlyAdded[id] = nil end
   for id,_ in pairs(numCcTargets) do numCcTargets[id] = nil end

   if db.honorRaidMarks then
      usedRaidIcons = {}
      -- Look at the marks in the raid to ensure we don't reset them.
      self:IterateGroup(function(self, unit)
			   local id = GetRaidTargetIndex(unit)
			   if id then
			      usedRaidIcons[id] = unit
			      if unit == playerName then
				 playerIcon = id
			      end
			   end
		     end)
   end

   for id = 1, 8 do
      if usedRaidIcons and usedRaidIcons[id] then
	 LowSetTarget(id, usedRaidIcons[id], 300, nil, usedRaidIcons[id])
      else
	 if markedTargets[id].uid then
	    if not targets then targets = {} end
	    targets[id] = markedTargets[id].uid
	 end
	 LowSetTarget(id)
	 if db.resetRaidIcons then SetRaidTarget("player", id) end
      end
   end
   if targets then
      SetNetworkData("CLEAR", targets)
      self:SendUrgentMessage(message)
   end
   -- Hack, sometimes the last mark isn't removed.
   
   if db.resetRaidIcons then
      if playerIcon then 
	 SetRaidTarget("player", playerIcon)
      else
	 self:ScheduleTimer(function() SetRaidTarget("player", 0) end, 0.75)
      end
   end
   if log.info then log.info(L["Resetting raid targets."]) end
   self:ScanGroupMembers()
end


function MagicMarker:OnProfileChanged(db,name)
   if log.trace then log.trace("Profile changed to %s", name) end
   db = self.db.profile
   self:NotifyChange()
end

