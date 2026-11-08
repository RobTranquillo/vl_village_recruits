-- Startup self test (enable with village_recruits_selftest = true).
-- Runs headless on a dedicated server: hires a villager for a fake owner,
-- checks persistence via staticdata, dismisses it again, then shuts down.
local R = village_recruits
local OWNER = "selftest_owner"
local POS = vector.new(0, 0, 0)
local results, failed = {}, 0

local function check(cond, msg)
	results[#results + 1] = (cond and "PASS " or "FAIL ") .. msg
	if not cond then failed = failed + 1 end
end

local function finish()
	for _, line in ipairs(results) do core.log("action", "[village_recruits selftest] " .. line) end
	core.log("action", ("[village_recruits selftest] DONE: %d checks, %d failed"):format(#results, failed))
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
	check(r.base_texture[1]:find("village_recruits_head_mask.png", 1, true) ~= nil, "skin uses head mask")

	-- Jumping: on flat open ground the following recruit must not hop.
	for x = -3, 3 do
		for z = -3, 3 do
			core.set_node(vector.offset(pos, x, -1, z), {name = "mcl_core:stone"})
			core.set_node(vector.offset(pos, x, 0, z), {name = "air"})
			core.set_node(vector.offset(pos, x, 1, z), {name = "air"})
		end
	end
	r.object:set_pos(vector.offset(pos, 0, -0.49, 0)) -- feet on the stone
	r.object:set_velocity(vector.zero())
	check(r.order == "follow" and not r:do_jump(), "no jumping on flat ground while following")
	core.set_node(vector.offset(pos, 0, 0, 1), {name = "mcl_core:stone"})
	r.object:set_yaw(0) -- facing +z, towards the block
	check(r:do_jump() == true, "jumps when a block is in front")
	core.set_node(vector.offset(pos, 0, 0, 1), {name = "air"})
	r.object:set_velocity(vector.zero())

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

		-- Shield: blocks half of a frontal hit, nothing from behind, wears down.
		check(R.give_item(r2, fake_player, ItemStack("mcl_shields:shield")), "recruit accepts a shield")
		check(r2._shield_obj and r2._shield_obj:get_attach() == r2.object, "shield shown on the arm")
		r2.object:set_yaw(0) -- facing +z
		local here = r2.object:get_pos()
		local front = core.add_entity(vector.offset(here, 0, 0, 2), "village_recruits:wield")
		local back = core.add_entity(vector.offset(here, 0, 0, -2), "village_recruits:wield")
		local caps = {full_punch_interval = 1, damage_groups = {fleshy = 10}}
		local cf = R.shield_filter(r2, front, caps)
		local cb = R.shield_filter(r2, back, caps)
		check(cf.damage_groups.fleshy == 5, "shield blocks half from the front (" .. cf.damage_groups.fleshy .. ")")
		check(cb.damage_groups.fleshy == 10, "shield does not block from behind")
		check(ItemStack(r2._shield):get_wear() > 0, "shield wears when blocking")
		front:remove(); back:remove()

		-- Totem: fatal damage leaves the recruit alive with 1 HP, totem used up.
		check(R.give_item(r2, fake_player, ItemStack("mcl_totems:totem")), "recruit accepts a totem")
		r2.health = 0
		r2:check_for_death("hit", {type = "punch"})
		check(r2.health == 1 and r2.state ~= "die", "totem prevents death")
		check(r2._totem == "", "totem is used up")

		-- Food: rejects poison, stores bread, eats when hurt.
		check(not R.give_item(r2, fake_player, ItemStack("mcl_mobitems:rotten_flesh")), "refuses rotten flesh")
		check(R.give_item(r2, fake_player, ItemStack("mcl_farming:bread 5")), "recruit takes bread")
		check(ItemStack(r2._food[1]):get_count() == 5, "5 bread in the food bag")
		r2.health = 8
		R.food_step(r2, 3)
		check(r2.health > 8, "eats when hurt (health now " .. r2.health .. ")")
		check(ItemStack(r2._food[1]):get_count() == 4, "one bread eaten")
		r2.health = 20
		R.food_step(r2, 3)
		check(ItemStack(r2._food[1]):get_count() == 4, "does not eat at full health")

		-- Menu layout: every slot grid lies inside the window, none overlap.
		local fs = R.equipment_formspec(r2)
		local w, h = fs:match("size%[([%d.]+),([%d.]+)%]")
		w, h = tonumber(w), tonumber(h)
		local boxes, inside = {}, true
		for x, y, cols, rows in fs:gmatch("list%[[^;]+;[^;]+;([%d.]+),([%d.]+);(%d+),(%d+);") do
			local b = {x = tonumber(x), y = tonumber(y)}
			b.x2 = b.x + tonumber(cols) * 1.25 - 0.25
			b.y2 = b.y + tonumber(rows) * 1.25 - 0.25
			if b.x2 > w or b.y2 > h then inside = false end
			boxes[#boxes + 1] = b
		end
		local overlap = false
		for i = 1, #boxes do
			for j = i + 1, #boxes do
				local a, b = boxes[i], boxes[j]
				if a.x < b.x2 and b.x < a.x2 and a.y < b.y2 and b.y < a.y2 then overlap = true end
			end
		end
		check(#boxes == 7 and inside and not overlap,
			("menu layout fits %sx%s, %d slot grids, no overlap"):format(w, h, #boxes))
		check(h <= 9, "menu is compact (height " .. h .. " <= 9)")
		check(fs:find("armor;0.375,1.2;4,1;1]", 1, true) ~= nil, "armor slots in one row")

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
		check(r3 and r3._shield_obj ~= nil and r3._shield ~= "", "shield restored after reload")
		check(r3 and ItemStack(r3._food[1]):get_count() == 4, "food restored after reload")
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
		check(drops >= 4, "gear dropped on dismiss (" .. drops .. " items)")
		local back
		for _, ent in pairs(core.luaentities) do
			if ent.name == R.VILLAGER and ent._profession == "farmer" then back = ent end
		end
		check(back ~= nil, "villager restored with profession")
	end
	-- Recruits saved under the old mod name are converted on load.
	local old = core.add_entity(pos, "vl_recruits:recruit", core.serialize({
		owner = OWNER, _recruit_id = "old-recruit-1", order = "stand",
		_weapon = "mcl_tools:sword_iron",
	}))
	local converted
	for _, ent in pairs(core.luaentities) do
		if ent.name == R.ENTITY and ent._recruit_id == "old-recruit-1" then converted = ent end
	end
	check(old == nil or not old:get_pos(), "old vl_recruits entity replaced")
	check(converted and converted.owner == OWNER and converted.order == "stand",
		"old recruit converted with owner and order")
	check(converted and converted.damage > R.BASE_DAMAGE, "old recruit keeps its weapon")
	check(R.count(OWNER) == 1, "converted recruit re-registered")
	if converted then
		R.unregister(OWNER, converted._recruit_id)
		converted.object:remove()
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
