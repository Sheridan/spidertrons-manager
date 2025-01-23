function string:contains(sub)
  return self:find(sub, 1, true) ~= nil
end

function string:startswith(start)
  return self:sub(1, #start) == start
end

function string:endswith(ending)
  return ending and (ending == "" or self:sub(-#ending) == ending)
end

function string:replace(old, new)
  local s = self
  local search_start_idx = 1

  while true do
      local start_idx, end_idx = s:find(old, search_start_idx, true)
      if not start_idx then
          break
      end

      local postfix = s:sub(end_idx + 1)
      s = s:sub(1, start_idx - 1) .. new .. postfix

      search_start_idx = start_idx + #new
  end

  return s
end

function string:insert(pos, text)
  if pos < 1 or pos > #self + 1 then
      error("Position out of bounds")
  end
  return self:sub(1, pos - 1) .. text .. self:sub(pos)
end
