
require("constants")
local player_storage = require("lib.player_storage")
local spidertrons_manager = require("lib.spidertrons_manager")
local Singleton = require("lib.singleton")
local CGui = Singleton.derive("CGui")

local function surface_localised_name(surface)
  if surface.localised_name then
    return surface.localised_name
  end
  if surface.planet then
    return surface.planet.prototype.localised_name
  end
  local name = surface.name
  return name:sub(1, 1):upper() .. name:sub(2)
end

local function surface_sprite(surface)
  if surface.planet then
    return "[planet=" .. surface.planet.name .. "] "
  end
  return nil
end

local function surface_sprite_and_name(surface)
  local name = surface_localised_name(surface)
  local sprite = surface_sprite(surface)
  if sprite ~= nil then
    return {"", sprite, name}
  end
  return name
end

function CGui:_window(player)
    local w = player.gui.screen[GUI_NAME]
    return (w and w.valid) and w or nil
end

function CGui:_tabpane(player)
    local w = self:_window(player)
    return w and w["spidertron_manager_tabbed_pane"] or nil
end

function CGui:_add_titlebar(window)
  local titlebar = window.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = window
  titlebar.style.height = 8
  local filler = titlebar.add{ type = "empty-widget", style = "draggable_space", ignored_by_interaction = true }
  filler.style.height = 8
  filler.style.horizontally_stretchable = true
end

function CGui:_add_tabpane(window)
  window.add{ type = "tabbed-pane", name = "spidertron_manager_tabbed_pane", style = "spidertron_manager_tabbed_pane" }
end

function CGui:_add_window(player)
    local window = player.gui.screen.add{type = "frame", name = GUI_NAME, direction = "vertical"}
    window.style.horizontally_stretchable = true
    window.style.horizontally_squashable = true

    local window_position = player_storage:load_window_position(player)
    if window_position ~= nil
    then
      window.location = window_position
    else
      window.auto_center = true
    end
    self:_add_titlebar(window)
    self:_add_tabpane(window)
end


function CGui:_add_tab(player, surface)
  local tabpane = self:_tabpane(player)
  local tab   = tabpane.add{ type = "tab"  , name = surface.name .. "_tab"    , style     = "spidertron_manager_tab", caption = surface_sprite_and_name(surface) }
  local frame = tabpane.add{ type = "frame", name = surface.name .. "_content", direction = "vertical"              , style = "sm_tab_content_frame"             }
                frame.add{   type = "flow" , name = surface.name .. "_table"  , direction = "vertical"              , style = "sm_tab_content_flow"              }
  tabpane.add_tab(tab, frame)
end

function CGui:_tab(player, surface)
  local tabpane = self:_tabpane(player)
  local tab_name = surface.name .. "_tab"
  for _, tab_data in pairs(tabpane.tabs) do
    if tab_data.tab.name == tab_name then
      return {tab = tab_data.tab, content = tab_data.content[surface.name .. "_table"]}
    end
  end
  return nil
end

function CGui:tab(player, surface)
  local tab = self:_tab(player, surface)
  if tab == nil then return nil end
  return tab.tab
end

function CGui:tab_content(player, surface)
  local tab = self:_tab(player, surface)
  if tab == nil then return nil end
  return tab.content
end

function CGui:select_surface_tab(player, surface)
  if not self:is_opened(player) then return end
  local tabpane = self:_tabpane(player)
  local tab_name = surface.name .. "_tab"
  for i, tab_data in ipairs(tabpane.tabs) do
    if tab_data.tab.name == tab_name then
      tabpane.selected_tab_index = i
      return
    end
  end
end


function CGui:_add_sprite_button(parent, name, tooltip, style, sprite, tags)
  return parent.add{
    type = "sprite-button",
    name = name,
    style = style,
    tooltip = tooltip,
    sprite = sprite,
    tags = tags
}
end

function CGui:_add_surface_table(surface, player)
  self:_add_tab(player, surface)
  local surface_table = self:tab_content(player, surface)
  local surface_squads = spidertrons_manager:get_surface_squads(surface)

  for squad_name, spidertrons in pairs(surface_squads) do
    local squad_leader = spidertrons_manager:squad_leader(surface, squad_name)
    local button_tags = { squad_name = squad_name, surface_name = surface.name }
    local row = surface_table.add{ type = "flow" , direction = "horizontal", style = "sm_squad_row" }
    local color_label =   row.add{ type = "label", caption = "◼", style = "sm_squad_color", }
    color_label.style.font_color = squad_leader.color
    color_label.style.font = "sm_squad_color_font"
    -- local color_box = row.add{ type = "progressbar", value = 1, style = "sm_squad_color_box"}
    -- color_box.style.color = squad_leader.color
    row.add{ type = "label", caption = #spidertrons                                     , style = "sm_squad_count"}
    row.add{ type = "label", caption = spidertrons_manager:spidertron_name(squad_leader), style = "sm_squad_name" }
    row.add{ type = "empty-widget", style = "sm_squad_filler", ignored_by_interaction = true }
    local button_flow = row.add{ type = "flow", direction = "horizontal", style = "sm_squad_buttons" }

    if player.character and player.character.valid and player.character.surface and player.character.surface == surface then
      self:_add_sprite_button(button_flow, squad_name .. "_sm_follow_button", { "sm_gui.follow_me_tooltip"}, "slot_button", "spidertron_follow", button_tags)
    end
    self:_add_sprite_button(button_flow, squad_name .. "_sm_go_location_button", { "sm_gui.go_location_tooltip"}, "slot_button", "spidertron_go_to_location", button_tags)
    self:_add_sprite_button(button_flow, squad_name .. "_sm_go_home_button"    , { "sm_gui.go_home_tooltip"}    , "slot_button", "spidertron_go_to_home"    , button_tags)
    self:_add_sprite_button(button_flow, squad_name .. "_sm_control_button"    , { "sm_gui.control_tooltip"}    , "slot_button", "spidertron_control"       , button_tags)
    self:_add_sprite_button(button_flow, squad_name .. "_sm_view_button"       , { "sm_gui.view_tooltip"}       , "slot_button", "open_spidertron_view"     , button_tags)
    self:_add_sprite_button(button_flow, squad_name .. "_sm_give_remote_button", { "sm_gui.give_remote_tooltip"}, "slot_button", "another_spidertron_remote", button_tags)
    self:_add_sprite_button(button_flow, squad_name .. "_sm_settings_button"   , { "sm_gui.settings_tooltip"}   , "slot_button", "open_spidertron_settings" , button_tags)

    surface_table.add{ type = "line", direction = "horizontal" }
  end
end

function CGui:is_opened(player)
  return player.gui.screen[GUI_NAME] ~= nil
end

function CGui:show(player)
  if self:is_opened(player) then return end
  self:_add_window(player)
  for _, surface in pairs(game.surfaces) do
    if spidertrons_manager:spidertrons_exists_on_surface(surface) then
      self:_add_surface_table(surface, player)
    end
  end
  self:select_surface_tab(player, player.surface)
  player.set_shortcut_toggled(SHORTCUT_NAME, true)
end

function CGui:hide(player)
  if not self:is_opened(player) then return end

  local window = self:_window(player)
  if not window then return end

  if window.valid then
    player_storage:save_window_position(player, window.location)
    window.destroy()
  end
  player.set_shortcut_toggled(SHORTCUT_NAME, false)
end

return CGui.get_instance()
