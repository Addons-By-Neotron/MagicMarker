--[[
  MagicMarker configuration
]]

local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)

local BabbleZone = LibStub("LibBabble-Zone-3.0") 
local ZoneReverse = BabbleZone:GetReverseLookupTable()
local ZoneLookup  = BabbleZone:GetLookupTable()

BabbleZone = nil

local options = {}
local db = MagicMarkerDB

local options = { 
   type = "group", 
   name = L["Magic Marker"],
   args = {
      mobs = {
	 type = "group",
	 name = L["Mob Config"],
	 args = {}, 
	 order = 300
      }, 
      categories = {
	 type = "group",
	 name = L["Target Customization"],
	 order = 0,
	 args = { }
      }, 
   }
}
local mobdata, targetdata

-- Config UI name => ID
local CONFIG_MAP = {
   NUMCC=8, 
}

-- ID => Config UI name
local ACT_LIST = { "TANK", "CC" }
local CC_LIST = { "00NONE", "SHEEP", "BANISH", "SHACKLE", "HIBERNATE", "TRAP", "KITE", "MC", "FEAR" }
local PRI_LIST = { "P1", "P2", "P3", "P4" }
local RT_LIST =  { "Star",  "Circle",  "Diamond",  "Triangle",  "Moon",  "Square",  "Cross",  "Skull", "_Remove" }
local ccDropdown, priDropdown, catDropdown, raidIconDropdown




do
   ccDropdown = {}
   priDropdown = {}
   catDropdown = {}
   raidIconDropdown = {}
   for num, txt in ipairs(CC_LIST) do
      ccDropdown[txt] = L[txt]
      CONFIG_MAP[txt] = num
   end
   for num, txt in ipairs(PRI_LIST) do
      priDropdown[txt] = L[txt]
      CONFIG_MAP[txt] = num
   end
   for num, txt in ipairs(ACT_LIST) do
      catDropdown[txt] = L[txt]
      CONFIG_MAP[txt] = num
   end
   for num, txt in ipairs(RT_LIST) do
      raidIconDropdown[txt] = L[txt]
      CONFIG_MAP[txt] = num
   end
end

function MagicMarker:GetMarkForCategory(category)
   if category == 1 then
      return targetdata.TANK or {}
   end
   return targetdata[ CC_LIST[category] ] or {}
end

function MagicMarker:IsUnitIgnored(pri)
   return pri == CONFIG_MAP.P4
end

local function getID(value)
   return tonumber(string.sub(value, -1))
end

local function uniqList(list, id, newValue, empty, max)
   local addEmpty = false
   list[id] = newValue

   if id == #list then
      for iter = 1,id-1 do
	 if list[iter] == value then
	    addEmpty = true
	 end
      end
   end
   
   local currentPos = 1
   local seen_value = { empty = true }
   
   for iter = 1,max do
      if list[iter] and not seen_value[ list[iter] ] then
	 list[currentPos] = list[iter]
	 currentPos = currentPos+1
	 seen_value[ list[iter] ] = true
      end
   end
   if addEmpty then
      list[currentPos] = empty
      currentPos = currentPos + 1
   end
   for iter = currentPos, max do
      list[iter] = nil
   end
   return list
end
   
