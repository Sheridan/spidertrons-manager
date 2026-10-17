require("lib.gui")
require("lib.math")
require("lib.string_util")

local player_storage = require("lib.player_storage")

local SHORTCUT_NAME = "open_spidertron_gui_shortcut"
local GUI_NAME = "spidertron_manager_gui"

-- Player helpers

local function get_event_player(event)
  if event.player_index then return game.get_player(event.player_index) end
  if event.entity and event.entity.last_user then return event.entity.last_user end
  return nil
end

-- Spidertons helpers

local function spidertron_name(spidertron)
  if spidertron.entity_label then return spidertron.entity_label end
  -- if spidertron.prototype.localised_name then return spidertron.prototype.localised_name end
  return spidertron.name
end

local function is_spidertrons_exists(player)
  return player.surface.count_entities_filtered{type = "spider-vehicle", to_be_deconstructed = false, force = player.force} > 0
end

local function find_spidertrons(player)
  local spidertrons_groups = {}
  local surface_spidertrons = player.surface.find_entities_filtered{type = "spider-vehicle", to_be_deconstructed = false, force = player.force}
  table.sort(surface_spidertrons, function(a,b) return spidertron_name(a) < spidertron_name(b) end)
  for _, spidertron in pairs(surface_spidertrons)
  do
    if spidertron.valid
    then
      -- if spidertron.commandable then game.print("!") end
      local group_name = player.surface.name .. "_" .. spidertron_name(spidertron)
      if not spidertrons_groups[group_name]
      then
          spidertrons_groups[group_name] = {}
      end
      table.insert(spidertrons_groups[group_name], spidertron)
    end
  end
  return spidertrons_groups
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
        cache = true,
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
  if #spidertrons > 1
    then
      local src_spidertron = player_storage.load_player_data(player, "settings_source_spidertron", nil)
      for _, spidertron in ipairs(spidertrons)
      do
        spidertron.copy_settings(src_spidertron, player)
      end
  end
  player_storage.rm_player_data(player, "selection_target_group")
  player_storage.rm_player_data(player, "settings_source_spidertron")
end

-- GUI

local function set_shortcut_state(player, is_toggled)
  player.set_shortcut_toggled(SHORTCUT_NAME, is_toggled)
  player_storage.save_player_data(player, "window_is_opened", is_toggled)
end

local function spidertron_gui_opened(player)
  return player.gui.screen.spidertron_manager_gui ~= nil
end

