-- Recruit equipment. Each loaded recruit gets a detached inventory
-- "vl_recruits_<id>" with these lists (field = saved copy in staticdata):
--   armor  5 slots (mcl_armor uses 2..5)  self._armor  {[2..5] = itemstring}
--   weapon 1 slot  (sword / axe)          self._weapon itemstring
--   shield 1 slot                         self._shield itemstring
--   totem  1 slot  (totem of undying)     self._totem  itemstring
--   food   3 slots (stacks)               self._food   {[1..3] = itemstring}
local R = vl_recruits
local S = R.S
local F = core.formspec_escape

R.BASE_DAMAGE = 3        -- bare hands
local MAX_DISTANCE = 8   -- owner must stay this close while using the menu
local ARMOR_POINT_REDUCTION = 4 -- % less damage per armor point
local MIN_FLESHY = 20    -- never more than 80% damage reduction
R.SHIELD_BLOCK = 0.5     -- share of damage a shield blocks from the front
local SHIELD_DURABILITY = 336
local FOOD_SLOTS = 3
local EAT_INTERVAL = 2   -- seconds between bites

local SINGLE_LISTS = {"weapon", "shield", "totem"}

local loaded = {} -- recruit id -> luaentity

local function inv_name(id) return "vl_recruits_" .. id end

local function recruit_for(inv)
	local id = inv:get_location().name:match("^vl_recruits_(.+)$")
	local self = id and loaded[id]
	if self and self.object:get_pos() then return self end
end

local function may_access(self, player)
	if not self or not player or player:get_player_name() ~= self.owner then return false end
	return vector.distance(player:get_pos(), self.object:get_pos()) <= MAX_DISTANCE
end

-- Item classification ----------------------------------------------------------

local function armor_index(stack)
	local def = stack:get_definition()
	local element = def and mcl_armor.elements[def._mcl_armor_element or ""]
	return element and element.index
end

function R.is_weapon(stack)
	local name = stack:get_name()
	if core.get_item_group(name, "sword") == 0 and core.get_item_group(name, "axe") == 0 then
		return false
	end
	local caps = stack:get_tool_capabilities()
	return caps and caps.damage_groups and (caps.damage_groups.fleshy or 0) > 0
end

function R.is_shield(stack)
	return core.get_item_group(stack:get_name(), "shield") > 0
end

function R.is_totem(stack)
	return stack:get_name() == "mcl_totems:totem"
end

-- Food that heals: group "eatable" = HP restored. Poisonous food and food that
-- leaves a container behind (stews, honey) is refused.
function R.food_value(stack)
	local name = stack:get_name()
	local heal = core.get_item_group(name, "eatable")
	if heal <= 0 then return 0 end
	local f = core.global_exists("mcl_hunger") and mcl_hunger.registered_foods[name]
	if f and (f.poisontime or (f.replace and f.replace ~= "")) then return 0 end
	return heal
end

function R.is_food(stack)
	return R.food_value(stack) > 0
end

-- Which list (and slot) an item belongs to; nil if it is no equipment.
local function slot_for(stack)
	local idx = armor_index(stack)
	if idx then return "armor", idx end
	if R.is_weapon(stack) then return "weapon", 1 end
	if R.is_shield(stack) then return "shield", 1 end
	if R.is_totem(stack) then return "totem", 1 end
	if R.is_food(stack) then return "food" end
end

-- Persistence --------------------------------------------------------------

local function save(self)
	local inv = self.inventory
	if not inv then return end
	self._armor = {}
	for i = 2, 5 do
		self._armor[i] = inv:get_stack("armor", i):to_string()
	end
	for _, list in ipairs(SINGLE_LISTS) do
		self["_" .. list] = inv:get_stack(list, 1):to_string()
	end
	self._food = {}
	for i = 1, FOOD_SLOTS do
		self._food[i] = inv:get_stack("food", i):to_string()
	end
end

-- Attached models (sword in the right hand, shield on the left arm) -----------

