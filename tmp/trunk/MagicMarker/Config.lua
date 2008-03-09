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
local R = LibStub("AceConfigRegistry-3.0")
local C = LibStub("AceConfigDialog-3.0")

local BabbleZone = LibStub("LibBabble-Zone-3.0") 
local ZoneReverse = BabbleZone:GetReverseLookupTable()
local ZoneLookup  = BabbleZone:GetLookupTable()

local MobNotesDB
local options, standardZoneOptions, standardMobOptions
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

function MagicMarker:NoMobNote(arg)
   return not MobNotesDB or not MobNotesDB[GetMobName(arg)] 
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
	    handler = KeybindHelper,
	    get = "GetKeybind",
	    set = "SetKeybind",
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
	    },
	 },
      }
   }
   standardZoneOptions = {
      optionHeader = {
	 type = "header",
	 name = L["Zone Options"],
	 order = 1
      },
      targetMark = {
	 width = "full",
	 type = "toggle",
	 name = L["Enable auto-marking on target change"],
	 handler = MagicMarker,
	 set = "SetZoneConfig",
	 get = "GetZoneConfig",
	 order = 20,
      },
      mm = {
	 width = "full",
	 type = "toggle",
	 name = L["Enable Magic Marker in this zone"],
	 handler = MagicMarker,
	 set = "SetZoneConfig",
	 get = "GetZoneConfig",
	 order = 10,
      },
      deletehdr = {
	 type = "header",
	 name = "",
	 order = 99
      }, 
   }
   standardMobOptions = {
      header = {
	 name = GetMobName,
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
	 hidden = "IsIgnored",
      },
      ccheader = {
	 name = L["Crowd Control Config"], 
	 type = "header",
	 hidden = "IsIgnored",
	 order = 40
      },
      ccinfo = {
	 type = "description",
	 name = L["CCHELPTEXT"],
	 order = 50,
	 hidden = "IsIgnored",
      }, 
      addcc = {
	 type = "execute",
	 name = L["Add new crowd control"],
	 func = "AddNewCC",
	 order = 300,
	 hidden = "IsHiddenAddCC", 
      },
      mobnotes = {
	 name = GetMobNote, 
	 type = "description", 
	 order = 20,
	 hidden = "NoMobNote",
      },
      mobnoteheader = {
	 name = L["Mob Notes"],
	 type = "header", 
	 order = 15,
	 hidden = "NoMobNote",
      },
      deletehdr = {
	 type = "header",
	 name = "",
	 order = 10000
      }
   }

   for num = 1,CONFIG_MAP.NUMCC do
      standardMobOptions["ccopt"..num] = {
	 name = L["Crowd Control #"]..num,
	 type = "select",
	 values = ccDropdown,
	 order = 100+num,
	 hidden = "IsHiddenCC",
      }
   end
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
--   log.trace("Setting "..id.." to "..value)
   targetdata[type] = uniqList(targetdata[type] or {}, id, value, 9, 8)
end

