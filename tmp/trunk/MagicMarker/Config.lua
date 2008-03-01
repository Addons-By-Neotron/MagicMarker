--[[
  MagicMarker configuration
]]

local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)

local options = {}
local db = MagicMarkerDB

local marks = {
   ["star"] = L["Star"], 
   ["circle"] = L["Circle"],
   ["diamond"] = L["Diamond"],
   ["triangle"] = L["Triangle"],
   ["moon"] = L["Moon"],
   ["square"] = L["Square"],
   ["cross"] = L["Cross"],
   ["skull"] = L["Skull"],
}

local options = { 
   type = "group", 
   name = L["Magic Marker Configuration"],
   args = {
      mobs = {
	 type = "group",
	 name = L["Mob Group Controls"],
	 args = {}, 
	 order = 300
      }, 
      categories = {
	 type = "group",
	 name = L["Categories"],
	 order = 0,
	 args = { }
      }, 
      add_group = {
	 type = "group",
	 name = L["Add new category"], 
	 desc = L["Add new category"],
	 order = 1000,
	 args = {}, 
      },
   }
}

function MagicMarker:GenerateOptions(categories)
   local opts = options.args.categories.args;
   for id, catName in pairs(categories) do
      opts["group"..id] = {
	 type = "group",
	 name = catName,
	 order = id,
	 args = {}
      }
   end
end


LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Magic Marker"], options, "magicmarker") 
