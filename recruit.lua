-- The recruit mob. Built on mcl_mobs and VoxeLibre's player model
-- (mcl_armor_character.b3d), which has an armor layer and a Wield_Item bone.
-- Skin: a plain mcl_skins outfit with the hired villager's head on top.
local R = village_recruits
local S = R.S
local mob_class = mcl_mobs.mob_class

local MESH = "mcl_armor_character.b3d"
local DEFAULT_VILLAGER_SKIN = "mobs_mc_villager.png"
local FALLBACK_BODY = "mcl_skins_character_1.png"
local ICON_FOLLOW = "mobs_mc_wolf_icon_roam.png"
local ICON_STAND = "mobs_mc_wolf_icon_sit.png"
local TELEPORT_INTERVAL = 1
local GUARD_RADIUS = 3

-- Recruit uniform: mcl_skins template without hair/face parts (the villager
-- head replaces the whole head area), blue shirt, dark trousers.
local body_texture
local function get_body()
	if body_texture then return body_texture end
	if core.global_exists("mcl_skins") and mcl_skins.template1 and mcl_skins.template1.base then
		local skin = table.copy(mcl_skins.template1)
		skin.hair, skin.eye, skin.mouth, skin.headwear, skin.cape = nil, nil, nil, nil, nil
		skin.top_color = 0xff2b4f86
		skin.bottom_color = 0xff2e2a26
		body_texture = mcl_skins.compile_skin(skin)
	end
	if not body_texture or body_texture == "" then
		body_texture = FALLBACK_BODY
	end
	return body_texture
end

-- Player-layout skin with the villager's head. The villager head UV starts at
-- the same place as the player head; the mask keeps the top 8x8 head part.
function R.make_skin(villager_skin)
	villager_skin = villager_skin or DEFAULT_VILLAGER_SKIN
	return "(" .. get_body() .. ")^((" .. villager_skin .. ")^[mask:village_recruits_head_mask.png)"
end

local function owner_player(self)
	return self.owner and self.owner ~= "" and core.get_player_by_name(self.owner) or nil
end

local function is_friend(self, obj)
	if not obj then return false end
	if obj:is_player() then
		return obj:get_player_name() == self.owner
	end
	local ent = obj:get_luaentity()
	return ent and ent.name == R.ENTITY and ent.owner == self.owner or false
end

function R.update_nametag(self)
	if self._custom_name then return end
	self.nametag = S("@1's recruit", self.owner)
	self:update_tag()
end

local function show_icon(self, texture)
	local pos = self.object:get_pos()
	if not pos then return end
	core.add_particle({
		pos = vector.offset(pos, 0, 2.4, 0),
		velocity = vector.new(0, 0.2, 0),
		expirationtime = 1,
		size = 4,
		texture = texture,
		playername = self.owner,
		glow = core.LIGHT_MAX,
	})
end

-- Orders -----------------------------------------------------------------

function R.set_order(self, order)
	self.attack = nil
	self.state = "stand"
	self.following = nil
	if order == "follow" then
		self.order = "follow"
		self._guard_pos = nil
		show_icon(self, ICON_FOLLOW)
	else
		self.order = "stand"
		self._guard_pos = vector.round(self.object:get_pos())
		show_icon(self, ICON_STAND)
	end
	self:set_velocity(0)
	self:set_animation("stand")
end

-- Teleport --------------------------------------------------------------

