--[[
**********************************************************************
MagicMarker - your best friend for raid marking. See README.txt for
more details.
**********************************************************************
This file is part of MagicMarker, a World of Warcraft Addon

MagicMarker is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MagicMarker is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MagicMarker.  If not, see <http://www.gnu.org/licenses/>.
**********************************************************************
]]

local MINOR_VERSION = tonumber(("$Revision$"):match("%d+"))

MagicMarker = LibStub("AceAddon-3.0"):NewAddon("MagicMarker", "AceConsole-3.0",
					       "AceEvent-3.0", "AceTimer-3.0",
					       "LibLogger-1.0")
local MagicMarker = MagicMarker
local MagicComm   = LibStub("MagicComm-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)


MagicMarker.MAJOR_VERSION = "MagicMarker-1.0"
MagicMarker.MINOR_VERSION = MINOR_VERSION

MagicMarker:SetPerformanceMode(true) -- ensure unused loggers are unset


-- Upvalue of global functions
local GetRaidTargetIndex = GetRaidTargetIndex
local GetRealZoneText = GetRealZoneText
local GetTime = GetTime
local IsAltKeyDown = IsAltKeyDown
local InCombatLockdown = InCombatLockdown
local SetRaidTarget = SetRaidTarget
local UnitGUID = UnitGUID
local UnitIsDead = UnitIsDead
local UnitPlayerControlled = UnitPlayerControlled
local UnitClass = UnitClass
local UnitCreatureType = UnitCreatureType
local UnitCanAttack = UnitCanAttack
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitSex = UnitSex
local format = string.format
local strfind = strfind
local strlen = strlen
local sub = string.sub
local sort = table.sort

-- Parameters
local markedTargets = {}
local recentlyAdded = {}
local numCcTargets = {}
local fakeTank = nil

-- Number of CC used for each crowd control method
local ccUsed = {}

local networkData = {}

-- class makeup of the party/raid
local raidClassList = {}

-- Spell ID to CC id mapping (upvalued)
local spellIdToCCID

-- More upvalues
local mobdata
local db

-- CC Classes, matches CC_LIST in Config.lua. Tank/kite has no classes specified for it
local CC_CLASS = {
   false, "MAGE", "WARLOCK", "PRIEST", "DRUID", "HUNTER", false ,
   "PRIEST", "WARLOCK", "ROGUE", "WARLOCK", "DRUID",
   "DRUID", "PALADIN", "HUNTER", "WARLOCK", "PALADIN"
}


local defaultConfigDB = {
   profile = {
      autolearncc = true,
      acceptCCPrio = false,
      acceptMobData = false,
      acceptRaidMarks = false,
      battleMarking = true,
      honorMarks = false,
      honorRaidMarks = true,
      logLevel = 3,
      mobDataBehavior = 1,
      resetRaidIcons = true,
      modifier = "ALT",
      minTankTargets = 1,
      alphasystem = false,
   }
}

local function SetNetworkData(cmd, data, misc1, misc2, misc3, misc4)
   networkData.cmd = cmd
   networkData.data = data
   networkData.misc1 = misc1
   networkData.misc2 = misc2
   networkData.misc3 = misc3
   networkData.misc4 = misc4
   networkData.dbversion = MagicMarkerDB.version
end


local function LowSetTarget(id, uid, val, ccid, guid)
   markedTargets[id].guid  = guid
   markedTargets[id].uid  = uid 
   markedTargets[id].ccid  = ccid
   markedTargets[id].value = val
   if uid then
      markedTargets[id].time = GetTime()
   else
      markedTargets[id].time = 0
   end
end

function MagicMarker:OnInitialize()
   -- Set up the config database
   self.db = LibStub("AceDB-3.0"):New("MagicMarkerConfigDB", defaultConfigDB, "Default")
   self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
   self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
   self.db.RegisterCallback(self, "OnProfileDeleted","OnProfileChanged")
   self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

   -- this is the mob database
   MagicMarkerDB = MagicMarkerDB or { }
   MagicMarkerDB.frameStatusTable = MagicMarkerDB.frameStatusTable or {}
   MagicMarkerDB.mobdata = MagicMarkerDB.mobdata or {} 

   MagicMarkerDB.unitCategoryMap = nil -- Delete old data, no way to convert since it's missing zone info

   self:UpgradeDatabase()
   
   mobdata = MagicMarkerDB.mobdata

   db = self.db.profile
   -- Buggy FuBar_MM caused these to be stored as strings
   db.logLevel = tonumber(db.logLevel)
   db.mobDataBehavior = tonumber(db.mobDataBehavior)

   db.remarkDelay = nil -- no longer needed

   -- sets ccprio/raid target defaults
   self:FixProfileDefaults()

   -- This is moved to the profile
   if MagicMarkerDB.targetdata then
      db.targetdata = MagicMarkerDB.targetdata
      MagicMarkerDB.targetdata = nil
   end

   self:SetLogLevel(db.logLevel)
   self.commPrefix = "MagicMarker"
   self.commPrefixRT = "MagicMarkerRT"
   
   -- no longer used
   MagicMarkerDB.debug = nil   
   MagicMarkerDB.logLevel = nil

   for id = 1,8 do
      markedTargets[id] = {}
   end

   spellIdToCCID = self.spellIdToCCID;
end

function MagicMarker:OnEnable()
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")
   self:ZoneChangedNewArea()
   self:GenerateOptions()
   self:RegisterChatCommand("mmtmpl", function() MagicMarker:Print("This command is deprected. Use |cffdfa9cf/mm tmpl|r or |cffdfa9cf/magic tmpl|r instead.")  end, false, true)

   MagicComm:RegisterListener(self, "MM")
end

function MagicMarker:OnDisable()
   MagicComm:UnregisterListener(self, "MM")
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterChatCommand("magic")
   self:DisableEvents()
end

function MagicMarker:OnMobdataReceive(zone, data, version, sender) 
   if version ~= MagicMarkerDB.version then 
      if self.trace then self:trace("[Net] MagicMarkerDB version mismatch (got = %s, have %d).", tostring(version), MagicMarkerDB.version) end
      return
   end
   if db.acceptMobData then
      if self.debug then self:debug("[Net] Received mob data for %s from %s.", data.name, sender) end
      self:MergeZoneData(zone, data)
   end
   self:NotifyChange()
end

function MagicMarker:OnTargetReceive(data, version, sender) 
   if version ~= MagicMarkerDB.version then 
      if self.trace then self:trace("[Net] MagicMarkerDB version mismatch (got = %s, have %d).", tostring(version), MagicMarkerDB.version) end
      return
   end
   if db.acceptRaidMarks then
      if self.debug then self:debug("[Net] Received raid mark configuration from %s.", sender) end
      db.targetdata = data
   end
   self:NotifyChange()
end

function MagicMarker:OnCCPrioReceive(data, version, sender) 
   if version ~= MagicMarkerDB.version then 
      if self.trace then self:trace("[Net] MagicMarkerDB version mismatch (got = %s, have %d).", tostring(version), MagicMarkerDB.version) end
      return
   end
   if db.acceptCCPrio then
      if self.debug then self:debug("[Net] Received crowd control prioritizations %s.", sender) end
      db.ccprio = data
   end
   self:NotifyChange()
end


function MagicMarker:OnCommMark(mark, uid, value, ccid, guid)
   if markedTargets[mark].guid == guid
      and markedTargets[mark].value == value
      and markedTargets[mark].ccid == ccid
   then
      return -- Duplicate message
   end
   local hash = self:GetUnitHash(uid)
   local name = hash and hash.name or uid
   if self.debug then 
      self:debug("[Net] Marked %s as %s with %s",
		(hash and hash.name) or uid,
		(ccid and self:GetCCName(ccid)) or "unknown",
		self:GetTargetName(mark))
   end

      
   if ccid and ccid > 1 then
      numCcTargets[ uid ] = (numCcTargets[ uid ] or 0) + 1
   end
   
   self:ReserveMark(mark, uid, value, guid, ccid, false, true, name)
end
   
function MagicMarker:OnCommUnmark(mark, uid)
   if not markedTargets[mark] then
      return -- Already unmarked
   end
   if self.debug then
      local hash = self:GetUnitHash(uid)
      self:debug("[Net] Unmarking %s from %s.", self:GetTargetName(mark), (hash and hash.name) or uid)
   end
   self:ReleaseMark(mark, uid, nil, true) 
end

function MagicMarker:OnCommReset(marks)
   if self.debug then
      self:debug("[Net] Raid cache clear received.")
   end
   numCcTargets = {}
   for mark,uid in pairs(marks) do
      self:ReleaseMark(mark, uid, nil, true)
   end
end

local verRespMsg = "%s: %s revision %s"
function MagicMarker:OnVersionResponse(ver, major, minor, sender)
   self:Print(verRespMsg:format(sender, major or "Unknown", minor or "Unknown"))
end

function MagicMarker:QueryAddonVersions()
   SetNetworkData("VCHECK")
   self:SendUrgentMessage()
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
	 simpleName = self:SimplifyName(mob.name)
	 if simpleName ~= mob then
	    -- mob is a 2.4 numeric ID
	    if localData[simpleName] then
	       localData[mob] = localData[simpleName]
	       localData[simpleName] = nil
	    end
	 else
	    for lm, ld in pairs(localData) do
	       simpleName = self:SimplifyName(ld.name)
	       if simpleName == mob then
		  -- We found a numeric id locally, use that instead
		  mob = lm
		  break
	       end
	    end
	 end
	 if not localData[mob] or db.mobDataBehavior == 2 then
	    if self.trace then self:trace("Replacing entry for %s from remote data.", data.name) end
	    localData[mob] = data
	 end
      end
   end   
   self:AddZoneConfig(zone, zoneData)
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
   if self.trace then self:trace("Broadcast raid target data to the raid.") end
   SetNetworkData("TARGETS", db.targetdata)
   self:SendBulkMessage()
end

function MagicMarker:BroadcastCCPriorities()
   if self.trace then self:trace("Broadcast cc priority data to the raid.") end
   SetNetworkData("CCPRIO", db.ccprio)
   self:SendBulkMessage()
end

-- Returns [GUID, UID, Name]
-- UID is mob name minus spaces in 2.3 and the
-- mob ID in 2.4 

local function GUIDToUID(guid)
   local uid = tonumber(sub(guid, 7, 12), 16)
   if uid == 0 then
      return nil
   end
   return tostring(uid)
end

function MagicMarker:GetUnitID(unit)
   local guid, uid
   local unitName = UnitName(unit)
   guid = UnitGUID(unit)
   uid = GUIDToUID(guid)
   return guid, uid or MagicMarker:SimplifyName(unitName), unitName
end

 tankPriorityList = {}
 ccPriorityList = {}
 assignedTargets = {}
 externalTargets = {}
 templateTargets = {}

do 
   local deathEvents = {
      UNIT_DIED = true,
      PARTY_KILL = true,
      UNIT_DESTROYED = true
   }
   
   function MagicMarker:HandleCombatEvent(_, _, event, _, _, _,
					  guid, name, _, spellid, spellname)
      if db.autolearncc and event == "SPELL_AURA_APPLIED" then
	 local ccid = spellIdToCCID[spellid]
	 if not ccid then return end
	 uid = GUIDToUID(guid)
	 if not uid then return end
	 
	 local hash = self:GetUnitHash(nil, true, uid)
	 if hash then
	    if not hash.ccopt then
	       hash.ccopt = {}
	    end
	    local addcc = function(newccid)
			     if not hash.ccopt[newccid] then
				hash.ccopt[newccid] = true
				if self.debug then
				   self:debug("Learned that %s can be CC'd with %s",
					     hash.name, spellname)
				end
			     end
			  end
	    if type(ccid) == "table" then
	       for id = 1,#ccid do
		  addcc(ccid[id])
	       end
	    else
	       addcc(ccid)
	    end
	    self:NotifyChange()
	 end
      elseif deathEvents[event] then
	 local data = assignedTargets[guid]
	 if data then
	    if self.debug then self:debug("Releasing %s from dead mob %s.", self:GetTargetName(data.mark), name) end
	    MagicMarker:SmartMark_RemoveGUID(guid, data.mark)
	 else
	    for mark,data in pairs(markedTargets) do
	       if data.guid == guid then
		  if self.debug then self:debug("Releasing %s from dead mob %s.", self:GetTargetName(mark), name) end
		  MagicMarker:ReleaseMark(mark, data.uid)
		  break
	       end
	    end
	 end
      end
   end
end

do
   local notPvPInstance = { raid = true, party = true }
   function MagicMarker:ZoneChangedNewArea()
      local zone,name = self:GetZoneName()
      if zone == nil or zone == "" then
	 self:ScheduleTimer(self.ZoneChangedNewArea,5,self)
      else
	 local zoneData = mobdata[zone]
	 local enableLogging
	 if not zoneData or zoneData.mm == nil then
	    local inInstance, type = IsInInstance()
	    enableLogging = inInstance and notPvPInstance[type]
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
end

function MagicMarker:EnableEvents(markOnTarget)
   if not self.addonEnabled then
      self.addonEnabled = true
      if MMFu then MMFu:Update() end
      if self.info then self:info(L["Magic Marker enabled."]) end
      if markOnTarget then
	 self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMarkUnit", "target")
      end
      self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "SmartMarkUnit", "mouseover")   
      self:RegisterEvent("RAID_ROSTER_UPDATE", "ScheduleGroupScan")
      self:RegisterEvent("PARTY_MEMBERS_CHANGED", "ScheduleGroupScan")
      self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "HandleCombatEvent")
      self:ScheduleGroupScan()
   end
