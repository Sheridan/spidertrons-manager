require("lib.gui")
require("lib.math")
require("lib.string_util")
local player_storage = require("lib.player_storage")

local SHORTCUT_NAME = "open_spidertron_gui_shortcut"
local GUI_NAME = "spidertron_manager_gui"

-- ==========================================
-- Player helpers
-- ==========================================
local function get_event_player(event)
  if event.player_index then return game.get_player(event.player_index) end
  if event.entity and event.entity.last_user then return event.entity.last_user end
  return nil
end

-- ==========================================
-- Spidertons helpers
-- ==========================================
local function spidertron_name(spidertron)
  if spidertron.entity_label then return spidertron.entity_label end
  return spidertron.name
end

local function spidertrons_exists_on_surface(player)
  local spidertrons = player.surface.find_entities_filtered{
    type = "spider-vehicle",
    force = player.force,
    limit = 1,
  }
  return #spidertrons > 0
end

local function find_spidertrons(player, spidertron_id_for_ignore)
  local spidertrons_groups = {}
  local surface_spidertrons = player.surface.find_entities_filtered{type = "spider-vehicle", to_be_deconstruct = false, force = player.force}
  table.sort(surface_spidertrons, function(a,b) return spidertron_name(a) < spidertron_name(b) end)
  for _, spidertron in pairs(surface_spidertrons) do
    if spidertron.valid then
      if spidertron_id_for_ignore == nil or spidertron.unit_number ~= spidertron_id_for_ignore then
        local group_name = player.surface.name .. "_" .. spidertron_name(spidertron)
        if not spidertrons_groups[group_name] then
          spidertrons_groups[group_name] = {}
        end
        table.insert(spidertrons_groups[group_name], spidertron)
        -- game.print("Found unit: " .. spidertron.unit_number)
      end
    end
  end
  return spidertrons_groups
end

local function spidertrons_groups_count(spidertrons_groups)
  local groups_count = 0
  for _ in pairs(spidertrons_groups) do
    groups_count = groups_count + 1
  end
  return groups_count
end

local function request_spidertron_path(spidertron, goal_position)
  if not spidertron or not spidertron.valid then return end
  local surface = spidertron.surface
  local MAX_GAP = 3
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
  player_storage.save_group_data(nil, "path_requests", path_id, path_data)
end

local function store_home(player, target_group, area, as_point)
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
  player_storage.save_group_data(player, "home_data", target_group, home_data)
  player_storage.rm_player_data(player, "selection_target_group")
end

local function apply_settings_to_group(player)
  local spidertrons = find_spidertrons(player)[player_storage.load_player_data(player, "selection_target_group", nil)]
  if not spidertrons then return end
  if #spidertrons > 1 then
    local src_spidertron = player_storage.load_player_data(player, "settings_source_spidertron", nil)
    if src_spidertron then
      for _, spidertron in ipairs(spidertrons) do
        spidertron.copy_settings(src_spidertron, player)
      end
    end
  end
  player_storage.rm_player_data(player, "selection_target_group")
  player_storage.rm_player_data(player, "settings_source_spidertron")
end

-- ==========================================
-- GUI
-- ==========================================
local function set_shortcut_state(player, is_toggled)
  player.set_shortcut_toggled(SHORTCUT_NAME, is_toggled)
  player_storage.save_player_data(player, "window_is_opened", is_toggled)
end

local function spidertron_gui_opened(player)
  return player.gui.screen.spidertron_manager_gui ~= nil
end

