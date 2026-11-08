-- Startup self test (enable with vl_recruits_selftest = true).
-- Runs headless on a dedicated server: hires a villager for a fake owner,
-- checks persistence via staticdata, dismisses it again, then shuts down.
local R = vl_recruits
local OWNER = "selftest_owner"
local POS = vector.new(0, 0, 0)
local results, failed = {}, 0

local function check(cond, msg)
	results[#results + 1] = (cond and "PASS " or "FAIL ") .. msg
	if not cond then failed = failed + 1 end
end

local function finish()
	for _, line in ipairs(results) do core.log("action", "[vl_recruits selftest] " .. line) end
	core.log("action", ("[vl_recruits selftest] DONE: %d checks, %d failed"):format(#results, failed))
	core.request_shutdown("selftest finished", false, 0)
end

local function ground_pos(p)
	for y = 60, -20, -1 do
		local q = vector.new(p.x, y, p.z)
		local below = core.registered_nodes[core.get_node(vector.offset(q, 0, -1, 0)).name]
		local here = core.registered_nodes[core.get_node(q).name]
		local above = core.registered_nodes[core.get_node(vector.offset(q, 0, 1, 0)).name]
		if below and below.walkable and here and not here.walkable and above and not above.walkable then
			return q
		end
	end
end

local function run()
	check(core.registered_entities[R.ENTITY] ~= nil, "recruit entity registered")
	check(core.registered_entities[R.ENTITY].do_attack ~= mcl_mobs.mob_class.do_attack,
		"friendly-fire guard installed")

	local pos = ground_pos(POS) or vector.new(0, 30, 0)
	local vobj = core.add_entity(pos, R.VILLAGER)
	check(vobj ~= nil, "villager spawned at " .. core.pos_to_string(pos))
	if not vobj then return finish() end
	local villager = vobj:get_luaentity()
	villager._profession = "farmer"

	-- Hire path without a real player (try_hire needs one for the inventory).
	local data = core.deserialize(villager:get_staticdata()) or {}
	local skin = vobj:get_properties().textures[1]
	vobj:remove()
	local r = R.spawn_recruit(pos, 0, OWNER, {villager_data = core.serialize(data), skin = skin})
	check(r ~= nil, "recruit spawned")
	if not r then return finish() end
	check(r.owner == OWNER and r.order == "follow", "owner and order set")
	check(R.count(OWNER) == 1, "registry counts 1 recruit")
	check(r.base_texture[1]:find("vl_recruits_head_mask.png", 1, true) ~= nil, "skin uses head mask")

	R.set_order(r, "stand")
	check(r.order == "stand" and r._guard_pos ~= nil, "stand order stores guard position")

	-- Persistence: recreate from staticdata like an unload/reload would.
	local sd = r:get_staticdata()
	local id = r._recruit_id
	r.object:remove()
	local robj = core.add_entity(pos, R.ENTITY, sd)
	local r2 = robj and robj:get_luaentity()
	check(r2 and r2.owner == OWNER and r2._recruit_id == id and r2.order == "stand",
		"owner/id/order survive staticdata roundtrip")
	check(r2 and r2.base_texture and r2.base_texture[1] == r.base_texture[1], "skin survives roundtrip")

	-- Equipment: model, armor, weapon.
	if r2 then
		check(r2.object:get_properties().mesh == "mcl_armor_character.b3d", "uses the player model")
		local given = {}
		local fake_player = {
			get_player_name = function() return OWNER end,
			set_wielded_item = function(_, s) given.wield = s end,
			get_inventory = function() return {add_item = function(_, _, s) given.back = s; return ItemStack() end} end,
			get_pos = function() return pos end,
		}
		local chest = ItemStack("mcl_armor:chestplate_iron")
		check(core.registered_items["mcl_armor:chestplate_iron"] ~= nil, "iron chestplate exists")
		check(R.give_item(r2, fake_player, chest), "recruit accepts a chestplate")
		local fleshy = r2.object:get_armor_groups().fleshy
		check(fleshy and fleshy < 100, "armor reduces damage (fleshy=" .. tostring(fleshy) .. ")")
		check(r2.object:get_properties().textures[2] ~= "blank.png", "armor layer textured")
		check(R.give_item(r2, fake_player, ItemStack("mcl_tools:sword_iron")), "recruit accepts a sword")
		check(r2.damage > R.BASE_DAMAGE, "sword raises damage to " .. tostring(r2.damage))
		check(r2._wield_obj and r2._wield_obj:get_attach() == r2.object, "sword shown in hand")
		check(not R.give_item(r2, fake_player, ItemStack("mcl_core:dirt")), "ignores non-equipment")
		check(R.give_item(r2, fake_player, ItemStack("mcl_armor:chestplate_diamond"))
			and given.back and given.back:get_name() == "mcl_armor:chestplate_iron",
			"swapping armor returns the old piece")

		-- Gear survives unload/reload.
		local fleshy_before = r2.object:get_armor_groups().fleshy
		local sd2 = r2:get_staticdata()
		r2.object:remove()
		local o3 = core.add_entity(pos, R.ENTITY, sd2)
		local r3 = o3 and o3:get_luaentity()
		check(r3 and r3.object:get_armor_groups().fleshy == fleshy_before,
			"armor groups restored after reload (fleshy=" .. tostring(fleshy_before) .. ")")
		check(r3 and r3._armor and r3._armor[3] == "mcl_armor:chestplate_diamond", "armor saved in staticdata")
		check(r3 and r3.damage > R.BASE_DAMAGE, "weapon damage restored after reload")
		check(r3 and r3._wield_obj ~= nil, "sword shown again after reload")
		r2 = r3
	end

	-- Friendly-fire guard.
	if r2 then
		local fake_owner = {is_player = function() return true end,
			get_player_name = function() return OWNER end}
		r2:do_attack(fake_owner)
		check(r2.attack == nil, "does not attack its owner")
	end

	-- Dismiss back into the villager.
	if r2 then
		R.dismiss(r2)
		check(R.count(OWNER) == 0, "registry empty after dismiss")
		local drops = 0
		for _, o in ipairs(core.get_objects_inside_radius(pos, 3)) do
			local e = o:get_luaentity()
			if e and e.name == "__builtin:item" then drops = drops + 1 end
		end
		check(drops >= 2, "gear dropped on dismiss (" .. drops .. " items)")
		local back
		for _, ent in pairs(core.luaentities) do
			if ent.name == R.VILLAGER and ent._profession == "farmer" then back = ent end
		end
		check(back ~= nil, "villager restored with profession")
	end
	finish()
end

core.register_on_mods_loaded(function()
	core.after(1, function()
		core.forceload_block(POS, true)
		core.emerge_area(vector.offset(POS, -16, -32, -16), vector.offset(POS, 16, 64, 16),
			function(_, _, remaining)
				if remaining == 0 then core.after(1, run) end
			end)
	end)
end)