end

function MagicMarker:DisableEvents()
   if self.addonEnabled then
      self.addonEnabled = false
      if MMFu then MMFu:Update() end
      if self.info then self:info(L["Magic Marker disabled."]) end
      self:UnregisterEvent("PLAYER_TARGET_CHANGED")
      self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")   
      self:UnregisterEvent("RAID_ROSTER_UPDATE")
      self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
      self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   end
end

function MagicMarker:ToggleMagicMarker()
   if self.addonEnabled then
      self:DisableEvents()
   else
      self:EnableEvents()
   end      
end

local party_idx = { "party1", "party2", "party3", "party4" }

function MagicMarker:MarkRaidTargets()
   if self.debug then self:debug("Making all targets of the raid.") end
   self:IterateGroup(function (self, unit) self:SmartMarkUnit(unit.."target") end, true)
end

local groupScanTimer

function MagicMarker:LogClassInformation(unitName, class)
   if not class then _,class = UnitClass(unitName) end
   if class then 
      raidClassList[class] = (raidClassList[class] or 0) + 1
      if self.trace then self:trace("  found %s => %s.", unitName, class) end
   elseif self.warn then
      self:warn(L["Unable to determine the class for %s."], unitName)
   end
end

function MagicMarker:ScanGroupMembers()
   if raidClassList.FAKE then return end
   for id,_ in pairs(raidClassList) do raidClassList[id] = 0 end
   if UnitClass("player") then
      if self.trace then self:trace("Rescanning raid/party member classes.") end
      self:IterateGroup(self.LogClassInformation)
   end
