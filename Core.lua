addon = LibStub("AceAddon-3.0"):NewAddon("EasyDungeonFinder", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");
config = LibStub("AceConfig-3.0");
dialog = LibStub("AceConfigDialog-3.0");

local dungeons = {
	["Vault of the Wardens (Mythic)"] = "Vault of the Wardens",
	["Eye of Azshara (Mythic)"] = "Eye of Azshara",
	["The Arcway (Mythic)"] = "The Arcway",
	["Maw of Souls (Mythic)"] = "Maw of Souls",
	["Halls of Valor (Mythic)"] = "Halls of Valor",
	["Darkheart Thicket (Mythic)"] = "Darkheart Thicket",
	["Black Rook Hold (Mythic)"] = "Black Rook Hold",
	["Neltharion's Lair (Mythic)"] = "Neltharion's Lair",
	["Assault on Violet Hold (Mythic)"] = "Assault on Violet Hold",
	["Court of Stars (Mythic)"] = "Court of Stars",
}

local filterTerms = {
	"+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9", "+10", "+11", "+12", "+13", "+14", "+15"
};

local SavedDungeons = {}

local defaults = {
		char = {
			roles = {
				DAMAGER = false,
				HEALER = false,
				TANK = false,
			},
			dungeons = {},
			level = 0
		}
}

function addon:OnInitialize()
	self:RegisterChatCommand("edf", "ShowConfigWindow");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self.db = LibStub("AceDB-3.0"):New("EasyDungeonFinderDB", defaults, true)
end

function addon:BuildOptions()
	local options = {
	    name = "EasyDungeonFinder",
	    handler = addon,
	    type = 'group',
	    args = {
				roles = {
					name = "Roles",
					type = "group",
					inline = true,
					order = 1,
					args = {
						DAMAGER = {
							name = "Damage",
							type = "toggle",
							set = function(info, value) addon.db.char.roles.DAMAGER = value; end,
							get = function(info) return addon.db.char.roles.DAMAGER; end
						},
						HEALER = {
							name = "Healer",
							type = "toggle",
							set = function(info, value) addon.db.char.roles.HEALER = value; end,
							get = function(info) return addon.db.char.roles.HEALER; end,
						},
						TANK = {
							name = "Tank",
							type = "toggle",
							set = function(info, value) addon.db.char.roles.TANK = value; end,
							get = function(info) return addon.db.char.roles.TANK; end,
						}
					}
				},
		    dungeons = {
					name = 'Dungeons',
		      type = 'multiselect',
					values = dungeons,
		      set = function(info, value, checked) addon.db.char.dungeons[value] = checked; end,
		    	get = function(info, value) return addon.db.char.dungeons[value]; end,
					order = 2
		    },
				level = {
					name = 'Level',
					type = 'range',
					min = 0,
					max = 15,
					step = 1,
					set = function(info, value) addon.db.char.level = value; end,
					get = function(info) return addon.db.char.level; end,
					order = 3,
				},
				startSearch = {
					name = 'Start looking for group',
					type = 'execute',
					func = 'StartLookForDungeon',
					order = 4,
					width = 'full',
				},
				stopSearch = {
					name = 'Stop looking for group',
					type = 'execute',
					func = 'StopLookForDungeon',
					order = 5,
					width = 'full',
				}
	    }
	}
	return options;
end

function addon:PLAYER_ENTERING_WORLD()
	config:RegisterOptionsTable("EasyDungeonFinder", self.BuildOptions(), nil)
end

function addon:ShowConfigWindow()
	dialog:Open("EasyDungeonFinder");
end

function ShouldApplyToGroup(id)
	local id, activityID, name, comment, voiceChat, iLvl,_,_,_,_,_,_, leaderName, numMembers = C_LFGList.GetSearchResultInfo(id);
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(activityID)

	-- We dont have this dungeon checked
	if ( addon.db.char.dungeons[fullName] ~= true ) then
		return false;
	end

	-- try to filter out mythic +
	if ( addon.db.char.level == 0 ) then
		for i, term in ipairs(filterTerms) do
			if ( string.match(name, term) ) then
				return false;
			end
		end
	else
		local filter = ("+" .. addon.db.char.level);
		if ( not string.match(name, filter) ) then
			return false;
		end
	end

	local tank = false;
	local healer = false;
	local damage = 0;

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

	local canBeTank = addon.db.char.roles.TANK
	local canBeHealer = addon.db.char.roles.HEALER
	local canBeDamager = addon.db.char.roles.DAMAGER

	if ( canBeHealer and not healer and tank ) then
		return true;
	elseif ( canBeTank and not tank and healer ) then
		return true;
	elseif ( canBeDamager and tank and healer and damage < 3 ) then
		return true;
	end

end

function addon:StartLookForDungeon()
	self:Print("Started looking for groups.");
	self:LookForDungeon()
	self.timer = self:ScheduleRepeatingTimer("LookForDungeon", 30);
end

function addon:StopLookForDungeon()
	self.searching = false;
	self:Print("Stopped looking for groups.");
	self:CancelTimer(self.timer);
end

function addon:LookForDungeon()
	self:Print("...searching...");
	C_LFGList.ClearSearchResults(); -- Reset the search
	C_LFGList.Search(2, ""); -- Gets everything in premade dungeon groups
	C_Timer.After(3, function() -- Give the search time to complete
		local searchCount, searchResults = C_LFGList.GetSearchResults();
		for _, v in pairs(searchResults) do
			if ( ShouldApplyToGroup(v) and C_LFGList.GetNumApplications() < 5  ) then
				local groupName = select(3,C_LFGList.GetSearchResultInfo(v));
				local activityID = select(2,C_LFGList.GetSearchResultInfo(v));
				local dungeonName = select(1,C_LFGList.GetActivityInfo(activityID));
				self:Print("Applied to " .. groupName .. ", " .. dungeonName);
				local canBeTank = addon.db.char.roles.TANK;
				local canBeHealer = addon.db.char.roles.HEALER;
				local canBeDamager = addon.db.char.roles.DAMAGER;
				C_LFGList.ApplyToGroup(v, "", canBeTank, canBeHealer, canBeDamage);
			end
		end
	end)
end
