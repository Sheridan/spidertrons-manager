require("lib.gui")
require("lib.string_util")

local function area_center(box)
  local left_top = box.left_top
  local right_bottom = box.right_bottom

  local center_x = (left_top.x + right_bottom.x) / 2
  local center_y = (left_top.y + right_bottom.y) / 2

  return {x = center_x, y = center_y}
end

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

local function open_spidertron_gui(player)
  if player.opened then return end
  local gui = add_window(player, "spidertron_manager_gui", {"sm_gui.window_caption"})

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
      if player.surface and player.character.surface and player.surface == player.character.surface
      then
        add_sprite_button(button_flow, group_name .. "_follow_button", {"sm_gui.follow_me_tooltip"}, "slot_button", "utility/player_force_icon", button_tags)
      end
      add_sprite_button(button_flow, group_name .. "_give_remote_button", {"sm_gui.give_remote_tooltip"}, "slot_button", "shortcut/give-spidertron-remote", button_tags)
      add_sprite_button(button_flow, group_name .. "_go_home_button"    , {"sm_gui.go_home_tooltip"}    , "slot_button", "utility/shoot_cursor_green"     , button_tags)
      add_sprite_button(button_flow, group_name .. "_settings_button"   , {"sm_gui.settings_tooltip"}   , "slot_button", "open_spidertron_settings"       , button_tags)
  end
end

local function apply_settings_to_group(player)
  local spidertrons = find_spidertrons(player)[storage.spidertron_manager_data.selection_target_group]
  if #spidertrons > 1
    then
      local src_spidertron = storage.spidertron_manager_data.settings_source_spidertron
      for _, spidertron in ipairs(spidertrons)
      do
        spidertron.copy_settings(src_spidertron, player)
      end
  end
  storage.spidertron_manager_data.selection_target_group = nil
  storage.spidertron_manager_data.settings_source_spidertron = nil
  open_spidertron_gui(player)
end

local function get_event_player(event)
  if event.player_index then return game.get_player(event.player_index) end
  if event.entity and event.entity.last_user then return event.entity.last_user end
  return nil
end

local function on_button_click_followme(event)
  local player = get_event_player(event)
  if player
  then
    for _, spidertron in ipairs(find_spidertrons(player)[event.element.tags.group_name])
    do
      if event.control
      then
        spidertron.autopilot_destination = player.character.position
      else
        spidertron.follow_target = player.character
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
  if player
  then
    local group_name = event.element.tags.group_name
    if event.control
    then -- set home
      if player.is_cursor_empty()
      then
        storage.spidertron_manager_data.selection_target_group = group_name
        local cursor = player.cursor_stack
        cursor.set_stack({name="spidertrons-manager-set-home-tool"})
        player.opened = nil
      end
    else -- go home
      for _, spidertron in ipairs(find_spidertrons(player)[group_name])
      do
        spidertron.autopilot_destination = storage.spidertron_manager_data.home_position[group_name]
      end
    end
  end
end

local function on_button_click_settings(event)
  local player = get_event_player(event)
  if player
  then
    local group_name = event.element.tags.group_name
    storage.spidertron_manager_data.settings_source_spidertron = find_spidertrons(player)[group_name][1]
    player.opened = storage.spidertron_manager_data.settings_source_spidertron
    storage.spidertron_manager_data.selection_target_group = group_name
  end
end

local function on_home_area_selected(event)
  if storage.spidertron_manager_data.selection_target_group
  then
    local player = get_event_player(event)
    if player
    then
      storage.spidertron_manager_data.home_position[storage.spidertron_manager_data.selection_target_group] = area_center(event.area)
      storage.spidertron_manager_data.selection_target_group = nil
      open_spidertron_gui(player)
      player.cursor_stack.clear()
    end
  end
end

local function set_shortcut_availability(event)
  -- game.print("set_shortcut_availability")
  local player = get_event_player(event)
  if player
  then
    player.set_shortcut_available("open_spidertron_gui_shortcut", is_spidertrons_exists(player))
  end
end

