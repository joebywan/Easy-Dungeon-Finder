local E, C = unpack(EasyDungeonFinder);

function E:CreateOptionsTable()
	E.Options = {
	    name = "EasyDungeonFinder",
	    handler = addon,
	    type = 'group',
	    args = {
	      roles = {
	        name = "Roles",
	        type = "group",
	        inline = true,
	        args = {
	          DAMAGER = {
	            name = "Damage",
	            type = "toggle",
	            set = function(info, value) E.db.roles.DAMAGER = value; end,
	            get = function(info) return E.db.roles.DAMAGER; end
	          },
	          HEALER = {
	            name = "Healer",
	            type = "toggle",
	            set = function(info, value) E.db.roles.HEALER = value; end,
	            get = function(info) return E.db.roles.HEALER; end
	          },
	          TANK = {
	            name = "Tank",
	            type = "toggle",
	            set = function(info, value) E.db.roles.TANK = value; end,
	            get = function(info) return E.db.roles.TANK; end
	          }
	        }
	      },
				vacant = {
					name = 'Must have',
					type = 'multiselect',
					values = C['vacant'],
					get = function(info, value) return E.db.vacant[value] end,
					set = function(info, value, checked) E.db.vacant[value] = checked end,
				},
	      dungeons = {
	        name = 'Dungeons',
	        type = 'multiselect',
	        values = C['dungeons'],
					get = function(info, value) return E.db.dungeons[value] end,
	        set = function(info, value, checked) E.db.dungeons[value] = checked end,
	      },
	      level = {
	        name = 'Level',
	        type = 'range',
	        min = 0,
	        max = 15,
	        step = 1,
	        set = function(info, value) E.db.level = value; end,
	        get = function(info) return E.db.level; end,
	      },
				ilvl = {
					name = 'Minimum Item Level',
					type = 'input',
					order = 5,
					pattern = "[0-9]",
					usage = "Must be a number",
					set = function(info, value) E.db.ilvl = value; end,
					get = function(info) return E.db.ilvl; end,
				},
				actions = {
					name = "Controls",
					type = "group",
					inline = true,
					order = -1,
					args = {
						startSearch = {
							name = 'Start',
							type = 'execute',
							func = function() E:StartLookForDungeon() end
						},
						stopSearch = {
							name = 'Stop',
							type = 'execute',
							func = function() E:StopLookForDungeon() end
						}
					}
				}
     }
	}
end
