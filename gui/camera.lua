require("constants")
require("lib.game")
require("lib.math")

local ZOOM_CONST = 0.028125
local ZOOM_MAX = 1.0
local ZOOM_MIN = 0.01

local spidertrons_manager = require("lib.spidertrons_manager")

-- gui/settings_window.lua
local CGui = require("gui.base")

local CCamera = {}
setmetatable(CCamera, { __index = CGui })
CCamera.__index = CCamera

function CCamera:new(surface_name, squad_name)
  local caption = surface_squad_caption(surface_name, squad_name)
  local instance = setmetatable({}, CCamera)
  CGui._init(instance, CAMERA_WINDOW_PREFIX .. surface_name .. ":" .. squad_name, caption)
  instance._surface_name = surface_name
  instance._squad_name = squad_name
  instance._camera = nil
  instance._side_size = 350
  return instance
end

function CCamera:_build_content(window, player)
    self:_squad_preview(window)
end

function CCamera:_calculate_zoom_for_bbox(bbox)
    local dx = bbox.right_bottom.x - bbox.left_top.x
    local dy = bbox.right_bottom.y - bbox.left_top.y

    -- Находим максимальную сторону (тернарный оператор быстрее math.max в LuaJIT)
    local max_dim = dx > dy and dx or dy

    -- Защита от деления на ноль и экстремального зума на вырожденных bbox (менее 0.5 тайла)
    if max_dim < 0.5 then max_dim = 0.5 end

    -- Расчет зума с учетом запаса
    local zoom = (self._side_size * ZOOM_CONST) / max_dim

    -- Быстрый clamp (ограничение) без вызова math.min / math.max
    if     zoom > ZOOM_MAX then return ZOOM_MAX
    elseif zoom < ZOOM_MIN then return ZOOM_MIN end

    return zoom
end

function CCamera:_squad_preview(window)
  local surface = as_surface(self._surface_name)
  local surface_index = surface.index

  local squad_leader = spidertrons_manager:squad_leader(spidertrons_manager:get_squad(surface, self._squad_name))
  local squad_bounding_box = spidertrons_manager:squad_bounding_box(surface, self._squad_name)

  self._camera = window.add({
      type = "camera",
      name = "sm_preview_camera",
      entity = squad_leader,
      position = get_area_center(squad_bounding_box),
      surface_index = surface_index,
  })
  self._camera.zoom = self:_calculate_zoom_for_bbox(squad_bounding_box)
  self._camera.style.size = {self._side_size, self._side_size}
end

function CCamera:update()
  if not spidertrons_manager:squad_exists(self._surface_name, self._squad_name) then return end
  local squad_bounding_box = spidertrons_manager:squad_bounding_box(self._surface_name, self._squad_name)
  self._camera.position = get_area_center(squad_bounding_box)
  self._camera.zoom = self:_calculate_zoom_for_bbox(squad_bounding_box)
end

return CCamera