local function attach_model(self, field, entity, bone, pos, rot)
	local obj = self[field]
	if obj and obj:get_pos() then return obj end
	obj = core.add_entity(self.object:get_pos(), entity)
	if not obj then return end
	obj:set_attach(self.object, bone, pos, rot)
	self[field] = obj
	return obj
end

local function remove_model(self, field)
	if self[field] then
		self[field]:remove()
		self[field] = nil
	end
end

local function update_weapon(self)
	local stack = ItemStack(self._weapon or "")
	if not stack:is_empty() and R.is_weapon(stack) then
		self.damage = stack:get_tool_capabilities().damage_groups.fleshy
	else
		self.damage = R.BASE_DAMAGE
	end
	if stack:is_empty() then
		remove_model(self, "_wield_obj")
		return
	end
	local wield = attach_model(self, "_wield_obj", "vl_recruits:wield", "Wield_Item")
	if not wield then return end
	wield:set_properties({wield_item = stack:get_name()})
	-- Same hand pose the player model uses for tool-like items (mcl_playerplus).
	mcl_util.set_bone_position(self.object, "Wield_Item",
		vector.new(0, 4.7, 3.1), vector.new(-1.57, 3.93, 1.57))
end

-- Same texture rules as mcl_shields' own shield entity.
local function shield_texture(stack)
	local texture = "mcl_shield_base_nopattern.png"
	local name = stack:get_name()
	if name ~= "mcl_shields:shield" and name ~= "mcl_shields:shield_enchanted" then
		local custom = stack:get_meta():get_string("mcl_shields:shield_custom_pattern_texture")
		local color = core.registered_items[name] and core.registered_items[name]._shield_color
		if custom ~= "" then
			texture = custom
		elseif color then
			texture = texture .. "^(mcl_shield_pattern_base.png^[colorize:" .. color .. ")"
		end
	end
	if core.global_exists("mcl_enchanting") and mcl_enchanting.is_enchanted(name) then
		texture = texture .. mcl_enchanting.overlay
	end
	return texture
end

local function update_shield(self)
	local stack = ItemStack(self._shield or "")
	if stack:is_empty() then
		remove_model(self, "_shield_obj")
		return
	end
	-- Resting position of an off-hand shield on the player model (mcl_shields).
	local obj = attach_model(self, "_shield_obj", "vl_recruits:shield", "Arm_Left",
		vector.new(-3, -5, 0), vector.new(0, 180, 0))
	if obj then obj:set_properties({textures = {shield_texture(stack)}}) end
end

local function attached_model(def)
	def.physical = false
	def.pointable = false
	def.collide_with_objects = false
	def.static_save = false
	return {
		initial_properties = def,
		on_step = function(self)
			if not self.object:get_attach() then self.object:remove() end
		end,
	}
end

core.register_entity("vl_recruits:wield", attached_model({
	visual = "wielditem",
	visual_size = {x = 0.21, y = 0.21},
	wield_item = "",
}))

core.register_entity("vl_recruits:shield", attached_model({
	visual = "mesh",
	mesh = "mcl_shield.obj",
	textures = {"mcl_shield_base_nopattern.png"},
	visual_size = {x = 1, y = 1},
}))

-- Armor: texture layer and damage reduction (called from mcl_armor.update) --

function R.apply_armor(self, info)
	self.base_texture = self.base_texture or {}
	self.base_texture[2] = info.texture or "blank.png"
	self.object:set_properties({textures = self.base_texture})

	local groups
	if type(self.armor) == "table" then
		groups = table.copy(self.armor)
	else
		groups = {fleshy = self.armor or 100}
	end
	groups.immortal = 1 -- mcl_mobs does its own health handling
	groups.fleshy = math.max(MIN_FLESHY, (groups.fleshy or 100) - (info.points or 0) * ARMOR_POINT_REDUCTION)
	self.object:set_armor_groups(groups)
	self._armor_points = info.points or 0
end

local function refresh(self, listname, stack, removed)
	if listname == "armor" then
		if removed then
			mcl_armor.on_unequip(stack, self.object)
		else
			mcl_armor.on_equip(stack, self.object)
		end
	elseif listname == "weapon" then
		update_weapon(self)
	elseif listname == "shield" then
		update_shield(self)
	end
