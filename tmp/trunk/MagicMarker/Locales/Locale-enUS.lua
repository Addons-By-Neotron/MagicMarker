-- MagicMarker
-- enUS and enGB Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "enUS", true)


L["Magic Marker"] = true

-- Key Bindings
L["Reset raid icon cache"] = true
L["Mark selected target"] = true
L["Unmark selected target"] = true
L["Toggle config dialog"] = true
L["Mark party/raid targets"] = true

-- Options Config
L["Options"] = true
L["Crowd Control Config"] = true
L["Priority"] = true
L["Category"] = true
L["Mob Database"] = true
L["Raid Target Settings"] = true
L["Add new crowd control"] = true
L["Add raid icon"] = true
L["Crowd Control #"] = true
L["Key Bindings"] = true
L["Log level"] = true
L["General Options"] = true
L["%s has a total of %d mobs. %s of these are newly discovered."] = true
L["Out of these mobs %d are ignored."] = true
L["None"] = true
L["Mob Notes"] = true
L["Zone Options"] = true
L["Enable auto-marking on target change"] = true
L["Enable Magic Marker in this zone"] = true
L['Delete mob from database (not recoverable)'] = true 
L['Delete entire zone from database (not recoverable)'] = true
L["Introduction"] = true
L["Delay between remarking"] = true
L["Marking Behavior"] = true
L["Honor pre-existing raid icons"] = true
L["Reserve raid group icons"] = true
L["Reset raid icons when resetting the cache"] = true
L["Enable target re-prioritization during combat"] = true
 
-- Options config confirmation
L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"] = true
L["Are you sure you want to delete |cffd9d919%s|r from the database?"] = true

-- Mark categories
L["Tank"] = true
L["Crowd Control - Sheep"] = true
L["Crowd Control - Banish"] = true
L["Crowd Control - Other"] = true
L["Ignored"] = true

-- CC Names
L["SHEEP"] = "Sheep"
L["BANISH"] = "Banish"
L["SHACKLE"] = "Shackle"
L["HIBERNATE"] = "Hibernate"
L["TRAP"] = "Trap" 
L["KITE"] = "Kite"
L["MC"] = "Mind Control"
L["FEAR"] = "Fear"
L["SAP"] = "Sap"
L["00NONE"] = "None "

-- Priority names
L["P1"] = "Very High"
L["P2"] = "High"
L["P3"] = "Medium"
L["P4"] = "Low"
L["P5"] = "Very Low"
L["P6"] = "Ignore"

-- Category names
L["TANK"] = "Tank"
L["CC"] = "Crowd Control"

-- Raid icons
L["Star"] = true
L["Circle"] = true
L["Diamond"] = true
L["Triangle"] = true
L["Moon"] = true
L["Square"] = true
L["Cross"] = true
L["Skull"] = true
L["None"] = "None"

-- Help Texts
L["CCHELPTEXT"] = "Here you configure all CC methods that are available for this target. The ordering is the priority in which they are attempted be used. I.e if the raid has two mages but two sheep targets are already assigned, it will iterate through the specified methods until one is found. If none is found, it will revert back to assigning a tank or arbitrary symbol to the target."
L["MOBDATAHELPTEXT"] = "Welcome to the Mob Database. Here you configure the priority, category and desired crowd control methods for all the mobs in the database. For mobs of category tank the crowd control methods can be ignored. If you choose to ignore a mob it will still be present in the list (in case you decide to unignore it). Once ignored, it will never get any raid targets assigned to it.\n\nYou can also delete a zone or individual mob entries in the zone. Please be aware that this action can't be reversed."
L["MARKDELAYHELPTEXT"] = "After setting a raid mark there's a delay before the client sees it. Since names are non-unique, this can cause a race condition. This value is the time in seconds between marking two mobs with the same name."
L["HONORHELPTEXT"] = "When enabled Magic Marker will honor raid icons assigned by a third party. If detected, they will be reserved and blocked from automatic use reused until a cache reset is preformed."
L["NOREUSEHELPTEXT"] = "When enabled, Magic Marker will not use any raid icons that have been manually assigned to the raid/party members."
L["INCOMBATHELPTEXT"] = "Whether or not Magic Marker should be allowed to change assigned raid marks during combat if it sees higher priority targets. Note that this only decides whether to unmark lower priority mobs. Unassigned icons will always be used on unmarked target, regardless of combat status."
L["RESETICONHELPTEXT"] = "When resetting the raid icon cache, also reset all raid icons. Note that if the option to reserve raid group icons is enabled, those icons will remain regardless of status of this parameter."

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = true
L["Resetting raid targets."] = true
L["Magic Marker enabled."] = true
L["Magic Marker disabled."] = true
L["Save party/raid mark layout"] = true
L["Load party/raid mark layout"] = true
L["Unable to determine the class for %s."] = true
L["Deleting zone %s from the database!"] = true
L["Deleting mob %s from zone %s from the database!"] = true
L["Added third party mark (%s) for mob %s."] = true

-- Log levels
L["NONE"] = "Disabled"
L["ERROR"] = "Errors only"
L["WARN"] = "Errors and warnings"
L["INFO"] = "Informational messages"
L["DEBUG"] = "Debug messaging"
L["TRACE"] = "Debug trace messages"
