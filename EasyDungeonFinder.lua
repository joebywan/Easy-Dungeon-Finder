local levels = {
	[2] = "Two",
	[3] = "Three",
	[4] = "Four",
	[5] = "Five",
	[6] = "Six",
	[7] = "Seven",
	[8] = "Eight",
	[9] = "Nine",
	[10] = "Ten",
	[11] = "Eleven",
	[12] = "Twelve",
	[13] = "Thirteen",
	[14] = "Fouteen",
	[15] = "Fifteen"}
local keywords = {
	"carry",
	"carries",
	"depleted",
	"link key",
	"your key"}
local dungeons = {
	["VAULT_OF_THE_WARDENS"]   = "Vault of the Wardens",
	["EYE_OF_AZSHARA"]         = "Eye of Azshara",
	["THE_ARCWAY"]             = "The Arcway",
	["MAW_OF_SOULS"]           = "Maw of Souls",
	["HALLS_OF_VALOR"]         = "Halls of Valor",
	["DARKHEAR_THICKET"]       = "Darkheart Thicket",
	["BLACK_ROOK_HOLD"]        = "Black Rook Hold",
	["NELTHARIONS_LAIR"]       = "Neltharion's Lair",
	["ASSAULT_ON_VIOLOT_HOLD"] = "Assault on Violet Hold",
	["COURT_OF_STARS"]         = "Court of Stars",
	["RETURN_TO_KARAZHAN"]      = "Return to Karazhan"}
local timer = 0
local interval = 30
local lookingForGroup = false
local groupsAppliedTo = {}
local enableItemLevel
local requiredItemLevel
local requiredRole
local enableMythicPlus
local minimumMythicLevel
local maximumMythicLevel
local enabledDungeons = {}
local tank = false
local healer = false
local damage = false
local groupTank = false
local groupHealer = false
local groupDamage = 0

SLASH_EASYDUNGEONFINDER1 = '/edf'
function SlashCmdList.EASYDUNGEONFINDER(msg, editbox)
	local EasyDungeonFinderFrame = _G["EasyDungeonFinderFrame"]
	EasyDungeonFinderFrame:Show()
end

function FindDungeonGroups()
	print("Finding more groups")

	local searchCount, searchResults = C_LFGList.GetSearchResults()

	for k, v in pairs(searchResults) do
		local id, activityID, name, comment, voiceChat, iLvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, numMembers = C_LFGList.GetSearchResultInfo(v)
		local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activityID)
		local apply = true

		-- Mythic +
		if ( enableMythicPlus ) then
			apply = false
			for i = minimumMythicLevel, maximumMythicLevel do
				if ( string.match(name:lower(), "+"..i) ) then
					apply = true
				end
			end
		end

		-- Dungeon filter
		if ( not enabledDungeons[activityName] ) then
			apply = false
		end

		-- Item level filter
		if ( enableItemLevel and requiredItemLevel > iLvl ) then
			apply = false
		end

		-- Keyword filter
		for i, term in ipairs(keywords) do
			if ( string.match(name:lower(), term) ) then
				apply = false
			end
		end

		-- Available roles
		local tankSpotAvailable = true
		local healerSpotAvailable = true
		local damageSpotsAvailable = 3
		for i = 1, numMembers do
			local memberRole = C_LFGList.GetSearchResultMemberInfo(id, i)
			if ( memberRole == "DAMAGER" ) then
				damageSpotsAvailable = damageSpotsAvailable - 1
			elseif ( memberRole == "HEALER" ) then
				healerSpotAvailable = false
			elseif ( memberRole == "TANK") then
				tankSpotAvailable = false
			end
		end

		-- Required roles
		if ( requiredRole == "BOTH" and not ( healerSpotAvailable and tankSpotAvailable ) ) then
			apply = false
		elseif ( requiredRole == "EITHER" and not ( healerSpotAvailable or tankSpotAvailable ) ) then
			apply = false
		elseif ( requiredRole == "HEALER" and healerSpotAvailable ) then
			apply = false
		elseif ( requiredRole == "TANK" and tankSpotAvailable ) then
			apply = false
		end

		if ( groupHealer and not healerSpotAvailable) then
			apply = false
		end

		if ( groupTank and not tankSpotAvailable ) then
			apply = false
		end

		if ( groupDamage > damageSpotsAvailable ) then
			apply = false
		end

		-- already applied
		if ( groupsAppliedTo[v] ) then
			apply = false
		end

		if ( UnitInParty('player') and pendingRoleCheck ) then
			apply = false
		end

		if ( C_LFGList.GetNumApplications() >= 5 ) then
			apply = false
		end

		if ( apply ) then
			local msg = string.format("Applied to %s, %s", activityName, name)

			if ( UnitInParty('player') ) then
				SendChatMessage(msg,"PARTY")
				pendingRoleCheck = true
			else
				print(msg)
			end

			groupsAppliedTo[v] = true
			C_LFGList.ApplyToGroup(v, "", tank, healer, damage)
		end

	end