end

-- Detached inventory ---------------------------------------------------------

local callbacks = {
	allow_put = function(inv, listname, index, stack, player)
		local self = recruit_for(inv)
		if not may_access(self, player) then return 0 end
		local target, slot = slot_for(stack)
		if target ~= listname then return 0 end
		if listname == "food" then return stack:get_count() end
		if slot and slot ~= index then return 0 end
		return 1
	end,
	allow_take = function(inv, listname, index, stack, player)
		return may_access(recruit_for(inv), player) and stack:get_count() or 0
	end,
	allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		-- Only rearranging food is useful; everything else has a fixed slot.
		if from_list == "food" and to_list == "food" and may_access(recruit_for(inv), player) then
			return count
		end
		return 0
	end,
	on_put = function(inv, listname, index, stack)
		local self = recruit_for(inv)
		if not self then return end
		save(self)
		refresh(self, listname, stack, false)
	end,
	on_take = function(inv, listname, index, stack)
		local self = recruit_for(inv)
		if not self then return end
		save(self)
		refresh(self, listname, stack, true)
	end,
	on_move = function(inv)
		local self = recruit_for(inv)
		if self then save(self) end
	end,
}

-- Create (or return) the inventory of a loaded recruit and apply its gear.
function R.equipment_activate(self)
	local id = self._recruit_id
	if not id then return end
	if self.inventory and loaded[id] == self then return self.inventory end

	local name = inv_name(id)
	core.remove_detached_inventory(name)
	local inv = core.create_detached_inventory(name, callbacks)
	inv:set_size("armor", 5)
	for i, item in pairs(self._armor or {}) do
		inv:set_stack("armor", tonumber(i), ItemStack(item))
	end
	for _, list in ipairs(SINGLE_LISTS) do
		inv:set_size(list, 1)
		inv:set_stack(list, 1, ItemStack(self["_" .. list] or ""))
	end
	inv:set_size("food", FOOD_SLOTS)
	for i, item in pairs(self._food or {}) do
		inv:set_stack("food", tonumber(i), ItemStack(item))
	end
	self.inventory = inv
	loaded[id] = self

	mcl_armor.update(self.object)
	update_weapon(self)
	update_shield(self)
	return inv
end

function R.equipment_deactivate(self)
	local id = self._recruit_id
	if id and loaded[id] == self then
		loaded[id] = nil
		core.remove_detached_inventory(inv_name(id))
	end
	self.inventory = nil
	remove_model(self, "_wield_obj")
	remove_model(self, "_shield_obj")
end

