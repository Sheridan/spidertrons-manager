require("lib.math")
require("lib.string_util")
require("lib.game")
require("lib.debug")

local player_storage = require("lib.player_storage")
local Singleton = require("lib.singleton")

local CSpidertronsManager = {}
CSpidertronsManager.__index = CSpidertronsManager

local CSpidertronsManager = Singleton.derive("CSpidertronsManager")

function CSpidertronsManager:_init()
  self:reset_selection()
  self._squads = {}
end
---
--- selection
---
function CSpidertronsManager:select_squad(squad) self._selected_squad = squad end
function CSpidertronsManager:selected_squad() return self._selected_squad end
function CSpidertronsManager:select_spidertron(spidertron) self._selected_spidertron = spidertron end
function CSpidertronsManager:selected_spidertron() return self._selected_spidertron end
function CSpidertronsManager:reset_selection()
  self._selected_squad = nil
  self._selected_spidertron = nil
end

---
--- loading
---

function CSpidertronsManager:add_to_squad(surface, squad_name, spidertron)
  if self._squads[surface.name] == nil then self._squads[surface.name] = { surface = surface, squads = {}} end
  if self._squads[surface.name].squads[squad_name] == nil then self._squads[surface.name].squads[squad_name] = { surface = surface, squad_name = squad_name, spidertrons = {}} end
  table.insert(self._squads[surface.name].squads[squad_name].spidertrons, spidertron)
end

function CSpidertronsManager:find_spidertrons(player, spidertron_id_for_ignore, surface)
  local surface = as_surface(surface) or player.surface
  local surface_spidertrons = surface.find_entities_filtered{type = "spider-vehicle", to_be_deconstructed = false, force = player.force}
  table.sort(surface_spidertrons, function(a,b) return self:spidertron_name(a) < self:spidertron_name(b) end)
  for _, spidertron in pairs(surface_spidertrons) do
    if spidertron.valid then
      if spidertron_id_for_ignore == nil or spidertron.unit_number ~= spidertron_id_for_ignore then
        local squad_name = self:spidertron_name(spidertron)
        self:add_to_squad(surface, squad_name, spidertron)
      end
    end
  end
end

function CSpidertronsManager:load_spidertrons(player, spidertron_id_for_ignore)
  self._squads = {}
  for _, surface in pairs(game.surfaces) do
    self:find_spidertrons(player, spidertron_id_for_ignore, surface)
  end
  -- sm_log_found_squads(self._squads)
  -- sm_log("Spidertrons loaded")
  return self:spidertrons_exists()
end

---
--- extract data helpers
---

function CSpidertronsManager:spidertron_name(spidertron)
  if spidertron.entity_label then return spidertron.entity_label end
  return spidertron.name
end

function CSpidertronsManager:spidertrons_exists_on_surface(surface)
  local surface_data = self._squads[as_surface(surface).name]
	return surface_data ~= nil and next(surface_data.squads) ~= nil
end

function CSpidertronsManager:spidertrons_exists()
  for _, surface in pairs(game.surfaces) do
    if self:spidertrons_exists_on_surface(surface) then return true end
  end
  return false
end

function CSpidertronsManager:get_surface_squads(surface)
  return self._squads[as_surface(surface).name].squads
end

function CSpidertronsManager:get_squad(surface, squad_name)
  return self:get_surface_squads(as_surface(surface))[squad_name]
end

function CSpidertronsManager:squad_leader(squad)
  return squad.spidertrons[1]
end

function CSpidertronsManager:squad_valid(squad)
  return squad ~= nil and  squad.spidertrons and #squad.spidertrons > 0
end

function CSpidertronsManager:squad_exists(surface, squad_name)
  surface = as_surface(surface)
  return self._squads[surface.name] ~= nil and self._squads[surface.name].squads[squad_name] ~= nil and self:squad_valid(self:get_squad(surface, squad_name))
end


function CSpidertronsManager:squad_bounding_box(surface, squad_name)
  local squad = self:get_squad(surface, squad_name)
  local positions = {}
  for _, spidertron in ipairs(squad.spidertrons) do
    table.insert(positions, spidertron.position)
  end
  local bounding_box = get_bounding_box(positions)
  local collision_box = self:squad_leader(squad).prototype.collision_box

  local cb_width  = collision_box.right_bottom.x - collision_box.left_top.x
  local cb_height = collision_box.right_bottom.y - collision_box.left_top.y

  return {
      left_top = {
        x = bounding_box.left_top.x - cb_width,
        y = bounding_box.left_top.y - cb_height },
      right_bottom = {
        x = bounding_box.right_bottom.x + cb_width,
        y = bounding_box.right_bottom.y + cb_height  }
    }
end

---
--- mod target methods
---

function CSpidertronsManager:view_squad(player, surface, squad_name)
  player.centered_on = self:squad_leader(self:get_squad(surface, squad_name))
end

