-- MagicMarker
-- deDE Localization file
-- by EnSabahNur and Bl4ckSh33p

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "deDE")
if not L then return end

L["Magic Marker"] = "Magic Marker";

-- Key Bindings
--L["Reset raid icon cache"] = true 
L["Mark selected target"] = "Ausgew\195\164hltes Ziel markieren";
L["Unmark selected target"] = "Markierung auf aktuellem Ziel entfernen";
--L["Toggle config dialog"] = true
--L["Mark party/raid targets"] = true

-- Options Config
L["%s has a total of %d mobs.\n%s of these are newly discovered."] = "%s hat insgesamt %d Mobs.\n%s davon sind neu entdeckt."
--L["Accept mobdata broadcast messages"] = true
--L["Accept raid mark broadcast messages"] = true
--L["Accept CC priority broadcast messages"] = true
L["Add new crowd control"] = "Neue Gruppenkontrolle hinzuf\195\188gen"
L["Add raid icon"] = "Schlachtzug-Icon hinzuf\195\188gen"
--L["Broadcast all zone data to the raid group."] = true
--L["Broadcast raid target settings to the raid group."] = true
--L["Broadcast zone data to the raid group."] = true
-- L["Broadcast crowd control priority settings to the raid group."] = true
L["Category"] = "Kategorie"
L["Config"] = "Konfiguration"
--L["Data Broadcasting"] = true
--L["Data Sharing"] = true
--L["Delay between remarking"] = true
--L["Enable Magic Marker in this zone"] = true
--L["Enable auto-marking on target change"] = true
--L["Enable target re-prioritization during combat"] = true
L["General Options"] = "Generelle Einstellungen"
--L["Honor pre-existing raid icons"] = true
--L["Introduction"] = true
--L["Key Bindings"] = true
--L["Log level"] = true
--L["Marking Behavior"] = true
--L["Max # to Crowd Control"] = true
--L["Merge - local priority"] = true
--L["Merge - remote priority"] = true
--L["Mob Database"] = true
--L["Mob Notes"] = true
--L["Mobdata data import behavior"] = true
L["Key Bindings"] = "Tastenzuweisungen"
--L["Log level"] = true
--L["Marking Behavior"] = true
--L["Max # to Crowd Control"] = true
--L["Merge - local priority"] = true
--L["Merge - remote priority"] = true
L["Mob Database"] = "Mob Datenbank"
L["Mob Notes"] = "Mob Notizen"
L["None"] = "Keines"
L["Options"] = "Einstellungen"
L["\nOut of these mobs %d are ignored."] = "\nVon diesen Mobs sind %d ignoriert."
--L["Preserve raid group icons"] = true
L["Priority"] = "Priorit\195\164t"
L["Raid Target Settings"] = "Schlachtzugs-Zieleinstellungen"
--L["Replace with remote data"] = true
--L["Reset raid icons when resetting the cache"] = true
--L["Zone Options"] = true
--L['Delete entire zone from database (not recoverable)'] = true
--L['Delete mob from database (not recoverable)'] = true 
--L["Unused Crowd Control Methods"] = true 

-- Options config confirmation
L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"] = true
L["Are you sure you want to delete |cffd9d919%s|r from the database?"] = true

-- CC Names
L["BANISH"] = "Verbannen"
--L["ENSLAVE"] = "Enslave" -- NEW
L["FEAR"] = "Furcht"
L["HIBERNATE"] = "Winterschlaf"
L["KITE"] = "Kiten"
L["MC"] = "Gedankenkontrolle"
--L["ROOT"] = "Root" -- NEW
L["SAP"] = "Kopfnuss"
L["SHACKLE"] = "Untote Fesseln"
L["SHEEP"] = "Schaf"
L["TRAP"] = "Falle" 
L["00NONE"] = "Keine "

-- Priority names
--L["P1"] = "Very High"
L["P2"] = "Hoch"
L["P3"] = "Mittel"
L["P4"] = "Niedrig"
--L["P5"] = "Very Low"
L["P6"] = "Ignorieren"

-- Category names
L["TANK"] = "Tank"
L["CC"] = "Gruppenkontrolle"

-- Raid icons
L["Star"] = "Stern"
L["Circle"] = "Kreis"
L["Diamond"] = "Diamant"
L["Triangle"] = "Dreieck"
L["Moon"] = "Mond"
L["Square"] = "Quadrat"
L["Cross"] = "Kreuz"
L["Skull"] = "Totenkopf"
L["None"] = "Keines"

