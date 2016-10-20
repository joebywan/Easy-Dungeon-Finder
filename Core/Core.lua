local E, C = unpack(EasyDungeonFinder);
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");

function E:OnInitialize()
  self:RegisterChatCommand("edf", "ShowConfigWindow");
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:Enable();
end

function E:Enable()
  self.db = LibStub("AceDB-3.0"):New("EasyDungeonFinderDB", C['defaults']).char
  self:CreateOptionsTable()
end

function E:PLAYER_ENTERING_WORLD()
	AceConfig:RegisterOptionsTable("EasyDungeonFinder", E.Options, nil)
end

function E:ShowConfigWindow()
	AceConfigDialog:Open("EasyDungeonFinder");
end

function E:ShouldApplyToGroup(id)

  local id, activityID, name, comment, voiceChat, iLvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, numMembers = C_LFGList.GetSearchResultInfo(id);
  local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activityID);

	-- We dont have this dungeon checked
	if ( E.db.dungeons[activityName] ~= true ) then
		return false;
	end

  if ( E.db.ilvl ~= 0 and tonumber(E.db.ilvl) >= iLvl ) then
    return false
  end

	-- try to filter out mythic +
	if ( E.db.level == 0 ) then
		for i, term in ipairs(C['filter']) do
			if string.find(name, term) then
				return false
			end
		end
	else
		local filter = ("+" .. E.db.level);
		if ( not string.match(name, filter) ) then
			return false
		end
	end

	local tank = false
	local healer = false
	local damage = 0

	for i=1,numMembers do -- check all member roles
		local memberRole = C_LFGList.GetSearchResultMemberInfo(id, i)
		if ( memberRole == "DAMAGER" ) then
			damage = damage + 1
		elseif ( memberRole == "HEALER") then
			healer = true
		elseif ( memberRole == "TANK") then
			tank = true
		end
	end

	local canBeTank = E.db.roles.TANK
	local canBeHealer = E.db.roles.HEALER
	local canBeDamager = E.db.roles.DAMAGER

	if ( canBeHealer and healer ) then
		canBeHealer = false
  end

	if ( canBeTank and tank ) then
		canBeTank = false
  end

	if ( canBeDamager and damage == 3 ) then
		canBeDamager = false
	end

  if ( not canBeHealer and not canBeTank and not canBeDamager ) then
    return false
  end

  if ( E.db.vacant.TANK and not tank ) then
    return false
  end

  if ( E.db.vacant.HEALER and not healer ) then
    return false
  end

  if ( E.db.vacant.EITHER and not ( tank or healer) ) then
    return false
  end

  return true

end

function E:StartLookForDungeon()
	self:Print("Timer started.")
  self.LookingForDungeon = true
  self:LookForDungeon()
	self:ScheduleRepeatingTimer("LookForDungeon", 30)
end

function E:StopLookForDungeon()
  self:Print("Timer stopped.")
  self.LookingForDungeon = false
	self:CancelAllTimers()
end

function E:LookForDungeon()
	self:Print("Starting new search..");
	C_LFGList.ClearSearchResults() -- Reset the search
	C_LFGList.Search(2, "") -- Gets everything in premade dungeon groups
	C_Timer.After(3, function() -- Give the search time to complete
		local searchCount, searchResults = C_LFGList.GetSearchResults()
		for _, v in pairs(searchResults) do
			if ( self:ShouldApplyToGroup(v) and C_LFGList.GetNumApplications() < 5  ) then
				local groupName = select(3,C_LFGList.GetSearchResultInfo(v))
				local activityID = select(2,C_LFGList.GetSearchResultInfo(v))
				local dungeonName = select(1,C_LFGList.GetActivityInfo(activityID))
				self:Print("Applied to " .. dungeonName .. " - " .. groupName)
				local canBeTank = E.db.roles.TANK
				local canBeHealer = E.db.roles.HEALER
				local canBeDamager = E.db.roles.DAMAGER
				C_LFGList.ApplyToGroup(v, "", canBeTank, canBeHealer, canBeDamager)
			end
		end
	end)
end