end

function OnEvent(self, event, ...)
	local unit = ...
	EDF = _G[EasyDungeonFinderFrame]
	if ( event == "PLAYER_ENTERING_WORLD" ) then

	elseif ( event == "GROUP_ROSTER_CHANGED" or event == "GROUP_JOINED") then
		print("Stopped looking for a dungeon.")
		lookingForGroup = false
		enabledDungeons = {}
		EDF.StartButton:SetEnabled(true)
		EDF.StopButton:SetEnabled(false)
	elseif ( event == "LFG_ROLE_CHECK_DECLINED" ) then
		pendingRoleCheck = false
	elseif ( event == "LFG_ROLE_CHECK_ROLE_CHOSEN" ) then
		print("LFG_ROLE_CHECK_ROLE_CHOSEN"..unit)
		pendingRoleCheck = false
	end
end

function OnUpdate(self, elapsed)
	timer = timer + elapsed
	if ( timer > interval and lookingForGroup) then
		FindDungeonGroups()
		timer = 0
	end
end

function StartButton_OnClick(self)
	local EDF = _G["EasyDungeonFinderFrame"]

	enableItemLevel = EDF.EnableItemLevel:GetChecked()
	requiredItemLevel = EDF.ItemLevel:GetNumber()
	requiredRole = EDF.Role:GetValue()
	enableMythicPlus = EDF.EnableMythicPlus:GetChecked()
	minimumMythicLevel = EDF.MinimumMythicLevel:GetValue()
	maximumMythicLevel = EDF.MaximumMythicLevel:GetValue()
	local spec = GetSpecialization()
	local myRole = GetSpecializationRole(spec)

	enabledDungeons = {}
	for k, v in pairs(dungeons) do
		if ( EDF[k]:GetChecked() ) then
			local activityName
			if ( enableMythicPlus ) then
				activityName = string.format("%s (Mythic Keystone)", v)
			else
				activityName = string.format("%s (Mythic)", v)
			end
			enabledDungeons[activityName] = true
		end
	end

	if ( myRole == "HEALER" ) then
		healer = true
		groupHealer = true
	elseif ( myRole == "TANK" ) then
		tank = true
		groupTank = true
	elseif ( myRole == "DAMAGER" ) then
		damage = true
		groupDamage = groupDamage + 1
	end

	if ( UnitInParty("player") ) then
		local partyMemberRole
		for i = 1, GetNumGroupMembers() do
			partyMemberRole = UnitGroupRolesAssigned("party"..i)
			if ( partyMemberRole == "HEALER" ) then
				groupHealer = true
			elseif ( partyMemberRole == "TANK" ) then
				groupTank = true
			elseif ( partyMemberRole == "DAMAGE" ) then
				groupDamage = groupDamage + 1
			end
		end
	end

	EDF.StartButton:SetEnabled(false)
	EDF.StopButton:SetEnabled(true)
	lookingForGroup = true
  FindDungeonGroups()
end

function StopButton_OnClick(self)
	print("Stopped looking for a dungeon.")
	lookingForGroup = false
	local EDF = _G["EasyDungeonFinderFrame"]
	EDF.StartButton:SetEnabled(true)
	EDF.StopButton:SetEnabled(false)
end

function RoleDropDown_OnClick(self)
	EasyDungeonFinderFrameRoleDropDown:SetValue(self.value)
end

function RoleDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo()

	info.text = "None"
	info.func = RoleDropDown_OnClick
	info.value = "NONE"
	info.checked = nil
	UIDropDownMenu_AddButton(info)

	info.text = "Healer"
	info.func = RoleDropDown_OnClick
	info.value = "HEALER"
	info.checked = nil
	UIDropDownMenu_AddButton(info)

	info.text = "Tank"
	info.func = RoleDropDown_OnClick
	info.value = "TANK"
	info.checked = nil
	UIDropDownMenu_AddButton(info)

	info.text = "Both"
	info.func = RoleDropDown_OnClick
	info.value = "BOTH"
	info.checked = nil
	UIDropDownMenu_AddButton(info)

	info.text = "Either"
	info.func = RoleDropDown_OnClick
	info.value = "EITHER"
	info.checked = nil
	UIDropDownMenu_AddButton(info)
end

function MythicPlusMinimumLevelDropDown_OnClick(self)
	EasyDungeonFinderFrameMythicPlusMinimumLevelDropDown:SetValue(self.value)
end

function MythicPlusMinimumLevelDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo()

	for k, v in pairs(levels) do
		info.text = v
		info.func = MythicPlusMinimumLevelDropDown_OnClick
		info.value = k
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

function MythicPlusMaximumLevelDropDown_OnClick(self)
	EasyDungeonFinderFrameMythicPlusMaximumLevelDropDown:SetValue(self.value)
end

function MythicPlusMaximumLevelDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo()

	info.text = "None"
	info.func = MythicPlusMaximumLevelDropDown_OnClick
	info.value = "NONE"
	info.checked = nil
	UIDropDownMenu_AddButton(info)

	for k, v in pairs(levels) do
		info.text = v
		info.func = MythicPlusMaximumLevelDropDown_OnClick
		info.value = k
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

function SavedToDungeon(dungeonName)
	for i = 1 , GetNumSavedInstances() do
		name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
		if ( (locked or extended) and dungeonName == name and difficultyName == "Mythic") then
			return true
		end
	end
	return false
end

local EasyDungeonFinder = CreateFrame("Frame", "EasyDungeonFinderFrame", UIParent, "BasicFrameTemplate")
EasyDungeonFinder:SetSize(400,650)
EasyDungeonFinder:SetPoint("CENTER")
EasyDungeonFinder.TitleText:SetText("Premade Finder")
EasyDungeonFinder:Hide()
EasyDungeonFinder:SetMovable(true)
EasyDungeonFinder:EnableMouse(true)
EasyDungeonFinder:RegisterForDrag("LeftButton")
EasyDungeonFinder:SetScript("OnDragStart", EasyDungeonFinder.StartMoving)
EasyDungeonFinder:SetScript("OnDragStop", EasyDungeonFinder.StopMovingOrSizing)

EasyDungeonFinder:RegisterEvent("PLAYER_ENTERING_WORLD")
EasyDungeonFinder:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
EasyDungeonFinder:RegisterEvent("LFG_ROLE_CHECK_DECLINED")
EasyDungeonFinder:RegisterEvent("LFG_ROLE_CHECK_ROLE_CHOSEN")
EasyDungeonFinder:RegisterEvent("LFG_ROLE_CHECK_UPDATE")
EasyDungeonFinder:RegisterEvent("PARTY_INVITE_REQUEST")
EasyDungeonFinder:RegisterEvent("GROUP_JOINED")
EasyDungeonFinder:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")

EasyDungeonFinder:SetScript("OnEvent", OnEvent)
EasyDungeonFinder:SetScript("OnUpdate", OnUpdate)

local EnableItemLevel = CreateFrame("CheckButton", "$parentEnableItemLevel", EasyDungeonFinder, "InterfaceOptionsCheckButtonTemplate")
EnableItemLevel:ClearAllPoints()
EnableItemLevel:SetPoint("TOPLEFT", 20, -50)
EasyDungeonFinder.EnableItemLevel = EnableItemLevel

local EnableItemLevelText = _G["EasyDungeonFinderFrameEnableItemLevelText"]
EnableItemLevelText:ClearAllPoints()
EnableItemLevelText:SetWidth(100)
EnableItemLevelText:SetPoint("LEFT", EnableItemLevel, "RIGHT")
EnableItemLevelText:SetText("Item Level")