end


function MagicMarker:CacheRaidMarkForUnit(unit)
   local id = GetRaidTargetIndex(unit)
   if id then
      MagicMarkerDB.raidMarkCache[unit] = id
      if self.debug then self:debug("Cached "..id.." for "..unit); end
   end
end

function MagicMarker:CacheRaidMarks()
   MagicMarkerDB.raidMarkCache = {}   
   if self.debug then self:debug("Caching raid / party marks.") end
   self:IterateGroup(self.CacheRaidMarkForUnit)
end

function MagicMarker:MarkRaidFromCache()
   if not MagicMarkerDB.raidMarkCache then
      return
   end
   for unit,id in pairs(MagicMarkerDB.raidMarkCache) do
      self:ReserveMark(id, unit, -1, unit, nil, true)
   end
end

function MagicMarker:IterateGroup(callback, useID, ...)
   local id, name, class

   if self.spam then self:spam("Iterating group...") end
   
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
   if self.debug then self:debug("Marking from template: "..template) end
   local usedMarks = {}
   if template == "arch" or template == "archimonde" then
      self:IterateGroup(MagicMarker.MarkTemplates.decursers.func, false, usedMarks)
      self:IterateGroup(MagicMarker.MarkTemplates.shamans.func, false, usedMarks)
   elseif MagicMarker.MarkTemplates[template] and MagicMarker.MarkTemplates[template].func then
      self:IterateGroup(MagicMarker.MarkTemplates[template].func, false, usedMarks)
   else
      if self.warn then self:warn(L["Unknown raid template: %s"], template) end
   end

   if next(usedMarks) then
      for id = 1,8 do
	 if usedMarks[id] then
	    externalTargets[id] = nil
	    templateTargets[id] = usedMarks[id]
	 else
	    templateTargets[id] = nil
	 end
      end
      self:SmartMark_RecalculateMarks()
   end
end

function MagicMarker:ScheduleGroupScan()
   if groupScanTimer then self:CancelTimer(groupScanTimer, true) end
   groupScanTimer = self:ScheduleTimer("ScanGroupMembers", 5)
end


