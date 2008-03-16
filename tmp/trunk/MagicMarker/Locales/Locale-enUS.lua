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
L["%s has a total of %d mobs. %s of these are newly discovered."] = true
L["Accept mobdata broadcast messages"] = true
L["Accept raid mark broadcast messages"] = true
L["Add new crowd control"] = true
L["Add raid icon"] = true
L["Broadcast all zone data to the raid group."] = true
L["Broadcast raid target settings to the raid group."] = true
L["Broadcast zone data to the raid group."] = true
L["Category"] = true
L["Config"] = true
L["Data Broadcasting"] = true
L["Data Sharing"] = true
L["Delay between remarking"] = true
L["Enable Magic Marker in this zone"] = true
L["Enable auto-marking on target change"] = true
L["Enable target re-prioritization during combat"] = true
L["General Options"] = true
L["Honor pre-existing raid icons"] = true
L["Introduction"] = true
L["Key Bindings"] = true
L["Log level"] = true
L["Marking Behavior"] = true
L["Max # to Crowd Control"] = true
L["Merge - local priority"] = true
L["Merge - remote priority"] = true
L["Mob Database"] = true
L["Mob Notes"] = true
L["Mobdata data import behavior"] = true
L["None"] = true
L["Options"] = true
L["Out of these mobs %d are ignored."] = true
L["Preserve raid group icons"] = true
L["Priority"] = true
L["Raid Target Settings"] = true
L["Replace with remote data"] = true
L["Reset raid icons when resetting the cache"] = true
L["Zone Options"] = true
L['Delete entire zone from database (not recoverable)'] = true
L['Delete mob from database (not recoverable)'] = true 

-- Options config confirmation
L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"] = true
L["Are you sure you want to delete |cffd9d919%s|r from the database?"] = true

-- CC Names
L["BANISH"] = "Banish"
L["ENSLAVE"] = "Enslave"
L["FEAR"] = "Fear"
L["HIBERNATE"] = "Hibernate"
L["KITE"] = "Kite"
L["MC"] = "Mind Control"
L["ROOT"] = "Root"
L["SAP"] = "Sap"
L["SHACKLE"] = "Shackle"
L["SHEEP"] = "Sheep"
L["TRAP"] = "Trap" 
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
L["NOREUSEHELPTEXT"] = "When enabled, Magic Marker will preserve all raid icons on the raid/party members, even through cache resets."
L["INCOMBATHELPTEXT"] = "Whether or not Magic Marker should be allowed to change assigned raid marks during combat if it sees higher priority targets. Note that this only decides whether to unmark lower priority mobs. Unassigned icons will always be used on unmarked target, regardless of combat status."
L["RESETICONHELPTEXT"] = "When resetting the raid icon cache, also reset all raid icons. Note that if the option to reserve raid group icons is enabled, those icons will remain regardless of status of this parameter."
L["IMPORTHELPTEXT"] = "This option dictates the behavior when you receive a mob data broadcast. Merging will keep data from both databases. If you choose local priority, your own settings won't be replaced - only new data will be added. With remote priority your local entries will be overriden by the remote data. The replace option will completely replace your database with the received data."
L["MOBBROADHELPTEXT"] = "If enabled you will accept zone mob data sent to you by the raid leader or assistant."
L["MARKBROADHELPTEXT"] = "If enabled you will accept raid mark configuration that is broadcasted by your raid leader. The new configuration will entirely replace your own settings."
L["BROADALLHELP"] = "Broadcasts all the data in your mob database to the raid. This can be a lot of data and it is recommended to broadcast individual zones instead."
L["MAXCCHELP"] = "Maximum number of mobs of this type to crowd control at any one time."

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

-- Other
L["Heroic"] = true

-- Command line options
L["Open configuration dialog."] = true
L["Unknown raid template: %s"] = true
L["Raid group target templates."] = true
L["About Magic Marker."] = true
L["Raid mark layout caching."] = true
 
-- Raid mark templates
L["Mark all mages and druids in the raid."] = true
L["Mark all shamans in the raid."]= true
L["Mark the decursers followed by the shamans."] = true
L["Alias for archimonde."] = true

