require "table"
require "string"
require "math"
require "lib/lib_MapMarker"
require "lib/lib_InterfaceOptions"
require "lib/lib_Callback2"
require "lib/lib_Slash"

--[[
Medic! Addon for Firefall by weableandbob - with additions by Legendinium

Version History:

Version 1:
Initial Release

Version 1.2:
*Fixed some really terrible grammar
*Moved enable button
*Added option for health on text notification
*Included a suggested addition to prevent freezing if the player is not fully loaded yet
*Added option for displaying the name of the person in need on the marker

Version 1.3:
*Fixed the bug where markers were getting stuck (I believe)

Version 1.4:
*Added icons to the markers
*Added Marker/trail/icon colors
*Added Marker "ping" count and interval
*Added Audio alert on initial marker ping
*Added Activation and marker destroy threshold based on caller's health
*Added friends only mode
*Added option for live status (HP% or time-till-respawn) on marker
*Marker auto-destroys on next ping when no longer needed

Version 1.5:
*Added safeguard on self spawn that destroys any lingering Medic! markers
*Added slash command '/medic clear' to manually clear all Medic! markers
*Fixed a bug where Accord Bios would not pass the "canHeal()" test
*Added tooltips to all the options under 'Esc->Options->Addons->Medic!' and changed healthy threshold to % for clarity

Known Issues:
* With the latest milestone patch, the FireFall core has adopted some basic features from the Medic! addon. It will now create markers of its own on player distress, though without pings, health/respawn info or indeed any user configurability.
(Health marker created only if distressed player has less than 50% HP, lasts 6 seconds, 1 initial ping only. Revive marker lasts 30 seconds, 1 initial ping only)
Medic! plays nice with this new core feature so long as the "Add Name To Marker" option is enabled. The next release of Medic! will integrate, extend or disable this part of the FireFall's functionality.

ToDo:
+Integrate with FireFall Core SOS functionality.
*Implement ping extensions
*Consider Color-by-severity-of-distress mode
*Implement "responsive mode" (faster update on life/time callbacks)
*Implement marker texture/color change on revive

--]]

-- Audio ping alternatives thanks to DW!
local AUDIO_CLIPS = {
	[1] = "Play_UI_Ability_Selection",
	[2] = "Play_SFX_UI_SIN_CooldownFail",
	[3] = "Play_ui_abilities_cooldown_complete",
	[4] = "Play_PAX_FirefallSplash_Victory",
	[5] = "Play_PAX_FirefallSplash_Defeat",
	[6] = "Play_Vox_Emote_Groan",
	[7] = "Play_PAX_FirefallSplash_Unlock",
	[8] = "Play_UI_Ticker_1stStageIntro",
	[9] = "Play_UI_Ticker_2ndStageIntro",
	[10] = "Play_UI_Ticker_LoudSecondTick",
	[11] = "Play_UI_Ticker_ZeroTick",
	[12] = "Play_UI_SlideNotification",
	[13] = "Play_UI_Login_Back",
	[14] = "Play_Click021",
	[15] = "Play_UI_Login_Confirm",
	[16] = "Play_UI_Login_Keystroke",
	[17] = "Play_Vox_VoiceSetSelect",
	[18] = "Play_UI_CharacterCreate_Confirm",
	[19] = "Play_UI_Login_Click",
	[20] = "Play_UI_Intermission",
	[21] = "Play_SFX_UI_Ding",
	[22] = "Play_SFX_UI_AchievementEarned",
	[23] = "Play_PvP_Confirmation",
	[24] = "Play_UI_SINView_Mode",
	[25] = "Stop_UI_SINView_Mode",
	[26] = "Stop_SFX_UI_E_Initiate_Loop_Fail",
	[27] = "Play_UI_SIN_ExtraInfo_On",
	[28] = "Play_SFX_UI_Loot_Flyover",
	[29] = "Play_SFX_UI_Loot_Abilities",
	[30] = "Play_SFX_UI_Loot_Crystite",
	[31] = "Play_SFX_UI_Loot_Basic",
	[32] = "Play_SFX_UI_Loot_Backpack_Pickup",
	[33] = "Play_SFX_UI_Loot_Battleframe_Pickup",
	[34] = "Play_SFX_UI_Loot_PowerUp",
	[35] = "Play_SFX_UI_Loot_Weapon_Pickup",
	[36] = "Play_UI_NavWheel_Open",
	[37] = "Play_UI_NavWheel_Close",
	[38] = "Play_UI_NavWheel_MouseLeftButton",
	[39] = "Play_UI_NavWheel_MouseLeftButton_Initiate",
	[40] = "Play_UI_NavWheel_MouseRightButton",
	[41] = "Play_UI_HUDNotes_Unpin",
	[42] = "Play_UI_HUDNotes_Pin",
	[43] = "Play_UI_SIN_Acquired",
	[44] = "Play_SFX_UI_TipPopUp",
	[45] = "Play_Vox_UI_Frame25",
	[46] = "Play_Vox_UI_Frame50",
	[47] = "Play_SFX_UI_GeneralAnnouncement",
	[48] = "Play_SFX_UI_End",
	[49] = "Play_SFX_UI_Ticker",
	[50] = "Play_SFX_UI_FriendOnline",
	[51] = "Play_SFX_UI_FriendOffline",
	[52] = "Play_UI_Beep_35",
	[53] = "Stop_SFX_NewYou_IntoAndLoop",
	[54] = "Play_SFX_UI_WhisperTickle",
	[55] = "Play_SFX_UI_AbilitySelect03_v4",
	[56] = "Play_SFX_WebUI_Equip_Weapon",
	[57] = "Play_SFX_NewYou_BodySelectionHulaPopUp",
	[58] = "Play_SFX_NewYou_IntoAndLoop",
	[59] = "Play_SFX_NewYou_GearRackScroll",
	[60] = "Play_SFX_WebUI_Equip_Battleframe",
	[61] = "Play_SFX_WebUI_Equip_BackpackModule",
	[62] = "Play_SFX_WebUI_Equip_BattleframeModule",
	[63] = "Play_UI_MapMarker_GetFocus",
	[64] = "Play_UI_Map_ZoomIn",
	[65] = "Play_UI_MapOpen",
	[66] = "Play_UI_Map_DetailClose",
	[67] = "Play_UI_MapClose",
	[68] = "Play_UI_Map_DetailOpen",
	[69] = "Play_SFX_NewYou_GenericConfirm",
	[70] = "Play_SFX_NewYou_ItemMenuPopup",
};


