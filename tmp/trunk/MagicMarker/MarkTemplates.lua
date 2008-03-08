

local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")


local decursers = { MAGE = true, DRUID = true }
local archimonde = { MAGE = true, DRUID = true, SHAMAN = true }
local mages = { MAGE = true }
local log
local function MarkIfClassHelper(self, unit, classes)
   local _,class = UnitClass(unit)
   if not log then
      log = self:GetLoggers() 
   end

   if class and classes[class] then
      for id = 1, 8 do 
	 if self:ReserveMark(id, unit, 1000) then
	    log.debug("Marking "..unit.." with target "..id)
	    return true
	 end
      end
   end
end

MagicMarker.MarkTemplates = {
   decursers  = function (self, unit) MarkIfClassHelper(self, unit, decursers) end,
   archimonde = function (self, unit) MarkIfClassHelper(self, unit, archimonde) end,
   mages = function (self, unit) MarkIfClassHelper(self, unit, mages) end,
}
