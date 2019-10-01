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

local mod = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)
local C = LibStub("AceConfigDialog-3.0")
local LD = LibStub("LibDropdown-1.0", true)
local QTIP   = LibStub("LibQTip-1.0")
local DBOpt = LibStub("AceDBOptions-3.0")
local tinsert = tinsert
local sort = table.sort
local fmt = string.format
local db, tooltip
local MMDB

local function white(str)
   return fmt("|cffffffff%s|r", str)
end

local function yellow(str)
   return fmt("|cffffff00%s|r", str)
end

local markedTargets, totalTargets

-- Options for the dropdown menu, partially populated by magic marker config data
local options = {
   type = "group",
   handler = mod,
   set = "SetProfileParam",
   get = "GetProfileParam",
   args = {
      config = { 
	 type = "execute",
	 name =  L["Toggle config dialog"],
	 desc = L["Toggle the Magic Marker configuration dialog."],
	 func = "ToggleConfigDialog",
	 order = 1
      }, 
      toggle = {
	 type = "toggle", 
	 name = L["Toggle event handling"],
	 desc = L["Enable or disable the event handling, i.e whether or not Magic Marker will insert mobs into the mob database, mark mobs etc."],
	 set = "ToggleMagicMarker",
	 get = function() return mod.addonEnabled end,
	 order = 2
      },
      assignments = {
	 type = "execute",
	 name = L["Report raid assignments"],
	 desc = L["Report the raid icon assignments to raid/party chat"]..".",
	 func = "ReportRaidMarks",
      },
      reset = {
	 type = "execute",
	 name = L["Reset raid icon cache"],
	 desc = L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."],
	 func = "ResetMarkData",
      },
      commsettings = {
	 type = "group",
	 name = L["Data Sharing"],
	 desc = L["Data Sharing"],
	 order = 1200,
	 args = {}
      },
      settings = { 
	 type = "group",
	 name = L["General Options"],
	 desc = L["General Options"],
	 order = 1100,
	 args = {}
      },
      profiledata = {
	 type = "group",
	 name = "Profile",
	 desc = "Profile",
	 order = 1300,
	 args = {}
      },
      cache = {
	 type = "group",
	 name = L["Raid mark layout caching"],
	 desc = L["RAIDMARKCACHEHELP"],
	 order = 1000,
	 args = {
	    save = {
	       type = "execute",
	       name = L["Save party/raid mark layout"],
	       desc = L["Save the current raid mark layout."],
	       func = "CacheRaidMarks",
	    },
	    load = {
	       type = "execute",
	       name = L["Load party/raid mark layout"],
	       desc = L["Load the currently saved raid mark layout."],
	       func = "MarkRaidFromCache",
	    },
	 }
      },
   }
}

function mod:SetupLDB()
   local LDB = LibStub("LibDataBroker-1.1", true)
   if not LDB then return end
   
   if LDB then
      mod.ldb =
	 LDB:NewDataObject("Magic Marker",
			   {
			      type =  "data source", 
			      label = L["Magic Marker"],
			      icon = [[Interface\Addons\MagicMarker\icon]],
			      OnClick = function(clickedframe, button)
					   if button == "LeftButton" then
					      if IsAltKeyDown() then
						 mod:ResetMarkData(IsShiftKeyDown())
					      elseif IsShiftKeyDown() then
						 mod:ToggleMagicMarker()
					      else
						 mod:ToggleConfigDialog()
					      end
					   elseif button == "MiddleButton" then
					      mod:ReportRaidMarks()
					   elseif button == "RightButton" then	
					      -- create the menu
					      if LD then						 
						 local frame = LD:OpenAce3Menu(options)
						 -- Anchor the menu to the mouse
						 frame:SetPoint("TOPLEFT", clickedframe, "BOTTOMLEFT", 0, 0)
						 frame:SetFrameLevel(clickedframe:GetFrameLevel()+100)
					      end
					   end
					end,
			      OnEnter = function(frame) mod:OnLDBEnter(frame) end,
			      OnLeave = function(frame) if tooltip then QTIP:Release(tooltip) tooltip = nil end end,
			   })
   end
   mod:UpdateLDBConfig()
   mod:UpdateLDBLabel()
end

function mod:UpdateLDB()
   mod:UpdateLDBLabel()
   if tooltip then
      mod:OnLDBEnter()
   end
end

function mod:UpdateLDBConfig()
   db = mod.db.profile
   MMDB = MagicMarkerDB   

   local mmopts = mod:GetOptions()
   options.args.commsettings.args = mmopts.args.options.args.commsettings.args
   options.args.settings.args = mmopts.args.options.args.settings.args
   if mmopts.args.options.args.profile then
      options.args.profiledata.args = mmopts.args.options.args.profile.args
      options.args.profiledata.name = mmopts.args.options.args.profile.name
      options.args.profiledata.desc = mmopts.args.options.args.profile.desc
      options.args.profiledata.handler = mmopts.args.options.args.profile.handler

   end
