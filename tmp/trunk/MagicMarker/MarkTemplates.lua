

local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")


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
	 if self:ReserveMark(id, unit, classes[class], nil, true) then
	    if log.debug then log.debug("Marking "..unit.." with target "..id) end
	    return true
	 end
      end
   end
end

MagicMarker.MarkTemplates = {
   decursers  = function (self, unit) MarkIfClassHelper(self, unit, decursers) end,
   archimonde = function (self, unit)
		   MarkIfClassHelper(self, unit, decursers)
		   MarkIfClassHelper(self, unit, shamans) -- lower priority
		end,
   mages = function (self, unit) MarkIfClassHelper(self, unit, mages) end,
}
