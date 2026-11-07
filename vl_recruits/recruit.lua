-- The recruit mob. Built on mcl_mobs; uses the vindicator model (arms + weapon
-- slot + punch animation) with the villager's head masked onto a tinted body.
local R = vl_recruits
local S = R.S
local mob_class = mcl_mobs.mob_class

local WEAPON = "default_tool_steelsword.png"
local BODY = "mobs_mc_vindicator.png^[colorize:#2b4f86:130"
local DEFAULT_VILLAGER_SKIN = "mobs_mc_villager.png"
local ICON_FOLLOW = "mobs_mc_wolf_icon_roam.png"
local ICON_STAND = "mobs_mc_wolf_icon_sit.png"
local TELEPORT_INTERVAL = 1
local GUARD_RADIUS = 3

-- Skin texture: soldier body with the hired villager's head.
function R.make_skin(villager_skin)
	villager_skin = villager_skin or DEFAULT_VILLAGER_SKIN
	return BODY .. "^((" .. villager_skin .. ")^[mask:vl_recruits_head_mask.png)"
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
	local item = clicker:get_wielded_item():get_name()
	if item == "mcl_mobs:nametag" then
		-- mcl_mobs already applied the name before calling us.
		self._custom_name = true
		return
	end
	if name ~= self.owner then
		core.chat_send_player(name, S("This recruit belongs to @1.", self.owner))
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
		collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.94, 0.3},
	},
	xp_min = 0,
	xp_max = 0,
	visual = "mesh",
	mesh = "mobs_mc_vindicator.b3d",
	head_swivel = "head.control",
	head_eye_height = 1.5,
	head_bone_position = vector.new(0, 2.2, 0),
	curiosity = 10,
	textures = {
		{R.make_skin(), "blank.png", WEAPON},
	},
	visual_size = {x = 2.75, y = 2.75},
	makes_footstep_sound = true,
	sounds = {
		damage = "mobs_mc_villager_hurt",
		distance = 10,
	},
	damage = 4,
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
	animation = {
		stand_speed = 25, stand_start = 40, stand_end = 59,
		walk_speed = 25, walk_start = 0, walk_end = 40,
		run_speed = 25, run_start = 0, run_end = 40,
		punch_speed = 25, punch_start = 90, punch_end = 110,
		die_speed = 15, die_start = 170, die_end = 180, die_loop = false,
	},
	on_rightclick = on_rightclick,
	do_custom = do_custom,
	on_die = function(self)
		R.unregister(self.owner, self._recruit_id)
		local player = owner_player(self)
		if player then
			core.chat_send_player(self.owner, S("One of your recruits has died."))
		end
	end,
})

-- Never attack the owner or the owner's other recruits, even when another
-- player made this recruit aggressive (_aggro makes mcl_mobs target players).
local def = core.registered_entities[R.ENTITY]
function def:do_attack(object)
	if is_friend(self, object) then return end
	return mob_class.do_attack(self, object)
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
	self.base_texture = {R.make_skin(opts.skin), "blank.png", WEAPON}
	obj:set_properties({textures = self.base_texture})
	if opts.health then
		self.health = math.min(opts.health, self.object:get_properties().hp_max or 20)
		obj:set_hp(self.health)
	end
	R.set_order(self, "follow")
	R.update_nametag(self)
	R.register(owner, self._recruit_id)
	return self
end
