
local function add_titlebar(gui, caption, close_button_name)
  local titlebar = gui.add{type = "flow"}
  titlebar.drag_target = gui
  titlebar.add{
    type = "label",
    style = "frame_title",
    caption = caption,
    ignored_by_interaction = true,
  }
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  titlebar.add{
    type = "sprite-button",
    name = close_button_name,
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = {"gui.close-instruction"},
  }
end

function add_window(player, name, caption)
  local gui = player.gui.screen.add{type = "frame", name = name, direction = "vertical"}
  if storage.window_position
  then
    gui.location = storage.window_position
  else
    gui.auto_center = true
  end
  local close_button_name = name .. "-x-button"
  add_titlebar(gui, caption, close_button_name)
  player.opened = gui
  return gui
end


function add_sprite_button(gui, name, tooltip, style, sprite, tags)
  return gui.add{
    type = "sprite-button",
    name = name,
    style = style,
    tooltip = tooltip,
    sprite = sprite,
    tags = tags
}
end
