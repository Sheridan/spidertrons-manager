require("constants")
-- local spidertrons_manager = require("lib.spidertrons_manager")

function sm_log(message)
  log(LOG_PREFIX .. message)
end

function sm_log_squad(squad)
  sm_log("Surface: " .. squad.surface.name)
  sm_log("Name: " .. squad.squad_name)
  sm_log("Spidertrons: " .. #squad.spidertrons)
end

function sm_log_found_squads(squads)
  for surface_name, surface_metadata in pairs(squads) do
    sm_log("--- Surface: (" .. surface_name .. ")[" .. surface_metadata.surface.name .. "] ---")
    for squad_name, squad in pairs(surface_metadata.squads) do
      sm_log("-- Squad " .. squad_name .. " --")
      sm_log_squad(squad)
    end
  end
end
