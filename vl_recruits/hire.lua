-- Hiring: sneak + right-click a villager while holding emeralds.
-- Without sneaking the villager's normal trading menu opens as usual.
local R = vl_recruits
local S = R.S

local EMERALD = "mcl_core:emerald"

-- Free the bed and job site the villager had claimed (see villager.lua on_die).
local function release_claims(villager)
	for _, field in ipairs({"_bed", "_jobsite"}) do
		local pos = villager[field]
		if pos then
			core.get_meta(pos):set_string("villager", "")
		end
	end
end

local function villager_snapshot(villager)
	local data = core.deserialize(villager:get_staticdata() or "") or {}
	data._bed = nil
	data._jobsite = nil
	data._trading_players = nil
	return core.serialize(data)
end

function R.try_hire(villager, player)
	local name = player:get_player_name()
	if villager.child then
		core.chat_send_player(name, S("Children cannot be recruited."))
		return true
	end
	if villager._trading_players and next(villager._trading_players) then
		core.chat_send_player(name, S("This villager is busy trading."))
		return true
	end
	if R.count(name) >= R.settings.max_per_player then
		core.chat_send_player(name, S("You already have @1 recruits (maximum).", R.settings.max_per_player))
		return true
	end

	local cost = R.settings.cost
	local creative = core.is_creative_enabled(name)
	local stack = player:get_wielded_item()
	if not creative then
		if stack:get_count() < cost then
			core.chat_send_player(name, S("Hiring costs @1 emeralds.", cost))
			return true
		end
		stack:take_item(cost)
		player:set_wielded_item(stack)
	end

	local obj = villager.object
	local pos, yaw = obj:get_pos(), obj:get_yaw()
	local props = obj:get_properties()
	local skin = props.textures and props.textures[1]
	local data = villager_snapshot(villager)
	local health = villager.health

	release_claims(villager)
	obj:remove()

	local recruit = R.spawn_recruit(pos, yaw, name, {
		villager_data = data,
		skin = skin,
		health = health,
	})
	if not recruit then
		-- Should not happen; give the villager back rather than losing it.
		core.add_entity(pos, R.VILLAGER, data)
		return true
	end
	core.sound_play("mobs_mc_villager", {pos = pos, max_hear_distance = 16}, true)
	core.chat_send_player(name, S("The villager joined you as a recruit (@1/@2).",
		R.count(name), R.settings.max_per_player))
	return true
end

-- Turn a recruit back into the villager it was.
function R.dismiss(recruit)
	local pos = recruit.object:get_pos()
	local yaw = recruit.object:get_yaw()
	R.unregister(recruit.owner, recruit._recruit_id)
	R.drop_equipment(recruit)
	R.equipment_deactivate(recruit)
	recruit.object:remove()
	local villager = core.add_entity(pos, R.VILLAGER, recruit._villager_data)
	if villager then villager:set_yaw(yaw) end
end

core.register_on_mods_loaded(function()
	local def = core.registered_entities[R.VILLAGER]
	assert(def, "vl_recruits: villager entity " .. R.VILLAGER .. " not found")
	local original = def.on_rightclick
	def.on_rightclick = function(self, clicker)
		if clicker and clicker:is_player()
				and clicker:get_player_control().sneak
				and clicker:get_wielded_item():get_name() == EMERALD then
			R.try_hire(self, clicker)
			return
		end
		return original(self, clicker)
	end
end)
