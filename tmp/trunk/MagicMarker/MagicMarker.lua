--[[
**********************************************************************
MagicMarker - your best friend for raid marking. See README.txt for
more details.
**********************************************************************
]]


MagicMarker = LibStub("AceAddon-3.0"):NewAddon("MagicMarker", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)


-- Upvalue of global functions
local GetTime = GetTime
local GetRealZoneText = GetRealZoneText
local IsAltKeyDown = IsAltKeyDown
local format = string.format
local UnitGUID = UnitGUID
local SetRaidTarget = SetRaidTarget
local GetRaidTargetIndex = GetRaidTargetIndex

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

   mobdata = MagicMarkerDB.mobdata
   targetdata = MagicMarkerDB.targetdata

end

function MagicMarker:OnEnable()
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")
   self:ZoneChangedNewArea()
   self:GenerateOptions()
   self:RegisterChatCommand("magic", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end, false, true)
   self:RegisterChatCommand("mmtmpl", "MarkRaidFromTemplate", false, true)
   self:ScanGroupMembers()
end

function MagicMarker:OnDisable()
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterChatCommand("magic")
   self:DisableEvents()
end

function MagicMarker:ZoneChangedNewArea()
   local zone = GetRealZoneText()
   
   if zone == nil or zone == "" then
      -- zone hasn't been loaded yet, try again in 5 secs.
      self:ScheduleTimer(self.ZoneChangedNewArea,5,self)
      --self:Print("Unable to determine zone - retrying in 5 secs")
      return
   end

   if IsInInstance() then
      self:EnableEvents()
   else
      self:DisableEvents()
   end
end

function MagicMarker:EnableEvents()
   if not self.addonEnabled then
      self.addonEnabled = true
      self:Print(L["Magic Marker enabled."])
      --self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMarkUnit", "target")
      self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "SmartMarkUnit", "mouseover")   
      self:RegisterEvent("RAID_ROSTER_UPDATE", "ScheduleGroupScan")
      self:RegisterEvent("PARTY_MEMBERS_CHANGED", "ScheduleGroupScan")
      self:ScheduleGroupScan()
   end
end

function MagicMarker:DisableEvents()
   if self.addonEnabled then
      self.addonEnabled = false
      self:Print(L["Magic Marker disabled."])
      --self:UnregisterEvent("PLAYER_TARGET_CHANGED")
      self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")   
      self:UnregisterEvent("RAID_ROSTER_UPDATE")
      self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
   end
end

local function GetUniqueUnitID(unit)
   if UnitGUID then return UnitGUID(unit) end -- 2.4
   local unitName = UnitName(unit)
   return format("%s:%d:%s:%d:%s",
			unitName, UnitLevel(unit),
			UnitClassification(unit), UnitSex(unit),
			UnitCreatureType(unit))
   
end

local party_idx = { "party1", "party2", "party3", "party4" }


function MagicMarker:MarkRaidTargets()
   local id, class, name
   raidClassList = {}
   groupScanTimer = nil
   self:PrintDebug("Making all targets of the raid.")
   
   if GetNumRaidMembers() > 0 then
      for id = 1,GetNumRaidMembers() do
	 self:SmartMarkUnit("raid"..id.."target");
      end
   elseif GetNumPartyMembers() > 0 then
      for id = 1,GetNumPartyMembers() do
	 self:SmartMarkUnit("raid"..id.."target");
      end
   end
end

local groupScanTimer

function MagicMarker:ScanGroupMembers()
   local id, class, name
   raidClassList = {}
   groupScanTimer = nil
   self:PrintDebug("Rescanning raid/party member classes.")
   
   if GetNumRaidMembers() > 0 then
      for id = 1,GetNumRaidMembers() do
	 name = GetRaidRosterInfo(id); 
	 _,class = UnitClass(name)
	 raidClassList[class] = (raidClassList[class] or 0) + 1
      end
   else
      if GetNumPartyMembers() > 0 then
	 for id = 1,GetNumPartyMembers() do
	    _,class = UnitClass(party_idx[id]);
	    raidClassList[class] = (raidClassList[class] or 0) + 1
	 end
      end
      _,class = UnitClass("player")
      raidClassList[class] = (raidClassList[class] or 0) + 1
   end
end


function MagicMarker:CacheRaidMarkForUnit(unit)
   local id = GetRaidTargetIndex(unit)
   if id then
      raidMarkCache[unit] = id
      self:PrintDebug("Cached "..id.." for "..unit);
   end
end

function MagicMarker:CacheRaidMarks()
   raidMarkCache = {}
   
   self:PrintDebug("Caching raid / party marks")
   self:IterateGroup(self.CacheRaidMarkForUnit)
end

function MagicMarker:MarkRaidFromCache()
   for unit,id in pairs(raidMarkCache) do
      self:ReserveMark(id, unit, 1000)
   end
end

function MagicMarker:IterateGroup(callback)
   local id, name
   raidMarkCache = {}

   self:PrintDebug("Caching raid / party marks")
   
   if GetNumRaidMembers() > 0 then
      for id = 1,GetNumRaidMembers() do
	 callback(self, GetRaidRosterInfo(id))
      end
   else
      if GetNumPartyMembers() > 0 then
	 for id = 1,GetNumPartyMembers() do
	    callback(self, GetRaidRosterInfo(party_idx[id]))
	 end
      end
      callback(self, GetRaidRosterInfo("player"));
   end   