local OFFSETS = {}
for x = -2, 2 do
	for z = -2, 2 do
		if math.abs(x) + math.abs(z) >= 2 then
			OFFSETS[#OFFSETS + 1] = vector.new(x, 0, z)
		end
	end
end

local function is_walkable(pos)
	local def = core.registered_nodes[core.get_node(pos).name]
	return def and def.walkable
end

local function find_spot_near(pos)
	local base = vector.round(pos)
	local order = table.copy(OFFSETS)
	table.shuffle(order)
	for _, off in ipairs(order) do
		for dy = 1, -1, -1 do
			local p = vector.offset(base, off.x, dy, off.z)
			if not is_walkable(p) and not is_walkable(vector.offset(p, 0, 1, 0))
					and is_walkable(vector.offset(p, 0, -1, 0)) then
				return p
			end
		end
	end
end

local function teleport_to_owner(self, player)
	local spot = find_spot_near(player:get_pos())
	if not spot then return end
	self.attack = nil
	self.state = "stand"
	self.object:set_pos(vector.offset(spot, 0, -0.49, 0))
	self:set_velocity(0)
end

-- Per-step logic (runs after mcl_mobs follow/attack checks) ---------------

local function do_custom(self, dtime)
	if not self.owner or self.owner == "" then return end
	R.food_step(self, dtime)

	if self.order == "follow" then
		local player = owner_player(self)
		if not player then return end
		-- mcl_mobs picks the first player in range; make sure it is the owner.
		if self.state ~= "attack" then
			self.following = player
		end
		self._tp_timer = (self._tp_timer or 0) + dtime
		if self._tp_timer >= TELEPORT_INTERVAL then
			self._tp_timer = 0
			local dist = vector.distance(player:get_pos(), self.object:get_pos())
			if dist > R.settings.teleport_distance and not player:get_attach() then
				teleport_to_owner(self, player)
			end
		end
	elseif self.order == "stand" and self._guard_pos and self.state ~= "attack" then
		-- Walk back to the post after a fight.
		local pos = self.object:get_pos()
		if vector.distance(pos, self._guard_pos) > GUARD_RADIUS then
			self:go_to_pos(self._guard_pos, self.walk_velocity)
			return false -- skip the stand state, which would stop us
		end
	end
end

-- Interaction -------------------------------------------------------------

local function on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then return end
	local name = clicker:get_player_name()
	local stack = clicker:get_wielded_item()
	if stack:get_name() == "mcl_mobs:nametag" then
		-- mcl_mobs already applied the name before calling us.
		self._custom_name = true
		return
	end
	if name ~= self.owner then
		core.chat_send_player(name, S("This recruit belongs to @1.", self.owner))
		return
	end
	-- Sneak: open the equipment menu.
	if clicker:get_player_control().sneak then
		R.show_equipment(self, clicker)
		return
	end
	-- Holding armor or a weapon: hand it over.
	if R.give_item(self, clicker, stack) then
		return
	end
	if self.order == "follow" then
		R.set_order(self, "stand")
		core.chat_send_player(name, S("Recruit holds position."))
	else
		R.set_order(self, "follow")
		core.chat_send_player(name, S("Recruit follows you."))
	end
end

-- Registration --------------------------------------------------------------

mcl_mobs.register_mob(R.ENTITY, {
	description = S("Recruit"),
	type = "npc",
	spawn_class = "passive",
	passive = false,
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.79, 0.3},
	},
	xp_min = 0,
	xp_max = 0,
	visual = "mesh",
	mesh = MESH,
	head_swivel = "Head_Control",
	head_eye_height = 1.5,
	head_bone_position = vector.new(0, 6.3, 0), -- only for Luanti <= 5.8
	curiosity = 10,
	-- skin, armor layer, cape
	textures = {
		{R.make_skin(), "blank.png", "blank.png"},
	},
	visual_size = {x = 1, y = 1},
	makes_footstep_sound = true,
	sounds = {
		damage = "mobs_mc_villager_hurt",
		distance = 10,
	},
	damage = R.BASE_DAMAGE,
	reach = 2,
	attack_type = "dogfight",
	attacks_monsters = true,
	attack_npcs = false,
	attack_animals = false,
	owner_loyal = true,
	can_despawn = false,
	order = "follow",
	follow = "",
	walk_chance = 0,
	walk_velocity = 1.2,
	run_velocity = 2.6,
	follow_velocity = 3.2,
	view_range = 16,
	fear_height = 4,
	jump = true,
	pathfinding = 1,
	drops = {},
	-- Frames of mcl_armor_character.b3d (see mcl_armor/player.lua)
	animation = {
		stand_speed = 30, stand_start = 0, stand_end = 79,
		walk_speed = 30, walk_start = 168, walk_end = 187,
		run_speed = 30, run_start = 440, run_end = 459,
		punch_speed = 30, punch_start = 189, punch_end = 198,
		die_speed = 15, die_start = 498, die_end = 498, die_loop = false,
	},
	on_rightclick = on_rightclick,
	do_custom = do_custom,
	after_activate = function(self)
		-- Older recruits (vindicator model) lose their textures on the mesh
		-- change; always rebuild the skin from the stored villager skin.
		self.base_texture = self.base_texture or {}
		self.base_texture[1] = R.make_skin(self._villager_skin)
		self.base_texture[2] = self.base_texture[2] or "blank.png"
		self.base_texture[3] = "blank.png"
		self.object:set_properties({textures = self.base_texture})
		R.equipment_activate(self)
	end,
	on_die = function(self)
		R.drop_equipment(self)
		R.equipment_deactivate(self)
		R.unregister(self.owner, self._recruit_id)
		if owner_player(self) then
			core.chat_send_player(self.owner, S("One of your recruits has died."))
		end
	end,
})

