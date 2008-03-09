--[[
  MagicMarker configuration
]]
local CONFIG_VERSION = 2
local format = format
local sub = string.sub
local tonumber = tonumber
local tolower = strlower

local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)

local BabbleZone = LibStub("LibBabble-Zone-3.0") 
local ZoneReverse = BabbleZone:GetReverseLookupTable()
local ZoneLookup  = BabbleZone:GetLookupTable()

local MobNotesDB
local options 
BabbleZone = nil

local db = MagicMarkerDB

local mobdata, targetdata

local log = MagicMarker:GetLoggers()

-- Config UI name => ID
local CONFIG_MAP = {
   NUMCC=9, 
}

-- ID => Config UI name
local ACT_LIST = { "TANK", "CC" }
local CC_LIST = { "00NONE", "SHEEP", "BANISH", "SHACKLE", "HIBERNATE", "TRAP", "KITE", "MC", "FEAR", "SAP" }
local PRI_LIST = { "P1", "P2", "P3", "P4", "P5", "P6" }
local RT_LIST =  { "Star",  "Circle",  "Diamond",  "Triangle",  "Moon",  "Square",  "Cross",  "Skull", "None" }
local ccDropdown, priDropdown, catDropdown, raidIconDropdown, logLevelsDropdown

-- KeybindHelper code from Xinhuan's addon IPopBar. Thanks for letting me use it! 
local KeybindHelper = {}
do
   local t = {}
   function KeybindHelper:MakeKeyBindingTable(...)
      for k in pairs(t) do t[k] = nil end
      for i = 1, select("#", ...) do
	 local key = select(i, ...)
	 if key ~= "" then
	    tinsert(t, key)
	 end
      end
      return t
   end
   
   function KeybindHelper:GetKeybind(info)
      return table.concat(self:MakeKeyBindingTable(GetBindingKey(info.arg)), ", ")
   end
   
   function KeybindHelper:SetKeybind(info, key)
      if key == "" then
	 local t = self:MakeKeyBindingTable(GetBindingKey(info.arg))
	 for i = 1, #t do
	    SetBinding(t[i])
	 end
      else
	 local oldAction = GetBindingAction(key)
	 local frame = LibStub("AceConfigDialog-3.0").OpenFrames["Magic Marker"]
	 if frame then
	    if ( oldAction ~= "" and oldAction ~= info.arg ) then
	       frame:SetStatusText(KEY_UNBOUND_ERROR:format(GetBindingText(oldAction, "BINDING_NAME_")))
	    else
	       frame:SetStatusText(KEY_BOUND)
	    end
	 end
	 SetBinding(key, info.arg)
      end
      SaveBindings(GetCurrentBindingSet())
   end
end


