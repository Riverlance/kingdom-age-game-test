
-- Support to __gc metamethod
do
  local gcProxies = { }

  -- The values in gcProxies are strong because they refer to their own keys.
  -- So, it needs to be forced to have also weak values, since we want to remove each entry from gcProxies if its key (metatable) is not in use anymore anywhere.
  setmetatable(gcProxies, { __mode = 'kv' }) -- Make keys and values weak

  local _setmetatable = setmetatable
  function setmetatable(table, metatable)
    if metatable.__gc then
      -- Create an empty userdata (the only values in Lua 5.1 that work with __gc metamethod is userdata).
      -- Then, we insert it in gcProxies (weak table); so when metatable is not in use anymore, it will also remove it from gcProxies.
      gcProxies[metatable] = newproxy(true)

      -- __gc from metatable of gcProxies[metatable] call __gc from metatable
      getmetatable(gcProxies[metatable]).__gc = function()
        if type(metatable.__gc) == 'function' then
          metatable.__gc(table)
        end
      end
    end

    return _setmetatable(table, metatable)
  end
end

-- Support to __len metamethod
do
  -- string (works only for `string:len()`, not for # symbol)
  local _stringlen = string.len
  function string:len()
    self     = tostring(self)
    local mt = getmetatable(self)
    if mt and mt.__len then
      return mt.__len(self)
    end
    return _stringlen(self)
  end

  -- table (works only for `table.getn`, not for # symbol)
  local _tablegetn = table.getn
  function table.getn(t)
    local mt = getmetatable(t)
    if mt and mt.__len then
      return mt.__len(t)
    end
    return _tablegetn(t)
  end
end

-- Support to __ipairs metamethod
do
  local _ipairs = ipairs
  function ipairs(data)
    local metatable = getmetatable(data)
    if metatable and metatable.__ipairs then
      return metatable.__ipairs(data)
    end
    return _ipairs(data)
  end
end

-- Support to __pairs metamethod
do
  local _pairs = pairs
  function pairs(data)
    local mt = getmetatable(data)
    if mt and mt.__pairs then
      return mt.__pairs(data)
    end
    return _pairs(data)
  end
end

--[=[
local MyClass = { }

MyClass.__ipairs = function(t)
  local i = 0
  return function()
    i = i + 1

    -- Implement your own `key`/`value` selection logic in place of `next`
    if t[i] then
      return i, t[i]
    end
  end
end

MyClass.__pairs = function(t)
  local k
  return function()
    local v

    -- Implement your own `key`/`value` selection logic in place of `next`
    k, v = next(t, k)
    if v then
      return k, v
    end
  end
end

local myObject = setmetatable({ 7, 8, ['x'] = 9 }, MyClass)

for i, v in ipairs(myObject) do
  print(i, v) --> 1 7; 2 8
end

for k, v in pairs(myObject) do
  print(k, v) --> 1 7; 2 8; 'x' 9
end
--]=]

-- Support to table parameter on newproxy
--[=[
  local proxy = newproxy{ }
  proxy.x = 7
  print(proxy.x) --> 7
  print((newproxy{y=8}).y) --> 8
  print(newproxy(proxy).x) --> 7
]=]
do
  local proxiesData = { }
  setmetatable(proxiesData, { __mode = 'k' }) -- Make keys weak

  local _newproxy = newproxy
  ---@version 5.1
  ---@param proxy boolean|table|userdata
  ---@return userdata
  ---@nodiscard
  function newproxy(proxy)
    if type(proxy) ~= 'table' then
      return _newproxy(proxy)
    end

    local values = proxy

    proxy    = _newproxy(true)
    local mt = getmetatable(proxy)

    function mt.__index(self, k)
      return proxiesData[proxy] and proxiesData[proxy][k] or nil
    end

    function mt.__newindex(self, k, v)
      proxiesData[proxy]    = proxiesData[proxy] or { }
      proxiesData[proxy][k] = v
    end

    -- Copy values to proxiesData
    for k, v in pairs(values) do
      proxy[k] = v
    end

    return proxy
  end
end
