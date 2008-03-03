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
-- Parameters
local MagicMarker = MagicMarker
local markedTargets = {}
local markedTargetValues= {}
local recentlyAdded = {}


-- upvalues of config data
local mobdata
local targetdata

function MagicMarker:OnInitialize()
   -- Set up the database
   MagicMarkerDB = MagicMarkerDB or { }
   MagicMarkerDB.frameStatusTable = MagicMarkerDB.frameStatusTable or {}
   MagicMarkerDB.mobdata = MagicMarkerDB.mobdata or {} 
   MagicMarkerDB.targetdata = MagicMarkerDB.targetdata or { ["TANK"]={ 8, 1, 2, 3, 4, 5, 6, 7 } }

   MagicMarkerDB.unitCategoryMap = nil -- Delete old data, no way to convert since it's missing zone info

   mobdata = MagicMarkerDB.mobdata
   targetdata = MagicMarkerDB.targetdata
   
   self:GenerateOptions()
   self:RegisterChatCommand("magic", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end)
end

function MagicMarker:OnEnable()
   self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMarkUnit", "target")
   self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "SmartMarkUnit", "mouseover")   
end

function MagicMarker:OnDisable()
   self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
   self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

local function GetUniqueUnitID(unit) 
   local unitName = UnitName(unit)
   return format("%s:%d:%s:%d:%s",
			unitName, UnitLevel(unit),
			UnitClassification(unit), UnitSex(unit),
			UnitCreatureType(unit))
   
end

-- Return whether a target is eligable for marking
local function UnitIsEligable (unit)
   return UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) and
      UnitCreatureType(unit) ~= "Critter"
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
function MagicMarker:GetNextUnitMark(unit) 
   local unitName = GetUnitName(unit)
   local unitHash = GetUnitHash(unitName)
   local unitValue = 0
   local cc,tankFirst = true
   
   if unitHash then
      if self:IsUnitIgnored(unitHash.priority) then return -1 end
      unitValue = self:UnitValue(unitName, unitHash)
      cc = unitHash.cc
      if unitHash.category == 1 then
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
	 raidMarkList = self:GetMarkForCategory(category)
	 raidMarkID = LowFindMark(raidMarkList, unitValue)
	 if raidMarkID then break end
      end
   end

   -- no mark found, fall back to tank list for default
   if not raidMarkID then
      raidMarkList = self:GetMarkForCategory(1)
      raidMarkID = LowFindMark(raidMarkList, unitValue)
   end
   
   -- None left for the specified category, 
   -- falling back to the "catch all"...
   return raidMarkID or 0 -- no target found
end

local unitValueCache = {}

function MagicMarker:UnitValue(unit, hash)
   if unitValueCache[unit] then return unitValueCache[unit] end
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
   if UnitIsEligable(unit) and (IsAltKeyDown() or unit == "target") then
      local unitGUID = GetUniqueUnitID(unit)
      local unitTarget = GetRaidTargetIndex(unit)
      
      self:InsertNewUnit(unitName, GetRealZoneText()) -- This will insert it if it's missing
      
      self:PrintDebug("Marking "..unitGUID.." ("..(unitTarget or "N/A")..")")
      
      if markedTargets[unitTarget] == unitGUID then
	 self:PrintDebug("  already marked.")
	 return
      end
      
      local now = GetTime()
      if recentlyAdded[unitGUID] and (now - recentlyAdded[unitGUID]) < 0.8 then
	 self:PrintDebug("  recently marked.")
	 return
      end
      
      recentlyAdded[unitGUID] = now
      
      local newTarget = self:GetNextUnitMark(unit)
      
      if newTarget == 0 then
	 self:PrintDebug("  No more raid targets available -- disabling marking.")
	 if markingEnabled then
	    self:ToggleMarkingMode()
	 end
      elseif newTarget == -1 then
	 self:PrintDebug("  Target on ignore list")
      else
	 self:PrintDebug("  => "..newTarget)
	 markedTargets[newTarget] = unitGUID
	 SetRaidTarget(unit, newTarget)
      end
   else
      if unitName then self:PrintDebug("Ignoring "..unitName) end
   end
end


function MagicMarker:MarkSingle()
   if UnitExists("target") then
      self:SmartMarkUnit("target")
   end
end

function MagicMarker:UnmarkSingle()
   if UnitExists("target") then
      local unitTarget = GetRaidTargetIndex("target")
      SetRaidTarget("target", 0)
      markedTargets[unitTarget] = nil
      markedTargetValues[unitTarget] = nil
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
   markedTargets = { }
   markedTargetValues = { }
   for id = 8,0,-1 do
      SetRaidTarget("player", id)
   end
   -- Hack, sometimes the last mark isn't removed.
   self:ScheduleTimer(function() SetRaidTarget("player", 0) end, 0.2)
   self:Print(L["Resetting raid targets."])
end


-- Keybind names

BINDING_HEADER_MagicMarker = L["Magic Marker"]
BINDING_NAME_MAGICMARKRESET = L["Reset raid icons"]
BINDING_NAME_MAGICMARKMARK = L["Mark selected target"]
BINDING_NAME_MAGICMARKUNMARK = L["Unmark selected target"]
BINDING_NAME_MAGICMARKTOGGLE = L["Toggle config dialog"]