-- Return whether a target is eligable for marking
local function UnitIsEligable (unit)
   local type = UnitCreatureType(unit)
   return UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit)
      and  type ~= "Critter" and type ~= "Totem" 
      and not UnitPlayerControlled(unit)  and not UnitIsPlayer(unit)
end

-- Return the hash for the unit of NIL if it's not available
function MagicMarker:GetUnitHash(unit, currentZone, uid)
   if currentZone then
      local zone = MagicMarker:GetZoneName()
      local tmpHash = mobdata[zone]
      if tmpHash then
	 if uid then
	    return tmpHash.mobs[uid]
	 else
	    local _,uid,name = MagicMarker:GetUnitID(unit)
	    return tmpHash.mobs[uid] or tmpHash.mpbs[MagicMarker:SimplifyName(name)]
	 end
      end
   else
      for _, data in pairs(mobdata) do
	 if data.mobs[unit] then
	    return data.mobs[unit]
	 end
      end
   end
end

local function LowFindMark(list, value, isTank, fallbackTank)
   local id, markedValue
   for _,id in ipairs(list) do
      if id > 0 and id < 9 then -- sanity check
	 markedValue = markedTargets[id].value or 0
	 if (value > markedValue or (isTank and id == fakeTank
				     and  (not fallbackTank or value < markedValue)))
	    and (db.battleMarking or not InCombatLockdown())
	 then
	    -- This will return the first free target or an already used target
	    -- if the value of the new target is higher.
	    if MagicMarker.trace then MagicMarker:trace("LowFindMark => "..tostring(id).." value "..tostring(value)) end
	    markedTargets[id].value = nil
	    return id, value
	 end
      end
   end
end

-- Return the next mark for the unit
function MagicMarker:GetNextUnitMark(unit, unitName, uid) 
   local unitHash = self:GetUnitHash(unit, true)
   local unitValue = 0
   local cc, tankFirst, cc_list_used
   local doFakeTank 
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
      cc = unitHash.ccopt
      if (not numCcTargets[ uid ]  or numCcTargets[ uid ] < unitHash.ccnum) -- Still can CC more.
	 and  unitHash.category ~= 1 then -- this mob should be CC'd
	 if (ccUsed[1] or 0) > 0 then -- we already have a tank defined
	    tankFirst = false
	 else
	    doFakeTank = true
	 end
      end
   end

   if self.trace then self:trace("  NextUnitMark for "..unitName..": tankFirst="..tostring(tankFirst)..", unitValue="..unitValue) end

   local raidMarkList, raidMarkID, raidMarkValue

   if tankFirst or not cc then
      raidMarkList = self:GetMarkForCategory(1) 
      raidMarkID, raidMarkValue = LowFindMark(raidMarkList, unitValue, true)
      if raidMarkID then
	 if doFakeTank then
	    fakeTank = raidMarkID
	    if self.debug then
	       self:debug("Marked %s as tank (fake) with %s", unitName, self:GetTargetName(raidMarkID))
	    end
	 else
	    if self.debug then
	       self:debug("Marked %s as tank with %s", unitName, self:GetTargetName(raidMarkID))
	    end
	 end
      end
   end -- tank marks

   if not raidMarkID and cc then 
      for _,category in ipairs(db.ccprio) do
	 local class = CC_CLASS[category]
	 if cc[category] and raidClassList[class] and raidClassList[class] > 0 then 
	    local cc_used_count = ccUsed[category] or 0
	    if cc_used_count >= raidClassList[class] then
	       local minval, replaceid = unitValue, nil
	       for id,data in pairs(markedTargets) do
		  if data.ccid == category and data.value < minval then
		     replaceid, minval = id, data.value
		  end
	       end
	       if replaceid then
		  self:ReleaseMark(replaceid, markedTargets[replaceid].uid)
		  cc_used_count = ccUsed[category] or 0
	       end
	    end
	    if not class or cc_used_count < raidClassList[class] then
	       raidMarkList = self:GetMarkForCategory(category)
	       raidMarkID, raidMarkValue = LowFindMark(raidMarkList, unitValue)
	       if raidMarkID then
		  cc_list_used = category
		  numCcTargets[ uid ] = (numCcTargets[ uid ] or 0) + 1
		  if self.debug then
		     self:debug("Marked %s as cc (%s) with %s", unitName, self:GetCCName(category) or "none",
			       self:GetTargetName(raidMarkID) or "none?!")
		  end
		  break
	       end
	    end
	 end
      end
   end
      
   -- no mark found, fall back to tank list for default
   if not raidMarkID and cc then
      raidMarkList = self:GetMarkForCategory(1)
      raidMarkID, raidMarkValue = LowFindMark(raidMarkList, unitValue, true, true)
      if raidMarkID then
	 if self.debug then
	    self:debug("Marked %s tank (fallback) with %s", unitName, self:GetTargetName(raidMarkID))
	 end
      end 
   end
   
   return raidMarkID or 0, cc_list_used, raidMarkValue
end

local unitValueCache = {}

function MagicMarker:UnitValue(uid, hash, modifier)
   --   if unitValueCache[unit] then return unitValueCache[unit] end
   local unitData = hash or self:GetUnitHash(uid)
   local value, ccvalue = 0, 0
   if not modifier then modifier = 0 end
   if unitData then
      value = 10-unitData.priority
      if value > 0 then
	 value = value * 2 + 2-unitData.category -- Tank > CC
      end

      if unitData.ccpriority == 6 then
	 ccvalue = value
      else
	 ccvalue = 10-unitData.ccpriority
	 if ccvalue > 0 then
	    ccvalue = ccvalue * 2 -- Tank > CC
	 end
      end
   end
   if self.trace then self:trace("Unit Value for %s = [%d, %d]", uid, value, ccvalue) end
--   unitValueCache[unit]  = value
   return value+modifier, ccvalue+modifier, unitData
end
   
