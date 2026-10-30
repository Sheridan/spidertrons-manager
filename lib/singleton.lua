local Singleton = {}
Singleton.__index = Singleton

function Singleton:_init()
end

function Singleton.derive(name)
    local class = {}
    class.__name = name or "Singleton"
    class.__index = class
    setmetatable(class, {
        __index = Singleton,
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
