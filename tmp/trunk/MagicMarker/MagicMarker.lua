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
local markedTargetValues= {}
local recentlyAdded = {}
-- Number of CC used for each crowd control method
local ccUsed = {}

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
local CC_CLASS = { false, "MAGE", "WARLOCK", "PRIEST", "DRUID", "HUNTER", false , "PRIEST", "WARLOCK", "ROGUE" }

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
   
   -- no longer used
   MagicMarkerDB.debug = nil   
   MagicMarkerDB.logLevel = nil
end

function MagicMarker:OnEnable()
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")
   self:ZoneChangedNewArea()
   self:GenerateOptions()
   self:RegisterChatCommand("magic", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end, false, true)
   self:RegisterChatCommand("mm", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end, false, true)
   self:RegisterChatCommand("mmtmpl", "MarkRaidFromTemplate", false, true)
   self:ScanGroupMembers()
   self:RegisterComm(self.commPrefix, "OnCommReceive")
end

function MagicMarker:OnDisable()
   self:UnregisterComm(self.commPrefix)
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterChatCommand("magic")
   self:DisableEvents()
end

function MagicMarker:OnCommReceive(prefix, encmsg, dist, sender)
   local decodeOk, message = self:Deserialize(encmsg)
   if sender == UnitName("player") then
      return -- don't want my own messages!
   end
   if message then
      if message.type == "MOBDATA" then
	 if db.acceptMobData then
	    if log.debug then log.debug("Received mob data for %s from %s.", message.data.name, sender) end
	    self:MergeZoneData(message.zone, message.data)
	 end
      elseif message.type == "TARGETS" then
	 if log.debug then log.debug("Received raid mark configuration from %s.", sender) end
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

function MagicMarker:BroadcastZoneData(zone)
   zone = MagicMarker:SimplifyName(zone)
   if mobdata[zone] then
      self:SendCommMessage(self.commPrefix, self:Serialize({
							      type = "MOBDATA",
							      zone = zone,
							      data = mobdata[zone]
							   }), "RAID", nil, "BULK")
   end
end

function MagicMarker:BroadcastAllZones()
   for zone, data in pairs(mobdata) do 
      self:SendCommMessage(self.commPrefix, self:Serialize({
							      type = "MOBDATA",
							      zone = zone,
							      data = data,
							   }), "RAID", nil, "BULK")
   end
end

function MagicMarker:BroadcastRaidTargets()
   if log.trace then log.trace("Broadcast raid target data to the raid.") end
   self:SendCommMessage(self.commPrefix, self:Serialize({
							   type = "TARGETS",
							   data = targetdata,
							}), "RAID", nil, "BULK")
end

local function GetUniqueUnitID(unit)
   if UnitGUID then return UnitGUID(unit) end -- 2.4
   local unitName = UnitName(unit)
   return format("%s:%d:%d",
		 unitName, UnitLevel(unit), UnitSex(unit))
   
end

function MagicMarker:PossiblyReleaseMark(unit, noTarget)
   local unitID = (noTarget and unit) or unit.."target"
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

--------------------------------
-- THIS IS A HACK UNTIL 2.4  ---
-- IT IS ENGLISH LOCALE ONLY ---
--------------------------------
function MagicMarker:UnitDeath()
   if log.trace then log.trace("Something died, checking for marks to free") end
   self:IterateGroup(self.PossiblyReleaseMark, true)
end

function MagicMarker:ZoneChangedNewArea()
   local zone = GetRealZoneText()
   
   if zone == nil or zone == "" then
      self:ScheduleTimer(self.ZoneChangedNewArea,5,self)
   else
      zone = MagicMarker:SimplifyName(zone)
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
      self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "UnitDeath")
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
      self:UnregisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
   end
end

local party_idx = { "party1", "party2", "party3", "party4" }

