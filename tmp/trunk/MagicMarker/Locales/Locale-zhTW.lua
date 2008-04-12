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

-- zhTW Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("MagicMarker", "zhTW")

if not L then return end

L["Magic Marker"] = true

-- Key Bindings
L["Reset raid icon cache"] = "重設團隊標記快取記憶"
L["Mark selected target"] = "標記目標"
L["Unmark selected target"] = "解除標記"
L["Toggle config dialog"] = "開關設定對話框"
L["Mark party/raid targets"] = "標記 小隊/團隊 目標"
L["Save party/raid mark layout"] = "儲存 小隊/團隊 標記配置"
L["Load party/raid mark layout"] = "讀取 小隊/團隊 標記配置"
L["Smart marking modifier key"] = "智慧標記按鍵"
L["SMARTMARKKEYHELP"] = "按下此鍵以使用滑鼠標記怪物。放開此鍵會關閉標記怪物功能。如果未設定此按鍵，會自動以 選項 => 通用設定 中的按鍵設定替代。"

-- Options Config
L["%s has a total of %d mobs.\n%s of these are newly discovered."] = "%s 總共有 %d 隻怪物。\n其中有 %s 是新發現的。"
L["Accept mobdata broadcast messages"] = "接受 mobdata 廣播訊息"
L["Accept raid mark broadcast messages"] = "接受團隊標記廣播訊息"
L["Accept CC priority broadcast messages"] = "接受控場優先順序廣播訊息"
L["Add new crowd control"] = "增加新的控場順序"
L["Add raid icon"] = "增加團隊標記"
L["Broadcast all zone data to the raid group."] = "向團隊廣播所有的區域資料"
L["Broadcast raid target settings to the raid group."] = "向團隊廣播團隊目標設定"
L["Broadcast zone data to the raid group."] = "向團隊廣播區域資料"
L["Broadcast crowd control priority settings to the raid group."] = "向團隊廣播控場優先順序設定"
L["Category"] = "類別"
L["Config"] = "設定"
L["Data Broadcasting"] = "資訊廣播"
L["Data Sharing"] = "資訊分享"
L["Delay between remarking"] = "重新標記時延遲操作"
L["Enable Magic Marker in this zone"] = "於此區域開啟 Magic Marker"
L["Enable auto-marking on target change"] = "於目標轉換時啟動自動標記"
L["Enable target re-prioritization during combat"] = "於戰鬥中開啟目標重訂優先順序"
L["General Options"] = "通用設定"
L["Honor pre-existing raid icons"] = "接受已存在的團隊標記圖示"
L["Introduction"] = "介紹"
L["Key Bindings"] = "按鍵設置"
L["Log level"] = "訊息紀錄等級"
L["Marking Behavior"] = "標記行為"
L["Max # to Crowd Control"] = "最大 # 控場"
L["Merge - local priority"] = "合併 - 本地端優先順序"
L["Merge - remote priority"] = "合併 - 遠端優先順序"
L["Mob Database"] = "怪物資料庫"
L["Mob Notes"] = true
L["Mobdata data import behavior"] = true
L["None"] = "無"
L["Options"] = "選項"
L["\nOut of these mobs %d are ignored."] = true
L["Preserve raid group icons"] = "保留團隊標記圖示"
L["Priority"] = "優先順序"
L["Raid Target Settings"] = "團隊目標設定"
L["Replace with remote data"] = "以遠端資訊覆蓋"
L["Reset raid icons when resetting the cache"] = "當重置 Cache 時重置團隊標記"
L["Zone Options"] = "區域選項"
L['Delete entire zone from database (not recoverable)'] = "從資料庫刪除整個區域 (無法回復)"
L['Delete mob from database (not recoverable)'] = "從資料庫刪除怪物 (無法回復)"
L["Unused Crowd Control Methods"] = "未使用的控場技能"
L["Auto learn CC" ] = "自動學習控場行為"
L["Smart Mark Modifier"] = "智慧標記"
L["Alt"] = true
L["Shift"] = true
L["Control"] = true

-- Options config confirmation
L["Are you |cffd9d919REALLY|r sure you want to delete |cffd9d919%s|r and all its mob data from the database?"] = "你 |cffd9d919確定|r 要從資料庫刪除 |cffd9d919%s|r 和所有的怪物資訊?"
L["Are you sure you want to delete |cffd9d919%s|r from the database?"] = "你確定要從資料庫刪除 |cffd9d919%s|r ?"

-- CC Names
L["BANISH"] = "放逐"
L["ENSLAVE"] = "奴役"
L["FEAR"] = "恐懼術"
L["HIBERNATE"] = "休眠"
L["KITE"] = "風箏"
L["MC"] = "心靈控制"
L["ROOT"] = "糾纏根鬚"
L["SAP"] = "悶棍"
L["SHACKLE"] = "束縛不死生物"
L["SHEEP"] = "變羊術"
L["TRAP"] = "陷阱" 
L["CYCLONE"] = "颶風術"
L["TURNEVIL"] = "Turn Evil"
L["TURNUNDEAD"] = "Turn Undead"
L["SCAREBEAST"] = "恐懼野獸"
L["SEDUCE"] = "魅惑"
L["00NONE"] = "無"

