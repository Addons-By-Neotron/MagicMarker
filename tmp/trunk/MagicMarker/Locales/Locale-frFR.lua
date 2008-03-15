-- MagicMarker
-- frFR Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "frFR", true)


L["Magic Marker"] = true

-- Key Bindings
L["Reset raid icon cache"] = "Réinit. cache icônes de raid"
L["Mark selected target"] = "Marque cible actuelle"
L["Unmark selected target"] = "Démarque cible actuelle"
L["Toggle config dialog"] = "Affiche configuration"
L["Mark party/raid targets"] = "Marque cibles groupe/raid"

-- Options Config
L["Options"] = "Options"
L["Config"] = "Configuration"
L["Priority"] = "Priorité"
L["Category"] = "Catégorie"
L["Mob Database"] = "Base des monstres"
L["Raid Target Settings"] = "Paramètres cible de raid"
L["Add new crowd control"] = "Ajout contrôle de monstre"
L["Add raid icon"] = "Ajout icône raid"
L["Crowd Control #"] = "Contrôle de monstre #"
L["Key Bindings"] = "Raccourcis"
L["Log level"] = "Niveau de log"
L["General Options"] = "Options générales"
L["%s has a total of %d mobs. %s of these are newly discovered."] = "%s a un total de %d monstres. %s sont nouvellement découverts."
L["Out of these mobs %d are ignored."] = true
L["None"] = "Aucun"
L["Mob Notes"] = "Notes du monstre"
L["Zone Options"] = "Options de la zone"
L["Enable auto-marking on target change"] = "Activer le marquage auto au changement de cible"
L["Enable Magic Marker in this zone"] = "Activer Magic Marker dans cette zone"
L['Delete mob from database (not recoverable)'] = "Supprime les monstres de la base (non réversible)" 
L['Delete entire zone from database (not recoverable)'] = "Supprime la zone entière de la base (non réversible)"
L["Introduction"] = "Introduction"
L["Delay between remarking"] = "Délais de remarquage"
L["Marking Behavior"] = "Comportement du marquage"
L["Honor pre-existing raid icons"] = "Respecter les icônes de raid pré-existantes"
L["Preserve raid group icons"] = "Préserve les icônes du raid"
L["Reset raid icons when resetting the cache"] = "Réinitialise les icônes de raid lors du reset du cache"
L["Enable target re-prioritization during combat"] = "Activer la re-prioritarisation pendant le combat"
L["Broadcast zone data to the raid group."] = "Diffuser au raid les données de la zone"
L["Data Sharing"] = "Partage des données"
L["Accept raid mark broadcast messages"] = "Accepte les messages de diffusion des icônes de raid"
L["Accept mobdata broadcast messages"] = "Accepte les messages de diffusion des données des monstres"
L["Mobdata data import behavior"] = "Comportement de l'import des données des monstres"
L["Merge - local priority"] = "Fusion - priorité locale"
L["Merge - remote priority"] = "Fusion - priorité distante"
L["Replace with remote data"] = "Utiliser les données distantes"
L["Data Broadcasting"] = "Diffusion des données"
L["Broadcast raid target settings to the raid group."] = "Diffuse au raid les paramètres de marquage"
L["Broadcast all zone data to the raid group."] = "Diffuse au raid toutes les données de la zone"
 
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
L["00NONE"] = "Aucun"

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

-- Printed non-debug messages
L["Added new mob %s in zone %s."] = "Ajout du nouveau monstre %s dans la zone %s."
L["Resetting raid targets."] = "Réinitialisation des icônes de raid."
L["Magic Marker enabled."] = "Magic Marker activé."
L["Magic Marker disabled."] = "Magic Marker désactivé."
L["Save party/raid mark layout"] = "Sauvegarde du plan de marquage du groupe/raid."
L["Load party/raid mark layout"] = "Chargement du plan de marquage du groupe/raid."
L["Unable to determine the class for %s."] = "Impossible de déterminer la classe pour %s."
L["Deleting zone %s from the database!"] = "Suppression de la zone %s de la base!"
L["Deleting mob %s from zone %s from the database!"] = "Suppression du monstre %s dans la zone %s de la base!"
L["Added third party mark (%s) for mob %s."] = "Ajout d'une marque d'une tierce partie (%s) pour le monstre %s."

-- Log levels
L["NONE"] = "Désactivé"
L["ERROR"] = "Erreurs seulement"
L["WARN"] = "Erreurs et avertissements"
L["INFO"] = "Messages d'information"
L["DEBUG"] = "Messages de debug"
L["TRACE"] = "Messages de trace de debug"

-- Other
L["Heroic"] = "Héroïque"