function CSpidertronsManager:control_squad(player, surface, squad_name)
  local squad = self:get_squad(surface, squad_name)
  local leader = self:squad_leader(squad)
  for _, spidertron in ipairs(squad.spidertrons) do
    if spidertron.unit_number ~= leader.unit_number then
      spidertron.follow_target = leader
    end
  end
  self:view_squad(player, surface, squad_name)
  leader.set_driver(player)
end

function CSpidertronsManager:store_home(area)
  local squad = self:selected_squad()

  if self:squad_valid(squad) then
    if entity_bigger_than_area(area, squad.spidertrons[1].prototype.collision_box) then
      player_storage:save_home(squad.surface.name, squad.squad_name, area, false)
    else
      player_storage:save_home(squad.surface.name, squad.squad_name, area, true)
    end
  else
    player_storage:save_home(squad.surface.name, squad.squad_name, area, true)
  end
  self:reset_selection()
end

function CSpidertronsManager:apply_settings_to_squad(player)
  local squad = self:selected_squad()
  if #squad.spidertrons > 1 then
    local src_spidertron = self:selected_spidertron()
    if src_spidertron then
      for _, spidertron in ipairs(squad.spidertrons) do
        spidertron.copy_settings(src_spidertron, player)
      end
    end
  end
  self:reset_selection()
end

---
--- movement
---

function CSpidertronsManager:go_location(player, area, position)
  local squad = self:selected_squad()
  if self:squad_valid(squad) then
    local use_pathfinding = player_storage:load_use_pathfinding(player)
    local positions = {}
    local is_area = entity_bigger_than_area(area, squad.spidertrons[1].prototype.collision_box)
    if is_area then
      positions = calculate_grid_positions(area, #squad.spidertrons)
    else
      local target_pos = position or get_area_center(area)
      for _ = 1, #squad.spidertrons do
        table.insert(positions, target_pos)
      end
    end
    for i, spidertron in ipairs(squad.spidertrons) do
      if spidertron.valid and positions[i] then
        if use_pathfinding then
          self:request_spidertron_path(spidertron, positions[i])
        else
          spidertron.autopilot_destination = positions[i]
        end
      end
    end
  end
  self:reset_selection()
end

function CSpidertronsManager:go_home(surface, squad_name, use_pathfinding)
  local home_data = player_storage:load_home(surface.name, squad_name)
  if not home_data then return end
  local spidertrons = self:get_squad(surface, squad_name).spidertrons
  if #spidertrons == 0 then return end
  local positions = {}
  if home_data.type == "area" and home_data.area then
    positions = calculate_grid_positions(home_data.area, #spidertrons)
  else
    local target_pos = home_data.position or home_data
    for _ = 1, #spidertrons do
      table.insert(positions, target_pos)
    end
  end
  for i, spidertron in ipairs(spidertrons) do
    if spidertron.valid and positions[i] then
      if use_pathfinding then
        self:request_spidertron_path(spidertron, positions[i])
      else
        spidertron.autopilot_destination = positions[i]
      end
    end
  end
end

function CSpidertronsManager:follow_me(player, surface, squad_name, use_pathfinding)
  if player and player.character then
    local squad = self:get_squad(surface, squad_name)
    for _, spidertron in ipairs(squad.spidertrons) do
      if spidertron.valid then
        if use_pathfinding then
          self:request_spidertron_path(spidertron, player.character.position)
          local data = {
            player_index = player.index,
            goal = player.character.position,
            use_pathfinding = use_pathfinding,
            surface_name = as_surface(surface).name,
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

function CSpidertronsManager:follow_me_done(spidertron)
  if #spidertron.autopilot_destinations > 0 then return end
  local follower_metadata = player_storage:load_follower(spidertron)
  player_storage:rm_follower(spidertron)
  if not follower_metadata then return end
  local player = game.players[follower_metadata.player_index]
  if player and player.valid and player.character and player.character.valid then
    if distance_squared(spidertron.position, player.character.position) > 256 then
      self:follow_me(player, follower_metadata.surface_name, follower_metadata.squad_name, follower_metadata.use_pathfinding)
      return
    end
    spidertron.follow_target = player.character
  end
end

---
--- path requesting
---

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

function CSpidertronsManager:path_request_complete(request_id, path, try_again_later)
  if not player_storage:exists_path_request(request_id) then return end
  local request_metadata = player_storage:load_path_request(request_id)

  local spidertron = game.get_entity_by_unit_number(request_metadata.spidertron_unit)
  if not spidertron or not spidertron.valid then return end

  if try_again_later then
    spidertron.autopilot_destination = request_metadata.goal -- need to shedule another try
    return
  end
  if path and #path > 0 then
    spidertron.autopilot_destination = path[1].position
    for i = 2, #path do
      spidertron.add_autopilot_destination(path[i].position)
    end
  else
    spidertron.autopilot_destination = request_metadata.goal
  end
end

return CSpidertronsManager.get_instance()
