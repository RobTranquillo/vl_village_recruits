-- Dorfrekruten (village_recruits): hire VoxeLibre villagers as soldiers.
-- Tested with Luanti 5.17.0 and VoxeLibre 0.92.3. All accesses to
-- mcl_mobs internals live in recruit.lua and hire.lua.

local modpath = core.get_modpath("village_recruits")

village_recruits = {
	S = core.get_translator("village_recruits"),
	storage = core.get_mod_storage(),
	ENTITY = "village_recruits:recruit",
	VILLAGER = "mobs_mc:villager",
	settings = {
		cost = tonumber(core.settings:get("village_recruits_cost")) or 3,
		max_per_player = tonumber(core.settings:get("village_recruits_max_per_player")) or 10,
		teleport_distance = tonumber(core.settings:get("village_recruits_teleport_distance")) or 16,
	},
}

dofile(modpath .. "/registry.lua")
dofile(modpath .. "/equipment.lua")
dofile(modpath .. "/recruit.lua")
dofile(modpath .. "/hire.lua")
dofile(modpath .. "/commands.lua")

if core.settings:get_bool("village_recruits_selftest", false) then
	dofile(modpath .. "/tests/selftest.lua")
end
