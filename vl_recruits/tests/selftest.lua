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
