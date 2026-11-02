local player_storage = require("lib.player_storage")
local gui_manager = require("gui.gui_manager")
local CGui = {}
CGui.__index = CGui

function CGui:extend()
  local child = {}
  child.__index = child
  setmetatable(child, { __index = self })
  return child
end

function CGui:_init(window_name, caption)
  self._window_name = window_name
  self._caption = caption
end

function CGui:_window(player)
  local w = player.gui.screen[self._window_name]
  return (w and w.valid) and w or nil
end

function CGui:is_opened(player)
  return player.gui.screen[self._window_name] ~= nil
end

function CGui:_add_titlebar(window)
  local titlebar = window.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = window
  titlebar.style.height = 8
  if self._caption ~= nil then
    titlebar.add{
      type = "label",
      style = "sm_window_caption_label",
      caption = self._caption,
      ignored_by_interaction = true,
    }
  end
  local filler = titlebar.add{ type = "empty-widget", style = "draggable_space", ignored_by_interaction = true }
  filler.style.height = 8
  filler.style.horizontally_stretchable = true
  local close_button = titlebar.add{
    type = "sprite-button",
    name = self._window_name .. "-x-button",
    style = "sm_window_close_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black"
  }
  close_button.tags = { window_name = self._window_name }
end

function CGui:_add_window(player)
  local window = player.gui.screen.add{type = "frame", name = self._window_name, direction = "vertical"}
  window.style.horizontally_stretchable = true
  window.style.horizontally_squashable = true
  local window_location = player_storage:load_window_location(player, self._window_name)
  if window_location ~= nil then
    window.location = window_location
  else
    window.auto_center = true
  end

  self:_add_titlebar(window)
  return window
end

function CGui:show(player)
  if self:is_opened(player) then return end

  local window = self:_add_window(player)
  self:_build_content(window, player)
  self:on_show(player, window)
  gui_manager:add_gui(self._window_name, self)
end

function CGui:hide(player)
  if not self:is_opened(player) then return end

  local window = self:_window(player)
  if not window then return end

  if window.valid then
    player_storage:save_window_location(player, self._window_name, window.location)
    window.destroy()
    self:on_hide(player)
  end
  gui_manager:rm_gui(self._window_name)
end

-- virtual methods
function CGui:_build_content(window, player)
  error("Метод _build_content должен быть реализован в дочернем классе")
end

function CGui:on_show(player, window)
    -- По умолчанию ничего не делаем
end

function CGui:on_hide(player, window)
    -- По умолчанию ничего не делаем
end

return CGui
