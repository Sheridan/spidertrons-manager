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

local function find_spidertrons(player)
  local spidertrons_groups = {}
  for _, spidertron in pairs(player.surface.find_entities_filtered{type = "spider-vehicle"})
  do
    if spidertron.valid
    then
      local group_name = player.surface.name .. "_" .. spidertron_name(spidertron)
      -- game.print(group_name)
      if not spidertrons_groups[group_name]
      then
          spidertrons_groups[group_name] = {}
      end
      table.insert(spidertrons_groups[group_name], spidertron)
    end
  end
  return spidertrons_groups
end

local function on_button_click_followme(event)
  local button_tags = event.element.tags
  local player = game.players[event.player_index]
  for group_name, spidertrons in pairs(find_spidertrons(player))
  do
    if group_name == button_tags.group_name
    then
      for _, spidertron in ipairs(spidertrons)
      do
        spidertron.follow_target = player.character
      end
    end
  end
end

local function on_button_click_give_remote(event)
  local button_tags = event.element.tags
  local player = game.players[event.player_index]
  if player.is_cursor_empty()
  then
    local cursor = player.cursor_stack
    for group_name, spidertrons in pairs(find_spidertrons(player))
    do
      if group_name == button_tags.group_name
      then
          cursor.set_stack({name="spidertron-remote"})
          player.spidertron_remote_selection = spidertrons
      end
    end
  end
end

local function on_button_click_go_home(event)
  local button_tags = event.element.tags
  local player = game.players[event.player_index]

  if event.control
  then -- set home
    if player.is_cursor_empty()
    then
      storage.spidertron_manager_data.selection_target = button_tags.group_name
      local cursor = player.cursor_stack
      cursor.set_stack({name="spidertrons-manager-set-home-tool"})
    end
  else -- go home
    for group_name, spidertrons in pairs(find_spidertrons(player))
    do
      if group_name == button_tags.group_name
      then
        for _, spidertron in ipairs(spidertrons)
        do
          spidertron.autopilot_destination = storage.spidertron_manager_data.home_position[group_name]
        end
      end
    end
  end
end

local function on_home_area_selected(event)
  if storage.spidertron_manager_data.selection_target
  then
    storage.spidertron_manager_data.home_position[storage.spidertron_manager_data.selection_target] = area_center(event.area)
    storage.spidertron_manager_data.selection_target = nil
  end
end

local function open_spidertron_gui(player)
  if player.opened then return end
  local gui = add_window(player, "spidertron_manager_gui", {"sm_gui.window_caption"})

  local sp_table = gui.add{
    type = "table",
    name = "sp_table",
    style = "sync_mods_table",
    column_count = 3,
    vertical_centering = true
  }

  for group_name, spidertrons in pairs(find_spidertrons(player))
  do
      local group_flow = gui.add{type = "flow", name = group_name .. "_flow", direction = "horizontal"}
      local sp_leader = spidertrons[1]
      local button_tags = { group_name = group_name }
      -- group_flow.add{type = "label", caption = spidertron_name(sp_leader)}
      sp_table.add{ type = "label", caption = spidertron_name(sp_leader) }
      sp_table.add{ type = "label", caption = #spidertrons }
      local button_flow = sp_table.add{ type = "flow", direction = "horizontal" }
      if player.surface and player.character.surface and player.surface == player.character.surface
      then
        add_sprite_button(button_flow, group_name .. "_follow_button", {"sm_gui.follow_me_tooltip"}, "slot_button", "utility/player_force_icon", button_tags)
      end
      add_sprite_button(button_flow, group_name .. "_give_remote_button", {"sm_gui.give_remote_tooltip"}, "slot_button", "shortcut/give-spidertron-remote", button_tags)
      add_sprite_button(button_flow, group_name .. "_go_home_button", {"sm_gui.go_home_tooltip"}, "slot_button", "utility/shoot_cursor_green", button_tags)

  end
end

local function init_storage()
  storage = storage or {}
  storage.spidertron_manager_data = storage.spidertron_manager_data or { home_position = {} }
end

local function register_event_handlers()
  script.on_event(defines.events.on_lua_shortcut,function(event)
    if event.prototype_name == "open_spidertron_gui_shortcut" then
      open_spidertron_gui(game.players[event.player_index])
    end
  end)

  script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name:endswith("-x-button") then event.element.parent.parent.destroy(); return end
    if event.element.name:endswith("follow_button") then on_button_click_followme(event); return end
    if event.element.name:endswith("give_remote_button") then on_button_click_give_remote(event); return end
    if event.element.name:endswith("go_home_button") then on_button_click_go_home(event); return end
  end)

  script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.valid and event.element.name == "spidertron_manager_gui" then
      event.element.destroy()
    end
  end)

  script.on_event(defines.events.on_player_selected_area, function(event)
    if event.item ~= "spidertrons-manager-set-home-tool" then return end
    on_home_area_selected(event)
  end)

  script.on_event("open_spidertron_gui_shortcut", function(event)
    open_spidertron_gui(game.players[event.player_index])
  end)
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

script.on_init(function()
  init_storage()
  register_event_handlers()
end)

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(configuration_changed)
