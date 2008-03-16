local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")
local L = LibStub("AceLocale-3.0"):GetLocale("MagicMarker", false)


local decursers = { MAGE = 1000, DRUID = 1000 }
local shamans = { SHAMAN = 500 }
local mages = { MAGE = 1000 }
local log
local function MarkIfClassHelper(self, unit, classes)
   local _,class = UnitClass(unit)
   if not log then
      log = self:GetLoggers() 
   end

   if class and classes[class] then
      for id = 1, 8 do 
	 if self:ReserveMark(id, unit, classes[class], unit, nil, true) then
	    if log.debug then log.debug("Marking "..unit.." with target "..id) end
	    return true
	 end
      end
   end
end

MagicMarker.MarkTemplates = {
   decursers  = {
      func = function (self, unit) MarkIfClassHelper(self, unit, decursers) end,
      desc = L["Mark all mages and druids in the raid"],
   },
   shamans = {
      func = function (self, unit) MarkIfClassHelper(self, unit, shamans) end,
      desc = L["Mark all shamans in the raid"],
      
   },
   archimonde = {
      desc = L["Mark the decursers followed by the shamans"],
      order = 1,
   },
   arch = {
      desc = L["Alias for archimonde"],
      order = 2,
   }
}
