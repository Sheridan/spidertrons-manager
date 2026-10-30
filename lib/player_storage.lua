require("constants")
require("lib.math")

local Singleton = require("lib.singleton")
local CPlayerStorage = Singleton.derive("CPlayerStorage")

-- function CPlayerStorage:_init()

-- end

-- === BASE GENERIC ===

function CPlayerStorage:_root(key)
  if storage[STORAGE_NAME] == nil then storage[STORAGE_NAME] = {} end
  if storage[STORAGE_NAME][key] == nil then storage[STORAGE_NAME][key] = {} end
  return storage[STORAGE_NAME][key]
end

-- === PLAYER GENERIC ===

function CPlayerStorage:_player_root(player)
  local key = "unknown"
  if player ~= nil then
    key = player.index
  end
  local root = self:_root("player")
  if root[key] == nil then root[key] = {} end
  return root[key]
end

function CPlayerStorage:_exists_player_data(player, name)
  return self:_player_root(player)[name] ~= nil
end

function CPlayerStorage:_save_player_data(player, name, value)
  self:_player_root(player)[name] = value
end

function CPlayerStorage:_load_player_data(player, name, default)
  if self:_exists_player_data(player, name) then return self:_player_root(player)[name] end
  return default
end

function CPlayerStorage:_rm_player_data(player, name)
  self:_player_root(player)[name] = nil
end

-- === SQUAD GENERIC ===
function CPlayerStorage:_squads_root()
  return self:_root("squads")
end

function CPlayerStorage:_squad_root(surface_name, squad_name)
  local squads_root = self:_squads_root()
  if squads_root[surface_name] == nil then squads_root[surface_name] = {} end
  if squads_root[surface_name][squad_name] == nil then squads_root[surface_name][squad_name] = {} end
  return squads_root[surface_name][squad_name]
end

function CPlayerStorage:_squad_data_exists(surface_name, squad_name, name)
  local squads_root = self:_squads_root()
  if squads_root[surface_name] == nil then return false end
  if squads_root[surface_name][squad_name] == nil then return false end
  return squads_root[surface_name][squad_name][name] ~= nil
end

function CPlayerStorage:_save_squad_data(surface_name, squad_name, name, value)
  self:_squad_root(surface_name, squad_name)[name] = value
end

function CPlayerStorage:_load_squad_data(surface_name, squad_name, name, default)
  if self:_squad_data_exists(surface_name, squad_name, name) then return self:_squad_root(surface_name, squad_name)[name] end
  return default
end

function CPlayerStorage:_rm_squad_data(surface_name, squad_name, name)
  if self:_squad_data_exists(surface_name, squad_name, name) then self:_squad_root(surface_name, squad_name)[name] = nil end
end

-- === SPIDERTRON GENERIC ===

function CPlayerStorage:_spidertrons_root()
  return self:_root("spidertrons")
end

function CPlayerStorage:_spidertron_root(spidertron)
  local spidertrons_root = self:_spidertrons_root()
  if spidertrons_root[spidertron.unit_number] == nil then spidertrons_root[spidertron.unit_number] = {} end
  return spidertrons_root[spidertron.unit_number]
end

function CPlayerStorage:_spidertron_data_exists(spidertron, name)
  return self:_spidertron_root(spidertron)[name] ~= nil
end

function CPlayerStorage:_save_spidertron_data(spidertron, name, value)
  self:_spidertron_root(spidertron)[name] = value
end

function CPlayerStorage:_load_spidertron_data(spidertron, name, default)
  if self:_spidertron_data_exists(spidertron, name) then return self:_spidertron_root(spidertron)[name] end
  return default
end

function CPlayerStorage:_rm_spidertron_data(spidertron, name)
  if self:_spidertron_data_exists(spidertron, name) then self:_spidertron_root(spidertron)[name] = nil end
end

---------------------------------
--- User methods
---------------------------------

function CPlayerStorage:load_window_position(player)
  return self:_load_player_data(player, "window_position", nil)
end

function CPlayerStorage:save_window_position(player, position)
  return self:_save_player_data(player, "window_position", position)
end

function CPlayerStorage:load_use_pathfinding(player)
  local result = self:_load_player_data(player, "use_pathfinding", nil)
  self:_rm_player_data(player, "use_pathfinding")
  return result ~= nil and result
end

function CPlayerStorage:save_use_pathfinding(player, value)
  return self:_save_player_data(player, "use_pathfinding", value)
end


---

function CPlayerStorage:_path_requests_root()
  return self:_root("path_requests")
end

function CPlayerStorage:save_path_request(path_id, path_data)
  self:_path_requests_root()[path_id] = path_data
end

function CPlayerStorage:exists_path_request(path_id)
  return self:_path_requests_root()[path_id] ~= nil
end

function CPlayerStorage:load_path_request(path_id)
  local result = self:_path_requests_root()[path_id]
  self:_path_requests_root()[path_id] = nil
  return result
end

---

function CPlayerStorage:save_follower(spidertron, data)
  self:_save_spidertron_data(spidertron, "follow_me", data)
end

function CPlayerStorage:load_follower(spidertron)
  return self:_load_spidertron_data(spidertron, "follow_me", nil)
end

function CPlayerStorage:rm_follower(spidertron)
  self:_rm_spidertron_data(spidertron, "follow_me")
end

---

function CPlayerStorage:save_home(surface_name, squad_name, area, as_point)
  local home_data
  if as_point then
    home_data = {
      type = "point",
      position = get_area_center(area)
    }
  else
    home_data = {
      type = "area",
      area = area
    }
  end

  self:_save_squad_data(surface_name, squad_name, "home", home_data)
end

function CPlayerStorage:load_home(surface_name, squad_name)
  return self:_load_squad_data(surface_name, squad_name, "home", nil)
end

return CPlayerStorage.get_instance()
