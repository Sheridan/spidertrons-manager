-- local player_storage = require("lib.player_storage")
local Singleton = require("lib.singleton")

local CScheduler = {}
CScheduler.__index = CScheduler
local CScheduler = Singleton.derive("CScheduler")

---
--- CScheduler class
---

function CScheduler:_init()
  self._regular = {}
  self._one_shoot = {}
  self._subscribed = false
end

function CScheduler:is_empty()
  return next(self._regular) == nil and next(self._one_shoot) == nil
end

function CScheduler:add(obj)
  self._regular[obj] = true
  self:_check_subscription()
end

function CScheduler:one_shoot(obj, after_ticks)
  self._one_shoot[obj] = after_ticks
  self:_check_subscription()
end

function CScheduler:rm(obj)
  if self._regular[obj] ~= nil then
    self._regular[obj] = nil
    self:_check_subscription()
  end
end

function CScheduler:_call_regular()
  for obj in pairs(self._regular) do
    if obj:valid() then
      obj:update()
    else
      self._regular[obj] = nil
    end
  end
end

function CScheduler:_call_one_shoot()
  for obj in pairs(self._one_shoot) do
    if obj:valid() then
      local ticks_to_skip = self._one_shoot[obj]
      if ticks_to_skip == 0 then
        -- log("Time to shoot!")
        obj:update()
        self._one_shoot[obj] = nil
      else
        -- log("Waiting....")
        self._one_shoot[obj] = self._one_shoot[obj] - 1
      end
    else
      self._one_shoot[obj] = nil
    end
  end
end

function CScheduler:update(tick)
  self:_call_regular()
  self:_call_one_shoot()
end

function CScheduler:_subscribe()
  if self._subscribed then return end

  local handler = function(event)
    self:update(event.tick)
  end

  script.on_event(defines.events.on_tick, handler)
  self._subscribed = true
  log("Subscribed")
end

function CScheduler:_unsubscribe()
  if not self._subscribed then return end
  script.on_event(defines.events.on_tick, nil)
  self._subscribed = false
  log("Unsubscribed")
end

function CScheduler:_check_subscription()
  if self:is_empty() then
    self:_unsubscribe()
  else
    self:_subscribe()
  end
end

return CScheduler.get_instance()