do
   local temp 
   ccDropdown = {}
   priDropdown = {}
   catDropdown = {}
   raidIconDropdown = {}
   logLevelsDropdown = {}

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
      temp = num..txt
      raidIconDropdown[temp] = L[txt]
      CONFIG_MAP[temp] = num
      RT_LIST[num] = temp
   end
   for logname,id in pairs(MagicMarker.logLevels) do
      logLevelsDropdown[id] = L[logname]
   end
   
   options = { 
      type = "group", 
      name = L["Magic Marker"],
      childGroups = "tab",
      args = {
	 mobs = {
	    type = "group",
	    name = L["Mob Database"],
	    args = {}, 
	    order = 300
	 }, 
	 categories = {
	    childGroups = "tab",
	    type = "group",
	    name = L["Raid Target Settings"],
	    order = 1,
	    args = { }
	 }, 
	 options = {
	    childGroups = "tab",
	    type = "group",
	    name = L["Options"],
	    order = 0,
	    args = {
	       generalHeader = {
		  type = "header",
		  name = L["General Options"],
		  order = 0,
	       },
	       debug = {
		  type = "select",
		  name = L["Log level"],
		  handler = MagicMarker,
		  set = "SetLogLevel",
		  get = "GetLogLevel",
		  order = 1,
		  values = logLevelsDropdown,
	       },
	       bindingHeader = {
		  type = "header",
		  name = L["Key Bindings"],
		  order = 100,
	       },
	       keyconfig = {
		  name = L["Toggle config dialog"],
		  desc = L["Toggle config dialog"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKTOGGLE",
		  order = 101,
	       },	    
	       keyreset = {
		  name = L["Reset raid icons"],
		  desc = L["Reset raid icons"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKRESET",
		  order = 101,
	       },	    
	       keymark = {
		  name = L["Mark selected target"],
		  desc = L["Mark selected target"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKMARK",
		  order = 102,
	       },	    
	       keyunmark = {
		  name = L["Unmark selected target"],
		  desc = L["Unmark selected target"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKUNMARK",
		  order = 103,
	       },	    
	       keymarkraid = {
		  name = L["Mark party/raid targets"],
		  desc = L["Mark party/raid targets"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKRAID",
		  order = 104,
	       },	    
	       keysave = {
		  name = L["Save party/raid mark layout"], 
		  desc = L["Save party/raid mark layout"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKSAVE",
		  order = 105,
	       },	    
	       keyload = {
		  name = L["Load party/raid mark layout"], 
		  desc = L["Load party/raid mark layout"],
		  type = "keybinding",
		  handler = KeybindHelper,
		  get = "GetKeybind",
		  set = "SetKeybind",
		  arg = "MAGICMARKLOAD",
		  order = 105,
	       },	    
	    },
	 },
      }
   }
end

function MagicMarker:GetMarkForCategory(category)
   if category == 1 then
      return targetdata.TANK or {}
   end
   return targetdata[ CC_LIST[category] ] or {}
end

function MagicMarker:IsUnitIgnored(pri)
   return pri == CONFIG_MAP.P6
end

local function getID(value)
   return tonumber(sub(value, -1))
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
   
function MagicMarker:SetRaidTargetConfig(info, value)
   local type = info[#info-1]
   local id = getID(info[#info])
   value = CONFIG_MAP[value]
--   log.trace("Setting "..id.." to "..value);
   targetdata[type] = uniqList(targetdata[type] or {}, id, value, 9, 8)
end

function MagicMarker:GetRaidTargetConfig(info)
   local type = info[#info-1]
   local id = getID(info[#info]) or 9
   if not targetdata[type] then
      return nil
   end
--   log.trace("Getting "..id.." to "..RT_LIST[ targetdata[type][id] ]);
   return RT_LIST[ targetdata[type][id] ]
end

function MagicMarker:SetMobConfig(info, value)
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
   
   if log.trace then log.trace("The " .. region.."/"..mob.."/"..var .. " was set to: " .. tostring(value) ) end
end

function MagicMarker:GetMobConfig(info)
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
   if log.trace then log.trace("The " .. region.."/"..mob.."/"..var .. " was gotten as: " .. tostring(value) ) end
   return value
end

function MagicMarker:SetZoneConfig(info, value)
   local var = info[#info]
   local region = info[#info-1]
   mobdata[region][var] = value
   if log.trace then log.trace("Setting %s:%s to %s", region, var, tostring(value)) end
   if region == self:SimplifyName(GetRealZoneText()) then
      if var == "mm" then
	 self:ZoneChangedNewArea()
      elseif var == "targetMark" then
	 if value then
	    self:RegisterEvent("PLAYER_TARGET_CHANGED", "SmartMarkUnit", "target")
	 else
	    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	 end
      end
   end
end

function MagicMarker:GetZoneConfig(info)
   local var = info[#info]
   local region = info[#info-1]
   return mobdata[region][var]
end


local function isIgnored(var)
   local prio = mobdata[var[#var-2]].mobs[var[#var-1]].priority
   local ignored = MagicMarker:IsUnitIgnored(prio)
   return ignored
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
   if not name then return "" end
   return gsub(name, " ", "")
end

local optionsCallout

function MagicMarker:InsertNewUnit(name, zone)
   local simpleName = self:SimplifyName(name)
   zone = ZoneReverse[zone] or zone;
   local simpleZone = self:SimplifyName(zone)
   local zoneHash = mobdata[simpleZone] or { name = zone, mobs = { }, handler = self, mm = 1 }

   mobdata[simpleZone] = zoneHash
   
   if not zoneHash.mobs[simpleName] then
      zoneHash.mobs[simpleName] = {
	 name = name,
	 new = true,
	 category = 1,
	 priority = 3,
	 cc = {}
      }
      if log.info then log.info(format(L["Added new mob %s in zone %s."],name, zone)) end

      if optionsCallout then self:CancelTimer(optionsCallout, true) end
      
      optionsCallout = self:ScheduleTimer(self.GenerateOptions, 2)
   end
   
   return mobdata[simpleZone].mobs[simpleName];
end

local function GetZoneInfo(hash)
   local new = 0
   local total = 0
   local ignored = 0
   local mobs = hash.mobs
   for mob,data in pairs(mobs) do
      if data.new then new = new + 1 end
      if data.priority == 4 then ignored = ignored + 1 end
      total = total + 1
   end
   if new > 0 then new = tostring(new) else new = L["None"] end

   local ret =  format(L["%s has a total of %d mobs. %s of these are newly discovered."],
			      hash.name, total, new)
   if ignored > 0 then
      ret = ret .. " "..format(L["Out of these mobs %d are ignored."], ignored);
   end
   return ret
end


local function GetMobName(arg)
   return mobdata[ arg[#arg-2] ] and mobdata[ arg[#arg-2] ].mobs[ arg[#arg-1] ].name
end
    

local function GetMobNote(arg)
   if not MobNotesDB then
      if _G.MobNotesDB then
	 MobNotesDB = _G.MobNotesDB
      else
	 return ""
      end
   end
   local name = GetMobName(arg)
   return MobNotesDB[GetMobName(arg)] or "N/A"
end

local function NoMobNote(arg)
   return not MobNotesDB or not MobNotesDB[GetMobName(arg)] 
end

function MagicMarker:RemoveZone(var)
   local zone = var[#var-1]
   if log.warn then
      log.warn(L["Deleting zone %s from the database!"],
	       ZoneLookup[mobdata[zone].name] or mobdata[zone].name)
   end
   mobdata[zone] = nil
   options.args.mobs.args[zone] = nil
end

function MagicMarker:RemoveMob(var)
   local mob = var[#var-1]
   local zone = var[#var-2]
   local hash = mobdata[zone]
      
   if log.info then
      log.info(L["Deleting mob %s from zone %s from the database!"],
	       hash.mobs[mob].name, ZoneLookup[hash.name] or hash.name)
   end
   hash.mobs[mob] = nil
   options.args.mobs.args[zone].args[mob] = nil
end

function MagicMarker:GenerateOptions()
   local opts = options.args.categories.args
   local subopts

   mobdata = MagicMarkerDB.mobdata
   targetdata = MagicMarkerDB.targetdata
   
   options.handler = MagicMarker
   options.args.categories.set = "SetRaidTargetConfig"
   options.args.categories.get = "GetRaidTargetConfig"

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
	 width="double",
	 handler = MagicMarker, 
	 args = {
	    zoneInfo = {
	       type = "description",
	       name = GetZoneInfo(zone), 
	       order = 0,
	    },
	    optionHeader = {
	       type = "header",
	       name = L["Zone Options"],
	       order = 1
	    },
	    targetMark = {
	       width = "full",
	       type = "toggle",
	       name = L["Enable auto-marking on target change"],
	       handler = self,
	       set = "SetZoneConfig",
	       get = "GetZoneConfig",
	       order = 20,
	    },
	    mm = {
	       width = "full",
	       type = "toggle",
	       name = L["Enable Magic Marker in this zone"],
	       handler = self,
	       set = "SetZoneConfig",
	       get = "GetZoneConfig",
	       order = 10,
	    },
	    deletehdr = {
	       type = "header",
	       name = "",
	       order = 99
	    }, 
	    delete = {
	       type = 'execute',
	       name = L['Delete entire zone from database (not recoverable)'],
	       order = 100,
	       width = "full",
	       func = "RemoveZone",
	       confirm = true,
	       confirmText = string.format(L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"],
					   ZoneLookup[zone.name] or zone.name)
	    }


	 },
	 set = "SetMobConfig",
	 get = "GetMobConfig", 
      }
      subopts = opts[id].args
      for mob, data in pairs(zone.mobs) do
	 subopts[mob] = {
	    type = "group",
	    args = {
	       header = {
		  name = data.name,
		  type = "header",
		  order = 0
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
		  order = 40
	       },
	       ccinfo = {
		  type = "description",
		  name = L["CCHELPTEXT"],
		  order = 50,
		  hidden = isIgnored,
	       }, 
	       addcc = {
		  type = "execute",
		  name = L["Add new crowd control"],
		  func = addNewCC,
		  order = 300,
		  hidden = isHiddenAddCC, 
	       },
	       mobnotes = {
		  name = GetMobNote, 
		  type = "description", 
		  order = 20,
		  hidden = NoMobNote,
	       },
	       mobnoteheader = {
		  name = L["Mob Notes"],
		  type = "header", 
		  order = 15,
		  hidden = NoMobNote,
	       },
	       deletehdr = {
		  type = "header",
		  name = "",
		  order = 10000
	       }, 
	       delete = {
		  type = 'execute',
		  name = L['Delete mob from database (not recoverable)'],
		  order = 10001,
		  width = "full",
		  func = "RemoveMob",
		  confirm = true,
		  confirmText = string.format(L["Are you sure you want to delete |cffd9d919%s|r from the database?"], data.name)
					      
	       }
	    }
	 }

	 for num = 1,CONFIG_MAP.NUMCC do
	    subopts[mob].args["ccopt"..num] = {
	       name = L["Crowd Control #"]..num,
	       type = "select",
	       values = ccDropdown,
	       order = 100+num,
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

function MagicMarker:GetCCName(ccid)
   return tolower(CC_LIST[ccid])
end

function MagicMarker:GetTargetName(ccid)
   return sub(RT_LIST[ccid], 2)
end

LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Magic Marker"], options)

function MagicMarker:UpgradeDatabase()
   local version = MagicMarkerDB.version or 0

   if version < 1 then
      -- Added two new priority levels and change logging 
      MagicMarkerDB.logLevel = (MagicMarkerDB.debug and self.logLevels.DEBUG) or self.logLevels.INFO;
      MagicMarkerDB.debug = nil
      for zone,zoneData in pairs(MagicMarkerDB.mobdata) do
	 for mob, mobData in pairs(zoneData.mobs) do
	    if mobData.priority == 4 then
	       mobData.priority = 6
	    else
	       mobData.priority = mobData.priority + 1
	    end
	 end
      end
   end

   if version < 1 then
      -- zone-level enable/disable feature, default to enable
      for zone,zoneData in pairs(MagicMarkerDB.mobdata) do
	 zoneData.mm = true
      end
   end

   MagicMarkerDB.version = CONFIG_VERSION
end

function MagicMarker:ClearOptions()
   options = {}
end
