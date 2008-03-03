-- MagicMarker
-- enUS and enGB Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "enUS", true)


L["Magic Marker"] = true

-- Key Bindings
L["Reset raid icons"] = true
L["Mark selected target"] = true
L["Unmark selected target"] = true
L["Toggle config dialog"] = true

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
L["Enable debug messages"] = true
L["General Options"] = true
L["%s has a total of %d mobs. %s of these are newly discovered."] = true
L["Out of these mobs %d are ignored."] = true
L["None"] = true

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
L["00NONE"] = "None "

-- Priority names
L["P1"] = "High"
L["P2"] = "Medium"
L["P3"] = "Low"
L["P4"] = "Ignore"

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
L["_Remove"] = "None"

-- Help Texts
L["CCHELPTEXT"] = "Here you configure all CC methods that are available for this target. The ordering is the priority in which they are attempted be used. I.e if the raid has two mages but two sheep targets are already assigned, it will iterate through the specified methods until one is found. If none is found, it will revert back to assigning a tank or arbitrary symbol to the target."

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = true
L["Resetting raid targets."] = true
