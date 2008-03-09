--[[
**********************************************************************
MagicMarker - your best friend for raid marking. See README.txt for
more details.
**********************************************************************
]]


MagicMarker = LibStub("AceAddon-3.0"):NewAddon("MagicMarker", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)


-- Upvalue of global functions
local GetRaidTargetIndex = GetRaidTargetIndex
local GetRealZoneText = GetRealZoneText
local GetTime = GetTime
local IsAltKeyDown = IsAltKeyDown
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

-- CC Classes, matches CC_LIST in Config.lua. Tank/kite has no classes specified for it
local CC_CLASS = { false, "MAGE", "WARLOCK", "PRIEST", "DRUID", "HUNTER", false , "PRIEST", "WARLOCK", "ROGUE" }


function MagicMarker:OnInitialize()
   -- Set up the database
   MagicMarkerDB = MagicMarkerDB or { }
   MagicMarkerDB.frameStatusTable = MagicMarkerDB.frameStatusTable or {}
   MagicMarkerDB.mobdata = MagicMarkerDB.mobdata or {} 
   MagicMarkerDB.targetdata = MagicMarkerDB.targetdata or { ["TANK"]={ 8, 1, 2, 3, 4, 5, 6, 7 } }

   MagicMarkerDB.unitCategoryMap = nil -- Delete old data, no way to convert since it's missing zone info

   self:UpgradeDatabase()
   
   mobdata = MagicMarkerDB.mobdata
   targetdata = MagicMarkerDB.targetdata

   log = self:GetLoggers()

   self:SetLogLevel(MagicMarkerDB.logLevel or (MagicMarkerDB.debug and self.logLevels.DEBUG) or self.logLevels.INFO)
   
   MagicMarkerDB.debug = nil -- no longer used
end

function MagicMarker:OnEnable()
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")
   self:ZoneChangedNewArea()
   self:GenerateOptions()
   self:RegisterChatCommand("magic", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end, false, true)
   self:RegisterChatCommand("mm", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end, false, true)
   self:RegisterChatCommand("mmtmpl", "MarkRaidFromTemplate", false, true)
   self:ScanGroupMembers()
end