local function IsModifierPressed()
   if GetBindingKey("MAGICMARKSMARTMARK") then
      return MagicMarker.markKeyDown
   elseif db.modifier == "ALT" then
      return IsAltKeyDown()
   elseif db.modifier == "SHIFT" then
      return IsShiftKeyDown()
   elseif db.modifier == "CTRL" then
      return IsControlKeyDown()
   end
end

local function SmartMark_TankSorter(unit1, unit2) 
   if unit1.value == unit2.value then
      return unit1.guid < unit2.guid -- ensure stable sort
   else
      return unit1.value > unit2.value
   end
end

local function SmartMark_CCSorter(unit1, unit2) 
   if unit1.ccval == unit2.ccval then
      return unit1.guid < unit2.guid -- ensure stable sort
   else
      return unit1.ccval > unit2.ccval
   end
end

function MagicMarker:IsValidMarker()
   return IsRaidLeader() or IsRaidOfficer() or IsPartyLeader()
end

-- This is solely for debugging purposes
-- i.e /dump MagicMarker.smdata
MagicMarker.smdata = {
   tank = tankPriorityList,
   cc = ccPriorityList,
   assigned = assignedTargets,
   external = externalTargets,
   template = templateTargets,
}

local valueModifier = 0.99

function SmartMark_FindUnusedMark(list, used)
   for _,id in pairs(list) do
      if not used[id] then
	 used[id] = true
	 return id
      end
   end
end

-- recalculate mark assignments based on the priority lists
do 
   local ccUsed = {}
   local marksUsed = {}
   local categoryMarkCache = {}
   local newCcCount = {}

   function MagicMarker:SmartMark_RecalculateMarks()
      local id, data, ccount
      local inCombat = InCombatLockdown()
      local canReprioritize = db.battleMarking or not inCombat
      -- empty data from the previous run
      for id in pairs(categoryMarkCache) do categoryMarkCache[id] = nil end
      for id in pairs(markedTargets)     do LowSetTarget(id)  end

      if canReprioritize then
	 -- reprioritize mid-combat
	 for id in pairs(ccUsed)            do ccUsed[id] = nil            end
	 for id in pairs(newCcCount)        do newCcCount[id] = nil        end
	 for id in pairs(marksUsed)         do marksUsed[id] = nil         end
	 for id in pairs(assignedTargets)   do assignedTargets[id] = nil   end
      end


      if self.debug then self:debug("Recalculating mark priority list:") end

      -- cache external targets
      if db.honorMarks then
	 for id,data in pairs(externalTargets) do
	    marksUsed[id] = true
	    assignedTargets[data.guid] = data
	    if self.debug then self:debug("++ %s => %s [external]", self:GetTargetName(id), data.name) end
	 end   
      end

      -- template targets
      for id,data in pairs(templateTargets) do
	 marksUsed[id] = true
	 assignedTargets[data] = id
	 if self.debug then self:debug("++ %s => %s [tmpl]", self:GetTargetName(id), data) end
      end
      
      -- Update list of marks used on the raid
      if db.honorRaidMarks then
	 self:IterateGroup(function(self, unit)
			      local id = GetRaidTargetIndex(unit)
			      if id then
				 assignedTargets[unit] = id
				 marksUsed[id] = true
				 if self.debug then
				    self:debug("++ %s => %s [raid]", self:GetTargetName(id), unit)
				 end			      
			      end
			   end)
      end
      
      
      -- Calculate marks for crowd control first
      for id = 1, #ccPriorityList do
	 data = ccPriorityList[id]
	 ccount = newCcCount[data.uid] or 0
	 if not assignedTargets[data.guid] and ccount < data.hash.ccnum then -- still got more cc for this UID
	    for _,category in ipairs(db.ccprio) do
	       local class = CC_CLASS[category]
	       local cc = data.hash.ccopt
	       if cc[category] and raidClassList[class] and raidClassList[class] > 0 then 
		  local cc_used_count = ccUsed[category] or 0
		  if not class or cc_used_count < raidClassList[class] then
		     categoryMarkCache[category] = categoryMarkCache[category] or self:GetMarkForCategory(category)
		     local nextid = SmartMark_FindUnusedMark(categoryMarkCache[category], marksUsed)
		     if nextid then
			data.mark = nextid
			data.ccused = category
			assignedTargets[data.guid] = data
			newCcCount[ data.uid ] = ccount + 1
			ccUsed[category] = cc_used_count + 1
			if self.debug then
			   self:debug("++ %s => %s [%s]", self:GetTargetName(nextid), data.name, self:GetCCName(category) or "none")
			end
			break
		     end
		  end
	       end
	    end 
	 end 
      end

      if not inCombat then -- Never change cc targets to tank targets during combat
	 local maxCCTargets = #tankPriorityList - db.minTankTargets
	 local assignedCount =  #assignedTargets
	 -- Ensure we have sufficient available targets for tanking.
	 if assignedCount >= maxCCTargets then
	    for id = #ccPriorityList, 1, -1 do
	       data = ccPriorityList[id]
	       if assignedTargets[data.guid] then 
		  assignedTargets[data.guid] = nil
		  assignedCount = assignedCount - 1
		  if self.debug then self:debug("-- %s => %s [insufficient tank targets].", self:GetTargetName(data.mark), data.name) end
		  marksUsed[data.mark] = nil
		  data.mark = nil
		  if assignedCount < maxCCTargets then
		     -- released enough
		     break
		  end
	       end
	    end
	 end
      end
      
      local tankMarkList = self:GetMarkForCategory(1)
      for id = 1, #tankPriorityList do
	 data = tankPriorityList[id]
	 if not assignedTargets[data.guid] then
	    -- Target is not crowd controlled, make it a tank target
	    local nextid = SmartMark_FindUnusedMark(tankMarkList, marksUsed)
	    if not nextid then
	       if self.debug then self:debug("=== no more marks available ===") end
	       break
	    else
	       data.mark = nextid
	       data.ccused = 1
	       assignedTargets[data.guid] = data
	       if self.debug then self:debug("++ %s => %s [tank].", self:GetTargetName(nextid), data.name) end
	    end
	 end
      end


      local tmphash = {}
      -- Attempt to remark targets if the raid members are targeting them.
      local marked = {}
      self:IterateGroup(function(self, unit)
			   local target = unit .. "target"
			   local focus = unit .. "focus"
			   tmphash.target = UnitGUID(target)
			   tmphash.focus = UnitGUID(focus) 
			   for unit, guid in pairs(tmphash) do
			      if not marked[guid] then
				 local data = assignedTargets[guid]
				 if type(data) == "table" then
				    marked[guid] = true
				    SetRaidTarget(unit, data.mark)
				 end
			      end
			   end
			end, true)
      
      if self.debug then self:debug("Done.") end

      -- TODO - need to rework syncing for this. 
      for guid,data in pairs(assignedTargets) do
	 if type(data) == "table" then
	    LowSetTarget(data.mark, data.uid, data.ccused == 1 and data.value or data.ccval, data.ccused, guid)
	    SetNetworkData("MARK", data.name, data.mark, data.ccused == 1 and data.value or data.ccval, data.ccused, guid)
	 else
	    LowSetTarget(data, guid, 1000, -1, guid)
	    SetNetworkData("MARK", guid, data, -1, -1, guid)
	 end
	 self:SendUrgentMessage()
      end
   end
