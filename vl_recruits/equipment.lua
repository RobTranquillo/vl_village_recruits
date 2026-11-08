-- Recruit equipment: armor (via mcl_armor) and one melee weapon.
-- Each loaded recruit gets a detached inventory "vl_recruits_<id>" with the
-- lists "armor" (5 slots, mcl_armor uses 2..5) and "weapon" (1 slot).
-- Contents are mirrored into self._armor / self._weapon, which mcl_mobs
-- saves with the entity's staticdata.
local R = vl_recruits
local S = R.S
local F = core.formspec_escape

R.BASE_DAMAGE = 3       -- bare hands
local MAX_DISTANCE = 8  -- owner must stay this close while using the menu
local ARMOR_POINT_REDUCTION = 4 -- % less damage per armor point
local MIN_FLESHY = 20   -- never more than 80% damage reduction

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

local function save(self)
	local inv = self.inventory
	if not inv then return end
	self._armor = {}
	for i = 2, 5 do
		self._armor[i] = inv:get_stack("armor", i):to_string()
	end
	self._weapon = inv:get_stack("weapon", 1):to_string()
end

-- Weapon: damage and the item shown in the hand ----------------------------

local function update_weapon(self)
	local stack = ItemStack(self._weapon or "")
	if not stack:is_empty() and R.is_weapon(stack) then
		self.damage = stack:get_tool_capabilities().damage_groups.fleshy
	else
		self.damage = R.BASE_DAMAGE
	end

	local wield = self._wield_obj
	if stack:is_empty() then
		if wield then wield:remove() end
		self._wield_obj = nil
		return
	end
	if not wield or not wield:get_pos() then
		wield = core.add_entity(self.object:get_pos(), "vl_recruits:wield")
		if not wield then return end
		wield:set_attach(self.object, "Wield_Item")
		self._wield_obj = wield
	end
	wield:set_properties({wield_item = stack:get_name()})
	-- Same hand pose the player model uses for tool-like items (mcl_playerplus).
	mcl_util.set_bone_position(self.object, "Wield_Item",
		vector.new(0, 4.7, 3.1), vector.new(-1.57, 3.93, 1.57))
end

core.register_entity("vl_recruits:wield", {
	initial_properties = {
		visual = "wielditem",
		visual_size = {x = 0.21, y = 0.21},
		physical = false,
		pointable = false,
		collide_with_objects = false,
		static_save = false,
		wield_item = "",
	},
	on_step = function(self)
		if not self.object:get_attach() then self.object:remove() end
	end,
})

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

-- Detached inventory ---------------------------------------------------------

local callbacks = {
	allow_put = function(inv, listname, index, stack, player)
		local self = recruit_for(inv)
		if not may_access(self, player) then return 0 end
		if listname == "armor" then
			return armor_index(stack) == index and 1 or 0
		elseif listname == "weapon" then
			return R.is_weapon(stack) and 1 or 0
		end
		return 0
	end,
	allow_take = function(inv, listname, index, stack, player)
		return may_access(recruit_for(inv), player) and stack:get_count() or 0
	end,
	allow_move = function() return 0 end,
	on_put = function(inv, listname, index, stack)
		local self = recruit_for(inv)
		if not self then return end
		save(self)
		if listname == "armor" then
			mcl_armor.on_equip(stack, self.object)
		else
			update_weapon(self)
		end
	end,
	on_take = function(inv, listname, index, stack)
		local self = recruit_for(inv)
		if not self then return end
		save(self)
		if listname == "armor" then
			mcl_armor.on_unequip(stack, self.object)
		else
			update_weapon(self)
		end
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
	inv:set_size("weapon", 1)
	for i, item in pairs(self._armor or {}) do
		inv:set_stack("armor", tonumber(i), ItemStack(item))
	end
	inv:set_stack("weapon", 1, ItemStack(self._weapon or ""))
	self.inventory = inv
	loaded[id] = self

	mcl_armor.update(self.object)
	update_weapon(self)
	return inv
end

function R.equipment_deactivate(self)
	local id = self._recruit_id
	if id and loaded[id] == self then
		loaded[id] = nil
		core.remove_detached_inventory(inv_name(id))
	end
	self.inventory = nil
	if self._wield_obj then
		self._wield_obj:remove()
		self._wield_obj = nil
	end
end

-- Drop all gear at the recruit's position (death, dismissal).
function R.drop_equipment(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local items = {}
	for _, item in pairs(self._armor or {}) do items[#items + 1] = item end
	items[#items + 1] = self._weapon
	for _, item in ipairs(items) do
		if item and item ~= "" then
			core.add_item(vector.offset(pos, 0, 0.5, 0), ItemStack(item))
		end
	end
	self._armor, self._weapon = {}, ""
	if self.inventory then
		self.inventory:set_list("armor", {})
		self.inventory:set_size("armor", 5)
		self.inventory:set_list("weapon", {})
		self.inventory:set_size("weapon", 1)
	end
end

-- Right-click with armor or a weapon: equip it, give the old piece back.
function R.give_item(self, player, stack)
	local inv = R.equipment_activate(self)
	if not inv then return false end
	local listname, index
	if armor_index(stack) then
		listname, index = "armor", armor_index(stack)
	elseif R.is_weapon(stack) then
		listname, index = "weapon", 1
	else
		return false
	end

	local new = stack:take_item(1)
	local old = inv:get_stack(listname, index)
	inv:set_stack(listname, index, new)
	save(self)
	if listname == "armor" then
		if not old:is_empty() then mcl_armor.on_unequip(old, self.object) end
		mcl_armor.on_equip(new, self.object)
	else
		update_weapon(self)
	end

	player:set_wielded_item(stack)
	if not old:is_empty() then
		local leftover = player:get_inventory():add_item("main", old)
		if not leftover:is_empty() then
			core.add_item(player:get_pos(), leftover)
		end
	end
	return true
end

-- Equipment menu (sneak + right-click) --------------------------------------

function R.show_equipment(self, player)
	local inv = R.equipment_activate(self)
	if not inv then return end
	local loc = "detached:" .. inv_name(self._recruit_id)
	local damage = self.damage or R.BASE_DAMAGE
	local points = self._armor_points or 0
	local hp = math.floor((self.health or 0) + 0.5)
	local title = self.nametag ~= "" and self.nametag or S("Recruit")
	local fs = table.concat({
		"formspec_version[4]",
		"size[11.75,10.9]",
		"label[0.375,0.5;", F(title), "]",
		"label[0.375,1.0;", F(S("Armor")), "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 1.3, 1, 4),
		"list[", loc, ";armor;0.375,1.3;1,4;1]",
		"label[2.2,1.0;", F(S("Weapon")), "]",
		mcl_formspec.get_itemslot_bg_v4(2.2, 1.3, 1, 1),
		"list[", loc, ";weapon;2.2,1.3;1,1;]",
		"label[4.2,1.6;", F(S("Health: @1/20", hp)), "]",
		"label[4.2,2.1;", F(S("Armor points: @1", points)), "]",
		"label[4.2,2.6;", F(S("Attack damage: @1", damage)), "]",
		"label[0.375,6.6;", F(S("Inventory")), "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 6.9, 9, 3),
		"list[current_player;main;0.375,6.9;9,3;9]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 9.75, 9, 1),
		"list[current_player;main;0.375,9.75;9,1;]",
		"listring[", loc, ";armor]",
		"listring[current_player;main]",
		"listring[", loc, ";weapon]",
		"listring[current_player;main]",
	})
	core.show_formspec(player:get_player_name(), "vl_recruits:equipment", fs)
end
