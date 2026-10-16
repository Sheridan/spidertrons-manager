function get_area_center(area)
  return {
    x = (area.left_top.x + area.right_bottom.x) / 2,
    y = (area.left_top.y + area.right_bottom.y) / 2
  }
end

function calculate_grid_positions(area, count)
  if count <= 0 then return {} end
  if count == 1 then
    local cx = (area.left_top.x + area.right_bottom.x) / 2
    local cy = (area.left_top.y + area.right_bottom.y) / 2
    return {{x = cx, y = cy}}
  end

  local width = area.right_bottom.x - area.left_top.x
  local height = area.right_bottom.y - area.left_top.y

  width = math.max(width, 2)
  height = math.max(height, 2)

  local ratio = width / height

  local rows = math.ceil(math.sqrt(count / ratio))
  local cols = math.ceil(count / rows)

  if cols * rows < count then
    cols = cols + 1
  end

  local step_x = width / cols
  local step_y = height / rows

  local positions = {}
  local idx = 1

  for r = 0, rows - 1 do
    for c = 0, cols - 1 do
      if idx > count then break end

      local px = area.left_top.x + (c + 0.5) * step_x
      local py = area.left_top.y + (r + 0.5) * step_y

      table.insert(positions, {x = px, y = py})
      idx = idx + 1
    end
    if idx > count then break end
  end

  return positions
end
