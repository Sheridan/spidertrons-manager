local Singleton = require("lib.singleton")

local CGuiManager = {}
CGuiManager.__index = CGuiManager

local CGuiManager = Singleton.derive("CGuiManager")

function CGuiManager:_init()
  self._guis = {}
end

function CGuiManager:add_gui(name, reference)
  self._guis[name] = reference
end

function CGuiManager:rm_gui(name)
  self._guis[name] = nil
end

function CGuiManager:gui(name)
  if self._guis[name] ~= nil then return self._guis[name] end
  return nil
end

function CGuiManager:hide_gui(name, player)
  if self._guis[name] ~= nil then
    self._guis[name]:hide(player)
  end
end

function CGuiManager:guis(name_prefix)
  local result = {}
  for name, ref in pairs(self._guis) do
    if name:startswith(name_prefix) then
      result[name] = ref
    end
  end
  return result
end

return CGuiManager.get_instance()
