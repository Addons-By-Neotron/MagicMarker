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

-- enUS and enGB Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "enUS", true)


L["Magic Marker"] = true

-- Key Bindings
L["Reset raid icon cache"] = true
L["Mark selected target"] = true
L["Unmark selected target"] = true
L["Toggle config dialog"] = true
L["Mark party/raid targets"] = true
L["Save party/raid mark layout"] = true
L["Load party/raid mark layout"] = true
L["Smart marking modifier key"] = true
L["Increase mob priority"] = true
L["Decrease mob priority"] = true
L["Increase CC mob priority"] = true
L["Decrease CC mob priority"] = true
L["Toggle mob category"] = true

L["SMARTMARKKEYHELP"] = "Hold down this key to mark targets on mouseover. Releasing the key will disable marking. If this key binding is unset, the modifier key specified in the Options => General Options will be used instead."
L["INCREASE PRIO HELP"] = "Increase the tank priority of the selected mob. Note that this quick key only affects tank priority. To modify the crowd control priority you need to go into the config UI."
L["DECREASE PRIO HELP"] = "Decrease the tank priority of the selected mob. Note that this quick key only affects tank priority. To modify the crowd control priority you need to go into the config UI."
L["INCREASE CC PRIO HELP"] = "Increase crowd control priority of the selected mob."
L["DECREASE CC PRIO HELP"] = "Decrease crowd control the priority of the selected mob."
L["SWAP TYPE HELP"] = "Change this mob's category from Tank to Crowd Control and vice versa."

-- Options Config
L["%s has a total of %d mobs.\n%s of these are newly discovered."] = true
L["Accept mobdata broadcast messages"] = true
L["Accept raid mark broadcast messages"] = true
L["Accept CC priority broadcast messages"] = true
L["Add new crowd control"] = true
L["Add raid icon"] = true
L["Add all raid icons"] = true
L["Broadcast all zone data to the raid group."] = true
L["Broadcast raid target settings to the raid group."] = true
L["Broadcast zone data to the raid group."] = true
L["Broadcast crowd control priority settings to the raid group."] = true
L["Category"] = true
L["Config"] = true
L["Data Broadcasting"] = true
L["Data Sharing"] = true
L["Delay between remarking"] = true
L["Enable Magic Marker in this zone"] = true
L["Enable auto-marking on target change"] = true
L["Enable target re-prioritization during combat"] = true
L["Preserve raid icons on units in combat"] = true
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
L["\nOut of these mobs %d are ignored."] = true
L["Preserve raid group icons"] = true
L["Priority"] = true
L["Raid Target Settings"] = true
L["Replace with remote data"] = true
L["Reset raid icons when resetting the cache"] = true
L["Zone Options"] = true
L['Delete entire zone from database (not recoverable)'] = true
L['Delete mob from database (not recoverable)'] = true 
L["Unused Crowd Control Methods"] = true
L["Auto learn CC" ] = true
L["Smart Mark Modifier"] = true
L["Alt"] = true
L["Shift"] = true
L["Control"] = true
L["New marking system"] = true
L["Minimum # of tank targets"] = true
L["Ignore dead people"] = true
L["Count Burn Down target as tanked mobs"] = true
L["MagicMarker_Data version newer than the previously imported data. Do you want to import it?"] = true

-- Options config confirmation
L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"] = true
L["Are you sure you want to delete |cffd9d919%s|r from the database?"] = true

-- CC Names
L["BANISH"] = "Banish"
L["ENSLAVE"] = "Enslave Demon"
L["FEAR"] = "Fear"
L["HIBERNATE"] = "Hibernate"
L["KITE"] = "Kite"
L["MC"] = "Mind Control"
L["ROOT"] = "Root"
L["SAP"] = "Sap"
L["SHACKLE"] = "Shackle"
L["SHEEP"] = "Sheep"
L["TRAP"] = "Trap" 
L["CYCLONE"] = "Cyclone"
L["TURNEVIL"] = "Turn Evil"
L["TURNUNDEAD"] = "Turn Undead"
L["BINDELEMENTAL"] = "Bind Elemental"
L["SCAREBEAST"] = "Scare Beast"
L["SEDUCE"] = "Seduction"
L["BLIND"] = "Blind"
L["BURN"] = "Burn Down"
L["HEX"] = "Hex"
L["REPENTANCE"] = "Repentance"
L["00NONE"] = "None"

-- Priority names
L["P0"] = "Same as Tank"
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

