require("constants")
require("lib.game")
local spidertrons_manager = require("lib.spidertrons_manager")

local Singleton = require("lib.singleton")
local CGui = require("gui.base")
local CManagerGui = Singleton.derive("CManagerGui", CGui)

function CManagerGui:_init()
    CGui._init(self, GUI_NAME)
end

function CManagerGui:_tabpane(player)
    local w = self:_window(player)
    return w and w["spidertron_manager_tabbed_pane"] or nil
end

function CManagerGui:_add_tabpane(window)
  window.add{ type = "tabbed-pane", name = "spidertron_manager_tabbed_pane", style = "spidertron_manager_tabbed_pane" }
end

function CManagerGui:_add_tab(player, surface)
  local tabpane = self:_tabpane(player)
  local tab   = tabpane.add{ type = "tab"  , name = surface.name .. "_tab"    , style     = "spidertron_manager_tab", caption = surface_caption(surface) }
  local frame = tabpane.add{ type = "frame", name = surface.name .. "_content", direction = "vertical"              , style = "sm_tab_content_frame"             }
                frame.add{   type = "flow" , name = surface.name .. "_table"  , direction = "vertical"              , style = "sm_tab_content_flow"              }
  tabpane.add_tab(tab, frame)
end

function CManagerGui:_tab(player, surface)
  local tabpane = self:_tabpane(player)
  local tab_name = surface.name .. "_tab"
  for _, tab_data in pairs(tabpane.tabs) do
    if tab_data.tab.name == tab_name then
      return {tab = tab_data.tab, content = tab_data.content[surface.name .. "_table"]}
    end
  end
  return nil
end

function CManagerGui:tab(player, surface)
  local tab = self:_tab(player, surface)
  if tab == nil then return nil end
  return tab.tab
end

function CManagerGui:tab_content(player, surface)
  local tab = self:_tab(player, surface)
  if tab == nil then return nil end
  return tab.content
end

function CManagerGui:select_surface_tab(player, surface)
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

function CManagerGui:_button_name(surface_name, squad_name, suffix)
  return surface_name .. ":" .. squad_name .. ":" .. suffix
end

function CManagerGui:_add_sprite_button(parent, name, tooltip, style, sprite, tags, hover_available)
  return parent.add{
    type = "sprite-button",
    name = name,
    style = style,
    tooltip = tooltip,
    sprite = sprite,
    tags = tags,
    raise_hover_events = hover_available
  }
end

function CManagerGui:_add_surface_table(surface, player)
  self:_add_tab(player, surface)
  local surface_table = self:tab_content(player, surface)
  local surface_squads = spidertrons_manager:get_surface_squads(surface)

  for squad_name, squad in pairs(surface_squads) do
    -- log(squad_name)
    local squad_leader = spidertrons_manager:squad_leader(squad)
    local button_tags = { squad_name = squad_name, surface_name = surface.name }
    local row = surface_table.add{ type = "flow" , direction = "horizontal", style = "sm_squad_row" }
    local color_label =   row.add{ type = "label", caption = "◼", style = "sm_squad_color", }
    color_label.style.font_color = squad_leader.color
    color_label.style.font = "sm_squad_color_font"
    -- local color_box = row.add{ type = "progressbar", value = 1, style = "sm_squad_color_box"}
    -- color_box.style.color = squad_leader.color
    row.add{ type = "label", caption = #squad.spidertrons                                     , style = "sm_squad_count"}
    row.add{ type = "label", caption = spidertrons_manager:spidertron_name(squad_leader), style = "sm_squad_name" }
    row.add{ type = "empty-widget", style = "sm_squad_filler", ignored_by_interaction = true }
    local button_flow = row.add{ type = "flow", direction = "horizontal", style = "sm_squad_buttons" }

    if is_character_on_surface(player, surface) then
      self:_add_sprite_button(button_flow, squad_name .. "_sm_follow_button", { "sm_gui.follow_me_tooltip"}, "slot_button", "spidertron_follow", button_tags, false)
    end
    self:_add_sprite_button(button_flow, self:_button_name(surface.name, squad_name, "sm_go_location_button"), { "sm_gui.go_location_tooltip"}, "slot_button", "spidertron_go_to_location", button_tags, false)
    self:_add_sprite_button(button_flow, self:_button_name(surface.name, squad_name, "sm_go_home_button"    ), { "sm_gui.go_home_tooltip"}    , "slot_button", "spidertron_go_to_home"    , button_tags, false)
    self:_add_sprite_button(button_flow, self:_button_name(surface.name, squad_name, "sm_control_button"    ), { "sm_gui.control_tooltip"}    , "slot_button", "spidertron_control"       , button_tags, false)
    self:_add_sprite_button(button_flow, self:_button_name(surface.name, squad_name, "sm_view_button"       ), { "sm_gui.view_tooltip"}       , "slot_button", "open_spidertron_view"     , button_tags, true)
    self:_add_sprite_button(button_flow, self:_button_name(surface.name, squad_name, "sm_give_remote_button"), { "sm_gui.give_remote_tooltip"}, "slot_button", "another_spidertron_remote", button_tags, false)
    self:_add_sprite_button(button_flow, self:_button_name(surface.name, squad_name, "sm_settings_button"   ), { "sm_gui.settings_tooltip"}   , "slot_button", "open_spidertron_settings" , button_tags, false)

    surface_table.add{ type = "line", direction = "horizontal" }
  end
end


function CManagerGui:_build_content(window, player)
  self:_add_tabpane(window)
  for _, surface in pairs(game.surfaces) do
    if spidertrons_manager:spidertrons_exists_on_surface(surface) then
      self:_add_surface_table(surface, player)
    end
  end
  self:select_surface_tab(player, player.surface)
end


function CManagerGui:on_show(player, window)
  player.set_shortcut_toggled(SHORTCUT_NAME, true)
end

function CManagerGui:on_hide(player)
  player.set_shortcut_toggled(SHORTCUT_NAME, false)
end

return CManagerGui.get_instance()