end
optionsdump = options
function mod:SetTargetCount(marked, total)
   markedTargets = marked
   totalTargets = total
   self:UpdateLDB()
end

function mod:UpdateLDBLabel()
   local str = white((mod.addonEnabled and L["Enabled"]) or L["Disabled"])

   if totalTargets and totalTargets > 0 then
      str = string.format("%s (%d/%d)", str, markedTargets, totalTargets)
   end
   mod.ldb.text = str
end

local function _n(text)
   return fmt("|cffffd200%s|r", text)
end

function mod:OnLDBEnter(frame)
   local y
   local zone = GetRealZoneText()
   local sortData = {}
   local hasData
   local cacheData = mod:GetMarkData()
   local valueToId = {}

   if not tooltip then
      tooltip = QTIP:Acquire("MagicMarkerLDBTooltip")
      tooltip:SetColumnLayout(4, "LEFT", "CENTER", "CENTER", "CENTER")
   else
      tooltip:Clear()      
   end
   
   -- Set up the mark data to be sorted, and see if we have data
   for id, data in pairs(cacheData) do
      if data.value then
	 local key = data.value * 10000 + id
	 valueToId[key] = id
	 tinsert(sortData,key )
	 hasData = true
      end
   end
   


   y = tooltip:AddLine( _n(L["Status"]));
   tooltip:SetCell(y, 2, mod.addonEnabled and L["Enabled"] or L["Disabled"], nil, "RIGHT", 3)
   y = tooltip:AddLine( _n(L["Zone"]))
   tooltip:SetCell(y, 2, zone, nil, "RIGHT", 3)

   local zoneID, _, heroic = mod:GetZoneName(zone)
   local inInstance, type = IsInInstance()
   if inInstance then
      local difficulty = GetInstanceDifficulty and GetInstanceDifficulty()
      local difftext
      if type == "raid" then
	 local dl = L["Raid"];
	 if difficulty == 1 then dl = dl .. " - 10"
	 elseif difficulty == 2 then dl = dl .. " - 25"
	 elseif difficulty == 3 then dl = dl .. " - 10 ".. L["Heroic"]
	 elseif difficulty == 4 then dl = dl .. " - 25 ".. L["Heroic"]
	 end
	 difftext = dl
      elseif type == 'pvp' or type == 'arena' then
	 difftext = "PvP"
      else
	 difftext = heroic and L["Heroic"] or L["Normal"]
      end
      y = tooltip:AddLine( _n(L["Difficulty"]));
      tooltip:SetCell(y, 2, difftext, nil, "RIGHT", 3)
   end
   
   if MMDB.mobdata[zoneID] then
      tooltip:AddLine(" ")
      y = tooltip:AddLine()
      tooltip:SetCell(y, 1, _n(mod:GetZoneInfo(MMDB.mobdata[zoneID])), nil, "LEFT", 4)
   end

   totalTargets  = 0
   markedTargets = 0

   if hasData then
      tooltip:AddLine(" ")
      sort(sortData, function(a,b) return a > b end)   
      tooltip:AddLine( yellow(L["Unit Name"]),
		       yellow(L["Mark Type"]), 
		       yellow(L["Score"]),
		       yellow(L["Marked"]))
      tooltip:AddSeparator()
      local data
      for _, id in pairs(sortData) do
	 id = valueToId[id]
	 data = cacheData[id]
	 if data.uid then
	    local valid
	    totalTargets = totalTargets + 1
	    if data.valid == nil then
	       valid = "N/A"
	       markedTargets = markedTargets + 1
	    elseif data.valid then
	       markedTargets = markedTargets + 1
	       valid =  L["Yes"]
	    else
	       valid = L["No"]
	    end
	    unitData = mod:GetUnitHash(data.uid)
	    tooltip:AddLine("|T"..mod:GetIconTexture(id)..":18|t".._n(unitData and unitData.name or data.uid),
			    _n(mod:GetCCName(data.ccid, data.value)),
			    _n(string.format("%2.2f", data.value)), 
			    _n(valid))
	 end
      end
   end 
   tooltip:AddLine(" ")

   local y = tooltip:AddLine()
   tooltip:SetCell(y, 1, _n(L["TOOLTIP_HINT"]), nil, "LEFT", 4)
   if frame then
      tooltip:SmartAnchorTo(frame)
   end
   tooltip:UpdateScrolling()
   tooltip:Show()
end