--VARIABLES

local g_MEnabled = true
local g_MMaxDistance = 100
local g_MFriendsOnly = false
local g_MHealthyThreshold = 0.92
local g_MTextNotification = true
local g_MTextHealth = true

local g_MHealEnabled = true
local g_MOnlyHealOnBio = true
local g_MReviveEnabled = true
local g_MOnlyReviveOnBio = false

local g_MNameOnMarker = true
local g_MStatusOnMarker = true
local g_MPings = 6
local g_MPingInterval = 1.6
local g_MHealColor = "83DC36"
local g_MReviveColor = "3494A1"

local g_MPlaySound = true
local g_MHealSound = "Play_SFX_UI_Loot_Abilities"
local g_MReviveSound = "Play_SFX_UI_AchievementEarned"

local g_MFriends = {}

local g_MMarkers = {}
local g_MMarkerIdPrefix = "Medic_"


--INTERFACE OPTIONS

InterfaceOptions.StartGroup({
	id="ENABLED", 
	label="Medic!", 
	checkbox=true, 
	default=g_MEnabled
})
	InterfaceOptions.AddSlider({
		id="MaxDistance", 
		label="Max Distance", 
		tooltip="Adjusts the maximum distance someone can be from you and still provide a notification",
		default=g_MMaxDistance, 
		min=10, 
		max=170, 
		inc=5, 
		suffix="m"
	})
	InterfaceOptions.AddCheckBox({
		id="friendsOnly", 
		label="Enable Alert From Friends Only", 
		tooltip="When enabled, ensures that only people in your friends list or squad will trigger the addon", 
		default=g_MFriendsOnly
	})
	InterfaceOptions.AddSlider({
		id="healthyThreshold", 
		label="Healthy Threshold %",
		tooltip="The threshold between 0 and 99% HP above which a player is considered healthy, and the addon is not triggered. Used to lower the amount of 'false positives' from players near full HP (mis)triggering a distress call", 
		default=(g_MHealthyThreshold*100), 
		min=1, 
		max=99, 
		inc=1
	})
	InterfaceOptions.AddCheckBox({
		id="TextNotificationEnabled", 
		label="Enable Text Notification", 
		tooltip="When enabled, displays the person in need and what they need in chat.", 
		default=g_MTextNotification
	})
	InterfaceOptions.AddCheckBox({
		id="TextNotificationHealth", 
		label="Display Health In Text Notifications", 
		tooltip="When enabled, distressed player's health is displayed in the text notification", 
		default=g_MTextHealth
	})
