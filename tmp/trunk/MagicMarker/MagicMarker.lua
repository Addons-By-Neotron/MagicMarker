--[[
**********************************************************************
MagicMarker - your best friend for raid marking. See README.txt for
more details.
**********************************************************************
]]


MagicMarker = LibStub("AceAddon-3.0"):NewAddon("MagicMarker", "AceConsole-3.0", "AceEvent-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)

local MagicMarker = MagicMarker
local learningFrame, learningScroll
local markingEnabled = false
local learningEnabled = false
local markedTargets = {}
local newTargets = {}
local targetCategoryList = {}
local recentlyAdded = {}

local mobdata
local targetdata

local ACTIONS = { TANK = 1, CC = 2, IGNORE = 3 }
local CCLIST = { TANK = 0, SHEEP = 1, BANISH = 2, SHACKLE = 3, HIBERNATE = 4, TRAP = 5, KITE = 6, MC = 7 }
local PRIORITY = { P1 = 1, P2 = 2, P3 = 3, P4 = 4 }

local CATEGORIES = {
   TANK = 1,
   SHEEP = 2, 
   BANISH = 3, 
   CC = 4, 
   OTHER = 5, 
   IGNORED = 6
}

local
   markCategories = {
   { 8, 1, 2 }, -- TANK
   { 5, 6, 4 }, -- SHEEP
   { 3, 7, 4, 5, 6 }, --    BANISH
   { 7, 4, 3 },  --    CC
   { 4, 7, 3, 5, 6, 2, 1, 8 } --    OTHER
}

local unitCategoryMap = {
}

local function ToggleDebug()
   MagicMarkerDB.debug = not MagicMarkerDB.debug
   if MagicMarkerDB.debug then
      MagicMarker:Print("Enabled debug output")
   else
      MagicMarker:Print("Disabled debug output")
   end
end

function MagicMarker:OnInitialize()
   -- Set up the database
   MagicMarkerDB = MagicMarkerDB or { }
   MagicMarkerDB.frameStatusTable = MagicMarkerDB.frameStatusTable or {}
   MagicMarkerDB.mobdata = MagicMarkerDB.mobdata or {}
   MagicMarkerDB.targetdata = MagicMarkerDB.targetdata or {}

   unitCategoryMap = MagicMarkerDB.unitCategoryMap or {}
   mobdata = MagicMarkerDB.mobData
   targetdata = MagicMarkerDB.targetdata
   
   self:GenerateOptions( {} )
   self:RegisterChatCommand("magic", function() LibStub("AceConfigDialog-3.0"):Open("Magic Marker") end)
end

function MagicMarker:OnEnable()
   
end

local function GetUniqueUnitID(unit) 
   local unitName = UnitName(unit)
   return string.format("%s:%d:%s:%d:%s",
			unitName, UnitLevel(unit),
			UnitClassification(unit), UnitSex(unit),
			UnitCreatureType(unit))
   
end

-- Return whether a target is eligable for marking
local function UnitIsEligable (unit)
   return UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) and
      UnitCreatureType(unit) ~= "Critter"
end

-- Return the next mark for the unit
function MagicMarker:GetNextUnitMark(unit) 
   local unitName = GetUnitName(unit)
   local category = unitCategoryMap[unitName]

   if category == nil then
      category = CATEGORIES.TANK
   elseif category == CATEGORIES.IGNORED then
      return -1 
   end
   
   self:PrintDebug("  Category = "..category);
   local key, value
   for key,value in pairs(markCategories[category]) do
      if not markedTargets[value] then
	 return value
      end
   end

   -- None left for the specified category, 
   -- falling back to the "catch all"...

   for key,value in pairs(markCategories[CATEGORIES.OTHER]) do
      if not markedTargets[value] then
	 return value
      end
   end
   
   return 0 -- no target found
end

function MagicMarker:SmartMarkUnit(unit)
   self:PrintDebug("Unit => "..unit)
   
   if UnitIsEligable(unit) then
      local unitGUID = GetUniqueUnitID(unit)
      local unitTarget = GetRaidTargetIndex(unit)

      self:PrintDebug("Marking "..unitGUID.." ("..(unitTarget or "N/A")..")");
      
      if markedTargets[unitTarget] == unitGUID then
	 self:PrintDebug("  already marked.")
	 return
      end

      local now = GetTime();
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
	 markedTargets[newTarget] = unitGUID
	 SetRaidTarget(unit, newTarget)
      end
   else
      self:PrintDebug("Ignoring "..UnitName(unit))
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
   end
