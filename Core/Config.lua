local E, C = unpack(EasyDungeonFinder);

C["dungeons"] = {
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

C["filter"] = {
	"+1",
	"+2",
	"+3",
	"+4",
	"+5",
	"+6",
	"+7",
	"+8",
	"+9",
	"+10",
	"+11",
	"+12",
	"+13",
	"+14",
	"+15"
}

C["defaults"] = {
		["char"] = {
			["roles"] = {
				["DAMAGER"] = false,
				["HEALER"] = false,
				["TANK"] = false,
			},
			["dungeons"] = {},
			["level"] = 0,
			["ilvl"] = 0,
		}
}
