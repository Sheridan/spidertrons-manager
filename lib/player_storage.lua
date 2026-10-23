local PStorage = {}

local STORAGE_KEY = "spidertron_manager_data"

local function get_root_index(player)
  if player ~= nil then
    return player.index
  end
  return "global"
end

-- Simple storage data

local function get_player_data(root_index, create)
  local root = storage[STORAGE_KEY]

  if root == nil then
    if not create then
      return nil
    end

    root = {}
    storage[STORAGE_KEY] = root
  end

  local player_data = root[root_index]

  if player_data == nil and create then
    player_data = {}
    root[root_index] = player_data
  end

  return player_data
end

local function cleanup_player_data(root_index)
  local root = storage[STORAGE_KEY]

  if root == nil then
    return
  end

  local player_data = root[root_index]

  if player_data ~= nil and next(player_data) == nil then
    root[root_index] = nil
  end

  if next(root) == nil then
    storage[STORAGE_KEY] = nil
  end
end

function PStorage.save_player_data(player, option_name, option_value)
  local root_index = get_root_index(player)
  local player_data = get_player_data(root_index, true)
  player_data[option_name] = option_value
end

function PStorage.exists_player_data(player, option_name)
  local root_index = get_root_index(player)
  local player_data = get_player_data(root_index, false)

  return player_data ~= nil and player_data[option_name] ~= nil
end

function PStorage.load_player_data(player, option_name, default_value)
  local root_index = get_root_index(player)
  local player_data = get_player_data(root_index, false)

  if player_data ~= nil and player_data[option_name] ~= nil then
    return player_data[option_name]
  end

  return default_value
end

function PStorage.rm_player_data(player, option_name)
  local root_index = get_root_index(player)
  local player_data = get_player_data(root_index, false)

  if player_data ~= nil then
    player_data[option_name] = nil
    cleanup_player_data(root_index)
  end
end

-- Associative arrays substorage data

local function get_group_data(root_index, group_name, create)
  local player_data = get_player_data(root_index, create)

  if player_data == nil then
    return nil
  end

  local group_data = player_data[group_name]

  if group_data == nil and create then
    group_data = {}
    player_data[group_name] = group_data
  end

  return group_data
end

function PStorage.save_group_data(player, option_name, group_name, option_value)
  local root_index = get_root_index(player)
  local group_data = get_group_data(root_index, group_name, true)
  group_data[option_name] = option_value
end

function PStorage.exists_group_data(player, option_name, group_name)
  local root_index = get_root_index(player)
  local group_data = get_group_data(root_index, group_name, false)
  return group_data ~= nil and group_data[option_name] ~= nil
end

function PStorage.load_group_data(player, option_name, group_name, default_value)
  local root_index = get_root_index(player)
  local group_data = get_group_data(root_index, group_name, false)

  if group_data ~= nil and group_data[option_name] ~= nil then
    return group_data[option_name]
  end

  return default_value
end

function PStorage.rm_group_data(player, option_name, group_name)
  local root_index = get_root_index(player)
  local player_data = get_player_data(root_index, false)

  if player_data == nil then
    return
  end

  local group_data = player_data[group_name]

  if group_data ~= nil then
    group_data[option_name] = nil

    if next(group_data) == nil then
      player_data[group_name] = nil
    end
  end

  if next(player_data) == nil then
    cleanup_player_data(root_index)
  end
end

return PStorage
