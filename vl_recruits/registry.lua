-- Which recruits belong to whom. Persisted in mod storage as
-- "owner:<player>" -> serialized set of recruit ids.
local R = vl_recruits

local function key(owner) return "owner:" .. owner end

local function load(owner)
	return core.deserialize(R.storage:get_string(key(owner))) or {}
end

local function save(owner, set)
	if next(set) then
		R.storage:set_string(key(owner), core.serialize(set))
	else
		R.storage:set_string(key(owner), "")
	end
end

function R.count(owner)
	local n = 0
	for _ in pairs(load(owner)) do n = n + 1 end
	return n
end

function R.register(owner, id)
	local set = load(owner)
	set[id] = true
	save(owner, set)
end

function R.unregister(owner, id)
	if not owner or owner == "" or not id then return end
	local set = load(owner)
	set[id] = nil
	save(owner, set)
end

-- Loaded (active) recruit entities of a player, optionally within radius of pos.
function R.active_recruits(owner, pos, radius)
	local list = {}
	for _, ent in pairs(core.luaentities) do
		if ent.name == R.ENTITY and ent.owner == owner and ent.object:get_pos() then
			if not pos or vector.distance(pos, ent.object:get_pos()) <= radius then
				list[#list + 1] = ent
			end
		end
	end
	return list
end