-- Expansion names
L["Cataclysm"] = true
L["Wrath of the Lich King"] = true
L["Burning Crusade"] = true
L["Original"] = true
L["Classic"] = true
L["Warlords of Draenor"] = true
L["Legion"] = true
L["Battle for Azeroth"] = true
L["Vanilla"] = true

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
L["CCAUTOHELPTEXT"] = "When enabled, Magic Marker will automatically learn what crowd control methods you can use on mobs when it is successfully applied."
L["SMARTMARKMODHELP"] = "Modifier key to press to enable smart marking. If you set the smart making modifier key binding, that key will be used instead."
L["NEWMARKHELP"] = "Enable the new prioritization system. It is designed to minimize the amount of remarking needed but is still in development. To use it hold in the modifier to sweep over all mobs you want to mark once. Then release the modifier and sweep over them a second time to do the final marking. Note if you manually mark or unmark a mob you need to sweep over all mobs again to ensure proper marks."
L["MINTANKHELP"] = "Minimum number of mobs to mark as tanks. This requires the new marking system. If insufficient tank targets are available after crowd control is set, the least prioritized crowd control targets will be released for tank targets."
L["FILTERDEADHELP"] = "Ignore dead people when iterating the raid group."
L["IN COMBAT UNIT HELP TEXT"] = "If enabled, Magic Marker will preserve raid marks on units that are combat. This will prevent accidental, unintended remarking during combat."
L["BURN DOWN HELP"] = "If enabled, mobs marked as burn down will be counted towards the minimum numbers to mark as tanks. This is useful since it will ensure that solo burn down targets (such as the scouts in Zul'Aman) will always be marked consistently."

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = true
L["Resetting raid targets."] = true
L["Magic Marker enabled."] = true
L["Magic Marker disabled."] = true
L["Unable to determine the class for %s."] = true
L["Deleting zone %s from the database!"] = true
L["Deleting mob %s from zone %s from the database!"] = true
L["Added third party mark (%s) for mob %s."] = true
L["Changed %s priority for %s to %s."] = true
L["Changed category for %s to %s."] = true

-- Log levels
L["NONE"] = "Disabled"
L["ERROR"] = "Errors only"
L["WARN"] = "Errors and warnings"
L["INFO"] = "Informational messages"
L["DEBUG"] = "Debug messaging"
L["TRACE"] = "Debug trace messages"
L["SPAM"] = "Highest level of debug log spam"

-- Other
L["Heroic"] = true
L["Normal"] = true
L["Raid"] = true

-- Command line options
L["Toggle configuration dialog"] = true
L["Unknown raid template: %s"] = true
L["Raid group target templates"] = true
L["About Magic Marker"] = true
L["Raid mark layout caching"] = true
L["Toggle Magic Marker event handling"] = true
 L["Query raid for their MagicMarker versions."] = true
 
-- Raid mark templates
L["Mark all mages and druids in the raid"] = true
L["Mark all shamans in the raid"]= true
L["Mark the decursers followed by the shamans"] = true
L["Alias for archimonde"] = true

-- LDB Display
L["Disabled"] = true
L["Enabled"] = true
L["Zone"] = true
L["Status"] = true
L["Toggle event handling"] = true
L["Load the currently saved raid mark layout."] = true
L["Save the current raid mark layout."] = true
L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."] = true
L["Enable or disable the event handling, i.e whether or not Magic Marker will insert mobs into the mob database, mark mobs etc."] = true
L["Toggle the Magic Marker configuration dialog."] = true

L["RAIDMARKCACHEHELP"] = "This functionality lets you save the raid mark layout of the raid and then recall it. Useful to, for example, have raid marks enabled during phase 2 of Illidan but disabled in the other phases."
L["RAIDTMPLHELP"] = "Raid templates allow you to quickly mark certain classer or roles in the raid."

L["External"] = true
L["Template"] = true
L["Difficulty"] = true
L["Unit Name"] = true
L["Mark Type"] = true
L["Score"] = true
L["Marked"] = true
L["Report the raid icon assignments to raid/party chat"] = true
L["Report raid assignments"] = true
L["Profile name"] = true
L["Active profile: %s"] = true

L["TOOLTIP_HINT"] =
   "|cffeda55fClick|r |cffffd200to toggle config dialog.|r\n"..
   "|cffeda55fShift-Click|r |cffffd200to toggle event handling.|r\n"..
   "|cffeda55fAlt-Click|r |cffffd200to reset raid icon cache.|r\n"..
   "|cffeda55fAlt-Shift-Click|r |cffffd200to hard reset raid icon cache.|r\n"..
   "|cffeda55fMiddle-Click|r |cffffd200to print raid assignments to group chat.|r"

-- creature description
L["Creature type"] = true
L["family"] = true
L["classification"] = true
L["unit is a caster"] = true

-- Yes! No!
L["Yes"] = true
L["No"] = true

