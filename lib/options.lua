require("constants")

function use_pathfinding(player, shift)
  local movement = settings.get_player_settings(player.index)[PATHFIND_OPTION].value
  return (movement == "pathfinder" and not shift) or (movement == "direct" and shift)
end
