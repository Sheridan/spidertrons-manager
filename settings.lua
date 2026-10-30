require("constants")
data:extend({
  {
    type = "string-setting",
    name = PATHFIND_OPTION,
    setting_type = "runtime-per-user",
    default_value = "pathfinder",
    allowed_values = {"pathfinder", "direct"}
  }
})