local function open_spidertron_gui(player, spidertron_id_for_ignore)
  if not player.gui.screen[GUI_NAME] then
    if spidertron_gui_opened(player) then return end
    local found_spidertrons_groups = find_spidertrons(player, spidertron_id_for_ignore)
    local groups_count = spidertrons_groups_count(found_spidertrons_groups)
    if groups_count > 0 then
      local gui = add_window(player_storage, player, GUI_NAME, {"sm_gui.window_caption"})
      local sp_table = gui.add{
          type = "table",
          name = "sp_table",
          style = "sync_mods_table",
          column_count = 4,
          vertical_centering = true
      }
      for group_name, spidertrons in pairs(found_spidertrons_groups) do
        local sp_leader = spidertrons[1]
        local button_tags = { group_name = group_name }
        sp_table.add{ type = "label", caption = "◼ " }.style.font_color = sp_leader.color
        sp_table.add{ type = "label", caption = spidertron_name(sp_leader) }
        sp_table.add{ type = "label", caption = #spidertrons }

        local button_flow = sp_table.add{ type = "flow", direction = "horizontal" }
        if player.character and player.character.valid and player.surface == player.character.surface then
            add_sprite_button(button_flow, group_name .. "_sm_follow_button", {"sm_gui.follow_me_tooltip"}, "slot_button", "spidertron_follow", button_tags)
        end
        add_sprite_button(button_flow, group_name .. "_sm_give_remote_button", {"sm_gui.give_remote_tooltip"}, "slot_button", "another_spidertron_remote", button_tags)
        add_sprite_button(button_flow, group_name .. "_sm_go_home_button"    , {"sm_gui.go_home_tooltip"}    , "slot_button", "spidertron_go_to_location", button_tags)
        add_sprite_button(button_flow, group_name .. "_sm_view_button"       , {"sm_gui.view_tooltip"}       , "slot_button", "open_spidertron_view"     , button_tags)
        add_sprite_button(button_flow, group_name .. "_sm_settings_button"   , {"sm_gui.settings_tooltip"}   , "slot_button", "open_spidertron_settings" , button_tags)
      end
      player_storage.save_player_data(player, "window_is_opened", true)
      set_shortcut_state(player, true)
    else
      set_shortcut_state(player, false)
    end
  end
end

local function close_spidertron_gui(player)
  local gui = player.gui.screen[GUI_NAME]
  if gui then
    player_storage.save_player_data(player, "window_position", gui.location)
    gui.destroy()
  end
  set_shortcut_state(player, false)
end

-- ==========================================
-- Button click handlers
-- ==========================================
local function on_button_click_followme(event)
  local player = get_event_player(event)
  if player and player.character then
    local group_name = event.element.tags.group_name
    local spidertrons = find_spidertrons(player)[group_name]
    if not spidertrons then return end
    for _, spidertron in ipairs(spidertrons) do
      if spidertron.valid then
        if event.control then
          spidertron.autopilot_destination = player.character.position
        elseif event.shift then
          request_spidertron_path(spidertron, player.character.position)
          local follows_data = {
            player_index = player.index,
            goal = player.character.position
          }
          player_storage.save_group_data(nil, "pending_follows", spidertron.unit_number, follows_data)
        else
          spidertron.follow_target = player.character
        end
      end
    end
  end
end

local function on_button_click_give_remote(event)
  local player = get_event_player(event)
  if player and player.is_cursor_empty() then
    local cursor = player.cursor_stack
    cursor.set_stack({name="spidertron-remote"})
    player.spidertron_remote_selection = find_spidertrons(player)[event.element.tags.group_name]
  end
end

local function on_button_click_go_home(event)
  local player = get_event_player(event)
  if not player then return end
  local group_name = event.element.tags.group_name
  if event.control then
    if player.is_cursor_empty() then
      player_storage.save_player_data(player, "selection_target_group", group_name)
      local cursor = player.cursor_stack
      cursor.set_stack({name="spidertrons-manager-set-home-tool"})
      close_spidertron_gui(player)
    end
  else
    local home_data = player_storage.load_group_data(player, "home_data", group_name, nil)
    if not home_data then return end
    local spidertrons = find_spidertrons(player)[group_name]
    if not spidertrons or #spidertrons == 0 then return end

    local use_pathfinding = event.shift
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
          request_spidertron_path(spidertron, positions[i])
        else
          spidertron.autopilot_destination = positions[i]
        end
      end
    end
  end
end

local function on_button_click_view(event)
  local player = get_event_player(event)
  if player then
    local spidertron = find_spidertrons(player)[event.element.tags.group_name][1]
    if spidertron and spidertron.valid then
      player.centered_on = spidertron
    end
  end
end

local function on_button_click_settings(event)
  local player = get_event_player(event)
  if player then
    local group_name = event.element.tags.group_name
    local source_spidertron = find_spidertrons(player)[group_name][1]
    player_storage.save_player_data(player, "settings_source_spidertron", source_spidertron)
    player.set_controller{
      type = defines.controllers.remote,
      position = source_spidertron.position,
      surface = source_spidertron.surface
    }
    close_spidertron_gui(player)
    player.opened = source_spidertron
    player_storage.save_player_data(player, "selection_target_group", group_name)
  end
end

local function on_home_area_selected(event)
  local player = get_event_player(event)
  if not player then return end
  local target_group = player_storage.load_player_data(player, "selection_target_group", nil)
  if not target_group then return end

  local spidertrons = find_spidertrons(player)[target_group]
  if spidertrons and #spidertrons > 0 and spidertrons[1] and spidertrons[1].valid then
    local collision_box = spidertrons[1].prototype.collision_box
    local area_width = event.area.right_bottom.x - event.area.left_top.x
    local area_height = event.area.right_bottom.y - event.area.left_top.y
    local spidertron_width = collision_box.right_bottom.x - collision_box.left_top.x
    local spidertron_height = collision_box.right_bottom.y - collision_box.left_top.y
    -- local home_data
    if area_width < spidertron_width or area_height < spidertron_height then
      store_home(player, target_group, event.area, true)
    else
      store_home(player, target_group, event.area, false)
    end
  else
    store_home(player, target_group, event.area, true)
  end
  open_spidertron_gui(player)
  player.cursor_stack.clear()
end

local function update_interface(event, spidertron_id_for_ignore)
  local player = get_event_player(event)
  local spidertrons_on_surface = spidertrons_exists_on_surface(player)
  player.set_shortcut_available(SHORTCUT_NAME, spidertrons_on_surface)
  if spidertrons_on_surface then
    if spidertron_gui_opened(player) then
      close_spidertron_gui(player)
      open_spidertron_gui(player, spidertron_id_for_ignore)
    end
  else
    if spidertron_gui_opened(player) then
      close_spidertron_gui(player)
    end
  end
end

local function on_surface_changed(event)
    update_interface(event)
end

-- ==========================================
-- Event Handlers (Вынесены из регистраторов)
-- ==========================================
local function handle_lua_shortcut(event)
  if event.prototype_name == SHORTCUT_NAME then
    local player = game.get_player(event.player_index)
    if not player then return end
    if player.gui.screen[GUI_NAME] then
      close_spidertron_gui(player)
    else
      open_spidertron_gui(player)
    end
  end
end

local function handle_gui_click(event)
  local player = get_event_player(event)
  if not player then return end

  if event.element.name:endswith("sm_follow_button")      then on_button_click_followme(event); return end
  if event.element.name:endswith("sm_give_remote_button") then on_button_click_give_remote(event); return end
  if event.element.name:endswith("sm_go_home_button")     then on_button_click_go_home(event); return end
  if event.element.name:endswith("sm_settings_button")    then on_button_click_settings(event); return end
  if event.element.name:endswith("sm_view_button")        then on_button_click_view(event); return end
end

local function handle_script_path_request_finished(event)
  local req = player_storage.load_group_data(nil, "path_requests", event.id, nil)
  if not req then return end
  player_storage.rm_group_data(nil, "path_requests", event.id)

  local spidertron = game.get_entity_by_unit_number(req.spidertron_unit)
  if not spidertron or not spidertron.valid then return end

  if event.try_again_later then
    spidertron.autopilot_destination = req.goal
    return
  end

  if event.path and #event.path > 0 then
    spidertron.autopilot_destination = event.path[1].position
    for i = 2, #event.path do
      spidertron.add_autopilot_destination(event.path[i].position)
    end
  else
    spidertron.autopilot_destination = req.goal
  end
end

local function handle_spider_command_completed(event)
  local spidertron = event.vehicle
  if not spidertron or not spidertron.valid then return end

  local data = player_storage.load_group_data(nil, "pending_follows", spidertron.unit_number, nil)
  if not data then return end

  local dx = spidertron.position.x - data.goal.x
  local dy = spidertron.position.y - data.goal.y
  if (dx * dx + dy * dy) > 25 then return end

  player_storage.rm_group_data(nil, "pending_follows", spidertron.unit_number)
  local player = game.get_player(data.player_index)
  if player and player.valid and player.character and player.character.valid then
    spidertron.follow_target = player.character
  end
end

local function handle_spidertron_destroyed(event)
  local entity = event.entity
  if entity and entity.valid and entity.type == "spider-vehicle" then
    if player_storage.exists_group_data(nil, "pending_follows", entity.unit_number) then
      player_storage.rm_group_data(nil, "pending_follows", entity.unit_number)
    end
    update_interface(event, entity.unit_number)
  end
end

local function handle_gui_closed(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  if event.element and event.element.valid and event.element.name == GUI_NAME then
    player_storage.save_player_data(player, "window_position", event.element.location)
    return
  end

  local source_spidertron = player_storage.load_player_data(player, "settings_source_spidertron", nil)
  if  event.entity
      and event.entity.valid
      and event.entity.type == "spider-vehicle"
      and source_spidertron
      and source_spidertron.unit_number == event.entity.unit_number
      and event.gui_type ~= defines.gui_type.opened_entity_grid
  then
    apply_settings_to_group(player)
    open_spidertron_gui(player)
  end
end

local function handle_player_selected_area(event)
  if event.item ~= "spidertrons-manager-set-home-tool" then return end
  on_home_area_selected(event)
end

local function handle_custom_shortcut(event)
  open_spidertron_gui(get_event_player(event))
end

local function handle_entity_renamed(event)
  if event.entity
  and event.entity.valid
  and event.entity.type == "spider-vehicle"
  then
    update_interface(event)
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

  script.on_event(defines.events.on_lua_shortcut                , handle_lua_shortcut)
  script.on_event(defines.events.on_gui_click                   , handle_gui_click)
  script.on_event(defines.events.on_script_path_request_finished, handle_script_path_request_finished)
  script.on_event(defines.events.on_spider_command_completed    , handle_spider_command_completed)
  script.on_event(defines.events.on_gui_closed                  , handle_gui_closed)
  script.on_event(defines.events.on_player_selected_area        , handle_player_selected_area)
  script.on_event(SHORTCUT_NAME                                 , handle_custom_shortcut)

  script.on_event(defines.events.on_entity_died        , handle_spidertron_destroyed, spider_event_filter)
  script.on_event(defines.events.script_raised_destroy , handle_spidertron_destroyed, spider_event_filter)
  script.on_event(defines.events.on_robot_mined_entity , handle_spidertron_destroyed, spider_event_filter)
  script.on_event(defines.events.on_player_mined_entity, handle_spidertron_destroyed, spider_event_filter)

  -- Остальные события
  script.on_event(defines.events.on_player_changed_surface, on_surface_changed)
  script.on_event(defines.events.on_player_created        , update_interface)
  script.on_event(defines.events.on_built_entity          , update_interface, spider_event_filter)
  script.on_event(defines.events.on_robot_built_entity    , update_interface, spider_event_filter)
  script.on_event(defines.events.on_entity_renamed        , handle_entity_renamed)
end

local function configuration_changed()
  init_storage()
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