end

function MagicMarker:MarkRaidFromTemplate(template)
   MagicMarker:PrintDebug("Marking from template: "..template)
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
	 MagicMarker:PrintDebug("LowFindMark => "..tostring(id).." value "..tostring(value))
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
   self:PrintDebug("  NextUnitMark for "..unitName..": tankFirst="..tostring(tankFirst)..", unitValue="..unitValue)
   local raidMarkList 
   local raidMarkID
   
   if tankFirst or not cc then
      raidMarkList = self:GetMarkForCategory(1) 
      raidMarkID = LowFindMark(raidMarkList, unitValue)
   end -- tank marks

   if not raidMarkID then 
      for _,category in ipairs(cc) do
	 local class = CC_CLASS[category]
	 local cc_used_count = ccUsed[category] or 0
	 if not class or cc_used_count < (raidClassList[class] or 0)
	 then
	    raidMarkList = self:GetMarkForCategory(category)
	    raidMarkID = LowFindMark(raidMarkList, unitValue)
	    if raidMarkID then
	       ccUsed[category] = cc_used_count + 1
	       cc_list_used = category
	       break
	    end
	 end
      end
   end
      
   -- no mark found, fall back to tank list for default
   if not raidMarkID then
      raidMarkList = self:GetMarkForCategory(1)
      raidMarkID = LowFindMark(raidMarkList, unitValue)
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
      value = 4-unitData.priority
      if value > 0 then
	 value = value * 2 + 2-unitData.category -- Tank > CC
      end
   end
   self:PrintDebug(format("Unit Value for %s = %d", unit, value))
   unitValueCache[unit]  = value
   return value
end
   
local function unitValue(unit1, unit2) 
   return MagicMarker:UnitValue(unit1) >  MagicMarker:UnitValue(unit2)
end

function MagicMarker:SmartMarkUnit(unit)
   self:PrintDebug("Unit => "..unit)
   local unitName = UnitName(unit)
   local altKey = IsAltKeyDown()
   if UnitIsEligable(unit) and (IsAltKeyDown() or unit ~= "mouseover") then
      local unitGUID = GetUniqueUnitID(unit)
      local unitTarget = GetRaidTargetIndex(unit)
      
      self:InsertNewUnit(unitName, GetRealZoneText()) -- This will insert it if it's missing
      
      self:PrintDebug("Marking "..unitGUID.." ("..(unitTarget or "N/A")..")")
      
      if markedTargets[unitTarget] and markedTargets[unitTarget].guid == unitGUID then
	 self:PrintDebug("  already marked.")
	 return
      end
      
      if recentlyAdded[unitGUID] then 
	 self:PrintDebug("  recently marked.")
	 return
      end
      
      local newTarget, ccID = self:GetNextUnitMark(unit)
      
      if newTarget == 0 then
	 self:PrintDebug("  No more raid targets available -- disabling marking.")
	 if markingEnabled then
	    self:ToggleMarkingMode()
	 end
      elseif newTarget == -1 then
	 self:PrintDebug("  Target on ignore list")
      else
	 recentlyAdded[unitGUID] = true
	 self:ScheduleTimer(function(arg) recentlyAdded[arg] = nil end, 0.7, unitGUID) -- To clear it up
      
	 self:PrintDebug("  => "..newTarget)
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
      if unitName then self:PrintDebug("Ignoring "..unitName) end
   end
end

function MagicMarker:ReserveMark(mark, unit, value)
   if not markedTargets[mark] or markedTargetValues[mark] < value then
      if markedTargets[mark] then
	 local ccid = markedTargets[mark].ccid;
	 ccUsed[ ccid ] = ccUsed[ ccid ] - 1
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
   if UnitExists("target") then
      self:SmartMarkUnit("target")
   end
end

function MagicMarker:UnmarkSingle()
   if UnitExists("target") then
      local unitTarget = GetRaidTargetIndex("target")
      if unitTarget and markedTargets[unitTarget] then
	 SetRaidTarget("target", 0)
	 ccUsed[ markedTargets[unitTarget].ccid ] = nil
	 markedTargets[unitTarget] = nil
	 markedTargetValues[unitTarget] = nil
      end
   end
end

function MagicMarker:PrintDebug(...) 
   if MagicMarkerDB.debug then
      self:Print(...)
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


-- Keybind names

BINDING_HEADER_MagicMarker = L["Magic Marker"]
BINDING_NAME_MAGICMARKRESET = L["Reset raid icons"]
BINDING_NAME_MAGICMARKMARK = L["Mark selected target"]
BINDING_NAME_MAGICMARKUNMARK = L["Unmark selected target"]
BINDING_NAME_MAGICMARKTOGGLE = L["Toggle config dialog"]
BINDING_NAME_MAGICMARKRAID = L["Mark party/raid targets"]
BINDING_NAME_MAGICMARKSAVE = L["Save party/raid mark layout"]
BINDING_NAME_MAGICMARKLOAD = L["Load party/raid mark layout"]
