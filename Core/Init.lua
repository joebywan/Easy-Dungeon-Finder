local AddOnName, Engine = ...

local AddOn = LibStub("AceAddon-3.0"):NewAddon("EasyDungeonFinder", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

Engine[1] = AddOn
Engine[2] = {}

function Engine:unpack()
	return self[1], self[2], self[3]
end

_G[AddOnName] = Engine
