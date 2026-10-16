
local function add_titlebar(gui, caption, close_button_name)
  local titlebar = gui.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = gui
  titlebar.style.height = 8
  -- titlebar.add{
  --   type = "label",
  --   style = "frame_title",
  --   caption = caption,
  --   ignored_by_interaction = true,
  -- }
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  filler.style.height = 8
  filler.style.horizontally_stretchable = true
  -- titlebar.add{
  --   type = "sprite-button",
  --   name = close_button_name,
  --   style = "frame_action_button",
  --   sprite = "utility/close",
  --   hovered_sprite = "utility/close_black",
  --   clicked_sprite = "utility/close_black",
  --   tooltip = {"gui.close-instruction"},
  -- }
end

function add_window(player_storage, player, name, caption)
  local gui = player.gui.screen.add{type = "frame", name = name, direction = "vertical"}

  local window_position = player_storage.load_player_data(player, "window_position", nil)
  if window_position ~= nil
  then
    gui.location = window_position
  else
    gui.auto_center = true
  end
  local close_button_name = name .. "-x-button"
  add_titlebar(gui, caption, close_button_name)
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