-- Help Texts
L["CCHELPTEXT"] = "Here you configure all CC methods that are available for this target. The actual methods used are determined by the crowd control priority configuration, the raid makeup and individual mob prioritization. If no available crowd controllers are found, the mob will revert to being tanked." 
L["MOBDATAHELPTEXT"] = "Welcome to the Mob Database. Here you configure the priority, category and desired crowd control methods for all the mobs in the database. For mobs of category tank the crowd control methods can be ignored. If you choose to ignore a mob it will still be present in the list (in case you decide to unignore it). Once ignored, it will never get any raid targets assigned to it.\n\nYou can also delete a zone or individual mob entries in the zone. Please be aware that this action can't be reversed."
L["MARKDELAYHELPTEXT"] = "After setting a raid mark there's a delay before the client sees it. Since names are non-unique, this can cause a race condition. This value is the time in seconds between marking two mobs with the same name."
L["HONORHELPTEXT"] = "When enabled Magic Marker will honor raid icons assigned by a third party. If detected, they will be reserved and blocked from automatic use reused until a cache reset is preformed."
L["NOREUSEHELPTEXT"] = "When enabled, Magic Marker will preserve all raid icons on the raid/party members, even through cache resets."
L["INCOMBATHELPTEXT"] = "Whether or not Magic Marker should be allowed to change assigned raid marks during combat if it sees higher priority targets. Note that this only decides whether to unmark lower priority mobs. Unassigned icons will always be used on unmarked target, regardless of combat status."
L["RESETICONHELPTEXT"] = "When resetting the raid icon cache, also reset all raid icons. Note that if the option to reserve raid group icons is enabled, those icons will remain regardless of status of this parameter."
L["IMPORTHELPTEXT"] = "This option dictates the behavior when you receive a mob data broadcast. Merging will keep data from both databases. If you choose local priority, your own settings won't be replaced - only new data will be added. With remote priority your local entries will be overriden by the remote data. The replace option will completely replace your database with the received data."
L["MOBBROADHELPTEXT"] = "If enabled you will accept zone mob data sent to you by the raid leader or assistant."
L["MARKBROADHELPTEXT"] = "If enabled you will accept raid mark configuration that is broadcasted by your raid leader. The new configuration will entirely replace your own settings."
L["BROADALLHELP"] = "Broadcasts all the data in your mob database to the raid. This can be a lot of data and it is recommended to broadcast individual zones instead."
L["MAXCCHELP"] = "Maximum number of mobs of this type to crowd control at any one time."
L["LOGLEVELHELP"] = "The logging level determines the amount of output printed by the addon. Debug can be useful as you're getting use to the addon or want to figure out why it marked in a specific way. Trace is only useful for debugging and for development purposes."
L["CCBROADHELPTEXT"] = "If enabled you will accept crowd control prioritization configuration data sent to you by the group leader or assistant."

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = "Neuer Mob %s in Zone %s hinzugef\195\188gt."
L["Resetting raid targets."] = "Schlachtzugs-Ziele zur\195\188cksetzen."
--L["Magic Marker enabled."] = true
--L["Magic Marker disabled."] = true
--L["Save party/raid mark layout"] = true
--L["Load party/raid mark layout"] = true
--L["Unable to determine the class for %s."] = true
--L["Deleting zone %s from the database!"] = true
--L["Deleting mob %s from zone %s from the database!"] = true
--L["Added third party mark (%s) for mob %s."] = true

-- Log levels
--L["NONE"] = "Disabled"
--L["ERROR"] = "Errors only"
--L["WARN"] = "Errors and warnings"
--L["INFO"] = "Informational messages"
--L["DEBUG"] = "Debug messaging"
--L["TRACE"] = "Debug trace messages"

-- Other
--L["Heroic"] = true
--L["Normal"] = true
L["Raid"] = true

-- Command line options
-- L["Toggle configuration dialog"] = true
-- L["Unknown raid template: %s"] = true
-- L["Raid group target templates"] = true
-- L["About Magic Marker"] = true
-- L["Raid mark layout caching"] = true
-- L["Toggle Magic Marker event handling"] = true
--    
-- Raid mark templates
-- L["Mark all mages and druids in the raid"] = true
-- L["Mark all shamans in the raid"]= true
-- L["Mark the decursers followed by the shamans"] = true
-- L["Alias for archimonde"] = true

-- FuBar plugin
-- L["Disabled"] = true
-- L["Enabled"] = true
-- L["Zone"] = true
-- L["Status"] = true
-- L["Toggle event handling"] = true
-- L["Load the currently saved raid mark layout."] = true
-- L["Save the current raid mark layout."] = true
-- L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."] = true
-- L["Short FuBar Text"] = true
-- L["Hide Magic Marker from the FuBar status text."] = true
-- L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."] = true
-- L["Enable or disable the event handling, i.e whether or not Magic Marker will insert mobs into the mob database, mark mobs etc."] = true
-- L["Toggle the Magic Marker configuration dialog."] = true
-- L["Report the raid icon assignments to raid/party chat"] = true

L["RAIDMARKCACHEHELP"] = "This functionality lets you save the raid mark layout of the raid and then recall it. Useful to, for example, have raid marks enabled during phase 2 of Illidan but disabled in the other phases." -- new
L["RAIDTMPLHELP"] = "Raid templates allow you to quickly mark certain classer or roles in the raid." -- new
-- 
-- L["External"] = true
-- L["Template"] = true
-- L["Difficulty"] = true
-- L["Unit Name"] = true
-- L["Mark Type"] = true
-- L["Score"] = true
-- L["Profile name"] = true
-- L["Active profile: %s"] = true

L["TOOLTIP_HINT"] =
   "\n|cffeda55fClick|r to toggle config dialog.\n"..
   "|cffeda55fShift-Click|r to toggle event handling.\n"..
   "|cffeda55fAlt-Click|r to reset raid icon cache.\n"..
   "|cffeda55fAlt-Shift-Click|r to hard reset raid icon cache.\n"..
   "|cffeda55fMiddle-Click|r to print raid assignments to group chat."

-- creature description
-- L["Creature type"] = true
-- L["family"] = true
-- L["classification"] = true
-- L["unit is a caster"] = true

-- Yes! No!
L["Yes"] = "Ja"
L["No"] = "Nein"
