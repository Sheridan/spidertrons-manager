-- lib/singleton.lua
local Singleton = {}
Singleton.__index = Singleton

function Singleton:_init()
end

function Singleton.derive(name, base_class)
    local class = {}
    class.__name = name or "Singleton"
    class.__index = class

    -- Если передан базовый класс — наследуемся от него, иначе от Singleton
    local base = base_class or Singleton

    setmetatable(class, {
        __index = base,
        __call = function(self)
            return self.get_instance()
        end,
    })

    class._instance = nil
    function class.get_instance()
        if class._instance then
            return class._instance
        end
        local instance = setmetatable({}, class)
        class._instance = instance
        instance:_init()
        return instance
    end
    return class
end

return Singleton
