local UpdateInterval = 30.0;
local LookingForDungeon = false;
SearchTerm = "Mythic";
local savedDungeons = {}
canBeTank, canBeHealer, canBeDamage = false, false, false;
local filterTerms = {"+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9", "+10", "+11", "+12", "+13", "+14", "+15", "carry", "link"};

local function onUpdate(self, elapsed)
	if LookingForDungeon == false then
		return
	end
	if ( not self.TimeSinceLastUpdate ) then
		self.TimeSinceLastUpdate = 0
	end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
  if ( self.TimeSinceLastUpdate > UpdateInterval and LookingForDungeon ) then
		print("Starting new search...")
		LookForDungeon(SearchTerm);
    self.TimeSinceLastUpdate = 0;
  end
end

local f = CreateFrame("frame")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
local function OnEvent(self, event, ...)
	if ( UnitInParty("player") ) then
		print("Group found. Stopped looking for a dungeon.")
		LookingForDungeon = false;
	end
end
f:SetScript("OnEvent", OnEvent);
f:SetScript("OnUpdate", onUpdate);

function LookForDungeon(SearchTerm)

	C_LFGList.ClearSearchResults()
	C_LFGList.Search(2, SearchTerm, 0, 4, C_LFGList.GetLanguageSearchFilter())
	C_Timer.After(3, function()
		local searchCount, searchResults = C_LFGList.GetSearchResults()
		if ( searchCount == 0 ) then
			print("No results found.")
			return
		end
		for k, v in pairs(searchResults) do
			local id, activityID, name, comment, voiceChat, iLvl,_,_,_,_,_,_, leaderName, numMembers = C_LFGList.GetSearchResultInfo(v);

			local hasTank = false;
			local hasHealer = false;
			local totalDamager = 0

			local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(activityID)

			for i = 1, numMembers, 1 do
				memberInfo = C_LFGList.GetSearchResultMemberInfo(v, i)
				if memberInfo == "DAMAGER" then
					totalDamager = totalDamager + 1
				elseif ( memberInfo == "HEALER") then
					hasHealer = true
				elseif ( memberInfo == "TANK") then
					hasTank = true
				end
			end

			local saved = false;
			for _, savedName in pairs(savedDungeons) do
				if ( fullName == savedName ) then
					saved = true;
				end
			end

			if ( SearchTerm ~= "Mythic" ) then
				saved = false;
			end

			local shouldApply = false;
			if ( canBeHealer and not hasHealer and hasTank ) then
				shouldApply = true;
			elseif (canBeTank and not hasTank and hasHealer) then
				shouldApply = true;
			elseif (canBeDamage and totalDamager < 3  and hasTank and hasHealer ) then
				shouldApply = true;
			end

			if ( SearchTerm == "Mythic" ) then
				for i, term in ipairs(filterTerms) do
					if ( string.match(name, term) ) then
						shouldApply = false;
					end
				end
			end

			if ( shouldApply and not saved and C_LFGList.GetNumApplications() < 5 ) then
				print("Applied to " .. name .. ", " .. fullName)
				C_LFGList.ApplyToGroup(v, "", canBeTank, canBeHealer, canBeDamage)
			end

		end
	end)

end

SLASH_EASYDUNGEONFINDER1 = '/edf';
function SlashCmdList.EASYDUNGEONFINDER(msg, editbox)
	if ( LookingForDungeon == true ) then
		LookingForDungeon = false;
		SearchTerm = "Mythic";
		print("Stopped looking for a dungeon.")
	else
		if ( msg:match("%w") ) then
			SearchTerm = msg;
		else
			SearchTerm = "Mythic";
		end

		canBeTank = LFDQueueFrameRoleButtonTank.checkButton:GetChecked()
		canBeHealer = LFDQueueFrameRoleButtonHealer.checkButton:GetChecked()
		canBeDamage = LFDQueueFrameRoleButtonDPS.checkButton:GetChecked()

		for i = 1, GetNumSavedInstances(), 1 do
			name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
			if locked == true then
				local savedName = string.format("%s (%s)", name, difficultyName)
				table.insert(savedDungeons, savedName)
			end
		end
		if ( next(savedDungeons) ~= nil ) then
			print("Saved to:");
			for k, v in pairs(savedDungeons) do
				print(v);
			end
		end
		LookingForDungeon = true;
		LookForDungeon(SearchTerm);
		print("Started looking for a dungeon.")
	end

end