end

function MagicMarker:SmartMark_AddGUID(guid, uid, name)
   for id, data in ipairs(tankPriorityList) do
      if data.guid == guid then
	 return data -- already known
      end
   end
   local value, ccval, hash = self:UnitValue(uid, nil, valueModifier)
   if hash and self:IsUnitIgnored(hash.priority) then return end

   local newhash = {
      uid = uid,
      name = hash and hash.name or name,
      guid = guid,
      value = value,
      ccval = ccval,
      hash = hash
   }
   valueModifier = valueModifier - 0.001
   
   tankPriorityList[#tankPriorityList+1] = newhash
   sort(tankPriorityList, SmartMark_TankSorter)

   if newhash.hash.category == 2 and newhash.hash.ccopt then
      ccPriorityList[#ccPriorityList+1]     = newhash
      sort(ccPriorityList, SmartMark_CCSorter)
   end

   self:SmartMark_RecalculateMarks()

   return assignedTargets[guid]
end

local function SmartMark_CleanList(hash, guid)
   local found 
   for id, data in ipairs(hash) do	
      if moveit then
	 hash[id-1] = data
      elseif data.guid == guid then
	 if self.trace then self:trace(" Found unit to remove: %s", data.guid) end
	 found = data
      end
   end
   if found then
      hash[#hash] = nil
   end
   return found
end

function MagicMarker:SmartMark_RemoveGUID(guid, mark)
   local changed
   if self.trace then self:trace("Looking for unit on tank list...") end
   local changed = SmartMark_CleanList(tankPriorityList, guid)
   if changed then
      if changed.hash.category == 2 and changed.hash.ccopt then
	 if self.trace then self:trace("Looking for unit on cc list...") end
	 -- We only clean cc list if needed
	 SmartMark_CleanList(ccPriorityList, guid)
      end
      changed = true
   end
   
   if externalTargets[mark] then
      externalTargets[mark] = nil
      if self.trace then self:trace("Removed external target...") end
      changed = true
   end
   if templateTargets[mark] then
      templateTargets[mark] = nil
      if self.trace then self:trace("Removed template target...") end
      changed = true
   end
   if changed and (not InCombatLockdown() or db.battleMarking) then
      -- only recalculate when not in combat or if battlemarking is enabled.
      if self.trace then self:trace("Recalculate due to changed unit lists...") end
      self:SmartMark_RecalculateMarks()
   end
end

function MagicMarker:SmartMark_MarkUnit(unit)
   if not UnitExists(unit) then return end
   local unitName = UnitName(unit)
   if UnitIsDead(unit) then
      return
   elseif UnitIsEligable(unit) then
      local unitTarget = GetRaidTargetIndex(unit)
      local guid, uid = MagicMarker:GetUnitID(unit)
      local data
      self:InsertNewUnit(uid, unitName, unit)
      if not self:IsValidMarker() then
	 return
      end

      data = assignedTargets[guid]

      if not data and unitTarget and db.honorMarks then
	 -- found external marks
	 if externalTargets[unitTarget] then
	    if externalTargets[unitTarget].guid ~= guid then
	       externalTargets[unitTarget].guid = guid
	       externalTargets[unitTarget].uid  = uid
	       externalTargets[unitTarget].name = unitName
	       externalTargets[unitTarget].mark = unitTarget
	    end
	 else
	    for id,data in pairs(externalTargets) do
	       if data.guid == guid then
		  externalTargets[unitTarget] = data
		  externalTargets[id] = nil
		  break
	       end
	    end
	    if not externalTargets[unitTarget] then
	       externalTargets[unitTarget] = {
		  name = unitName, guid = guid, uid = uid, mark = unitTarget, ccused = -1
	       }
	    end
	 end
	 if self.debug then
	    self:debug(L["Added third party mark (%s) for mob %s."],
		       self:GetTargetName(unitTarget), unitName)
	 end
	 return
      end
      
      if type(data) == "table" then
	 if data.mark ~= unitTarget then
	    SetRaidTarget(unit, data.mark)
	 end
      elseif (IsModifierPressed() or unit ~= "mouseover") then
	 data = self:SmartMark_AddGUID(guid, uid, unitName)
	 if data and data.mark ~= unitTarget then
	    SetRaidTarget(unit, data.mark)
	 end
      end
   end
end

function MagicMarker:SmartMarkUnit(unit)

   if db.alphasystem then
      self:SmartMark_MarkUnit(unit)
   else
      self:OldSmartMarkUnit(unit)
   end
end

function MagicMarker:OldSmartMarkUnit(unit)
   if not UnitExists(unit) then return end

   local unitName = UnitName(unit)

   if UnitIsDead(unit) then
      return
   elseif UnitIsEligable(unit) then
      local unitTarget = GetRaidTargetIndex(unit)
      local guid, uid = MagicMarker:GetUnitID(unit)
      -- This will insert the unit into the database if it's missing
      self:InsertNewUnit(uid, unitName, unit)
      if not self:IsValidMarker() then
	 return
      end
      if unitTarget then
	 if markedTargets[unitTarget].uid == uid then
	    if self.spam then log.spam("  already marked.") end
	    return
	 elseif db.honorMarks and (GetTime() - (markedTargets[unitTarget].time or 0)) > 1.0 then
	    self:ReserveMark(unitTarget, uid, 50, guid, nil, nil)
	    if self.debug then
	       self:debug(L["Added third party mark (%s) for mob %s."],
			 self:GetTargetName(unitTarget), unitName)
	    end
	    return
	 end
      elseif recentlyAdded[guid] then
	 if self.trace then self:trace("Found known target that wasn't marked.") end
	 self:ReleaseMark(recentlyAdded[guid], unit)
      end
            
      if (IsModifierPressed() or unit ~= "mouseover") then
	 
	 if self.trace then self:trace("Marking "..guid.." ("..(unitTarget or "N/A")..")") end

	 if recentlyAdded[guid] then 
	    if self.trace then self:trace("  already marked") end
	    return
	 end
	 
	 local newTarget, ccID, value = self:GetNextUnitMark(unit, unitName, uid)
	 
	 if newTarget == 0 then
	    if self.trace then self:trace("  No more raid targets available.") end
	    if markingEnabled then
	       self:ToggleMarkingMode()
	    end
	 elseif newTarget == -1 then
	    if self.trace then self:trace("  Target on ignore list") end
	 else
	    recentlyAdded[guid] = newTarget
	    if self.trace then self:trace("  => guid: %s -- uid: %s -- mark: %s -- val: %s -- ccid: %s", guid, tostring(uid), tostring(newTarget), tostring(value), tostring(ccID)) end
	    self:ReserveMark(newTarget, uid, value, guid, ccID)
	    SetRaidTarget(unit, newTarget)
	 end
      end
   elseif unitName and self.spam then
      self:spam("Ignoring "..unitName) 
   end
end

function MagicMarker:ReleaseMark(mark, unit, setTarget, fromNetwork)
   if self.trace then self:trace("Releasing mark %d from %s.", mark, unit) end
   if setTarget then SetRaidTarget(unit, 0) end
   local olduid
   if db.alphasystem then
      if externalTargets[mark] then
	 olduid = externalTargets[mark].uid
	 externalTargets[mark] = nil
	 self:SmartMark_RecalculateMarks()
      else
	 for id,data in pairs(tankPriorityList) do
	    if self.trace then self:trace("Comparing %d to %d", data.mark, mark) end
	    if data.mark == mark then
	       olduid = data.uid
	       MagicMarker:SmartMark_RemoveGUID(data.guid)
	    end
	 end
      end
      templateTargets[mark] = nil
   else
      olduid = markedTargets[mark].uid
      if fakeTank == mark then
	 fakeTank = nil
      end
      if olduid then
	 recentlyAdded[markedTargets[mark].guid] = nil
	 local ccid = markedTargets[mark].ccid
	 if ccid and ccUsed[ccid] then
	    ccUsed[ ccid ] = ccUsed[ ccid ] - 1
	    if self.spam then
	       self:spam("  num --ccUsed for %s = %d",
			 self:GetCCName(ccid), ccUsed[ccid])
	    end
	    if ccid > 1 then
	       if (numCcTargets[ olduid ] or 0) > 1 then
		  numCcTargets[ olduid ] = numCcTargets[ olduid ] - 1
	       else
		  numCcTargets[ olduid ] = nil
	       end
	    end
	 end
	 LowSetTarget(mark)
      end
   end

   if olduid then
      if not fromNetwork then
	 SetNetworkData("UNMARK", olduid, mark)
	 self:SendUrgentMessage()
      end
      return true
   end
end

function MagicMarker:ReserveMark(mark, unit, value, guid, ccid, setTarget, fromNetwork, name)
   if not MagicMarker:IsValidMarker() then return end
   if self.trace then self:trace("Reserving mark %d for %s with value %d, ccid=%s, set=%s.", mark, unit, value, tostring(ccid), tostring(setTarget)) end
   
   if db.alphasystem then
      if value == -1 then
	 templateTargets[mark] = unit
	 if setTarget then SetRaidTarget(unit, mark) end
	 self:SmartMark_RecalculateMarks()
      else
	 if self.spam then self:spam("Adding guid %s => %s", guid, name) end
	 self:SmartMark_AddGUID(guid, GUIDToUID(guid), name)
      end
      return true
   else
      local olduid = markedTargets[mark].uid
      local oldval =  markedTargets[mark].value or 0
      if not olduid or value == -1 or oldval < value or (fromNetwork and oldval == 50) then 
	 if olduid then
	    self:ReleaseMark(mark, olduid, setTarget, fromNetwork)
	 end
	 
	 LowSetTarget(mark, unit, (value == -1 and 2000) or value, ccid, guid)
	 
	 if ccid then
	    ccUsed[ ccid ] = (ccUsed[ ccid ] or 0) + 1
	    if self.spam then
	       self:spam("  num ++ccUsed for %s = %d",
			 self:GetCCName(ccid), ccUsed[ccid])
	    end
	 end
	 
	 if setTarget then
	    SetRaidTarget(unit, mark)
	 end
	 
	 if not fromNetwork then
	    SetNetworkData("MARK", unit, mark, value, ccid, guid)
	    self:SendUrgentMessage()
	 end
	 return true
      end
   end
   return false
end

function MagicMarker:SendUrgentMessage()
   MagicComm:SendUrgentMessage(networkData, "MM")
end

function MagicMarker:SendBulkMessage()
   if MagicMarker:IsValidMarker() then
      MagicComm:SendBulkMessage(networkData, "MM")
   end
end

function MagicMarker:MarkSingle()
   self:SmartMarkUnit("target")
end

function MagicMarker:UnmarkSingle()
   if UnitExists("target") then
      local mark = GetRaidTargetIndex("target")
      if db.alphasystem then
	 self:SmartMark_RemoveGUID(UnitGUID("target"), mark)
      end
      if mark then self:ReleaseMark(mark, "target", true) end
   end
end


function MagicMarker:GetMarkData()
   return markedTargets
end

-- Disable memoried marksdata
function MagicMarker:ResetMarkData(hardReset)
   local id
   local usedRaidIcons
   local playerIcon
   local playerName = UnitName("player")
   local targets
   local markToUID = {}
   valueModifier = 0.99
   for id in pairs(ccUsed) do ccUsed[id] = nil end
   for id in pairs(recentlyAdded) do recentlyAdded[id] = nil end
   for id in pairs(numCcTargets) do numCcTargets[id] = nil end
   for id in pairs(tankPriorityList) do tankPriorityList[id] = nil end
   for id in pairs(ccPriorityList) do ccPriorityList[id] = nil end
   
   for id,data in pairs(assignedTargets) do
      if type(data) == "table" then 
	 markToUID[data.mark] = data.uid
      end
      assignedTargets[id] = nil
   end

   fakeTank = nil

   if db.honorRaidMarks and not hardReset then
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
	 templateTargets[id] = usedRaidIcons[id]
      else
	 templateTargets[id] = nil
	 
	 if externalTargets[id] then
	    if not targets then targets = {} end
	    targets[id] = externalTargets[id].uid
	 elseif markedTargets[id] then
	    if not targets then targets = {} end
	    targets[id] = markedTargets[id].uid
	 elseif marktoUID[id] then
	    if not targets then targets = {} end
	    targets[id] = marktoUID[id]
	 end
	 LowSetTarget(id)
	 if hardReset or db.resetRaidIcons then SetRaidTarget("player", id) end
      end
      externalTargets[id] = nil
   end
   if targets then
      SetNetworkData("CLEAR", targets)
      self:SendUrgentMessage()
   end
   -- Hack, sometimes the last mark isn't removed.
   
   if hardReset or db.resetRaidIcons then
      if playerIcon then 
	 SetRaidTarget("player", playerIcon)
      else
	 self:ScheduleTimer(function() SetRaidTarget("player", 0) end, 0.75)
      end
   end
   if self.info then self:info(L["Resetting raid targets."]) end
   self:ScanGroupMembers()
end

local function myconcat(hash, key, str)
   if hash[key] then
      hash[key] = str.join(" ", hash[key], str)
   else
      hash[key] = str
   end
end

function MagicMarker:ReportRaidMarks()
   local assign = {}
   local test
   if GetNumRaidMembers() > 0 then
      dest = "RAID"
   elseif GetNumPartyMembers() > 0 then
      dest = "PARTY"
   end
   
   local sortData = {}
   local hasData

   local valueToId = {}
   for id, data in pairs(markedTargets) do
      if data.value then
	 local key = data.value * 10000 + id
	 valueToId[key] = id
	 tinsert(sortData, key)
	 hasData = true
      end
   end
   if hasData then
      SendChatMessage("*** Raid Target assignments:", dest)
      sort(sortData, function(a,b) return a > b end)   
      
      for _, id in pairs(sortData) do
	 id = valueToId[id]
	 data = markedTargets[id]
	 local unitData = self:GetUnitHash(data.uid)
	 if unitData then
	    if data.ccid then
	       test = string.format("%s %s: %s",
				    self:GetTargetName(id, true),
				    self:GetCCName(data.ccid, 1),
				    unitData.name)
	       
	       if data.ccid == 1 then
		  SendChatMessage(test,dest)
	       else
		  assign[#assign+1] = test
	       end
	    elseif data.value == 50 then
	       assign[#assign+1] =string.format("%s Other: %s",
						self:GetTargetName(id, true),
						unitData.name)
	    end
	 end
      end
      for i = 1,#assign do
	 SendChatMessage(assign[i], dest)
      end
   end
end

-- can use this to set an override for the raid setup - hash like this
-- { DRUID = 2, MAGE = 1 }
-- etc
function MagicMarker:SetFakeRaidMakeUp(map)
   raidClassList = map
   map.FAKE = 1
end

function MagicMarker:FixProfileDefaults()
   if not db.ccprio then
      db.ccprio = {
	 10, -- sap
	 3, -- banish
	 2, -- sheep
	 4, -- shackle
	 5, -- hibernate
	 6, -- trap
	 9, -- fear
	 11, -- enslave
	 12, -- root
      }
   end
   if not db.targetdata then
      db.targetdata = {
	 TANK = { 8, 1, 2, 3, 4, 5, 6, 7 }
      }
   end
end

function MagicMarker:OnProfileChanged(event, newdb)

   if event ~= "OnProfileDeleted" then
      db = self.db.profile
      self:FixProfileDefaults()
      
      for key,val in pairs(db.ccprio) do
	 if not val or val == 1 then
	    db.ccprio[key] = nil
	 end
      end
      self:SetLogLevel(db.logLevel)
      self:SetStatusText(string.format(L["Active profile: %s"], self.db:GetCurrentProfile()))
   end
      
   self:NotifyChange()

   if MMFu then MMFu:GenerateProfileConfig() end
end

