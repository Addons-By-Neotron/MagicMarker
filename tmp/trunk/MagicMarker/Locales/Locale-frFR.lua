
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

-- frFR Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "frFR")

if not L then return end

L["Magic Marker"] = true

-- Key Bindings
L["Mark party/raid targets"] = "Marque cibles groupe/raid"
L["Mark selected target"] = "Marque cible actuelle"
L["Reset raid icon cache"] = "Réinit. cache icônes de raid"
L["Toggle config dialog"] = "Affiche configuration"
L["Unmark selected target"] = "Démarque cible actuelle"
L["Save party/raid mark layout"] = "Sauvegarde du modèle de marquage du groupe/raid."
L["Load party/raid mark layout"] = "Chargement du modèle de marquage du groupe/raid."
L["Smart marking modifier key"] = "Touche de modification pour le marquage"
L["SMARTMARKKEYHELP"] = "Tenez appuyée cette touche pour marquer les cibles à la souris. Relâchez la pour désactiver le marquage. Si ce raccourci n'est pas défini, la touche de modification spécifiée dans Options => Options générales sera utilisée à la place."

-- Options Config
L["%s has a total of %d mobs. %s of these are newly discovered."] = "%s a un total de %d monstres.\n%s sont nouvellement découverts."
L["Accept mobdata broadcast messages"] = "Accepte les messages de diffusion des données des monstres"
L["Accept raid mark broadcast messages"] = "Accepte les messages de diffusion des icônes de raid"
L["Accept CC priority broadcast messages"] = "Accepte les messages de diffusion de priorités de contrôle"
L["Add new crowd control"] = "Ajout contrôle de monstre"
L["Add raid icon"] = "Ajout icône raid"
L["Broadcast all zone data to the raid group."] = "Diffuse au raid toutes les données de la zone"
L["Broadcast raid target settings to the raid group."] = "Diffuse au raid les paramètres de marquage"
L["Broadcast zone data to the raid group."] = "Diffuser au raid les données de la zone"
L["Broadcast crowd control priority settings to the raid group."] = "Diffuser au raid les paramètres de priorité de contrôle"
L["Category"] = "Catégorie"
L["Config"] = "Configuration"
L["Crowd Control #"] = "Contrôle de monstre #"
L["Data Broadcasting"] = "Diffusion des données"
L["Data Sharing"] = "Partage des données"
L["Delay between remarking"] = "Délais de remarquage"
L["Enable Magic Marker in this zone"] = "Activer Magic Marker dans cette zone"
L["Enable auto-marking on target change"] = "Activer le marquage auto au changement de cible"
L["Enable target re-prioritization during combat"] = "Activer la re-prioritarisation pendant le combat"
L["General Options"] = "Options générales"
L["Honor pre-existing raid icons"] = "Respecter les icônes de raid pré-existantes"
L["Introduction"] = "Introduction"
L["Key Bindings"] = "Raccourcis"
L["Log level"] = "Niveau de log"
L["Marking Behavior"] = "Comportement du marquage"
L["Max # to Crowd Control"] = "Nombre max de monstres à contrôler"
L["Merge - local priority"] = "Fusion - priorité locale"
L["Merge - remote priority"] = "Fusion - priorité distante"
L["Mob Database"] = "Base des monstres"
L["Mob Notes"] = "Notes du monstre"
L["Mobdata data import behavior"] = "Comportement de l'import des données des monstres"
L["None"] = "Aucun"
L["Options"] = "Options"
L["\nOut of these mobs %d are ignored."] = "\nDe ces monstres, %d sont ignorés"
L["Preserve raid group icons"] = "Préserve les icônes du raid"
L["Priority"] = "Priorité"
L["Raid Target Settings"] = "Paramètres cible de raid"
L["Replace with remote data"] = "Utiliser les données distantes"
L["Reset raid icons when resetting the cache"] = "Réinitialise les icônes de raid lors du reset du cache"
L["Zone Options"] = "Options de la zone"
L['Delete entire zone from database (not recoverable)'] = "Supprime la zone entière de la base (non réversible)"
L['Delete mob from database (not recoverable)'] = "Supprime les monstres de la base (non réversible)" 
L["Unused Crowd Control Methods"] = "Méthodes de contrôle inutilisées"
L["Auto learn CC" ] = "Apprentissage auto des contrôles"
L["Smart Mark Modifier"] = "Touche de modification"
L["Alt"] = "Alt"
L["Shift"] = "Maj"
L["Control"] = "Ctrl"
  
-- Options config confirmation
L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"] = "Êtes-vous |cffd9d919VRAIMENT|r certain de vouloir supprimer |cffd9d919%s|r et tous ses monstres de la base ?"
L["Are you sure you want to delete |cffd9d919%s|r from the database?"] = "Êtes-vous certain de vouloir supprimer |cffd9d919%s|r de la base"

-- CC Names
L["SHEEP"] = "Métamorphose"
L["BANISH"] = "Bannir"
L["SHACKLE"] = "Entrave"
L["HIBERNATE"] = "Hibernation"
L["TRAP"] = "Piège" 
L["KITE"] = "Kite"
L["MC"] = "Contrôle mental"
L["FEAR"] = "Peur"
L["SAP"] = "Assommer"
L["ENSLAVE"] = "Asservir"
L["ROOT"] = "Sarments"
L["CYCLONE"] = "Cyclone"
--L["TURNEVIL"] = "Turn Evil" --Didn't found the translation
L["TURNUNDEAD"] = "Renvoi des morts-vivants"
L["SCAREBEAST"] = "Effrayer une bête"
L["SEDUCE"] = "Séduction"
L["00NONE"] =  "Aucun"