function MagicMarker:MarkRaidTargets()
   if log.debug then log.debug("Making all targets of the raid.") end
   self:IterateGroup(function (self, unit) self.SmartMarkUnit(unit.."target") end, true)
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
   raidClassList = {}
   if UnitClass("player") then
      if log.debug then log.debug("Rescanning raid/party member classes.") end
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
      self:ReserveMark(id, unit, 1000)
   end
end

function MagicMarker:IterateGroup(callback, useID, ...)
   local id, name, class

   if log.trace then log.trace("Iterating group...") end
   
   if GetNumRaidMembers() > 0 then
      for id = 1,GetNumRaidMembers() do
	 name, _, _, _, _, class = GetRaidRosterInfo(id)
	 if useID then
	    callback(self, "raid"..id, class, ...)
	 else
	    callback(self, name, class, ...)
	 end
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
   if MagicMarker.MarkTemplates[template] then
      self:IterateGroup(MagicMarker.MarkTemplates[template])
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
local function GetUnitHash(unitName, zoneName)
   local tmpHash = mobdata[MagicMarker:SimplifyName(zoneName or GetRealZoneText())]
   if tmpHash then
      return tmpHash.mobs[MagicMarker:SimplifyName(unitName)]
   end
end

local function LowFindMark(list, value)
   local id, markedValue
   for _,id in ipairs(list) do
      markedValue = markedTargetValues[id]
      if not markedValue or (value > markedValue and (db.battleMarking or not InCombatLockdown())) then
	 -- This will return the first free target or an already used target
	 -- if the value of the new target is higher.
	 if log.trace then log.trace("LowFindMark => "..tostring(id).." value "..tostring(value)) end
	 markedTargetValues[id] = nil
	 return id, value
      end
   end
end

-- Return the next mark for the unit
function MagicMarker:GetNextUnitMark(unit,value) 
   local unitName = GetUnitName(unit)
   local unitHash = GetUnitHash(unitName)
   local unitValue = 0
   local cc,tankFirst, cc_list_used
   local testedMethods = {}
   tankFirst = true
   cc_list_used = 1 -- Tank
   
   if db.honorRaidMarks then
      -- Update list of marks used on the raid
      for id,value in pairs(markedTargetValues) do
	 if value > 100 then -- reserved player mark
	    markedTargets[id]  = nil
	    markedTargetValues[id] = nil
	 end
      end
      self:IterateGroup(function(self, unit)
			   local id = GetRaidTargetIndex(unit)
			   if id then
			      markedTargets[id]  = { guid = unit }
			      markedTargetValues[id] = 300
			   end
			end)
   end
   
   if unitHash then
      if self:IsUnitIgnored(unitHash.priority) then return -1 end
      unitValue = self:UnitValue(unitName, unitHash)
      cc = unitHash.cc
      if unitHash.category ~= cc_list_used then
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
	       if log.debug then log.debug("Marked %s as cc (%s) with %s", unitName, self:GetCCName(category) or "none",
					   self:GetTargetName(raidMarkID) or "none?!") end
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
   
   -- None left for the specified category, 
   -- falling back to the "catch all"...
   return raidMarkID or 0, cc_list_used, raidMarkValue
end

local unitValueCache = {}

function MagicMarker:UnitValue(unit, hash)
   --   if unitValueCache[unit] then return unitValueCache[unit] end
   local unitData = hash or GetUnitHash(unit)
   local value = 0
   
   if unitData then
      value = 10-unitData.priority
      if value > 0 then
	 value = value * 2 + 2-unitData.category -- Tank > CC
      end
   end
   if log.trace then log.trace("Unit Value for %s = %d", unit, value) end
--   unitValueCache[unit]  = value
   return value
end
   