function MagicMarker:GetRaidTargetConfig(info)
   local type = info[#info-1]
   local id = getID(info[#info]) or 9
   if not targetdata[type] then
      return nil
   end
--   log.trace("Getting "..id.." to "..RT_LIST[ targetdata[type][id] ])
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
      options.args.mobs.args[region].plugins.mobList[mob].name = 
	 mobdata[region].mobs[mob].name
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


function MagicMarker:IsIgnored(var)
   local prio = mobdata[var[#var-2]].mobs[var[#var-1]].priority
   local ignored = MagicMarker:IsUnitIgnored(prio)
   return ignored
end

function MagicMarker:IsHiddenCC(var)
   if self:IsIgnored(var) then return true end
   local index = getID(var[#var])
   local cc = mobdata[var[#var-2]].mobs[var[#var-1]].cc 
   if not cc[index] then return true end
   return false
end

function MagicMarker:IsHiddenRT(var)
   local index = getID(var[#var])
   local list = targetdata[var[#var-1]]
   return not list or not list[index] 
end

function MagicMarker:IsHiddenAddRT(var)
   local index = getID(var[#var])
   local list = targetdata[var[#var-1]] 
   if not list then return false end
   return list[#list] == 9 or #list == 8
end

function MagicMarker:IsHiddenAddCC(var)
   if self:IsIgnored(var) then return true end
   local cc = mobdata[var[#var-2]].mobs[var[#var-1]].cc
   return cc[#cc] == 1 or #cc == CONFIG_MAP.NUMCC 
end
   
function MagicMarker:AddNewCC(var)
   local val = mobdata[var[#var-2]].mobs[var[#var-1]].cc
   val[#val+1] = 1
end
   
function MagicMarker:AddNewRT(var)
   local val = targetdata[var[#var-1]] or {}
   val[#val+1] = 9
   targetdata[var[#var-1]] = val
end
   
function MagicMarker:SimplifyName(name)
   if not name then return "" end
   return gsub(name, " ", "")
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
      ret = ret .. " "..format(L["Out of these mobs %d are ignored."], ignored)
   end
   return ret
end

local optionsCallout

function MagicMarker:InsertNewUnit(name, zone)
   local simpleName = self:SimplifyName(name)
   zone = ZoneReverse[zone] or zone
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
   end

   if not options.args.mobs.args[simpleZone] then
      options.args.mobs.args[simpleZone] = self:ZoneConfigData(simpleZone, zoneHash)
   else 
      options.args.mobs.args[simpleZone].args.loader.hidden = false
      options.args.mobs.args[simpleZone].args.zoneInfo.name = GetZoneInfo(zoneHash)
   end
   self:NotifyChange()
   return mobdata[simpleZone].mobs[simpleName]
end

function MagicMarker:RemoveZone(var)
   local zone = var[#var-1]
   if log.warn then
      log.warn(L["Deleting zone %s from the database!"],
	       ZoneLookup[mobdata[zone].name] or mobdata[zone].name)
   end
   mobdata[zone] = nil
   options.args.mobs.args[zone] = nil
   self:NotifyChange()
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
   options.args.mobs.args[zone].plugins.mobList[mob] = nil
   options.args.mobs.args[zone].args.zoneInfo.name = GetZoneInfo(hash)
   self:NotifyChange()
end

function MagicMarker:BuildMobConfig(var)
   local mob = var[#var-1]
   local zone = var[#var-2]
   local zoneHash = options.args.mobs.args[zone]
   local subopts = options.args.mobs.args[zone].plugins.mobList
   local name = subopts[mob].name
   
   if log.trace then log.trace("Generating configuration for %s in zone %s", mob, zone) end

   subopts[mob].args.loader.hidden = true
   
   subopts[mob].plugins = {
      sharedMobConfig = standardMobOptions,
      privateMobConfig = {
	 delete = {
	    type = 'execute',
	    name = L['Delete mob from database (not recoverable)'],
	    order = 10001,
	    width = "full",
	    func = "RemoveMob",
	    confirm = true,
	    confirmText = string.format(L["Are you sure you want to delete |cffd9d919%s|r from the database?"], name)
	 }
      }
   }
   self:NotifyChange()
end

function MagicMarker:NotifyChange()
   self:UnloadOptions()
   R:NotifyChange(L["Magic Marker"])
end
 
local unloadTimer
function MagicMarker:UnloadOptions()
   if C.OpenFrames[L["Magic Marker"]] then
      if not unloadTimer then
	 unloadTimer = self:ScheduleRepeatingTimer("UnloadOptions", 5)
      end
      return
   end
   if unloadTimer then
      self:CancelTimer(unloadTimer, true)  
      unloadTimer = nil
   end
   
   for id, hash in pairs(options.args.mobs.args) do
      if id ~= "headerdata" then
	 hash.args.loader.hidden = false
	 hash.plugins.mobList = nil
	 if log.trace then log.trace("Unloaded mob options for %s.", hash.name) end
      end
   end
   R:NotifyChange(L["Magic Marker"])
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
	       func = "AddNewRT",
	       order = 1000,
	       hidden = "IsHiddenAddRT", 
	    }
	 },
      }
      for icon = 1,8 do
	 opts[catName].args["icon"..icon] = {
	    type = "select",
	    name = "Raid Icon #"..icon,
	    dialogControl = "MMRaidIcon",
	    order = icon*10,
	    hidden = "IsHiddenRT",
	    values = raidIconDropdown,
	 }
      end
      
   end

   opts = options.args.mobs.args
   opts.headerdata = {
      type = "group",
      name = L["Introduction"],
      args = {
	 header = {
	    type = "header",
	    name = L["Introduction"]
	 },
	 desc = {
	    type = "description",
	    name = L["MOBDATAHELPTEXT"]
	 }
      },
      order = 0,
   }
   for id, zone in pairs(mobdata) do
      opts[id] = self:ZoneConfigData(id, zone)
   end
end

function MagicMarker:ZoneConfigData(id, zone)
   return {
      type = "group",
      name = ZoneLookup[zone.name] or zone.name,
      handler = MagicMarker, 
      args = {
	 zoneInfo = {
	    type = "description",
	    name = GetZoneInfo(zone), 
	    order = 0,
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
	 },
	 loader = {
	    type = "toggle",
	    name = "loader",
	    get = "LoadMobListForZone",
	    arg = id,
	 }
      },
      plugins = {
	 StandardZone = standardZoneOptions, 
      },
      set = "SetMobConfig",
      get = "GetMobConfig", 
   }
end

function MagicMarker:LoadMobListForZone(var)
   local zone = var[#var-1]
   local zoneData = options.args.mobs.args[zone]
   local name = mobdata[zone].name
   local subopts = {}

   name = ZoneReverse[name] or name

   if log.trace then log.trace("Loading mob list for zone %s", name) end

   zoneData.args.loader.hidden = true 
--   zoneData.args.loader.get = nil -- prevent further loading

   zoneData.plugins.mobList = subopts

   for mob, data in pairs(mobdata[zone].mobs) do
      subopts[mob] = {
	 type = "group",
	 name = (data.new and "* "..data.name) or data.name,
	 args = {
	    loader = {
	       name = "Loader",
	       type = "toggle",
	       get = "BuildMobConfig"
	    }
	 }
      }
   end
   self:NotifyChange()
end

function MagicMarker:GetCCName(ccid)
   return tolower(CC_LIST[ccid])
end

function MagicMarker:GetTargetName(ccid)
   return sub(RT_LIST[ccid], 2)
end

function MagicMarker:UpgradeDatabase()
   local version = MagicMarkerDB.version or 0

   if version < 1 then
      -- Added two new priority levels and change logging 
      MagicMarkerDB.logLevel = (MagicMarkerDB.debug and self.logLevels.DEBUG) or self.logLevels.INFO
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

   if version < 2 then
      -- zone-level enable/disable feature, default to enable
      for zone,zoneData in pairs(MagicMarkerDB.mobdata) do
	 zoneData.mm = true
      end
   end

   MagicMarkerDB.version = CONFIG_VERSION
end

local keyBindingOrder = 1000

local function AddKeyBinding(keyname, desc)
   _G["BINDING_NAME_"..keyname] = desc
   options.args.options.args[keyname] = {
      name = desc, 
      desc = desc, 
      type = "keybinding",
      arg = keyname,
      order = keyBindingOrder,
   }
   keyBindingOrder = keyBindingOrder + 1
end

-- Keybind names

BINDING_HEADER_MagicMarker = L["Magic Marker"]

AddKeyBinding("MAGICMARKRESET", L["Reset raid icons"])
AddKeyBinding("MAGICMARKMARK", L["Mark selected target"])
AddKeyBinding("MAGICMARKUNMARK", L["Unmark selected target"])
AddKeyBinding("MAGICMARKTOGGLE", L["Toggle config dialog"])
AddKeyBinding("MAGICMARKRAID", L["Mark party/raid targets"])
AddKeyBinding("MAGICMARKSAVE", L["Save party/raid mark layout"])
AddKeyBinding("MAGICMARKLOAD", L["Load party/raid mark layout"])

LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Magic Marker"], options)
