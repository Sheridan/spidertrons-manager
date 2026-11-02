
function as_surface(surface)
  if surface == nil then return nil end
  if type(surface) == "string" then
    surface = game.surfaces[surface]
  end
  return surface
end

function is_character_on_surface(player, surface)
  return player.character and player.character.valid and player.character.surface and player.character.surface == surface
end

function surface_localised_name(surface)
  if surface.localised_name then
    return surface.localised_name
  end
  if surface.planet then
    return surface.planet.prototype.localised_name
  end
  local name = surface.name
  return name:sub(1, 1):upper() .. name:sub(2)
end

function surface_sprite(surface)
  if surface.planet then
    return "[planet=" .. surface.planet.name .. "] "
  end
  return nil
end

function surface_caption(surface)
  surface = as_surface(surface)
  local name = surface_localised_name(surface)
  local sprite = surface_sprite(surface)
  if sprite ~= nil then
    return {"", sprite, name}
  end
  return name
end

function surface_squad_caption(surface_name, squad_name)
  local sc = surface_caption(surface_name)
  if type(sc) == "string" then
    return sc .. " : " .. squad_name
  end
  table.insert(sc, " : ")
  table.insert(sc, squad_name)
  return sc
end

function close_all_windows(player)
  for _,element in ipairs(player.gui.screen.children) do
    if element.name:startswith(GUI_NAME) then
      element.destroy()
    end
  end
end