function MagicMarker:OnDisable()
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterChatCommand("magic")
   self:DisableEvents()
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
	 if self:ReleaseMark(raidMark, unitID) then
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
   if log.debug then log.debug("Rescanning raid/party member classes.") end
   self:IterateGroup(self.LogClassInformation)
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
   raidMarkCache = {}

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
      if not markedValue or value > markedValue then
	 -- This will return the first free target or an already used target
	 -- if the value of the new target is higher.
	 if log.trace then log.trace("LowFindMark => "..tostring(id).." value "..tostring(value)) end
	 markedTargetValues[id] = value
	 return id
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
   
   if unitHash then
      if self:IsUnitIgnored(unitHash.priority) then return -1 end
      unitValue = self:UnitValue(unitName, unitHash)
      cc = unitHash.cc
      if unitHash.category ~= cc_list_used then
	 tankFirst = false
      end
   end
   if log.trace then log.trace("  NextUnitMark for "..unitName..": tankFirst="..tostring(tankFirst)..", unitValue="..unitValue) end
   local raidMarkList 
   local raidMarkID
   
   if tankFirst or not cc then
      raidMarkList = self:GetMarkForCategory(1) 
      raidMarkID = LowFindMark(raidMarkList, unitValue)
      if raidMarkID and log.debug then log.debug("Marked %s as tank with %s", unitName, self:GetTargetName(raidMarkID)) end
   end -- tank marks

   if not raidMarkID then 
      for _,category in ipairs(cc) do
	 local class = CC_CLASS[category]
	 local cc_used_count = ccUsed[category] or 0
	 if not class or cc_used_count < (raidClassList[class] or 0) then
	    raidMarkList = self:GetMarkForCategory(category)
	    raidMarkID = LowFindMark(raidMarkList, unitValue)
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
      raidMarkID = LowFindMark(raidMarkList, unitValue)
      if raidMarkID and log.debug then
	 log.debug("Marked %s tank (fallback) with %s", unitName, self:GetTargetName(raidMarkID))
      end 
   end
   
   -- None left for the specified category, 
   -- falling back to the "catch all"...
   return raidMarkID or 0, cc_list_used -- no target found
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
   unitValueCache[unit]  = value
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
   elseif UnitIsEligable(unit) and (IsAltKeyDown() or unit ~= "mouseover") then
      local unitGUID = GetUniqueUnitID(unit)
      local unitTarget = GetRaidTargetIndex(unit)
      
      self:InsertNewUnit(unitName, GetRealZoneText()) -- This will insert it if it's missing
      
      if log.trace then log.trace("Marking "..unitGUID.." ("..(unitTarget or "N/A")..")") end
      
      if markedTargets[unitTarget] and markedTargets[unitTarget].guid == unitGUID then
	 if log.trace then log.trace("  already marked.") end
	 return
      end
      
      if recentlyAdded[unitGUID] then 
	 if log.trace then log.trace("  recently marked.") end
	 return
      end
      
      local newTarget, ccID = self:GetNextUnitMark(unit)
      
      if newTarget == 0 then
	 if log.trace then log.trace("  No more raid targets available -- disabling marking.") end
	 if markingEnabled then
	    self:ToggleMarkingMode()
	 end
      elseif newTarget == -1 then
	 if log.trace then log.trace("  Target on ignore list") end
      else
	 recentlyAdded[unitGUID] = true
	 self:ScheduleTimer(function(arg) recentlyAdded[arg] = nil end, 0.7, unitGUID) -- To clear it up
	 
	 if log.trace then log.trace("  => "..newTarget) end
	 if markedTargets[newTarget] then 
	    ccUsed[ markedTargets[newTarget].ccid ] = ccID
	    markedTargets[newTarget].ccid = ccID	    
	    markedTargets[newTarget].guid = unitGUID
	 else
	    markedTargets[newTarget] = { guid=unitGUID, ccid = ccID }
	 end
	 SetRaidTarget(unit, newTarget)
      end
   else
      if unitName and log.trace then log.trace("Ignoring "..unitName) end 
   end
end

function MagicMarker:ReleaseMark(mark, target)
   SetRaidTarget(target, 0)
   if markedTargets[mark] then
      local ccid = markedTargets[mark].ccid
      if ccid and ccUsed[ccid] then
	 ccUsed[ ccid ] = ccUsed[ ccid ] - 1
      end
      markedTargets[mark] = nil
      markedTargetValues[mark] = nil
      return true
   end
end

function MagicMarker:ReserveMark(mark, unit, value)
   if not markedTargets[mark] or markedTargetValues[mark] < value then
      if markedTargets[mark] then
	 local ccid = markedTargets[mark].ccid
	 if ccid and ccUsed [ccid] then
	    ccUsed[ ccid ] = ccUsed[ ccid ] - 1
	 end
	 markedTargets[mark].ccid = "NONE"
	 markedTargets[mark].guid = unit
      else
	 markedTargets[mark] = { guid=unit, ccid = "NONE" }
      end
      markedTargetValues[mark] = value -- don't override
      SetRaidTarget(unit, mark)
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
      if mark then self:ReleaseMark(mark, "target") end
   end
end

-- Disable memoried marksdata
function MagicMarker:ResetMarkData()
   local id
   ccUsed = { }
   recentlyAdded = {}
   for id = 8,0,-1 do
      markedTargets[id]  = nil
      markedTargetValues[id] = nil
      SetRaidTarget("player", id)
   end
   -- Hack, sometimes the last mark isn't removed.
   self:ScheduleTimer(function() SetRaidTarget("player", 0) end, 0.75)
   self:Print(L["Resetting raid targets."])
   self:ScanGroupMembers()
end