-- Drop all gear at the recruit's position (death, dismissal).
function R.drop_equipment(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local items = {}
	for _, item in pairs(self._armor or {}) do items[#items + 1] = item end
	for _, list in ipairs(SINGLE_LISTS) do items[#items + 1] = self["_" .. list] end
	for _, item in pairs(self._food or {}) do items[#items + 1] = item end
	for _, item in ipairs(items) do
		if item and item ~= "" then
			core.add_item(vector.offset(pos, 0, 0.5, 0), ItemStack(item))
		end
	end
	self._armor, self._food = {}, {}
	for _, list in ipairs(SINGLE_LISTS) do self["_" .. list] = "" end
	local inv = self.inventory
	if inv then
		for _, list in ipairs({"armor", "weapon", "shield", "totem", "food"}) do
			local size = inv:get_size(list)
			inv:set_list(list, {})
			inv:set_size(list, size)
		end
	end
	remove_model(self, "_wield_obj")
	remove_model(self, "_shield_obj")
end

-- Right-click with equipment: equip it (old piece goes back to the player).
-- Food is added to the food slots, as much of the stack as fits.
function R.give_item(self, player, stack)
	local inv = R.equipment_activate(self)
	if not inv then return false end
	local listname, index = slot_for(stack)
	if not listname then return false end

	if listname == "food" then
		local leftover = inv:add_item("food", stack)
		if leftover:get_count() == stack:get_count() then
			core.chat_send_player(player:get_player_name(), S("The food bag is full."))
			return true
		end
		save(self)
		player:set_wielded_item(leftover)
		return true
	end

	local new = stack:take_item(1)
	local old = inv:get_stack(listname, index)
	inv:set_stack(listname, index, new)
	save(self)
	if not old:is_empty() then refresh(self, listname, old, true) end
	refresh(self, listname, new, false)

	player:set_wielded_item(stack)
	if not old:is_empty() then
		local leftover = player:get_inventory():add_item("main", old)
		if not leftover:is_empty() then
			core.add_item(player:get_pos(), leftover)
		end
	end
	return true
end

-- Shield: blocks part of the damage of hits from the front -------------------

-- Returns tool capabilities with reduced damage if the shield blocks the hit.
function R.shield_filter(self, hitter, caps)
	local inv = self.inventory
	if not inv or not hitter or not caps or not caps.damage_groups then return caps end
	local stack = inv:get_stack("shield", 1)
	if stack:is_empty() then return caps end

	local source = hitter
	local ent = hitter:get_luaentity()
	if ent and ent._shooter and ent._shooter.get_pos then source = ent._shooter end
	local spos, mypos = source:get_pos(), self.object:get_pos()
	if not spos or not mypos then return caps end
	local yaw = self.object:get_yaw() or 0
	local look = vector.new(-math.sin(yaw), 0, math.cos(yaw))
	if vector.dot(look, vector.subtract(spos, mypos)) <= 0 then return caps end

	local raw = caps.damage_groups.fleshy or 0
	local reduced = table.copy(caps)
	for group, value in pairs(caps.damage_groups) do
		reduced.damage_groups[group] = value * (1 - R.SHIELD_BLOCK)
	end

	core.sound_play({name = "mcl_block"}, {pos = mypos, max_hear_distance = 16}, true)
	if raw >= 3 then
		local durability = SHIELD_DURABILITY
		if core.global_exists("mcl_enchanting") then
			durability = durability * (mcl_enchanting.get_enchantment(stack, "unbreaking") + 1)
		end
		stack:add_wear(math.ceil(65535 / durability))
		if stack:is_empty() then
			core.sound_play("default_tool_breaks", {pos = mypos, max_hear_distance = 16}, true)
			core.chat_send_player(self.owner, S("A recruit's shield broke."))
		end
		inv:set_stack("shield", 1, stack)
		save(self)
		update_shield(self)
	end
	return reduced
end

-- Totem: saves the recruit from death once ------------------------------------

local TOTEM_COLORS = {"98BF22", "C49E09", "337D0B", "B0B021", "1E9200"}

function R.use_totem(self)
	local inv = self.inventory
	if not inv or not R.is_totem(inv:get_stack("totem", 1)) then return false end
	inv:set_stack("totem", 1, ItemStack(""))
	save(self)

	local pos = self.object:get_pos()
	core.sound_play({name = "mcl_totems_totem", gain = 1}, {pos = pos, max_hear_distance = 16}, true)
	for i = 1, 4 do
		for _, color in ipairs(TOTEM_COLORS) do
			core.add_particlespawner({
				amount = 5, time = 1,
				minpos = vector.offset(pos, -0.3, 0, -0.3), maxpos = vector.offset(pos, 0.3, 2, 0.3),
				minvel = vector.new(-1.5, 0, -1.5), maxvel = vector.new(1.5, 1.5, 1.5),
				minacc = vector.new(0, -0.1, 0), maxacc = vector.new(0, -1, 0),
				minexptime = 1, maxexptime = 3, minsize = 1, maxsize = 2,
				collisiondetection = true, collision_removal = true,
				texture = "mcl_particles_totem" .. i .. ".png^[colorize:#" .. color,
				glow = 10,
			})
		end
	end
	if core.global_exists("mcl_potions") then
		mcl_potions.give_effect_by_level("regeneration", self.object, 2, 45)
	end
	if self.owner and core.get_player_by_name(self.owner) then
		core.chat_send_player(self.owner, S("A totem saved one of your recruits from death!"))
	end
	return true
end

-- Food: the recruit heals itself when hurt -----------------------------------

function R.food_step(self, dtime)
	self._eat_timer = (self._eat_timer or 0) + dtime
	if self._eat_timer < EAT_INTERVAL then return end
	self._eat_timer = 0

	local inv = self.inventory
	if not inv or not self.health then return end
	local max = self.object:get_properties().hp_max or 20
	local missing = max - self.health
	if missing < 1 then return end

	for i = 1, FOOD_SLOTS do
		local stack = inv:get_stack("food", i)
		local heal = R.food_value(stack)
		-- Don't waste a big meal on a scratch, unless badly hurt.
		if heal > 0 and (heal <= missing or self.health <= max / 2) then
			local texture = stack:get_definition().inventory_image
			stack:take_item(1)
			inv:set_stack("food", i, stack)
			save(self)
			self.health = math.min(max, self.health + heal)
			local pos = self.object:get_pos()
			core.sound_play("mobs_mc_animal_eat_generic", {pos = pos, max_hear_distance = 12}, true)
			if texture and texture ~= "" then
				core.add_particlespawner({
					amount = 8, time = 0.3,
					minpos = vector.offset(pos, -0.2, 1.4, -0.2), maxpos = vector.offset(pos, 0.2, 1.6, 0.2),
					minvel = vector.new(-1, 1, -1), maxvel = vector.new(1, 2, 1),
					minacc = vector.new(0, -9.81, 0), maxacc = vector.new(0, -9.81, 0),
					minexptime = 0.5, maxexptime = 1, minsize = 1, maxsize = 2,
					texture = texture,
				})
			end
			return true
		end
	end
end

-- Equipment menu (sneak + right-click) --------------------------------------

function R.equipment_formspec(self)
	local inv = R.equipment_activate(self)
	if not inv then return end
	local loc = "detached:" .. inv_name(self._recruit_id)
	local damage = self.damage or R.BASE_DAMAGE
	local points = self._armor_points or 0
	local hp = math.floor((self.health or 0) + 0.5)
	local title = self.nametag ~= "" and self.nametag or S("Recruit")

	-- One row of recruit slots: armor (helmet, chestplate, leggings, boots),
	-- weapon, shield, totem, 3x food. Player inventory below, centered.
	local function slots(label, list, x, w, start)
		return table.concat({
			"label[", x, ",0.95;", F(label), "]",
			mcl_formspec.get_itemslot_bg_v4(x, 1.2, w, 1),
			"list[", loc, ";", list, ";", x, ",1.2;", w, ",1;", start or "", "]",
		})
	end
	local px = 1.075 -- (13.4 - 9 slots) / 2
	local fs = table.concat({
		"formspec_version[4]",
		"size[13.4,8.6]",
		"label[0.375,0.4;", F(title), "]",
		"label[6.2,0.4;", F(S("Health: @1/20", hp) .. "   " .. S("Armor points: @1", points)
			.. "   " .. S("Attack damage: @1", damage)), "]",
		slots(S("Armor"), "armor", 0.375, 4, 1),
		slots(S("Weapon"), "weapon", 5.475, 1),
		slots(S("Shield"), "shield", 6.825, 1),
		slots(S("Totem"), "totem", 8.175, 1),
		slots(S("Food"), "food", 9.525, 3),
		"label[", px, ",2.95;", F(S("Your inventory")), "]",
		mcl_formspec.get_itemslot_bg_v4(px, 3.2, 9, 3),
		"list[current_player;main;", px, ",3.2;9,3;9]",
		mcl_formspec.get_itemslot_bg_v4(px, 7.1, 9, 1),
		"list[current_player;main;", px, ",7.1;9,1;]",
		-- Shift-click moves food between bag and inventory.
		"listring[", loc, ";food]",
		"listring[current_player;main]",
	})
	return fs
end

function R.show_equipment(self, player)
	local fs = R.equipment_formspec(self)
	if fs then
		core.show_formspec(player:get_player_name(), "vl_recruits:equipment", fs)
	end
end
