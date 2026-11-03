require("constants")
require("lib.game")
require("lib.math")
local scheduler = require("lib.scheduler")

local ZOOM_CONST = 0.028125
local ZOOM_MAX = 1.0
local ZOOM_MIN = 0.01
local WINDOW_SIDE_SIZE = 350

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
  instance._squad = spidertrons_manager:get_squad(surface_name, squad_name)
  instance._camera = nil
  return instance
end

function CCamera:_build_content(window, player)
    self:_squad_preview(window)
end

function CCamera:_calculate_zoom_for_bbox(bbox)
    local dx = bbox.right_bottom.x - bbox.left_top.x
    local dy = bbox.right_bottom.y - bbox.left_top.y

    local max_dim = dx > dy and dx or dy -- Max side
    if max_dim < 0.5 then max_dim = 0.5 end -- if bounding box too small

    local zoom = (WINDOW_SIDE_SIZE * ZOOM_CONST) / max_dim
    if     zoom > ZOOM_MAX then return ZOOM_MAX
    elseif zoom < ZOOM_MIN then return ZOOM_MIN end

    return zoom
end

function CCamera:_squad_preview(window)
  local surface_index = self._squad.surface.index

  local squad_leader = spidertrons_manager:squad_leader(self._squad)
  local squad_bounding_box = spidertrons_manager:squad_bounding_box(self._squad)

  self._camera = window.add({
      type = "camera",
      name = "sm_preview_camera",
      entity = squad_leader,
      position = get_area_center(squad_bounding_box),
      surface_index = surface_index,
  })
  self._camera.zoom = self:_calculate_zoom_for_bbox(squad_bounding_box)
  self._camera.style.size = {WINDOW_SIDE_SIZE, WINDOW_SIDE_SIZE}
end

function CCamera:on_show(player, window)
  scheduler:add(self)
end

function CCamera:on_hide(player, window)
  scheduler:rm(self)
end

function CCamera:valid()
  return spidertrons_manager:squad_valid(self._squad)
end

function CCamera:update()
  if not spidertrons_manager:squad_is_moving(self._squad) then return end
  local squad_bounding_box = spidertrons_manager:squad_bounding_box(self._squad)
  self._camera.position = get_area_center(squad_bounding_box)
  self._camera.zoom = self:_calculate_zoom_for_bbox(squad_bounding_box)
end

return CCamera