local ItemLevel = CreateFrame("EditBox", "$parentItemLevel", EasyDungeonFinder, "InputBoxTemplate")
ItemLevel:SetPoint("TOPLEFT", EasyDungeonFinder, "TOPLEFT", 200, -50)
ItemLevel:SetSize(100,32)
ItemLevel:SetAutoFocus(false)
ItemLevel:SetEnabled(false)
ItemLevel:SetAlpha(0)
EasyDungeonFinder.ItemLevel = ItemLevel

EnableItemLevel:SetScript("OnClick", function(self)
	if ( self:GetChecked() ) then
		ItemLevel:SetEnabled(true)
		ItemLevel:SetAlpha(1)
	else
		ItemLevel:SetEnabled(false)
		ItemLevel:SetAlpha(0)
	end
end)

local RoleDropDown = CreateFrame("Button", "$parentRoleDropDown", EasyDungeonFinder, "UIDropDownMenuTemplate")
RoleDropDown:SetPoint("TOPLEFT", EasyDungeonFinder, "TOPLEFT", 180, -100)
UIDropDownMenu_SetWidth(RoleDropDown, 90)
UIDropDownMenu_Initialize(RoleDropDown, RoleDropDown_Initialize)
UIDropDownMenu_SetSelectedValue(RoleDropDown, "NONE");

RoleDropDown.SetValue = function(self, value)
	UIDropDownMenu_SetSelectedValue(RoleDropDown, value)
end

RoleDropDown.GetValue = function(self, value)
	return UIDropDownMenu_GetSelectedValue(RoleDropDown)
end

RoleDropDown.RefreshValue = function (RoleDropDown)
	UIDropDownMenu_Initialize(RoleDropDown, RoleDropDown_Initialize)
	UIDropDownMenu_SetSelectedValue(RoleDropDown, RoleDropDown.value)
end

EasyDungeonFinder.Role = RoleDropDown

local RoleDropDownLabel = RoleDropDown:CreateFontString("$parentLabel", "BACKGROUND", "GameFontHighlight")
RoleDropDownLabel:SetPoint("TOPLEFT", EasyDungeonFinder, "TOPLEFT", 20, -108)
RoleDropDownLabel:SetText("Required Roles")

local EnableMythicPlus = CreateFrame("CheckButton", "$parentEnableMythicPlus", EasyDungeonFinder, "InterfaceOptionsCheckButtonTemplate")
EnableMythicPlus:ClearAllPoints()
EnableMythicPlus:SetPoint("TOPLEFT", 20, -150)
EasyDungeonFinder.EnableMythicPlus = EnableMythicPlus

local EnableMythicPlusText = _G["EasyDungeonFinderFrameEnableMythicPlusText"]
EnableMythicPlusText:ClearAllPoints()
EnableMythicPlusText:SetWidth(100)
EnableMythicPlusText:SetPoint("LEFT", EnableMythicPlus, "RIGHT")
EnableMythicPlusText:SetText("Mythic Plus")

local MythicPlusMinimumLevelDropDown = CreateFrame("Button", "$parentMythicPlusMinimumLevelDropDown", EasyDungeonFinder, "UIDropDownMenuTemplate")
MythicPlusMinimumLevelDropDown:SetPoint("TOPLEFT", EasyDungeonFinder, "TOPLEFT", 180, -150)
MythicPlusMinimumLevelDropDown:SetAlpha(0)
UIDropDownMenu_SetWidth(MythicPlusMinimumLevelDropDown, 90)
UIDropDownMenu_Initialize(MythicPlusMinimumLevelDropDown, MythicPlusMinimumLevelDropDown_Initialize)
UIDropDownMenu_SetSelectedValue(MythicPlusMinimumLevelDropDown, 2)
EasyDungeonFinder.MinimumMythicLevel = MythicPlusMinimumLevelDropDown

MythicPlusMinimumLevelDropDown.SetValue = function(self, value)
	UIDropDownMenu_SetSelectedValue(MythicPlusMinimumLevelDropDown, value)
end

MythicPlusMinimumLevelDropDown.GetValue = function(self, value)
	return UIDropDownMenu_GetSelectedValue(MythicPlusMinimumLevelDropDown)
end

MythicPlusMinimumLevelDropDown.RefreshValue = function (MythicPlusMinimumLevelDropDown)
	UIDropDownMenu_Initialize(MythicPlusMinimumLevelDropDown, MythicPlusMinimumLevelDropDown_Initialize)
	UIDropDownMenu_SetSelectedValue(MythicPlusMinimumLevelDropDown, MythicPlusMinimumLevelDropDown.value)