local function unitValue(unit1, unit2) 
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
      local unitGUID = GetUniqueUnitID(unit)
      -- This will insert the unit into the database if it's missing
      self:InsertNewUnit(unitName, GetRealZoneText())

      if unitTarget then
	 if markedTargets[unitTarget] and markedTargets[unitTarget].guid == unitGUID then
	    if log.trace then log.trace("  already marked.") end
	    return
	 elseif db.honorMarks then
	    self:ReserveMark(unitTarget, unitGUID, 50)
	    if log.debug then
	       log.debug(L["Added third party mark (%s) for mob %s."],
			 self:GetTargetName(unitTarget), unitName)
	    end
	    return
	 end
      end
            
      if (IsAltKeyDown() or unit ~= "mouseover") then	 	 
	 if log.trace then log.trace("Marking "..unitGUID.." ("..(unitTarget or "N/A")..")") end

	 if recentlyAdded[unitGUID] then 
	    if log.trace then log.trace("  recently marked.") end
	    return
	 end
	 
	 local newTarget, ccID, value = self:GetNextUnitMark(unit)
	 
	 if newTarget == 0 then
	    if log.trace then log.trace("  No more raid targets available -- disabling marking.") end
	    if markingEnabled then
	       self:ToggleMarkingMode()
	    end
	 elseif newTarget == -1 then
	    if log.trace then log.trace("  Target on ignore list") end
	 else
	    recentlyAdded[unitGUID] = true
	    self:ScheduleTimer(function(arg) recentlyAdded[arg] = nil end, db.remarkDelay, unitGUID) -- To clear it up
	    
	    if log.trace then log.trace("  => %s -- %s -- %s -- %s", unitGUID, tostring(newTarget), tostring(value), tostring(ccID)) end
	    self:ReserveMark(newTarget, unitGUID, value, ccID)
	    SetRaidTarget(unit, newTarget)
	 end
      end
   elseif unitName and log.trace then
      log.trace("Ignoring "..unitName) 
   end
end

function MagicMarker:ReleaseMark(mark, target, setTarget)
   if log.trace then log.trace("Releasing mark %d from %s.", mark, target) end
   if setTarget then SetRaidTarget(target, 0) end
   if markedTargets[mark] then
      local ccid = markedTargets[mark].ccid
      if ccid and ccUsed[ccid] then
	 ccUsed[ ccid ] = ccUsed[ ccid ] - 1
      end
      markedTargets[mark].ccid = nil
      markedTargets[mark].guid = nil
      markedTargetValues[mark] = nil
      return true
   end
end

function MagicMarker:ReserveMark(mark, unit, value, ccID, setTarget)
   if log.trace then log.trace("Reserving mark %d for %s with value %d.", mark, unit, value) end
   if not markedTargets[mark] or ( markedTargetValues[mark] or 0) < value then
      if markedTargets[mark] then
	 self:ReleaseMark(mark, unit, setTarget)
	 markedTargets[mark].ccid = ccID
	 markedTargets[mark].guid = unit
      else
	 markedTargets[mark] = { guid=unit, ccid = ccID }
      end
      if ccID then
	 ccUsed[ ccID ] = (ccUsed[ ccid ] or 0) + 1
      end
      
      markedTargetValues[mark] = value
      
      if setTarget then SetRaidTarget(unit, mark) end
      return true
   end
   return false
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
   ccUsed = { }
   local usedRaidIcons = { }
   local playerIcon
   local playerName = UnitName("player")
   recentlyAdded = {}

   if db.honorRaidMarks then
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
   for id = 8,0,-1 do
      if id > 0 and usedRaidIcons[id] then
	 markedTargets[id] = { guid = usedRaidIcons[id] }
	 markedTargetValues[id] = 300
      else
	 markedTargets[id]  = nil
	 markedTargetValues[id] = nil
	 if db.resetRaidIcons then SetRaidTarget("player", id) end
      end
   end
   -- Hack, sometimes the last mark isn't removed.
   
   if db.resetRaidIcons then
      if playerIcon then 
	 SetRaidTarget("player", playerIcon)
      else
	 self:ScheduleTimer(function() SetRaidTarget("player", 0) end, 0.75)
      end
   end
   self:Print(L["Resetting raid targets."])
   self:ScanGroupMembers()
end


function MagicMarker:OnProfileChanged(db,name)
   if log.trace then log.trace("Profile changed to %s", name) end
   db = self.db.profile
   self:NotifyChange()
end