-- Priority names
L["P1"] = "非常高"
L["P2"] = "高"
L["P3"] = "中"
L["P4"] = "低"
L["P5"] = "非常低"
L["P6"] = "可忽略"

-- Category names
L["TANK"] = "坦克"
L["CC"] = "控場"

-- Raid icons
L["Star"] = "星星"
L["Circle"] = "圓圈"
L["Diamond"] = "鑽石"
L["Triangle"] = "三角"
L["Moon"] = "月亮"
L["Square"] = "方形"
L["Cross"] = "叉叉"
L["Skull"] = "骷髏"

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
L["Added new mob %s in zone %s."] = "已新增新的怪物 %s (在 %s 區域)。"
L["Resetting raid targets."] = "重設團隊目標。"
L["Magic Marker enabled."] = "Magic Marker已經啟動。"
L["Magic Marker disabled."] = "Magic Marker已經關閉。"
L["Unable to determine the class for %s."] = "無法判定 %s 的類別。"
L["Deleting zone %s from the database!"] = "從資料庫刪除區域 %s!"
L["Deleting mob %s from zone %s from the database!"] = "從資料庫刪除 %s 怪物 (在 %s)!"
L["Added third party mark (%s) for mob %s."] = "新增第三方小隊標記 %s (怪物 %s )"

-- Log levels
L["NONE"] = "關閉"
L["ERROR"] = "錯誤訊息"
L["WARN"] = "錯誤與警告訊息"
L["INFO"] = "提示訊息"
L["DEBUG"] = "除錯訊息"
L["TRACE"] = "除錯追蹤訊息"
L["SPAM"] = "Highest level of debug log spam"

-- Other
L["Heroic"] = "英雄"
L["Normal"] = "普通"
L["Raid"] = true

-- Command line options
L["Toggle configuration dialog"] = "開關設定視窗"
L["Unknown raid template: %s"] = "未知的團隊範本: %s"
L["Raid group target templates"] = "團隊目標範本"
L["About Magic Marker"] = "關於 Magic Marker"
L["Raid mark layout caching"] = "團隊標記配置快取"
L["Toggle Magic Marker event handling"] = "開關 Magic Marker 事件處理"
   
-- Raid mark templates
L["Mark all mages and druids in the raid"] = "標出所有團隊中的法師和得魯伊"
L["Mark all shamans in the raid"]= "標出所有團隊中的薩滿"
L["Mark the decursers followed by the shamans"] = "標出跟著薩滿的所有驅散魔法者"
L["Alias for archimonde"] = true

-- FuBar plugin
L["Disabled"] = "關閉"
L["Enabled"] = "開啟"
L["Zone"] = "區域"
L["Status"] = "狀態"
L["Toggle event handling"] = "切換事件處理"
L["Load the currently saved raid mark layout."] = "讀取目前儲存的團隊標記配置"
L["Save the current raid mark layout."] = "儲存目前的團隊標記配置"
L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."] = "重置團隊圖示快取。注意，這會接收例如「保留團隊標記」的選項。"
L["Short FuBar Text"] = "最小化"
L["Hide Magic Marker from the FuBar status text."] = true
L["Reset the raid icon cache. Note that this honors the Magic Marker options such as preserve raid marks."] = "重置團隊圖示快取。注意，這會接收例如「保留團隊標記」的選項。"
L["Enable or disable the event handling, i.e whether or not Magic Marker will insert mobs into the mob database, mark mobs etc."] = true
L["Toggle the Magic Marker configuration dialog."] = "開關 Magic Marker 設定對話框"

L["RAIDMARKCACHEHELP"] = "This functionality lets you save the raid mark layout of the raid and then recall it. Useful to, for example, have raid marks enabled during phase 2 of Illidan but disabled in the other phases."
L["RAIDTMPLHELP"] = "Raid templates allow you to quickly mark certain classer or roles in the raid."

L["External"] = true
L["Template"] = true
L["Difficulty"] = true
L["Unit Name"] = true
L["Mark Type"] = true
L["Score"] = true
L["Report the raid icon assignments to raid/party chat"] = true
L["Report raid assignments"] = true
L["Profile name"] = true
L["Active profile: %s"] = true

L["TOOLTIP_HINT"] =
   "\n|cffeda55fClick|r 開關設定視窗。\n"..
   "|cffeda55fShift-Click|r 切換事件處理。\n"..
   "|cffeda55fAlt-Click|r 重設團隊圖示快取記憶。\n"..
   "|cffeda55fAlt-Shift-Click|r 強行重設團隊圖示快取記憶。\n"..
   "|cffeda55fMiddle-Click|r to print raid assignments to group chat."

-- creature description
L["Creature type"] = true
L["family"] = true
L["classification"] = true
L["unit is a caster"] = true

-- Yes! No!
L["Yes"] = "是"
L["No"] = "否"

