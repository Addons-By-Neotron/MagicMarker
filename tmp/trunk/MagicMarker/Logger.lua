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

-- This file handles logging of variable levels

local MagicMarker = LibStub("AceAddon-3.0"):GetAddon("MagicMarker")

MagicMarker.logLevels = { NONE = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4, TRACE = 5, SPAM = 6 }

local logPrefix = {
   "|cffff0000ERROR:|r ", 
   "|cffffff00WARN:|r ", 
   "", 
   "|cffd9d919DEBUG:|r ", 
   "|cffd9d5fFTRACE:|r ",
   "|cffff5050SPAM:|r ",
}
local logLevels = MagicMarker.logLevels
local logLevel  = logLevels.INFO

local function LogMessage(level,...)
   if level <= logLevel
   then
      MagicMarker:Print(logPrefix[level]..string.format(...))
   end
end

local function debug(...) LogMessage(logLevels.DEBUG, ...) end
local function error(...) LogMessage(logLevels.ERROR, ...) end
local function warn(...) LogMessage(logLevels.WARN,  ...) end
local function info(...) LogMessage(logLevels.INFO,  ...) end
local function trace(...) LogMessage(logLevels.TRACE, ...) end
local function spam(...) LogMessage(logLevels.SPAM, ...) end

local loggers = { 
   debug = debug,
   error = error,
   warn  = warn,
   info  = info,
   trace = trace,
   spam = spam
}

function MagicMarker:GetLoggers() 
   return loggers
end

function MagicMarker:SetLogLevel(level)
   logLevel = tonumber(level)
   if logLevel >= logLevels.ERROR then loggers.error = error else loggers.error = nil end
   if logLevel >= logLevels.WARN  then loggers.warn = warn else loggers.warn = nil end
   if logLevel >= logLevels.INFO  then loggers.info = info else loggers.info = nil end
   if logLevel >= logLevels.DEBUG then loggers.debug = debug else loggers.debug = nil end
   if logLevel >= logLevels.TRACE then loggers.trace = trace else loggers.trace = nil end
   if logLevel >= logLevels.SPAM then loggers.spam = spam else loggers.spam = nil end
end

function MagicMarker:GetLogLevel() return logLevel end

