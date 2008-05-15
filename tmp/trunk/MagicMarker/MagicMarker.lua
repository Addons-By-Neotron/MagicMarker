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


-- Number of CC used for each crowd control method
local networkData = {}

-- class makeup of the party/raid
local raidClassList = {}

-- Spell ID to CC id mapping (upvalued)
local spellIdToCCID

-- More upvalues
local mobdata
local db

-- New method data 
local markedTargets = {}    -- [mark] => data
local tankPriorityList = {} -- ordered array of known targets
local ccPriorityList = {}   -- ordered array of known ccable targets
local assignedTargets = {}  -- guid => data
local externalTargets = {}  -- [mark] => data
local templateTargets = {}  -- [mark] => data

-- CC Classes, matches CC_LIST in Config.lua. Tank/kite has no classes specified for it
local CC_CLASS = {
   false, "MAGE", "WARLOCK", "PRIEST", "DRUID", "HUNTER", false ,
   "PRIEST", "WARLOCK", "ROGUE", "WARLOCK", "DRUID",
   "DRUID", "PALADIN", "HUNTER", "WARLOCK", "PALADIN", "ROGUE",false
}


local defaultConfigDB = {
   profile = {
      filterdead = false, 
      autolearncc = true,
      acceptCCPrio = false,
      acceptMobData = false,
      acceptRaidMarks = false,
      battleMarking = false,
      honorMarks = false,
      honorRaidMarks = true,
      logLevel = 3,
      mobDataBehavior = 1,
      resetRaidIcons = true,
      modifier = "ALT",
      minTankTargets = 1,
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

local function SetExternalTarget(id, guid, uid, name, hash)
   if id and id > 0 and id < 9 then
      externalTargets[id].guid = guid
      externalTargets[id].uid  = uid
      externalTargets[id].name = name
      externalTargets[id].mark = guid and id or nil
      externalTargets[id].hash = hash
   end
end

local function SetTemplateTarget(id, name, network)
   if id and id > 0 and id < 9 then 
      templateTargets[id].guid = name and UnitGUID(name) or nil
      templateTargets[id].name = name
      templateTargets[id].uid  = name
      templateTargets[id].mark = name and id or nil
      if name then
	 SetExternalTarget(id) 
	 for oid = 1, 8 do
	    -- We can only have the same template target once so clean it up
	    if oid ~= id and templateTargets[oid].name == name then
	       SetTemplateTarget(oid)
	    end
	 end
	 if not network then
	    SetNetworkData("MARKV2", name, id, "TMPL")
	    MagicMarker:SendUrgentMessage()
	 end
      end
   end
end

local function LowSetTarget(id, uid, val, ccid, guid)
   if id and id > 0 and id < 9 then 
      markedTargets[id].guid  = guid
      markedTargets[id].uid  = uid 
      markedTargets[id].ccid  = ccid
      markedTargets[id].value = val
   end
end

local function GUIDToUID(guid)
   local uid = tonumber(sub(guid, 7, 12), 16)
   if uid == 0 then
      return nil
   end
   return tostring(uid)
end

-- Returns [GUID, UID, Name]
function MagicMarker:GetUnitID(unit)
   local guid, uid
   local unitName = UnitName(unit)
   guid = UnitGUID(unit)
   uid = GUIDToUID(guid)
   return guid, uid or MagicMarker:SimplifyName(unitName), unitName
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
      externalTargets[id] = {}
      templateTargets[id] = {}
   end

   spellIdToCCID = MagicComm.spellIdToCCID
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


function MagicMarker:OnCommMarkV2(mark, guid, type, name)
   if type == "TMPL" then
      if templateTargets[mark].name ~= guid then
	 if markedTargets[mark].name and markedTargets[mark].name ~= guid then
	    MagicMarker:SmartMark_RemoveGUID(markedTargets[mark].guid, nil, nil, true)
	 end
	 SetTemplateTarget(mark, guid, true)
	 SetRaidTarget(guid, mark)
	 self:SmartMark_RecalculateMarks()
	 if self.debug then self:debug("[Net] Added template unit %s with mark %s.", guid, self:GetTargetName(mark) ) end
      elseif self.trace then
	 self:trace("[Net] Duplicate template unit %s received.", guid)
      end
   else 
      local data,new = self:SmartMark_AddGUID(guid, GUIDToUID(guid))
      if new then
	 if self.debug then self:debug("[Net] Added unit %s to list.", new.name or guid) end
      elseif self.trace then
	 self:trace("[Net] Duplicate unit guid %s received.", guid)
      end
   end
end
   
function MagicMarker:OnCommUnmarkV2(guid, mark)
   local data = assignedTargets[guid]
   local changed = MagicMarker:SmartMark_RemoveGUID(guid, mark, true)
   local name = guid
   if self.debug then
      name = (data and data.name) or name
   end
   if changed then
      if self.debug then self:debug("[Net] Removing %s from %s.", self:GetTargetName(mark), name) end
   elseif self.trace then
      self:trace("[Net] Already removed %s from %s.", self:GetTargetName(mark), name)
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

function MagicMarker:HandleCombatEvent(_, _, event, _, _, _,
				       guid, name, _, spellid, spellname)
   if db.autolearncc and event == "SPELL_AURA_APPLIED" then
      local ccid = spellIdToCCID[spellid]
      if not ccid then return end
      uid = GUIDToUID(guid)
      if not uid then return end
      
      local hash = self:GetUnitHash(uid, true)
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
	 elseif type(ccid) == "number" then
	    addcc(ccid)
	 end
	 self:NotifyChange()
      end
   elseif event == "UNIT_DIED" or event == "PARTY_KILL" then
      local data = assignedTargets[guid]
      if data then
	 if self.debug then self:debug("Releasing %s from dead mob %s.", self:GetTargetName(data.mark), name) end
	 MagicMarker:SmartMark_RemoveGUID(guid, data.mark, false, true)
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
	 self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMark_MarkUnit", "target")
      end
      self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "SmartMark_MarkUnit", "mouseover")   
      self:RegisterEvent("PLAYER_REGEN_ENABLED", "ScheduleGroupScan")
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
      self:UnregisterEvent("PLAYER_REGEN_ENABLED") -- rescan group every time we exit combat.
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
   self:IterateGroup(function (self, unit) self:SmartMark_MarkUnit(unit.."target") end, true)
end

local groupScanTimer

function MagicMarker:LogClassInformation(unitName, class)
   if not class then _,class = UnitClass(unitName)  end
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
      if markedTargets[id].uid and markedTargets[id].uid ~= unit then
	 MagicMarker:SmartMark_RemoveGUID(markedTargets[id].guid, nil, nil, true)
      end
      SetTemplateTarget(id, unit)
      self:SetRaidTarget(unit, id)
   end
   self:SmartMark_RecalculateMarks()
end

function MagicMarker:IterateGroup(callback, useID, ...)
   local id, name
   if self.spam then self:spam("Iterating group...") end
   
   if GetNumRaidMembers() > 0 then
      local maxgrp, class, groupid, online, dead
      local playerName = UnitName("player")
      local zoneID, zone = self:GetZoneName()

      maxgrp = self.zoneGroupNum[zoneID]

      for id = 1,GetNumRaidMembers() do
	 name, _, groupid, _, _, class, _, online, dead = GetRaidRosterInfo(id)
	 if name == playerName or (online and (not db.filterdead or not dead) and (not maxgroup or groupid <= maxgroup)) then
	    callback(self, (useID and "raid"..id) or name, class, ...)
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
      for id in pairs(usedMarks) do
	 if markedTargets[id].uid and markedTargets[id].uid ~= usedMarks[id] then
	    MagicMarker:SmartMark_RemoveGUID(markedTargets[id].guid, nil, nil, true)
	 end
	 SetTemplateTarget(id, usedMarks[id])
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
function MagicMarker:GetUnitHash(uid, currentZone)
   if not uid then return end
   if currentZone then
      local zone = MagicMarker:GetZoneName()
      local tmpHash = mobdata[zone]
      if tmpHash then
	 return tmpHash.mobs[uid]
      end
   else
      for _, data in pairs(mobdata) do
	 if data.mobs[uid] then
	    return data.mobs[uid]
	 end
      end
   end
end


local unitValueCache = {}

function MagicMarker:UnitValue(uid, hash, modifier)
   --   if unitValueCache[unit] then return unitValueCache[unit] end
   local unitData = hash or self:GetUnitHash(uid, true)
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
   tmpl = templateTargets,
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
   local raidScanTimer
   local ccUsed = {}
   local marksUsed = {}
   local categoryMarkCache = {}
   local newCcCount = {}

   function MagicMarker:OnCommResetV2()
      if self.debug then
	 self:debug("[Net] Raid cache clear received.")
      end

      valueModifier = 0.99

      for id in pairs(ccUsed)            do ccUsed[id] = nil            end
      for id in pairs(newCcCount)        do newCcCount[id] = nil        end
      for id in pairs(assignedTargets)   do assignedTargets[id] = nil   end
      for id in pairs(categoryMarkCache) do categoryMarkCache[id] = nil end
      for id in pairs(tankPriorityList)  do tankPriorityList[id] = nil  end
      for id in pairs(ccPriorityList)    do ccPriorityList[id] = nil    end

      for id = 1,8 do
	 LowSetTarget(id)
	 SetExternalTarget(id)
	 SetTemplateTarget(id)
	 marksUsed[id] = nil
      end
   end

   function MagicMarker:SmartMark_RecalculateMarks()
      local id, data, ccount
      local inCombat = InCombatLockdown()
      local canReprioritize = not inCombat or not next(assignedTargets)
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
      for id = 1,8 do 
	 if db.honorMarks and externalTargets[id].guid then
	    marksUsed[id] = true
	    assignedTargets[externalTargets[id].guid] = externalTargets[id]
	    if self.debug then self:debug("++ %s => %s [external]", self:GetTargetName(id), externalTargets[id].name) end
	 elseif templateTargets[id].guid then
	    marksUsed[id] = true
	    assignedTargets[templateTargets[id].guid] = templateTargets[id]
	    if self.debug then self:debug("++ %s => %s [tmpl]", self:GetTargetName(id), templateTargets[id].name) end
	 end  
      end

      -- Update list of marks used on the raid
      if db.honorRaidMarks then
	 self:IterateGroup(function(self, unit)
			      local id = GetRaidTargetIndex(unit)
			      if id and not templateTargets[id].guid then
				 local guid = UnitGUID(unit)
				 assignedTargets[guid] = { name = unit, mark = id, guid = guid, uid = name }
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
	       if cc[category] and (not class or raidClassList[class] and raidClassList[class] > 0) then 
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
	       data.mark = nil
	       data.ccused = nil
	       if self.debug then self:debug("== No mark available for %s.", data.name) end
	    else
	       data.mark = nextid
	       data.ccused = 1
	       assignedTargets[data.guid] = data
	       if self.debug then self:debug("++ %s => %s [tank].", self:GetTargetName(nextid), data.name) end
	    end
	 end
      end

      
      if raidScanTimer then self:CancelTimer(raidScanTimer, true) end
      raidScanTimer = self:ScheduleTimer("SmartMark_RemarkRaid", 1.0)
      
      if self.debug then self:debug("Done.") end

      -- TODO - need to rework syncing for this. 
      for guid,data in pairs(assignedTargets) do
	 if data.ccused then
	    LowSetTarget(data.mark, data.uid, data.ccused == 1 and data.value or data.ccval, data.ccused, guid)
	 elseif data.uid ~= data.name then
	    LowSetTarget(data.mark, data.uid, 0, -1, guid)
	 elseif data.mark then
	    LowSetTarget(data.mark, data.uid, nil, -2, data.name)
	 end
      end
   end

   local function SmartMark_MarkRaidTarget(self, unit, _, marked)
      local target = unit .. "target"
      local guid = UnitGUID(target)
      if not marked[guid] then
	 local data = assignedTargets[guid]
	 if data and data.value then
	    marked[guid] = true
	    if data.mark ~= GetRaidTargetIndex(target) then
	       if self.trace then
		  self:trace("Marking %s with %s [%s]",
			     data.name or guid,
			     self:GetTargetName(data.mark),
			     UnitName(unit))
	       end
	       data.lastSetMark = data.mark
	       SetRaidTarget(target, data.mark)
	    end
	 end
      end
   end
   
   function MagicMarker:SmartMark_RemarkRaid()
      if raidScanTimer then
	 self:CancelTimer(raidScanTimer, true)
	 raidScanTimer = nil
      end
      self:IterateGroup(SmartMark_MarkRaidTarget, true, {})
      SetNetworkData("ASSIGN", self:GetAssignData())
      self:SendBulkMessage()
   end

   function MagicMarker:SmartMark_AddGUID(guid, uid, name, mobHash)
      for id, data in ipairs(tankPriorityList) do
	 if data.guid == guid then
	    return data -- already known
	 end
      end
      local value, ccval, hash = self:UnitValue(uid, mobHash, valueModifier)
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

      if newhash.hash and newhash.hash.category == 2 and newhash.hash.ccopt then
	 ccPriorityList[#ccPriorityList+1]     = newhash
	 sort(ccPriorityList, SmartMark_CCSorter)
      end

      self:SmartMark_RecalculateMarks()

      return assignedTargets[guid], newhash
   end

   local function SmartMark_CleanList(hash, guid)
      local found
      for id, data in ipairs(hash) do	
	 if found then
	    hash[id-1] = data
	 elseif data.guid == guid then
	    if MagicMarker.trace then MagicMarker:trace(" Found unit to remove: %s", data.guid) end
	    found = data
	 end
      end
      if found then
	 hash[#hash] = nil
      end
      return found
   end

   function MagicMarker:SmartMark_RemoveGUID(guid, mark, fromNetwork, delay)
      local changed
      if self.trace then self:trace("Looking for unit on tank list...") end
      local changed = SmartMark_CleanList(tankPriorityList, guid)
      if changed then
	 if self.trace then self:trace("Removed from tank list, checking for CC.") end
	 if changed.hash.category == 2 and changed.hash.ccopt then
	    -- We only clean cc list if needed
	    if SmartMark_CleanList(ccPriorityList, guid) and self.trace then self:trace("Removed from cc list...") end
	 end
	 mark = changed.mark
      end
      
      if mark then
	 if externalTargets[mark].guid == guid then
	    SetExternalTarget(mark)
	    if self.trace then self:trace("Removed external target...") end
	    changed = true
	 end
	 if templateTargets[mark].guid == guid then
	    SetTemplateTarget(mark)	    
	    if self.trace then self:trace("Removed template target...") end
	    changed = true
	 end
      end

      if changed then
	 assignedTargets[guid] = nil
	 if mark then -- do some cleanup
	    LowSetTarget(mark)
	    marksUsed[mark] = nil
	    if type(changed) == "table" then
	       if changed.ccused then
		  -- Clean up crowd control cache
		  ccUsed[changed.ccused] = (ccUsed[changed.ccused] or 1) - 1
		  newCcCount[changed.uid] = (newCcCount[changed.uid] or 1) - 1
	       end
	    end
	 end
	 if not fromNetwork then
	    SetNetworkData("UNMARKV2", guid, mark)
	    self:SendUrgentMessage()
	 end
	 if not InCombatLockdown() and not delay then
	    -- only recalculate when not in combat or if battlemarking is enabled.
	    if self.trace then self:trace("Recalculate due to changed unit lists...") end
	    self:SmartMark_RecalculateMarks()
	 end
      end
      return changed
   end

   function MagicMarker:SmartMark_MarkUnit(unit)
      if not UnitExists(unit) then return end
      local unitName = UnitName(unit)
      if UnitIsDead(unit) then
	 return
      elseif UnitIsEligable(unit) then
	 local unitTarget = GetRaidTargetIndex(unit)
	 local guid, uid = MagicMarker:GetUnitID(unit)
	 local mobHash = self:InsertNewUnit(uid, unitName, unit)
	 local data, new

	 if not self:IsValidMarker() then
	    return
	 end
	 if not IsModifierPressed() and unit == "mouseover" then
	    -- Modifier isn't pressed and it's a mouseover, so return
	    return
	 end

	 data = assignedTargets[guid]
	 if not data then -- not marked but might still be known!
	    for _,tmpdata in pairs(tankPriorityList) do
	       if tmpdata.guid == guid then
		  data = tmpdata
		  break
	       end
	    end
	 end
	 if not data and unitTarget and db.honorMarks then
	    local ext = externalTargets[unitTarget] 
	    if ext.guid ~= guid then -- guids are not matching
	       for id,data in pairs(externalTargets) do
		  if data.guid == guid then 
		     SetExternalTarget(id) -- we had it under a different target, release it
		     break
		  end
	       end
	       SetExternalTarget(unitTarget, guid, uid, unitName, mobHash) -- set it
	       if self.debug then
		  self:debug(L["Added third party mark (%s) for mob %s."],
			     self:GetTargetName(unitTarget), unitName)
	       end
	       self:SmartMark_RecalculateMarks()
	    end
	    return
	 end
	 
	 if not data then
	    data, new = self:SmartMark_AddGUID(guid, uid, unitName, mobHash) 
	 end   

	 if data and data.mark ~= unitTarget then
	    data.lastSetMark = data.mark
	    self:SetRaidTarget(unit, data.mark)
	    SetNetworkData("MARKV2", guid, data.mark, nil, data.name)
	    self:SendUrgentMessage()
	 end
      end
   end
end

do
   local tmpdata = {}
   function MagicMarker:GetAssignData()
      for id in pairs(tmpdata) do
	 if not assignedTargets[id] then
	    tmpdata[id] = nil
	 end
      end
      for id,data in pairs(assignedTargets) do
	 if data.value then 
	    if not tmpdata[id] then tmpdata[id] = {} end
	    local m = tmpdata[id]
	    m.name  = data.name
	    m.mark  = data.mark == data.lastSetMark and data.mark
	    m.val   = data.ccused == 1 and data.value or data.ccval
	    m.cc    = self:GetCCName(data.ccused, 1)
	 end
      end
      return tmpdata
   end
end

function MagicMarker:SetRaidTarget(unit, mark)
   if mark and unit and GetRaidTargetIndex(unit) ~= mark then
      SetRaidTarget(unit, mark)
   end
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
   self:SmartMark_MarkUnit("target")
end

function MagicMarker:UnmarkSingle()
   if UnitExists("target") then
      guid = UnitGUID("target")
      mark = GetRaidTargetIndex("target")
      MagicMarker:SmartMark_RemoveGUID(guid, mark)
      if mark then
	 SetRaidTarget("target", 0)
      end
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
   local targets = {}
   local markToUID = {}
   valueModifier = 0.99

   for id in pairs(tankPriorityList) do tankPriorityList[id] = nil end
   for id in pairs(ccPriorityList) do ccPriorityList[id] = nil end
   
   for id,data in pairs(assignedTargets) do
      if type(data) == "table" then 
	 markToUID[data.mark] = data.uid
      end
      assignedTargets[id] = nil
   end


   if db.honorRaidMarks and not hardReset then
      usedRaidIcons = {}
      -- Look at the marks in the raid to ensure we don't reset them.
      self:IterateGroup(function(self, unit)
			   local id = GetRaidTargetIndex(unit)
			   if id and not templateTargets[id].guid then
			      usedRaidIcons[id] = unit
			      if unit == playerName then
				 playerIcon = id
			      end
			   end
			end)
   end
   
   
   for id = 1, 8 do
      if not (usedRaidIcons and usedRaidIcons[id]) then
	 LowSetTarget(id)
	 if hardReset or db.resetRaidIcons then SetRaidTarget("player", id) end
	 SetTemplateTarget(id)
	 SetExternalTarget(id)
      end
   end

   if targets then
      SetNetworkData("CLEARV2")
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
   else
      return
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

-- number of groups able to enter the instance, used when scanning groups for CC etc.
MagicMarker.zoneGroupNum = {
   ["BlackTemple"] = 5,
   ["Gruul'sLair"] = 5,
   ["HyjalSummit"] = 5,
   ["Karazhan"] = 2,
   ["Magtheridon'sLair"] = 5,
   ["SerpentshrineCavern"] = 5,
   ["SunwellPlateau"] = 5,
   ["TempestKeep"] = 5,
   ["Zul'Aman"] = 2,
}
