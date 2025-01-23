data:extend({
  {
      type = "shortcut",
      name = "open_spidertron_gui_shortcut",
      localised_name = {"shortcut-name.open_spidertron_gui_shortcut"}, -- Локализованное имя
      icon = "__spidertrons-manager__/graphics/icons/spidertron-icon-64.png", -- Путь к иконке
      small_icon = "__spidertrons-manager__/graphics/icons/spidertron-icon-32.png", -- Путь к иконке
      icon_size = 64, -- Размер иконки
      small_icon_size = 32,
      action = "lua",
      on_lua_shortcut = "open_spidertron_gui", -- Имя события, которое будет вызвано
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
  }
})
