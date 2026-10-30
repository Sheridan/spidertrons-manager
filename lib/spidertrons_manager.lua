require("lib.math")
require("lib.string_util")

local player_storage = require("lib.player_storage")
local Singleton = require("lib.singleton")

local CSpidertronsManager = {}
CSpidertronsManager.__index = CSpidertronsManager

local CSpidertronsManager = Singleton.derive("CSpidertronsManager")

function CSpidertronsManager:_init()
  self:reset_selection()
  self._squads = {}
end

function CSpidertronsManager:select_squad(surface, squad_name)
  self._selected_squad = {
    surface = surface,
    squad_name = squad_name
  }
end
function CSpidertronsManager:selected_squad() return self._selected_squad end

function CSpidertronsManager:select_spidertron(spidertron) self._selected_spidertron = spidertron end
function CSpidertronsManager:selected_spidertron() return self._selected_spidertron end

function CSpidertronsManager:reset_selection()
  self._selected_squad = nil
  self._selected_spidertron = nil
end

function CSpidertronsManager:spidertrons_exists()
  return next(self._squads) ~= nil
end

function CSpidertronsManager:load_spidertrons(player, spidertron_id_for_ignore)
  self._squads = {}
  for _, surface in pairs(game.surfaces) do
    -- log(surface.name)
    local squad = self:find_spidertrons(player, spidertron_id_for_ignore, surface)
    if next(squad) ~= nil then
      self._squads[surface.name] = squad
    end
  end
  return self:spidertrons_exists()
end

function CSpidertronsManager:spidertron_name(spidertron)
  if spidertron.entity_label then return spidertron.entity_label end
  return spidertron.name
end

function CSpidertronsManager:spidertrons_exists_on_surface(surface)
  return self._squads[surface.name] ~= nil
end

function CSpidertronsManager:get_surface_squads(surface)
  return self._squads[surface.name]
end

function CSpidertronsManager:get_squad(surface, squad_name)
  if type(surface) == "string" then
    surface = game.surfaces[surface]
  end
  return self:get_surface_squads(surface)[squad_name]
end

function CSpidertronsManager:squad_leader(surface, squad_name)
  return self:get_squad(surface, squad_name)[1]
end

function CSpidertronsManager:find_spidertrons(player, spidertron_id_for_ignore, surface)
  local surface = surface or player.surface
  local spidertrons_squads = {}
  local surface_spidertrons = surface.find_entities_filtered{type = "spider-vehicle", to_be_deconstructed = false, force = player.force}
  table.sort(surface_spidertrons, function(a,b) return self:spidertron_name(a) < self:spidertron_name(b) end)
  for _, spidertron in pairs(surface_spidertrons) do
    if spidertron.valid then
      if spidertron_id_for_ignore == nil or spidertron.unit_number ~= spidertron_id_for_ignore then
        local squad_name = self:spidertron_name(spidertron)
        -- log(squad_name)
        if not spidertrons_squads[squad_name] then
          spidertrons_squads[squad_name] = {}
        end
        table.insert(spidertrons_squads[squad_name], spidertron)
        -- game.print("Found unit: " .. spidertron.unit_number)
      end
    end
  end
  return spidertrons_squads
end

function CSpidertronsManager:view_squad(player, surface_name, squad_name)
  player.centered_on = self:squad_leader(surface_name, squad_name)
end

function CSpidertronsManager:control_squad(player, surface_name, squad_name)
  local leader = self:squad_leader(surface_name, squad_name)
  local squad = self:get_squad(surface_name, squad_name)
  for _, spidertron in ipairs(squad) do
    if spidertron.unit_number ~= leader.unit_number then
      spidertron.follow_target = leader
    end
  end
  self:view_squad(player, surface_name, squad_name)
  leader.set_driver(player)
end

function CSpidertronsManager:follow_me(player, surface_name, squad_name, use_pathfinding)
  if player and player.character then
    local spidertrons = self:get_squad(surface_name, squad_name)
    if not spidertrons then return end
    for _, spidertron in ipairs(spidertrons) do
      if spidertron.valid then
        if use_pathfinding then
          self:request_spidertron_path(spidertron, player.character.position)
          local data = {
            player_index = player.index,
            goal = player.character.position,
            use_pathfinding = use_pathfinding,
            surface_name = surface_name,
            squad_name = squad_name
          }
          player_storage:save_follower(spidertron, data)
        else
          spidertron.follow_target = player.character
        end
      end
    end
  end
end

function CSpidertronsManager:path_request_complete(request_id, path, try_again_later)
    if not player_storage:exists_path_request(request_id) then return end
  local req = player_storage:load_path_request(request_id)

  local spidertron = game.get_entity_by_unit_number(req.spidertron_unit)
  if not spidertron or not spidertron.valid then return end

  if try_again_later then
    spidertron.autopilot_destination = req.goal -- need to shedule another try
    return
  end
  if path and #path > 0 then
    spidertron.autopilot_destination = path[1].position
    for i = 2, #path do
      spidertron.add_autopilot_destination(path[i].position)
    end
  else
    spidertron.autopilot_destination = req.goal
  end
end

function CSpidertronsManager:follow_me_done(spidertron)
  if #spidertron.autopilot_destinations > 0 then return end
  local data = player_storage:load_follower(spidertron)
  player_storage:rm_follower(spidertron)
  if not data then return end
  -- log(data.squad_name)
  local player = game.players[data.player_index]
  if player and player.valid and player.character and player.character.valid then
    -- log(distance_squared(spidertron.position, player.character.position))
    if distance_squared(spidertron.position, player.character.position) > 256 then
      self:follow_me(player, data.surface_name, data.squad_name, data.use_pathfinding)
      return
    end
    spidertron.follow_target = player.character
  end
end

function CSpidertronsManager:apply_settings_to_squad(player)
  local selected = self:selected_squad()
  local spidertrons = self:get_squad(selected.surface, selected.squad_name)
  if #spidertrons > 1 then
    local src_spidertron = self:selected_spidertron()
    if src_spidertron then
      for _, spidertron in ipairs(spidertrons) do
        spidertron.copy_settings(src_spidertron, player)
      end
    end
  end
  self:reset_selection()
end

function CSpidertronsManager:request_spidertron_path(spidertron, goal_position)
  if not spidertron or not spidertron.valid then return end
  local surface = spidertron.surface
  local MAX_GAP = 10
  local original_mask = spidertron.prototype.collision_mask
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

  local path_id = surface.request_path{
    bounding_box = spidertron.prototype.collision_box,
    collision_mask = mask,
    start = spidertron.position,
    goal = goal_position,
    force = spidertron.force,
    radius = 4,
    entity_to_ignore = spidertron,
    max_gap_size = MAX_GAP,
    max_attack_distance = MAX_GAP,
    pathfind_flags = {
      cache = false,
      prefer_straight_paths = false,
      allow_paths_through_own_entities = true
    }
  }
  if not path_id then return end

  local path_data = {
    spidertron_unit = spidertron.unit_number,
    goal = goal_position
  }
  player_storage:save_path_request(path_id, path_data)
end

return CSpidertronsManager.get_instance()
