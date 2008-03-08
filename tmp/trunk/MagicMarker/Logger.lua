-- This file handles logging of variable levels
local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")

-- 
MagicMarker.logLevels = { NONE = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4, TRACE = 5 }

local logPrefix = {
   "|cffff0000ERROR:|r ", 
   "|cffffff00WARN:|r ", 
   "", 
   "|cffd9d919DEBUG:|r ", 
   "|cffd9d5fFTRACE:|r "
}
local logLevels = MagicMarker.logLevels
local logLevel  = logLevels.INFO

function MagicMarker:SetLogLevel(path, level)
   logLevel = level or path
   MagicMarkerDB.logLevel = logLevel
end
function MagicMarker:GetLogLevel(path) return logLevel end

local function LogMessage(level,...)
   if level <= logLevel
   then
      MagicMarker:Print(logPrefix[level]..string.format(...))
   end
end


local loggers = { 
   debug = function(...) LogMessage(logLevels.DEBUG, ...) end, 
   error = function(...) LogMessage(logLevels.ERROR, ...) end, 
   warn  = function(...) LogMessage(logLevels.WARN,  ...) end, 
   info  = function(...) LogMessage(logLevels.INFO,  ...) end, 
   trace = function(...) LogMessage(logLevels.TRACE, ...) end
}

function MagicMarker:GetLoggers() 
   return loggers
end
