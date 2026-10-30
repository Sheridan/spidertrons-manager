require("constants")
require("lib.options")
require("lib.math")
require("lib.string_util")
local player_storage = require("lib.player_storage")
local spidertrons_manager = require("lib.spidertrons_manager")
local gui = require("lib.gui")

local game_load = false


-- ==========================================
-- Events helpers
-- ==========================================
local function get_event_player(event)
  if event.player_index then return game.get_player(event.player_index) end
  if event.entity and event.entity.valid then
    -- if event.entity.player then return event.entity.player end
    if event.entity.last_user then return event.entity.last_user end
  end
  return nil
end

local function entity_is_spidertron(entity)
  return entity and entity.valid and entity.type == "spider-vehicle"
end

-- ==========================================
-- Button click handlers
-- ==========================================
local function on_button_click_followme(event)
  local player = get_event_player(event)
  spidertrons_manager:follow_me(player, event.element.tags.surface_name, event.element.tags.squad_name, use_pathfinding(player, event.shift))
end

local function on_button_click_give_remote(event)
  local player = get_event_player(event)
  if player and player.is_cursor_empty() then
    local cursor = player.cursor_stack
    cursor.set_stack({name="spidertron-remote"})
    player.spidertron_remote_selection = spidertrons_manager:get_squad(event.element.tags.surface_name, event.element.tags.squad_name)
  end
end

local function on_button_click_go_home(event)
  local player = get_event_player(event)
  if not player then return end
  local squad_name = event.element.tags.squad_name
  local surface = game.surfaces[event.element.tags.surface_name]
  if event.control then
    if player.is_cursor_empty() then
      spidertrons_manager:select_squad(surface, squad_name)
      local cursor = player.cursor_stack
      cursor.set_stack({name=TOOL_SELECTION_HOME})
      gui:hide(player)
    end
  else
    local home_data = player_storage:load_home(surface.name, squad_name)
    if not home_data then return end
    local spidertrons = spidertrons_manager:get_squad(surface, squad_name)
    if not spidertrons or #spidertrons == 0 then return end

    local use_pathfinding = use_pathfinding(player, event.shift)
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
          spidertrons_manager:request_spidertron_path(spidertron, positions[i])
        else
          spidertron.autopilot_destination = positions[i]
        end
      end
    end
  end
end

local function on_button_click_go_location(event)
  local player = get_event_player(event)
  if not player then return end
  local squad_name = event.element.tags.squad_name
  local surface = game.surfaces[event.element.tags.surface_name]
  if player.is_cursor_empty() then
    spidertrons_manager:select_squad(surface, squad_name)
    player_storage:save_use_pathfinding(player, use_pathfinding(player, event.shift))
    local cursor = player.cursor_stack
    cursor.set_stack({name=TOOL_SELECTION_LOCATION})
    gui:hide(player)
  end
end

local function on_button_click_view(event)
  local player = get_event_player(event)
  if player then
    spidertrons_manager:view_squad(player, event.element.tags.surface_name, event.element.tags.squad_name);
  end
end

local function on_button_click_control(event)
  local player = get_event_player(event)
  if player then
    spidertrons_manager:control_squad(player, event.element.tags.surface_name, event.element.tags.squad_name)
  end
end

local function on_button_click_settings(event)
  local player = get_event_player(event)
  if player then
    local squad_name = event.element.tags.squad_name
    local surface_name = event.element.tags.surface_name
    local source_spidertron = spidertrons_manager:squad_leader(surface_name, squad_name)
    spidertrons_manager:select_spidertron(source_spidertron)
    spidertrons_manager:select_squad(surface_name, squad_name)
    player.set_controller{
      type = defines.controllers.remote,
      position = source_spidertron.position,
      surface = source_spidertron.surface
    }
    gui:hide(player)
    player.opened = source_spidertron
  end
end