InterfaceOptions.StopGroup()
InterfaceOptions.StartGroup({
	id="healEnabled", 
	label="Enable Heal Marker", 
	tooltip="Determines whether a marker is displayed when someone calls for healing.", 
	checkbox=g_MHealEnabled, 
	default=true
})
	InterfaceOptions.AddCheckBox({
		id="BioOnlyHeal", 
		label="Notify For Heal Only When Possible", 
		tooltip="When checked, makes it so that you only get heal notifications when you have something capable of healing with.", 
		default=g_MOnlyHealOnBio
	})
InterfaceOptions.StopGroup()
InterfaceOptions.StartGroup({
	id="reviveEnabled", 
	label="Enable Revive Marker", 
	tooltip="Determines whether a marker is displayed when someone calls for a revive.", 
	checkbox=true, 
	default=g_MReviveEnabled
})
	InterfaceOptions.AddCheckBox({
		id="BioOnlyRevive", 
		label="Notify For Revive Only On Biotech", 
		tooltip="When checked, makes it so that you only get revive notifications when you're playing Biotech", 
		default=g_MOnlyReviveOnBio
		})
InterfaceOptions.StopGroup()

InterfaceOptions.StartGroup({
	label="Marker customizations", 
	subtab={"Marker"}
})
	InterfaceOptions.AddCheckBox({
		id="AddNameToMarker", 
		label="Add Name To Marker", 
		tooltip="When checked, makes the person in need's name appear on the marker", 
		default=g_MNameOnMarker, 
		subtab={"Marker"}
	})
	InterfaceOptions.AddCheckBox({
		id="AddStatusToMarker", 
		label="Add Status To Marker", 
		tooltip="When checked, makes the person in need's HP or time-to-respawn appear on the marker", 
		default=g_MStatusOnMarker, 
		subtab={"Marker"}
	})
	InterfaceOptions.AddSlider({
		id="PINGS", 
		label="Max Pings", 
		tooltip="How many pings will fire before the marker expires. MaxPings*PingInterval == marker duration in seconds",
		default=g_MPings,
		min=1, 
		max=30, 
		inc=1, 
		subtab={"Marker"}
	})
	InterfaceOptions.AddSlider({
		id="PING_INTERVAL", 
		label="Interval Between Pings", 
		default=g_MPingInterval, 
		min=0.4, 
		max=10, 
		inc=0.2, 
		suffix="s", 
		subtab={"Marker"}
	})
	InterfaceOptions.AddColorPicker({
		id="healColor", 
		label="Marker Color For Healing", 
		tooltip="Color to use for heal markers (trail and icon)",
		default={tint=g_MHealColor}, 
		subtab={"Marker"}
	})
	InterfaceOptions.AddColorPicker({
		id="reviveColor", 
		label="Marker Color For Revive", 
		tooltip="Color to use for revive markers (trail and icon)",
		default={tint=g_MReviveColor}, 
		subtab={"Marker"}
	})
InterfaceOptions.StopGroup({subtab="Marker"})

InterfaceOptions.StartGroup({
	id="playSound", 
	label="Enable Audio", 
	tooltip="Makes a sound play on each marker ping",
	checkbox=true,
	default=g_MPlaySound, 
	subtab={"Sound"}
})
	InterfaceOptions.AddChoiceMenu({
		id="healSound", 
		label="Heal Audio Clip",
		tooltip="Sound clip to use for heal marker pings",
		default=g_MHealSound, 
		subtab={"Sound"}
	});
	InterfaceOptions.AddChoiceMenu({
		id="reviveSound", 
		label="Revive Audio Clip", 
		tooltip="Sound clip to use for revive marker pings",
		default=g_MReviveSound, 
		subtab={"Sound"}
	});
InterfaceOptions.StopGroup({subtab="Sound"})

InterfaceOptions.NotifyOnLoaded(true)