local function open_spidertron_gui(player)
  if spidertron_gui_opened(player) then return end
  local gui = add_window(player_storage, player, GUI_NAME, {"sm_gui.window_caption"})

  local sp_table = gui.add{
    type = "table",
    name = "sp_table",
    style = "sync_mods_table",
    column_count = 4,
    vertical_centering = true
  }

  for group_name, spidertrons in pairs(find_spidertrons(player))
  do
      local sp_leader = spidertrons[1]
      local button_tags = { group_name = group_name }
      sp_table.add{ type = "label", caption = "◼" }.style.font_color = sp_leader.color
      sp_table.add{ type = "label", caption = spidertron_name(sp_leader) }
      sp_table.add{ type = "label", caption = #spidertrons }
      local button_flow = sp_table.add{ type = "flow", direction = "horizontal" }
      if player.character and player.character.valid and player.surface == player.character.surface then
        add_sprite_button(button_flow, group_name .. "_sm_follow_button", {"sm_gui.follow_me_tooltip"}, "slot_button", "spidertron_follow", button_tags)
      end
      add_sprite_button(button_flow, group_name .. "_sm_give_remote_button", {"sm_gui.give_remote_tooltip"}, "slot_button", "another_spidertron_remote" , button_tags)
      add_sprite_button(button_flow, group_name .. "_sm_go_home_button"    , {"sm_gui.go_home_tooltip"}    , "slot_button", "spidertron_go_to_location" , button_tags)
      add_sprite_button(button_flow, group_name .. "_sm_view_button"       , {"sm_gui.view_tooltip"}       , "slot_button", "open_spidertron_view"      , button_tags)
      add_sprite_button(button_flow, group_name .. "_sm_settings_button"   , {"sm_gui.settings_tooltip"}   , "slot_button", "open_spidertron_settings"  , button_tags)
  end
  player_storage.save_player_data(player, "window_is_opened", true)
end

local function open_spidertron_gui_safe(player)
  if not player.gui.screen[GUI_NAME] then
    open_spidertron_gui(player)
  end
  set_shortcut_state(player, true)
end

local function close_spidertron_gui(player)
  local gui = player.gui.screen[GUI_NAME]
  if gui then
    player_storage.save_player_data(player, "window_position", gui.location)
    gui.destroy()
  end
  set_shortcut_state(player, false)
end


-- on-button's

local function on_button_click_followme(event)
  local player = get_event_player(event)
  if player and player.character then
    local group_name = event.element.tags.group_name
    local spidertrons = find_spidertrons(player)[group_name]
    if not spidertrons then return end
    for _, spidertron in ipairs(spidertrons) do
      if spidertron.valid then
        if event.control
        then
          spidertron.autopilot_destination = player.character.position
        elseif event.shift then
          request_spidertron_path(spidertron, player.character.position)
          local follows_data =  {
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
  if player and player.is_cursor_empty()
  then
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
  if player
  then
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
    local home_data
    if area_width < spidertron_width or area_height < spidertron_height then
      store_home(player, target_group, event.area, true)
    else
      store_home(player, target_group, event.area, false)
    end
  else
    store_home(player, target_group, event.area, true)
  end
  open_spidertron_gui_safe(player)
  player.cursor_stack.clear()
end

local function set_shortcut_availability(event)
  -- game.print("set_shortcut_availability")
  local player = get_event_player(event)
  if player
  then
    local is_sp_exists = is_spidertrons_exists(player)
    player.set_shortcut_available(SHORTCUT_NAME, is_sp_exists)
    return is_sp_exists
  end
  return false
end

local function on_surface_changed(event)
  local player = get_event_player(event)
  if  spidertron_gui_opened(player)    and
      set_shortcut_availability(event) and
      player_storage.load_player_data(player, "window_is_opened", false) then
    close_spidertron_gui(player)
    open_spidertron_gui_safe(player)
  end
end


local function init_storage()
  storage = storage or {}
end

local function register_event_handlers()
  script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == SHORTCUT_NAME then
      local player = game.get_player(event.player_index)
      if not player then return end

      if player.gui.screen[GUI_NAME] then
        close_spidertron_gui(player)
      else
        open_spidertron_gui_safe(player)
      end
    end
  end)

  script.on_event(defines.events.on_gui_click, function(event)
    local player = get_event_player(event)
    if event.element.name:endswith("sm_follow_button")      then on_button_click_followme(event); return end
    if event.element.name:endswith("sm_give_remote_button") then on_button_click_give_remote(event); return end
    if event.element.name:endswith("sm_go_home_button")     then on_button_click_go_home(event); return end
    if event.element.name:endswith("sm_settings_button")    then on_button_click_settings(event); return end
    if event.element.name:endswith("sm_view_button")        then on_button_click_view(event); return end
    -- if event.element.name:endswith("-x-button")             then
    --   event.element.parent.parent.destroy()
    --   player_storage.save_player_data(player, "window_is_opened", false)
    --   return
    -- end
  end)

  -- script.on_event(defines.events.on_gui_opened, function(event)
  --   game.print(event.name)
  --   game.print(event.gui_type)
  --   if event.element and event.element.valid then game.print(event.element.name) end
  --   if event.equipment and event.equipment.valid then game.print(event.equipment.name) end
  --   if event.gui_type == defines.gui_type.achievement	then game.print("achievement") end
  --   if event.gui_type == defines.gui_type.blueprint_library	then game.print("blueprint_library") end
  --   if event.gui_type == defines.gui_type.bonus	then game.print("bonus") end
  --   if event.gui_type == defines.gui_type.controller	then game.print("controller") end
  --   if event.gui_type == defines.gui_type.custom	then game.print("custom") end
  --   if event.gui_type == defines.gui_type.entity	then game.print("entity") end
  --   if event.gui_type == defines.gui_type.equipment	then game.print("equipment") end
  --   if event.gui_type == defines.gui_type.global_electric_network	then game.print("global_electric_network") end
  --   if event.gui_type == defines.gui_type.item	then game.print("item") end
  --   if event.gui_type == defines.gui_type.logistic	then game.print("logistic") end
  --   if event.gui_type == defines.gui_type.none	then game.print("none") end
  --   if event.gui_type == defines.gui_type.opened_entity_grid	then game.print("opened_entity_grid") end
  --   if event.gui_type == defines.gui_type.other_player	then game.print("other_player") end
  --   if event.gui_type == defines.gui_type.permissions	then game.print("permissions") end
  --   if event.gui_type == defines.gui_type.player_management	then game.print("player_management") end
  --   if event.gui_type == defines.gui_type.production	then game.print("production") end
  --   if event.gui_type == defines.gui_type.script_inventory	then game.print("script_inventory") end
  --   if event.gui_type == defines.gui_type.server_management	then game.print("server_management") end
  --   if event.gui_type == defines.gui_type.tile	then game.print("tile") end
  --   if event.gui_type == defines.gui_type.trains    then game.print("train") end
  -- end)

  script.on_event(defines.events.on_script_path_request_finished, function(event)

    local req = player_storage.load_group_data(nil, "path_requests", event.id, nil)
    if not req then return end
    player_storage.rm_group_data(nil, "path_requests", event.id)

    local spidertron = game.get_entity_by_unit_number(req.spidertron_unit)
    if not spidertron.valid then return end
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
  end)

  script.on_event(defines.events.on_spider_command_completed, function(event)
    local spidertron = event.vehicle

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
  end)

  script.on_event({defines.events.on_entity_died, defines.events.script_raised_destroy}, function(event)
    local entity = event.entity
    if entity and entity.valid and entity.type == "spider-vehicle" then
      if player_storage.exists_group_data(nil, "pending_follows", entity.unit_number) then
        player_storage.rm_group_data(nil, "pending_follows", entity.unit_number)
      end
    end
  end)

  script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if event.element and event.element.valid and event.element.name == GUI_NAME then
      player_storage.save_player_data(player, "window_position", event.element.location)
      return
    end

    local source_spidertron = player_storage.load_player_data(player, "settings_source_spidertron", nil)
    if event.entity
      and event.entity.valid
      and event.entity.type == "spider-vehicle"
      and source_spidertron
      and source_spidertron.unit_number == event.entity.unit_number
      and event.gui_type ~= defines.gui_type.opened_entity_grid
    then
      apply_settings_to_group(player)
      open_spidertron_gui_safe(player)
    end
  end)

  script.on_event(defines.events.on_player_selected_area, function(event)
    if event.item ~= "spidertrons-manager-set-home-tool" then return end
    on_home_area_selected(event)
  end)

  script.on_event(SHORTCUT_NAME, function(event)
    open_spidertron_gui_safe(get_event_player(event))
  end)

  local spider_event_filter = {
    {filter = "type", type = "spider-vehicle"},
  }

  script.on_event(defines.events.on_player_changed_surface, on_surface_changed)
  script.on_event(defines.events.on_player_created        , set_shortcut_availability)
  script.on_event(defines.events.on_built_entity          , set_shortcut_availability, spider_event_filter)
  script.on_event(defines.events.on_robot_built_entity    , set_shortcut_availability, spider_event_filter)
  script.on_event(defines.events.on_entity_died           , set_shortcut_availability, spider_event_filter)
  script.on_event(defines.events.on_robot_mined_entity    , set_shortcut_availability, spider_event_filter)
  script.on_event(defines.events.on_player_mined_entity   , set_shortcut_availability, spider_event_filter)

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