local function raidTargetSetter(info, value)
   local type = info[#info-1]
   local id = getID(info[#info])
   value = CONFIG_MAP[value]
   MagicMarker:PrintDebug("Setting "..id.." to "..value);
   targetdata[type] = uniqList(targetdata[type] or {}, id, value, 9, 8)
end

local function raidTargetGetter(info)
   local type = info[#info-1]
   local id = getID(info[#info])
   if not targetdata[type] then
      return nil
   end
   return RT_LIST[ targetdata[type][id] or 9 ]
end



local function mySetterFunc(info, value)
   local var = info[#info]
   local mob = info[#info-1]
   local region = info[#info-2]
   local ccid = getID(var)

   value = CONFIG_MAP[value]
   
   if ccid  then
      value = uniqList(mobdata[region].mobs[mob].cc or {}, ccid, value, 1, CONFIG_MAP.NUMCC)
      var = "cc"
   end

   mobdata[region].mobs[mob][var] = value

   if mobdata[region].mobs[mob].new then
      mobdata[region].mobs[mob].new = nil
      -- Remove the "new" mark
      options.args.mobs.args[region].args[mob].name = 
	 options.args.mobs.args[region].args[mob].args.header.name; 
   end
   
   MagicMarker:PrintDebug("The " .. region.."/"..mob.."/"..var .. " was set to: " .. tostring(value) )
end

local function myGetterFunc(info)
   local var = info[#info]
   local mob = info[#info-1]
   local region = info[#info-2]
   local value = mobdata[region].mobs[mob][var] or 1
   local ccid = getID(var)
   if ccid then
      value = CC_LIST[ mobdata[region].mobs[mob].cc[ccid] or 1 ]
   elseif var == "priority" then
      value = PRI_LIST[value]
   elseif var == "category" then
      value = ACT_LIST[value]
   end
   MagicMarker:PrintDebug("The " .. region.."/"..mob.."/"..var .. " was gotten as: " .. tostring(value) )
   return value
end


local function isIgnored(var)
   return MagicMarker:IsUnitIgnored(mobdata[var[#var-2]].mobs[var[#var-1]])
end

local function isHiddenCC(var)
   if isIgnored(var) then return true end
   local index = getID(var[#var])
   local cc = mobdata[var[#var-2]].mobs[var[#var-1]].cc 
   if not cc[index] then return true end
   return false
end

local function isHiddenRT(var)
   local index = getID(var[#var])
   local list = targetdata[var[#var-1]]
   return not list or not list[index] 
end

local function isHiddenAddRT(var)
   local index = getID(var[#var])
   local list = targetdata[var[#var-1]] 
   if not list then return false end
   return list[#list] == 9 or #list == 8
end

local function isHiddenAddCC(var)
   if isIgnored(var) then return true end
   local cc = mobdata[var[#var-2]].mobs[var[#var-1]].cc
   return cc[#cc] == 1 or #cc == CONFIG_MAP.NUMCC 
end
   
local function addNewCC(var)
   local val = mobdata[var[#var-2]].mobs[var[#var-1]].cc
   val[#val+1] = 1
end
   
local function addNewRT(var)
   local val = targetdata[var[#var-1]] or {}
   val[#val+1] = 9
   targetdata[var[#var-1]] = val
end
   
function MagicMarker:SimplifyName(name)
   return gsub(name, " ", "")
end

local optionsCallout

function MagicMarker:InsertNewUnit(name, zone)
   local simpleName = self:SimplifyName(name)
   zone = ZoneReverse[zone] or zone;
   local simpleZone = self:SimplifyName(zone)
   local zoneHash = mobdata[simpleZone] or { name = zone, mobs = { } }

   mobdata[simpleZone] = zoneHash
   
   if not zoneHash.mobs[simpleName] then
      zoneHash.mobs[simpleName] = {
	 name = name,
	 new = true,
	 category = 1,
	 priority = 2,
	 cc = {}
      }
      self:PrintDebug("Added new mob "..simpleName.." for zone "..simpleZone);

      if optionsCallout then self:CancelTimer(optionsCallout) end
      
      optionsCallout = self:ScheduleTimer(self.GenerateOptions, 1)
   end
   
   return mobdata[simpleZone].mobs[simpleName];
end

function MagicMarker:GenerateOptions()
   local opts = options.args.categories.args
   local subopts
   mobdata = MagicMarkerDB.mobdata
   targetdata = MagicMarkerDB.targetdata

   options.args.categories.set = raidTargetSetter
   options.args.categories.get = raidTargetGetter

   for id, catName in ipairs(CC_LIST) do
      if id == 1 then catName = "TANK" end -- hack
      opts[catName] = {
	 type = "group",
	 name = L[catName],
	 order = id,
	 args = {
	    addcc = {
	       type = "execute",
	       name = L["Add raid icon"],
	       func = addNewRT,
	       order = 1000,
	       hidden = isHiddenAddRT, 
	    }
	 },
      }
      for icon = 1,8 do
	 opts[catName].args["icon"..icon] = {
	    type = "select",
	    name = "Raid Icon #"..icon,
	    dialogControl = "MMRaidIcon",
	    order = icon*10,
	    hidden = isHiddenRT,
	    values = raidIconDropdown,
	 }
      end
      
   end

   opts = options.args.mobs.args;
   for id, zone in pairs(mobdata) do
      opts[id] = {
	 type = "group",
	 name = ZoneLookup[zone.name] or zone.name,
	 args = {},
	 set = mySetterFunc,
	 get = myGetterFunc, 
      }
      subopts = opts[id].args
      for mob, data in pairs(zone.mobs) do
	 subopts[mob] = {
	    type = "group", 
	    args = {
	       header = {
		  name = data.name,
		  type = "header",
		  order = 1
	       }, 
	       priority = {
		  name = L["Priority"],
		  type = "select",
		  values = priDropdown, 
		  order = 2,
	       },
	       category = {
		  name = "Category",
		  type = "select",
		  values = catDropdown, 
		  order = 3,
		  hidden = isIgnored,
	       },
	       ccheader = {
		  name = L["Crowd Control Config"], 
		  type = "header",
		  hidden = isIgnored,
		  order = 4
	       },
	       ccinfo = {
		  type = "description",
		  name = L["CCHELPTEXT"],
		  order = 5,
		  hidden = isIgnored,
	       }, 
	       addcc = {
		  type = "execute",
		  name = L["Add new crowd control"],
		  func = addNewCC,
		  order = 100,
		  hidden = isHiddenAddCC, 
	       }
	    }
	 }
	 
	 for num = 1,CONFIG_MAP.NUMCC do
	    subopts[mob].args["ccopt"..num] = {
	       name = L["Crowd Control #"]..num,
	       type = "select",
	       values = ccDropdown,
	       order = 10+num,
	       hidden = isHiddenCC,
	    }
	 end
	 if data.new then
	    subopts[mob].name = "* "..data.name;
	 else 
	    subopts[mob].name = data.name;
	 end
      end
   end
end

LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Magic Marker"], options, "magicmarker") 