function OnOptionCallback(args)
	local id = args.type
	local val = args.data
	if (string.upper(id) == "__LOADED") then
		g_MFirstRun = nil
	elseif id == "ENABLED" then
		g_MEnabled = val
	elseif id == "MaxDistance" then
		g_MMaxDistance = val
	elseif id == "friendsOnly" then
		g_MFriendsOnly = val
	elseif id == "healthyThreshold" then
		g_MHealthyThreshold = (val/100)
	elseif id == "TextNotificationEnabled" then
		g_MTextNotification = val
	elseif id == "TextNotificationHealth" then
		g_MTextHealth = val
	elseif id == "healEnabled" then
		g_MHealEnabled = val
	elseif id == "BioOnlyHeal" then
		g_MOnlyHealOnBio = val
	elseif id == "reviveEnabled" then
		g_MReviveEnabled = val
	elseif id == "BioOnlyRevive" then
		g_MOnlyReviveOnBio = val

	elseif id == "AddNameToMarker" then
		g_MNameOnMarker = val
	elseif id == "AddStatusToMarker" then
		g_MStatusOnMarker = val
	elseif id == "PINGS" then
		g_MPings = val
	elseif id == "PING_INTERVAL" then
		g_MPingInterval = val
	elseif id == "healColor" then
		g_MHealColor = val.tint
	elseif id == "reviveColor" then
		g_MReviveColor = val.tint

	elseif id == "playSound" then
		g_MPlaySound = val
	elseif id == "healSound" then
		g_MHealSound = val
		if not g_MFirstRun then System.PlaySound(g_MHealSound) end
	elseif id == "reviveSound" then
		g_MReviveSound = val
		if not g_MFirstRun then System.PlaySound(g_MReviveSound) end
	end
end


--SETUP

function OnComponentLoad()
	g_MFirstRun = true

	InterfaceOptions.SetCallbackFunc(function(id,val)
		OnOptionCallback({type = id, data = val})
	end, "Medic!");

	--Build list of audio clips
	for i,v in ipairs(AUDIO_CLIPS) do
		InterfaceOptions.AddChoiceEntry({menuId="healSound", val=v, label=v});
		InterfaceOptions.AddChoiceEntry({menuId="reviveSound", val=v, label=v});
	end

	--Build friends list
	local friends = Friends.GetList()
	for i, friend in pairs(friends) do
		local cleanName = cleanPlayerName(friend.player_name)
		g_MFriends[cleanName] = true
	end

	--Set Up slash command
	local chat_commands = {
		["help"] = function(args) Component.GenerateEvent('MY_SYSTEM_MESSAGE', {text="Medic! commands. Try '/medic clear' to clear markers."}) end,
		["clear"] = function(args) clearMarkers() end,
	}
	LIB_SLASH.BindCallback({
		slash_list="medic",
		description="Medic! commands.",
		func=function(args)
			local command = args.text ~= "" and args.text or "help"
			chat_commands[command](args)
		end
		})
end


--MAIN ROUTINE

function OnFriendlyDistress(args)
	--args.need = "health" or something else
	--args.entityId = number
	--args.distance	= meters to target
	if not (g_MEnabled and Player.IsReady()) then
		return false
	end

	if isHealthy(args) then
		return false
	end

	if args.distance >= g_MMaxDistance then
		return false
	end

	if g_MFriendsOnly and not isFriend(args) then
		return false
	end

	local distressMarker = nil

	--MODE HEAL
	if args.need == "health" and g_MHealEnabled then 
		if g_MOnlyHealOnBio == true and not canHeal() then
			return false
		end

		distressMarker = createDistressMarker(args)
		if distressMarker == false then
			return false -- halt execution if the caller already has a marker attached
		end

		if g_MPlaySound then
			System.PlaySound(g_MHealSound)
		end

		if g_MTextNotification then
			Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text=tostring(getName(args)).." needs healing!"})
			if g_MTextHealth then
				Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text=Game.GetTargetVitals(args.entityId).Health.." health"})
			end
		end
	--MODE REVIVE	
	elseif args.need == "revive" and g_MReviveEnabled then
		if g_MOnlyReviveOnBio == true and not isBio() then
			return false
		end
		distressMarker = createDistressMarker(args)
		if distressMarker == false then
			return false -- halt execution if the caller already has a marker
		end

		if g_MPlaySound then
			System.PlaySound(g_MReviveSound)
		end 

		if textNotification then
			Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text=tostring(getName(args)).." needs a revive!"})
		end

	else
		return false
	end

	setMarkerPings(args, distressMarker)

end

function OnSpawn()
	clearMarkers()
end


--HELPERS

function clearMarkers()
	if next(g_MMarkers) ~= nil then
		for id,marker in pairs(g_MMarkers) do
			g_MMarkers[id] = nil
			marker:Destroy()
		end 
	end
end

function getName(caller)
	return Game.GetTargetInfo(caller.entityId).name
end

function isHealthy(caller)
	return Game.GetTargetVitals(caller.entityId).health_pct > g_MHealthyThreshold
end

function createDistressMarker(caller)
	local markerId = g_MMarkerIdPrefix..tostring(caller.entityId)
	if g_MMarkers[markerId] then --Avoid duplicate markers
		--extendMarkerPing(markerId)
		return false
	end
	local marker = MapMarker.Create(markerId)
	g_MMarkers[markerId] = marker
	
	local markerColor = g_MReviveColor
	if caller.need == "health" then
		markerColor = g_MHealColor
	end

	marker:SetDistanceLatch(5, g_MMaxDistance)
	marker:BindToEntity(caller.entityId, 100)
