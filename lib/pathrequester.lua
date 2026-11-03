local player_storage = require("lib.player_storage")
local scheduler = require("lib.scheduler")

local CPathRequester = {}
CPathRequester.__index = CPathRequester

local MAX_GAP = 10
local mask_cache = {}

function CPathRequester:new(spidertron, goal_position, after_ticks)
  local instance = setmetatable({}, {__index = self})
  instance._spidertron = spidertron
  instance._goal_position = goal_position
  scheduler:one_shoot(instance, after_ticks)
  -- log("Requested path after " .. after_ticks .. " ticks")
  return instance
end

function CPathRequester:_spidertron_collision_mask()
  local prototype_name = self._spidertron.prototype.name
  if mask_cache[prototype_name] == nil then
    local original_mask = self._spidertron.prototype.collision_mask
    local mask = {
      layers = {},
      not_colliding_with_itself = original_mask and original_mask.not_colliding_with_itself or false
    }
    if original_mask and original_mask.layers then
      for layer, val in pairs(original_mask.layers) do
        mask.layers[layer] = val
      end
    end
    mask.layers["water_tile"] = true
    mask.layers["lava_tile"] = true
    mask_cache[prototype_name] = mask
  end
  return mask_cache[prototype_name]
end

function CPathRequester:valid()
  return self._spidertron and self._spidertron.valid
end

function CPathRequester:update()
  -- log("Requesting path...")
  local path_id = self._spidertron.surface.request_path{
    bounding_box        = self._spidertron.prototype.collision_box,
    collision_mask      = self:_spidertron_collision_mask(),
    start               = self._spidertron.position,
    goal                = self._goal_position,
    force               = self._spidertron.force,
    radius              = 4,
    entity_to_ignore    = self._spidertron,
    max_gap_size        = MAX_GAP,
    max_attack_distance = MAX_GAP,
    pathfind_flags      = {
      cache                            = false,
      prefer_straight_paths            = false,
      allow_paths_through_own_entities = true
    }
  }
  if not path_id then return end

  local path_data = {
    spidertron_unit = self._spidertron.unit_number,
    goal = self._goal_position
  }
  player_storage:save_path_request(path_id, path_data)
end


return CPathRequester