local function on_home_area_selected(event)
  local player = get_event_player(event)
  if not player then return end
  local target_squad = spidertrons_manager:selected_squad()
  if not target_squad then return end

  local spidertrons = spidertrons_manager:get_squad(target_squad.surface, target_squad.squad_name)
  if spidertrons and #spidertrons > 0 and spidertrons[1] and spidertrons[1].valid then
    if entity_bigger_than_area(event.area, spidertrons[1].prototype.collision_box) then
      player_storage:save_home(target_squad.surface.name, target_squad.squad_name, event.area, false)
    else
      player_storage:save_home(target_squad.surface.name, target_squad.squad_name, event.area, true)
    end
  else
    player_storage:save_home(target_squad.surface.name, target_squad.squad_name, event.area, true)
  end
  spidertrons_manager:reset_selection()
  gui:show(player)
  player.cursor_stack.clear()
end

local function on_location_area_selected(event)
  local player = get_event_player(event)
  if not player then return end
  local target_squad = spidertrons_manager:selected_squad()
  if not target_squad then return end

  local spidertrons = spidertrons_manager:get_squad(target_squad.surface, target_squad.squad_name)
  if not spidertrons or #spidertrons == 0 then return end

  local use_pathfinding = player_storage:load_use_pathfinding(player)
  local positions = {}
  local is_area = entity_bigger_than_area(event.area, spidertrons[1].prototype.collision_box)
  if is_area then
    positions = calculate_grid_positions(event.area, #spidertrons)
  else
    local target_pos = event.position or get_area_center(event.area)
    for _ = 1, #spidertrons do
      table.insert(positions, target_pos)
    end
  end
  for i, spidertron in ipairs(spidertrons) do
    if spidertron.valid and positions[i] then
      if use_pathfinding then
        spidertrons_manager:request_spidertron_path(spidertron, positions[i])
      else
        spidertron.autopilot_destination = positions[i]
      end
    end
  end
  spidertrons_manager:reset_selection()
  gui:show(player)
  player.cursor_stack.clear()
end

local function update_interface(player)
  player.set_shortcut_available(SHORTCUT_NAME, spidertrons_manager:spidertrons_exists())
  if gui:is_opened(player) then
    gui:hide(player)
    gui:show(player)
  end
end

local function on_surface_changed(event)
  local player = get_event_player(event)
  if gui:is_opened(player) then
    gui:select_surface_tab(player, player.surface)
  end
end

-- ==========================================
-- Event Handlers
-- ==========================================
local function on_shortcut(event)
  local player = get_event_player(event)
  if not player then return end
  if gui:is_opened(player) then
    gui:hide(player)
  else
    gui:show(player)
  end
end

local function handle_custom_shortcut(event)
  on_shortcut(event)
end

local function handle_lua_shortcut(event)
  if event.prototype_name == SHORTCUT_NAME then
    on_shortcut(event)
  end
end

local function handle_gui_click(event)
  local player = get_event_player(event)
  if not player then return end

  if event.element.name:endswith("sm_follow_button")      then on_button_click_followme(event)   ; return end
  if event.element.name:endswith("sm_give_remote_button") then on_button_click_give_remote(event); return end
  if event.element.name:endswith("sm_go_home_button")     then on_button_click_go_home(event)    ; return end
  if event.element.name:endswith("sm_go_location_button") then on_button_click_go_location(event); return end
  if event.element.name:endswith("sm_settings_button")    then on_button_click_settings(event)   ; return end
  if event.element.name:endswith("sm_view_button")        then on_button_click_view(event)       ; return end
  if event.element.name:endswith("sm_control_button")     then on_button_click_control(event)    ; return end
end

local function handle_script_path_request_finished(event)
  spidertrons_manager:path_request_complete(event.id, event.path, event.try_again_later)
end

local function handle_spider_command_completed(event)
  if entity_is_spidertron(event.vehicle) then
    -- log(event.vehicle.name)
    spidertrons_manager:follow_me_done(event.vehicle)
  end

end

local function handle_gui_closed(event)
  local player = get_event_player(event)
  if not player then return end

  local source_spidertron = spidertrons_manager:selected_spidertron()
  if  entity_is_spidertron(event.entity)
      and source_spidertron
      and source_spidertron.unit_number == event.entity.unit_number
      and event.gui_type ~= defines.gui_type.opened_entity_grid
  then
    spidertrons_manager:apply_settings_to_squad(player)
    gui:show(player)
  end
end

local function handle_player_selected_area(event)
  if event.item == TOOL_SELECTION_HOME     then on_home_area_selected(event)     end
  if event.item == TOOL_SELECTION_LOCATION then on_location_area_selected(event) end
end

local function handle_player_cursor_stack_changed(event)
  local player = get_event_player(event)
  if not player then return end
  if not player.cursor_stack.valid_for_read then
    local target_squad = spidertrons_manager:selected_squad()
    if target_squad then
      spidertrons_manager:reset_selection()
      gui:show(player)
    end
  end
end

-- spidertron changes on surfaces

local function handle_spidertron_created(event)
  local player = get_event_player(event)
  spidertrons_manager:load_spidertrons(player)
  update_interface(player)
end

local function handle_spidertron_renamed(event)
  if entity_is_spidertron(event.entity) then
    local player = get_event_player(event)
    spidertrons_manager:load_spidertrons(player)
    update_interface(player)
  end
end

local function handle_spidertron_destroyed(event)
  local entity = event.entity
  if entity_is_spidertron(entity) then
    player_storage:rm_follower(entity)
    local player = get_event_player(event)
    spidertrons_manager:load_spidertrons(player, entity.unit_number)
    update_interface(player)
  end
end

local function game_is_load(event)
  if not game_load then
    game_load = true
    local player = game.players[1]
    spidertrons_manager:load_spidertrons(player)
    player.set_shortcut_toggled(SHORTCUT_NAME, gui:is_opened(player))
    script.on_event(defines.events.on_tick, nil)
  end
end

-- ==========================================
-- Initialization & Registration
-- ==========================================

local function init_storage()
  storage = storage or {}
end

local function register_event_handlers()
  local spider_event_filter = {{filter = "type", type = "spider-vehicle"}}

  script.on_event(SHORTCUT_NAME                                 , handle_custom_shortcut)
  script.on_event(defines.events.on_lua_shortcut                , handle_lua_shortcut)
  script.on_event(defines.events.on_gui_click                   , handle_gui_click)
  script.on_event(defines.events.on_script_path_request_finished, handle_script_path_request_finished)
  script.on_event(defines.events.on_spider_command_completed    , handle_spider_command_completed)
  script.on_event(defines.events.on_gui_closed                  , handle_gui_closed)
  script.on_event(defines.events.on_player_selected_area        , handle_player_selected_area)

  script.on_event(defines.events.on_player_created     , handle_spidertron_created)
  script.on_event(defines.events.on_built_entity       , handle_spidertron_created, spider_event_filter)
  script.on_event(defines.events.on_robot_built_entity , handle_spidertron_created, spider_event_filter)
  script.on_event(defines.events.on_entity_renamed     , handle_spidertron_renamed)
  script.on_event(defines.events.on_entity_died        , handle_spidertron_destroyed, spider_event_filter)
  script.on_event(defines.events.script_raised_destroy , handle_spidertron_destroyed, spider_event_filter)
  script.on_event(defines.events.on_robot_mined_entity , handle_spidertron_destroyed, spider_event_filter)
  script.on_event(defines.events.on_player_mined_entity, handle_spidertron_destroyed, spider_event_filter)

  -- Остальные события
  script.on_event(defines.events.on_player_changed_surface, on_surface_changed)
  script.on_event(defines.events.on_player_cursor_stack_changed, handle_player_cursor_stack_changed)
  script.on_event(defines.events.on_tick, game_is_load)
end

local function configuration_changed()
  init_storage()
  for _, player in pairs(game.players) do
    if player.gui.screen["spidertron_manager_gui"] then
      player.gui.screen["spidertron_manager_gui"].destroy()
    end
  end

end

local function on_init()
  init_storage()
  register_event_handlers()
end

local function on_load()
  register_event_handlers()
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(configuration_changed)