--[[
	marker:AddHandler("OnDistanceTrip", function() -- OnDistanceTrip (or rather, the function that dispatches it) seems to itself be triggered by opening the map...
		log("--> OnDistanceTrip")
		g_MMarkers[markerId] = false
		marker:Destroy()
	end)
--]]
	if g_MStatusOnMarker then
		local markerTitleUpdater;
		markerTitleUpdater = Callback2.CreateCycle(function()
			if not g_MMarkers[markerId] then
				callback(function() markerTitleUpdater:Release() end, nil, 0.01) --A bit hack-ish, but CB2 has a tail-wrapper to the callbacks it's executing that needs the reference we are destroying with :Release() - see lib_Callback2.lua, line 270-3
				return false
			end
			local titleStr = ""
			if g_MNameOnMarker then
				titleStr = titleStr..getName(caller).." "
			end
			if g_MStatusOnMarker then
				local health = Game.GetTargetVitals(caller.entityId).health_pct * 100
				if health == 0.0 then --caller is downed, display time 'till respawn
					local respawn = Game.GetTargetRespawnTime(caller.entityId)
					titleStr = titleStr..string.format("%.1f", respawn.RemainingSeconds).."s"
				else
					titleStr = titleStr..math.floor(health).."%"	
				end
			end
			marker:SetTitle(titleStr)
		end)
		markerTitleUpdater:Run(0.5) --TODO: make user configurable (responsive mode on/off)
	elseif g_MNameOnMarker then
		marker:SetTitle(getName(caller))
	end

	marker:ShowOnHud(true)
	marker:ShowTrail(true)
	marker:SetThemeColor(markerColor)

	if caller.need == "health" then
		marker:GetIcon():SetTexture("battleframes", "medic")
	else
		marker:GetIcon():SetTexture("MapMarkers", "skull")
	end

	marker:GetIcon():SetParam("tint", markerColor)
	marker:GetIcon():SetParam("shadow", 0.25)

	return marker
end

function setMarkerPings(caller, marker)
	local pingCount = 1;
	local PING;
	PING = Callback2.CreateCycle(
		function()
			if next(marker) == nil then
				callback(function() PING:Release() end, nil, 0.01) --TODO: Refactor
				return
			end
			if not Game.IsTargetAvailable(caller.entityId) or isHealthy(caller) or pingCount == g_MPings then --First conditional: The caller is no longer in range - the marker has probably lost track
					g_MMarkers[marker:GetId()] = nil
					marker:Destroy()
					callback(function() PING:Release() end, nil, 0.01) 
			else
				marker:BindToEntity(marker:GetBoundEntity(), 100) --Rebind to entity as workaround for markers "falling off" bug
				marker:Ping()
				pingCount = pingCount + 1
			end
		end
	)
	PING:Run(g_MPingInterval)
end

-- Determines if the caller is a friend (or squadmate)
function isFriend(caller)
	local roster = Squad.GetRoster();
	if (roster) then 
		for i, squadmate in pairs(roster.members) do 
			if caller.entityId == squadmate.entityId then
				return true
			end
		end
	end
	local cleanCallerName = cleanPlayerName(Game.GetTargetInfo(caller.entityId).name)
	if g_MFriends[cleanCallerName] then
		return true
	end
	--The poor bastard's gonna have to fend for himself:
	return false
end

-- Cleans out army tags from eg Friends.GetList()[n].player_name
function cleanPlayerName(dirtyName)
        sep = "%s"
        cleanName = nil
        --if army tag is present, it will be overwritten by the clean player name on the second (last) iteration
        for str in string.gmatch(dirtyName, "([^"..sep.."]+)") do
                cleanName = str 
        end
        return cleanName
end

function isBio()
	if tostring(Player.GetCurrentArchtype()) == "medic" then
		return true
	else
		return false
	end
end

function canHeal()
	local weapon = Player.GetWeaponInfo()
	if weapon and weapon.WeaponType == "BioRifle" then
		return true
	end

	local healingAbilities = { --TODO: add healing generator
		["35040"] = "Healing Pillar",
		["34832"] = "Healing Ball",
		["31366"] = "Healing Wave",
		["34928"] = "Healing Dome",
		["35565"] = "Accord Chemical Sprayer",
	}

	for i,ability in pairs(Player.GetAbilities().slotted) do
		if healingAbilities[tostring(ability.abilityId)] then
			return true
		end
	end

	log("canHeal() returns false")
	return false
end
