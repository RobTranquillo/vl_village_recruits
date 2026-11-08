-- Chat commands: /rekruten <folgen|bleiben|liste|entlassen>
local R = village_recruits
local S = R.S

local RADIUS = 32

local function looked_at_recruit(player, owner)
	local eye = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	local target = vector.add(eye, vector.multiply(player:get_look_dir(), 8))
	for pointed in core.raycast(eye, target, true, false) do
		if pointed.type == "object" and pointed.ref ~= player then
			local ent = pointed.ref:get_luaentity()
			if ent and ent.name == R.ENTITY and ent.owner == owner then
				return ent
			end
		elseif pointed.type == "node" then
			return nil
		end
	end
end

local actions = {}

function actions.folgen(name, player)
	local list = R.active_recruits(name, player:get_pos(), RADIUS)
	for _, r in ipairs(list) do R.set_order(r, "follow") end
	return true, S("@1 recruits follow you.", #list)
end

function actions.bleiben(name, player)
	local list = R.active_recruits(name, player:get_pos(), RADIUS)
	for _, r in ipairs(list) do R.set_order(r, "stand") end
	return true, S("@1 recruits hold their position.", #list)
end

function actions.liste(name, player)
	local nearby = R.active_recruits(name, player:get_pos(), RADIUS)
	local loaded = R.active_recruits(name)
	return true, S("Recruits: @1 total, @2 loaded, @3 nearby.",
		R.count(name), #loaded, #nearby)
end

function actions.entlassen(name, player)
	local ent = looked_at_recruit(player, name)
	if not ent then
		return false, S("Look at one of your recruits to dismiss it.")
	end
	R.dismiss(ent)
	return true, S("The recruit was dismissed and is a villager again.")
end

core.register_chatcommand("rekruten", {
	params = "folgen | bleiben | liste | entlassen",
	description = S("Command your recruits"),
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if not player then return false, S("Only for players in the game.") end
		local action = actions[param:trim()]
		if not action then
			return false, S("Usage: /rekruten folgen | bleiben | liste | entlassen")
		end
		return action(name, player)
	end,
})