-- Priority names
L["P1"] = "Très haut"
L["P2"] = "Haut"
L["P3"] = "Moyen"
L["P4"] = "Bas"
L["P5"] = "Très bas"
L["P6"] = "Ignorer"

-- Category names
L["TANK"] = "Tank"
L["CC"] = "Contrôle de monstre"

-- Raid icons
L["Star"] = "Etoile"
L["Circle"] = "Rond"
L["Diamond"] = "Diamant"
L["Triangle"] = "Triangle"
L["Moon"] = "Lune"
L["Square"] = "Carré"
L["Cross"] = "Croix"
L["Skull"] = "Crâne"

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

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = "Ajout du nouveau monstre %s dans la zone %s."
L["Resetting raid targets."] = "Réinitialisation des icônes de raid."
L["Magic Marker enabled."] = "Magic Marker activé."
L["Magic Marker disabled."] = "Magic Marker désactivé."
L["Unable to determine the class for %s."] = "Impossible de déterminer la classe pour %s."
L["Deleting zone %s from the database!"] = "Suppression de la zone %s de la base!"
L["Deleting mob %s from zone %s from the database!"] = "Suppression du monstre %s dans la zone %s de la base!"
L["Added third party mark (%s) for mob %s."] = "Ajout d'une icône d'une tierce partie (%s) pour le monstre %s."

-- Log levels
L["NONE"] = "Désactivé"
L["ERROR"] = "Erreurs seulement"
L["WARN"] = "Erreurs et avertissements"
L["INFO"] = "Messages d'information"
L["DEBUG"] = "Messages de debug"
L["TRACE"] = "Messages de trace de debug"
L["SPAM"] = "Plus haut niveau de log de debug"

-- Other
L["Heroic"] = "Héroïque"
L["Normal"] = "Normal"
L["Raid"] = "Raid"

-- Command line options
L["Toggle configuration dialog"] = "Affiche/Cache la fenêtre de configuration"
L["Unknown raid template: %s"] = "Modèle de raid inconnu : %s"
L["Raid group target templates"] = "Modèles de cible du groupe de raid"
L["About Magic Marker"] = "A propos de Magic Marker"
L["Raid mark layout caching"] = "Modèles d'icônes de raid en cache"
L["Toggle Magic Marker event handling"] = "Active/Désactive le traitement des événements"
--    
-- Raid mark templates
L["Mark all mages and druids in the raid"] = "Marque tous les mages et druides  du raid"
L["Mark all shamans in the raid"]= "Marque tous les chamans du raid"
L["Mark the decursers followed by the shamans"] = "Marque tous les décurseurs puis les chamans"
L["Alias for archimonde"] = "Alias pour Archimonde"

-- FuBar plugin
L["Disabled"] = "Désactivé"
L["Enabled"] = "Activé"
L["Zone"] = "Zone"
L["Status"] = "Etat"
L["Toggle event handling"] = "Active/Désactive le traitement des événements"
L["Load the currently saved raid mark layout."] = "Charge le modèle d'icônes de raid actuellement enregistré"
L["Save the current raid mark layout."] = "Sauvegarde le modèle actuel d'icônes de raid"
L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."] = "Réinitialise le cache des icônes de raid. Notez que ceci préserve les options de Magic Marker ainsi que les icônes sur le raid."
L["Short FuBar Text"] = "Texte FuBar court"
L["Hide Magic Marker from the FuBar status text."] = "Cache Magic Marker de la barre d'état de FuBar."
L["Enable or disable the event handling, i.e whether or not Magic Marker will insert mobs into the mob database, mark mobs etc."] = "Active ou désactive le traitement des événements, i.e. si Magic Marker doit insérer ou non les monstres dans la base, marquer les monstres, etc."
L["Toggle the Magic Marker configuration dialog."] = "Affiche/Cache la fenêtre de configuration de Magic MArker"
L["Report the raid icon assignments to raid/party chat"] = "Signaler les affectations des icônes sur le chat raid/groupe"
L["Report raid assignments"] = "Signaler les affectations de raid"
L["RAIDMARKCACHEHELP"] = "Cette fonctionnalité vous permet d'enregistrer un modèle d'icônes de raid et de le réutiliser. Utile, par exemple, pour avoir les icônes de raid en phase 2 d'Illidan mais pas lors des autres phases."
L["RAIDTMPLHELP"] = "Un modèle d'icônes de raid vous permet de marquer rapidement certaines classes ou rôles dans le raid."
 
L["External"] = "Externe"
L["Template"] = "Modèle"
L["Difficulty"] = "Difficulté"
L["Unit Name"] = "Nom de l'unité"
L["Mark Type"] = "Type de marque"
L["Score"] = "Score"
L["Profile name"] = "Nom du profil"
L["Active profile: %s"] = "Profil actif : %s"

L["TOOLTIP_HINT"] =
   "\n|cffeda55fClic|r pour afficher/cacher la fenêtre de config.\n"..
   "|cffeda55fMaj-Clic|r pour activer/désactiver les événements.\n"..
   "|cffeda55fAlt-Clic|r pour réinitialiser le cache des icônes de raid.\n"..
   "|cffeda55fAlt-Maj-Clic|r pour faire un reset complet du cache.\n"..
   "|cffeda55fClic-Milieu|r pour signaler les affectations de raid sur le chat."

-- creature description
L["Creature type"] = "Type de créature"
L["family"] = "famille"
L["classification"] = "catégorie"
L["unit is a caster"] = "l'unité est un caster"

-- Yes! No!
L["Yes"] = "Oui"
L["No"] = "Non"