local def = core.registered_entities[R.ENTITY]

-- Before its first release the mod was called "vl_recruits". Only worlds from
-- that development version need this, so it is off by default (and keeps the
-- package out of VoxeLibre's "vl_" namespace unless explicitly enabled).
if core.settings:get_bool("village_recruits_convert_vl_recruits", false) then
	mcl_mobs.register_conversion(":vl_recruits:recruit", R.ENTITY)
end

-- Never attack the owner or the owner's other recruits, even when another
-- player made this recruit aggressive (_aggro makes mcl_mobs target players).
function def:do_attack(object)
	if is_friend(self, object) then return end
	return mob_class.do_attack(self, object)
end

-- mcl_mobs' do_jump skips its "is there a block in front of me?" check when
-- walk_chance is 0, so with walk_chance = 0 (no random wandering) the recruit
-- jumped on every step. Mid-air set_velocity is ignored, so it never walked.
-- Run the check as if wandering were enabled.
function def:do_jump()
	local walk_chance = self.walk_chance
	self.walk_chance = 1
	local jumped = mob_class.do_jump(self)
	self.walk_chance = walk_chance
	return jumped
end

-- Shield: reduce damage of hits from the front before mcl_mobs applies it.
function def:on_punch(hitter, tflp, tool_capabilities, dir, damage)
	tool_capabilities = R.shield_filter(self, hitter, tool_capabilities)
	return mob_class.on_punch(self, hitter, tflp, tool_capabilities, dir, damage)
end

-- Totem: survive a fatal hit once with 1 HP.
function def:check_for_death(cause, cmi_cause, info)
	if self.state ~= "die" and self.health and self.health <= 0 and R.use_totem(self) then
		self.health = 1
	end
	return mob_class.check_for_death(self, cause, cmi_cause, info)
end

-- Hooks used by mcl_armor (mcl_util.get_inventory / mcl_armor.update).
function def:create_inventory()
	return R.equipment_activate(self)
end

function def:update_armor(info)
	R.apply_armor(self, info)
end

function def:on_deactivate(removal)
	R.equipment_deactivate(self)
end

-- Spawn a fresh recruit for owner at pos. villager_data is the villager's
-- serialized staticdata (restored when dismissed), skin its current texture.
function R.spawn_recruit(pos, yaw, owner, opts)
	opts = opts or {}
	local obj = core.add_entity(pos, R.ENTITY)
	if not obj then return end
	obj:set_yaw(yaw or 0)
	local self = obj:get_luaentity()
	self.owner = owner
	self._recruit_id = mcl_util.gen_uuid()
	self._villager_data = opts.villager_data
	self._villager_skin = opts.skin
	self.base_texture = {R.make_skin(opts.skin), "blank.png", "blank.png"}
	obj:set_properties({textures = self.base_texture})
	if opts.health then
		self.health = math.min(opts.health, self.object:get_properties().hp_max or 20)
		obj:set_hp(self.health)
	end
	-- The id only exists now; create the equipment inventory for it.
	R.equipment_activate(self)
	R.set_order(self, "follow")
	R.update_nametag(self)
	R.register(owner, self._recruit_id)
	return self
end