end

function MagicMarker:PrintDebug(...) 
   if MagicMarkerDB.debug then
      self:Print(...)
   end
end

local function ChangeUnitCategory(widget, event, value)
   local unitName = widget.label:GetText()
   MagicMarker:PrintDebug("setting "..unitName.." to "..value)
   if value == CATEGORIES.TANK then
      -- Tank is default, no need to save
      unitCategoryMap[unitName] = nil 
   else
      unitCategoryMap[unitName] = value
   end
end

function MagicMarker:AddNewUnit(unit)

   if UnitIsEligable(unit) then
      local unitName = UnitName(unit)
      local zoneName = GetRealZoneText()
      self:InsertNewUnit(unitName, zoneName)
      
      if newTargets[unitName] then return end
            
      local dropdown = AceGUI:Create("Dropdown")
      
      dropdown:SetList(targetCategoryList)
      
      dropdown:SetValue(unitCategoryMap[unitName] or CATEGORIES.TANK)
      dropdown:SetLabel(unitName)

      dropdown:SetCallback("OnValueChanged", ChangeUnitCategory)
      
      newTargets[unitName] = dropdown
      learningScroll:AddChild(dropdown)   
   end
end

local function CloseLearningFrame(widget, event)
   AceGUI:Release(widget)
   learningFrame = nil
   learningScroll = nil
   if learningEnabled then
      MagicMarker:ToggleLearningMode()
   end
end

local function CreateLearningFrame()
   local f = AceGUI:Create("Frame")
   f:SetCallback("OnClose", CloseLearningFrame)
   f:SetTitle(L["Target Learner"])
   f:SetStatusText("Learning Mode Enabled")
   f:SetLayout("Fill")
   f:SetStatusTable(MagicMarkerDB.frameStatusTable)
   
   local scroll = AceGUI:Create("ScrollFrame")
   scroll:SetLayout("Flow")

   f:AddChild(scroll)
   f:Show()

   learningFrame = f
   learningScroll = scroll
end

-- Toggle interactive learning mode, allowing easy
-- categorization of targets you mouse over
function MagicMarker:ToggleLearningMode() 
   -- Don't enable marking if learning mode is on
   if markingEnabled then
      return
   end
   if not learningEnabled then
      self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "AddNewUnit", "mouseover")
      self:RegisterEvent("PLAYER_TARGET_CHANGED", "AddNewUnit", "target")
      learningEnabled = true
      if learningFrame then
	 learningFrame:SetStatusText("Learning Mode Enabled")
      else
	 newTargets = { }
	 CreateLearningFrame()
      end
   else
      self:GenerateOptions( {} )
      learningEnabled = false
      self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
      self:UnregisterEvent("PLAYER_TARGET_CHANGED")
      if learningFrame then
	 learningFrame:SetStatusText("Learning Mode Disabled")
      end
   end
end

-- Toggle smart marking. When enabled, it resets the cache
-- of already marked targets
function MagicMarker:ToggleMarkingMode()
   -- Don't enable marking if learning mode is on
   if learningEnabled then
      return
   end
   
   if not markingEnabled then
      markedTargets = { }
      markingEnabled = true
      self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMarkUnit", "target")
      self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "SmartMarkUnit", "mouseover")
      self:Print("Enabling Smart Marking")
   else
      markingEnabled = false
      self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
      self:UnregisterEvent("PLAYER_TARGET_CHANGED")
      self:Print("Disabling Smart Marking")
      RaidNotice_AddMessage(RaidBossEmoteFrame, "", ChatTypeInfo["RAID_WARNING"])
      recentlyAdded = {};
   end
end


-- Keybind names

BINDING_HEADER_MagicMarker = L["Magic Marker"]
BINDING_NAME_MAGICMARKTOGGLELEARN = L["Toggle learning mode"]
BINDING_NAME_MAGICMARKTOGGLEMARK = L["Toggle smart marking mode"]
BINDING_NAME_MAGICMARKMARK = L["Mark selected target"]
BINDING_NAME_MAGICMARKUNMARK = L["Unmark selected target"]
