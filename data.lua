require("constants")
data:extend({
  {
      type = "shortcut",
      name = SHORTCUT_NAME,
      localised_name = {"shortcut-name." .. SHORTCUT_NAME},
      icon = "__spidertrons-manager__/graphics/icons/spidertron-icon-64.png",
      small_icon = "__spidertrons-manager__/graphics/icons/spidertron-icon-32.png",
      icon_size = 64,
      small_icon_size = 32,
      action = "lua",
      on_lua_shortcut = "open_spidertron_gui",
      toggleable = true
  },
  {
    type = "selection-tool",
    name = TOOL_SELECTION_HOME,
    flags = { "only-in-cursor", "not-stackable" },
    hidden = true,
    hidden_in_factoriopedia = true,
    stack_size = 1,
    icon = "__spidertrons-manager__/graphics/icons/home-32.png",
    icon_size = 32,
    select = {
      border_color = {10, 95, 163},
      cursor_box_type = "entity",
      mode = "nothing"
    },
    alt_select = {
      border_color = {1, 1, 1},
      cursor_box_type = "entity",
      mode = "nothing"
    }
  },
  {
    type = "selection-tool",
    name = TOOL_SELECTION_LOCATION,
    flags = { "only-in-cursor", "not-stackable" },
    hidden = true,
    hidden_in_factoriopedia = true,
    stack_size = 1,
    icon = "__spidertrons-manager__/graphics/icons/to_location-32.png",
    icon_size = 32,
    select = {
      border_color = {10, 95, 163},
      cursor_box_type = "entity",
      mode = "nothing"
    },
    alt_select = {
      border_color = {1, 1, 1},
      cursor_box_type = "entity",
      mode = "nothing"
    }
  },
  {
    type = "custom-input",
    name = SHORTCUT_NAME,
    key_sequence = "U",
    enabled = true
  },
  { type = "sprite", name = "open_spidertron_settings" , filename = "__spidertrons-manager__/graphics/icons/open_spidertron_settings-64.png", width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  { type = "sprite", name = "open_spidertron_view"     , filename = "__spidertrons-manager__/graphics/icons/eye-64.png",                      width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  { type = "sprite", name = "another_spidertron_remote", filename = "__spidertrons-manager__/graphics/icons/remote-64.png",                   width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  { type = "sprite", name = "spidertron_follow"        , filename = "__spidertrons-manager__/graphics/icons/follow-64.png",                   width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  { type = "sprite", name = "spidertron_go_to_home"    , filename = "__spidertrons-manager__/graphics/icons/home-64.png",                     width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  { type = "sprite", name = "spidertron_go_to_location", filename = "__spidertrons-manager__/graphics/icons/to_location-64.png",              width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  { type = "sprite", name = "spidertron_control"       , filename = "__spidertrons-manager__/graphics/icons/control-64.png",                  width = 64, height = 64, flags = {"gui-icon"}, scale = 0.5 },
  {
    name = "sm_squad_color_font",
    type = "font",
    from = "default-bold",
    size = 18
  },
    {
    type = "font",
    name = "sm_window_caption_font",
    from = "default-bold",
    size = 8
  }
})

local function extend_raw(type, extention)
  data.raw[type].default[extention.name] = extention
end
-- tabs --
extend_raw('gui-style', {
  type = "tabbed_pane_style",
  parent = "tabbed_pane",
  name = "spidertron_manager_tabbed_pane",
  horizontally_stretchable = "on",
  margin = 2,
  horizontal_align = "center"
})
extend_raw('gui-style', {
  name = "sm_tab_content_frame",
  type = "frame_style",
  parent = "frame",
  horizontally_stretchable = "on",
  horizontally_squashable = "on",
  vertically_stretchable = "on",
  padding = 8
})
extend_raw('gui-style', {
  name = "sm_tab_content_flow",
  type = "vertical_flow_style",
  parent = "vertical_flow",
  horizontally_stretchable = "on",
  horizontally_squashable = "on"
})
extend_raw('gui-style', {
  type = "tab_style",
  parent = "tab",
  name = "spidertron_manager_tab",
  margin = 2,
  padding = 2
})
extend_raw('gui-style', {
  type = "button_style",
  parent = "close_button",
  name = "sm_window_close_button",
  size = 16,
  margin = 0
})
extend_raw('gui-style', {
  type = "label_style",
  parent = "label",
  name = "sm_window_caption_label",
  font = "sm_window_caption_font"
})
-- row --

extend_raw('gui-style', {
  name = "sm_squad_row",
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  horizontally_stretchable = "on",
  horizontally_squashable = "on",
  vertical_align = "center",
  padding = 0
})

extend_raw('gui-style', {
  name = "sm_squad_color",
  type = "label_style",
  parent = "label",
  horizontally_stretchable = "off",
  horizontally_squashable = "off",
  width = 24,
  right_padding = 4
})

extend_raw('gui-style', {
  name = "sm_squad_count",
  type = "label_style",
  parent = "label",
  horizontally_stretchable = "off",
  horizontally_squashable = "off",
  width = 24,
  horizontal_align = "right",
  right_padding = 4
})

extend_raw('gui-style', {
  name = "sm_squad_name",
  type = "label_style",
  parent = "label",
  horizontally_stretchable = "off",
  horizontally_squashable = "off"
})

extend_raw('gui-style', {
  name = "sm_squad_buttons",
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  horizontally_stretchable = "off",
  horizontally_squashable = "off",
  horizontal_align = "right"
})

extend_raw('gui-style', {
  name = "sm_squad_filler",
  type = "empty_widget_style",
  parent = "empty_widget",
  horizontally_stretchable = "on",
  horizontally_squashable = "on"
})