end

local MythicPlusMaximumLevelDropDown = CreateFrame("Button", "$parentMythicPlusMaximumLevelDropDown", EasyDungeonFinder, "UIDropDownMenuTemplate")
MythicPlusMaximumLevelDropDown:SetPoint("TOPLEFT", EasyDungeonFinder, "TOPLEFT", 180, -200)
MythicPlusMaximumLevelDropDown:SetAlpha(0)
UIDropDownMenu_SetWidth(MythicPlusMaximumLevelDropDown, 90)
UIDropDownMenu_Initialize(MythicPlusMaximumLevelDropDown, MythicPlusMaximumLevelDropDown_Initialize)
UIDropDownMenu_SetSelectedValue(MythicPlusMaximumLevelDropDown, 2)
EasyDungeonFinder.MaximumMythicLevel = MythicPlusMaximumLevelDropDown

MythicPlusMaximumLevelDropDown.SetValue = function(self, value)
	UIDropDownMenu_SetSelectedValue(MythicPlusMaximumLevelDropDown, value)
end

MythicPlusMaximumLevelDropDown.GetValue = function(self, value)
	return UIDropDownMenu_GetSelectedValue(MythicPlusMaximumLevelDropDown)
end

MythicPlusMaximumLevelDropDown.RefreshValue = function (MythicPlusMaximumLevelDropDown)
	UIDropDownMenu_Initialize(MythicPlusMaximumLevelDropDown, RoleDropDown_Initialize)
	UIDropDownMenu_SetSelectedValue(MythicPlusMaximumLevelDropDown, MythicPlusMaximumLevelDropDown.value)
end

EnableMythicPlus:SetScript("OnClick", function(self)
	if ( self:GetChecked() ) then
		MythicPlusMinimumLevelDropDown:SetAlpha(1)
		MythicPlusMaximumLevelDropDown:SetAlpha(1)
	else
		MythicPlusMinimumLevelDropDown:SetAlpha(0)
		MythicPlusMaximumLevelDropDown:SetAlpha(0)
	end
end)

local DungeonFrame = CreateFrame("Frame", "$parentDungeonFrame", EasyDungeonFinder)
DungeonFrame:SetSize(200, 250)
DungeonFrame:SetPoint("TOPLEFT", EasyDungeonFinder, "TOPLEFT", 16, -260)

local DungeonFrameLabel = DungeonFrame:CreateFontString("$parentLabel", "BACKGROUND", "GameFontHighlight")
DungeonFrameLabel:SetPoint("BOTTOMLEFT", DungeonFrame, "TOPLEFT", 0, 8)
DungeonFrameLabel:SetText("Dungeons")

local offset = 0
for k, v in pairs(dungeons) do
	local frame = CreateFrame("CheckButton", "$parent"..k, DungeonFrame, "InterfaceOptionsCheckButtonTemplate")
	local label = _G["EasyDungeonFinderFrameDungeonFrame"..k.."Text"]
	label:SetText(v)
	if ( SavedToDungeon(v) ) then
		label:SetTextColor(1,0,0,1)
	end
	if i == 1 then
		frame:SetPoint("TOPLEFT")
	else
		frame:SetPoint("TOPLEFT", 0 , -offset)
	end
	EasyDungeonFinder[k] = frame
	offset = offset + 30
end

local StartButton = CreateFrame("Button", "$parentStartButton", EasyDungeonFinder, "UIPanelButtonTemplate")
StartButton:SetSize(140,32)
StartButton:SetText("Start")
StartButton:SetPoint("BOTTOMLEFT", 16, 16)
StartButton:SetScript("OnClick", StartButton_OnClick)
EasyDungeonFinder.StartButton = StartButton

local StopButton = CreateFrame("Button", "$parentStopButton", EasyDungeonFinder, "UIPanelButtonTemplate")
StopButton:SetSize(140,32)
StopButton:SetText("Stop")
StopButton:SetPoint("BOTTOMRIGHT", -16, 16)
StopButton:SetScript("OnClick", StopButton_OnClick)
StopButton:SetEnabled(false)
EasyDungeonFinder.StopButton = StopButton