local function init_storage()
  storage = storage or {}
  storage.spidertron_manager_data = storage.spidertron_manager_data or { home_position = {} }
end

local function register_event_handlers()
  script.on_event(defines.events.on_lua_shortcut,function(event)
    if event.prototype_name == "open_spidertron_gui_shortcut" then
      open_spidertron_gui(get_event_player(event))
    end
  end)

  script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name:endswith("follow_button")      then on_button_click_followme(event); return end
    if event.element.name:endswith("give_remote_button") then on_button_click_give_remote(event); return end
    if event.element.name:endswith("go_home_button")     then on_button_click_go_home(event); return end
    if event.element.name:endswith("settings_button")    then on_button_click_settings(event); return end
    if event.element.name:endswith("-x-button")          then event.element.parent.parent.destroy(); return end
  end)

  script.on_event(defines.events.on_gui_closed, function(event)
    -- if event.gui_type == defines.gui_type.achievement	then game.print("achievement") end
    -- if event.gui_type == defines.gui_type.blueprint_library	then game.print("blueprint_library") end
    -- if event.gui_type == defines.gui_type.bonus	then game.print("bonus") end
    -- if event.gui_type == defines.gui_type.controller	then game.print("controller") end
    -- if event.gui_type == defines.gui_type.custom	then game.print("custom") end
    -- if event.gui_type == defines.gui_type.entity	then game.print("entity") end
    -- if event.gui_type == defines.gui_type.equipment	then game.print("equipment") end
    -- if event.gui_type == defines.gui_type.global_electric_network	then game.print("global_electric_network") end
    -- if event.gui_type == defines.gui_type.item	then game.print("item") end
    -- if event.gui_type == defines.gui_type.logistic	then game.print("logistic") end
    -- if event.gui_type == defines.gui_type.none	then game.print("none") end
    -- if event.gui_type == defines.gui_type.opened_entity_grid	then game.print("opened_entity_grid") end
    -- if event.gui_type == defines.gui_type.other_player	then game.print("other_player") end
    -- if event.gui_type == defines.gui_type.permissions	then game.print("permissions") end
    -- if event.gui_type == defines.gui_type.player_management	then game.print("player_management") end
    -- if event.gui_type == defines.gui_type.production	then game.print("production") end
    -- if event.gui_type == defines.gui_type.script_inventory	then game.print("script_inventory") end
    -- if event.gui_type == defines.gui_type.server_management	then game.print("server_management") end
    -- if event.gui_type == defines.gui_type.tile	then game.print("tile") end
    -- if event.gui_type == defines.gui_type.trains    then game.print("train") end
    -- game.print(event.name)
    -- game.print(event.gui_type)
    -- if event.element and event.element.valid then game.print(event.element.name) end
    -- if event.equipment and event.equipment.valid then game.print(event.equipment.name) end
    if event.element and event.element.valid and event.element.name == "spidertron_manager_gui" then
      event.element.destroy()
      return
    end
    if    event.entity
      and event.entity.valid
      and event.entity.name == "spidertron"
      and storage.spidertron_manager_data.selection_target_group
      and storage.spidertron_manager_data.settings_source_spidertron
      and storage.spidertron_manager_data.settings_source_spidertron.unit_number == event.entity.unit_number
      and event.gui_type ~= defines.gui_type.opened_entity_grid
    then
      -- game.print("!")
      apply_settings_to_group(get_event_player(event))
    end
  end)

  script.on_event(defines.events.on_player_selected_area, function(event)
    if event.item ~= "spidertrons-manager-set-home-tool" then return end
    on_home_area_selected(event)
  end)

  script.on_event("open_spidertron_gui_shortcut", function(event)
    open_spidertron_gui(get_event_player(event))
  end)

  local spider_event_filter = {
    {filter = "type", type = "spider-vehicle"},
    {filter = "ghost_name", name = "spidertron"},
    {filter = "name", name = "spidertron"},
  }

  script.on_event(defines.events.on_player_created        , set_shortcut_availability)
  script.on_event(defines.events.on_player_changed_surface, set_shortcut_availability)
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
