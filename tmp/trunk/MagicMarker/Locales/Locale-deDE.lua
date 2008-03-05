-- MagicMarker
-- deDE Localization file
-- by EnSabahNur and Bl4ckSh33p

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "deDE")
if not L then return end

L["Magic Marker"] = "Magic Marker";

-- Key Bindings
L["Toggle learning mode"] = "Lernmodus an/aus";
L["Toggle smart marking mode"] = "Intelligenter Markierungsmodus an/aus";
L["Mark selected target"] = "Ausgew\195\164hltes Ziel markieren";
L["Unmark selected target"] = "Markierung auf aktuellem Ziel entfernen";

-- Options Config
L["Options"] = "Einstellungen"
L["Crowd Control Config"] = "Gruppenkontroll-Konfiguration"
L["Priority"] = "Priorit\195\164t"
L["Category"] = "Kategorie"
L["Mob Database"] = "Mob Datenbank"
L["Raid Target Settings"] = "Schlachtzugs-Zieleinstellungen"
L["Add new crowd control"] = "Neue Gruppenkontrolle hinzuf\195\188gen"
L["Add raid icon"] = "Schlachtzug-Icon hinzuf\195\188gen"
L["Crowd Control #"] = "Gruppenkontrolle #"
L["Key Bindings"] = "Tastenzuweisungen"
L["Enable debug messages"] = "Debug-Meldungen aktivieren"
L["General Options"] = "Generelle Einstellungen"
L["%s has a total of %d mobs. %s of these are newly discovered."] = "%s hat insgesamt %d Mobs. %s davon sind neu entdeckt."
L["Out of these mobs %d are ignored."] = "Von diesen Mobs sind %d ignoriert."
L["None"] = "Keines"
L["Mob Notes"] = "Mob Notizen"

-- Mark categories
L["Tank"] = "Tank"
L["Crowd Control - Sheep"] = "Gruppenkontrolle - Schaf"
L["Crowd Control - Banish"] = "Gruppenkontrolle - Verbannen"
L["Crowd Control - Other"] = "Gruppenkontrolle - Andere"
L["Ignored"] = "Ignoriert"

-- CC Names
L["SHEEP"] = "Schaf"
L["BANISH"] = "Verbannen"
L["SHACKLE"] = "Untote Fesseln"
L["HIBERNATE"] = "Winterschlaf"
L["TRAP"] = "Falle" 
L["KITE"] = "Kiten"
L["MC"] = "Gedankenkontrolle"
L["FEAR"] = "Furcht"
L["SAP"] = "Kopfnuss"
L["00NONE"] = "Keine "

-- Priority names
L["P1"] = "Hoch"
L["P2"] = "Mittel"
L["P3"] = "Niedrig"
L["P4"] = "Ignorieren"

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
L["CCHELPTEXT"] = "Hier werden alle Gruppenkontroll-Methoden die f\195\188r das aktuelle Ziel verf\195\188gbar sind konfiguriert. Es wird nach Priorit\195\164t sortiert die nacheinander angewendet wird. Wenn im Schlachtzug zum Beispiel zwei Magier sind aber bereits zwei Schaf-Ziele zugewiesen wurden, wird durch die vorhandenen Methoden gewechselt bis eine passende gefunden wird. Falls keine gefunden wird, wird ein Tank oder ein noch vorhandenes Symbol dem Ziel zugewiesen."

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = "Neuer Mob %s in Zone %s hinzugef\195\188gt."
L["Resetting raid targets."] = "Schlachtzugs-Ziele zur\195\188cksetzen."
