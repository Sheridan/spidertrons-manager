data:extend({
  {
      type = "shortcut",
      name = "open_spidertron_gui_shortcut",
      localised_name = {"shortcut-name.open_spidertron_gui_shortcut"},
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
    name = "spidertrons-manager-set-home-tool",
    flags = { "only-in-cursor", "not-stackable" },
    hidden = true,
    hidden_in_factoriopedia = true,
    stack_size = 1,
    icon = "__core__/graphics/green-circle.png",
    icon_size = 25,
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
    name = "open_spidertron_gui_shortcut",
    key_sequence = "U"
  },
  {
    type = "sprite",
    name = "open_spidertron_settings",
    filename = "__spidertrons-manager__/graphics/icons/open_spidertron_settings-64.png",
    -- priority = "extra-high-no-scale",
    width = 64,
    height = 64,
    flags = {"gui-icon"},
    mipmap_count = 2,
    scale = 0.5
  },
  {
    type = "sprite",
    name = "open_spidertron_view",
    filename = "__spidertrons-manager__/graphics/icons/eye-64.png",
    -- priority = "extra-high-no-scale",
    width = 64,
    height = 64,
    flags = {"gui-icon"},
    mipmap_count = 2,
    scale = 0.5
  }
})
