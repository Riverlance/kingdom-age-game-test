#

function pack(...)
  return {...}
end

function argsize(...)
  return select('#', ...)
end



--- Traverses a table in order, based on keys.
---
--- ```lua
--- local t = { coconut = 8, apple = 7, banana = 9 }
---  -- or local t = { ['coconut'] = 8, ['apple'] = 7, ['banana'] = 9 }
---
--- for k, v in sortedpairs(t) do
---   print(k, v) --> apple 7; banana 9; coconut 8
--- end
---
--- for k, v in sortedpairs(t, function(a, b) return a > b end) do
---   print(k, v) --> coconut 8; banana 9; apple 7
--- end
--- ```
--- @param t table
--- @param sortCallback function
--- @return function
function sortedpairs(t, sortCallback)
  local mt = getmetatable(t)
  if mt and mt.__sortedpairs then
    return mt.__sortedpairs(t, sortCallback)
  end

  local keys = { }
  for k in pairs(t) do
    keys[#keys + 1] = k
  end

  table.sort(keys, sortCallback)

  local i = 0
  return function()
    i = i + 1
    return keys[i], t[keys[i]] -- key, value
  end
end



-- Base

--- Gets a value from a zipped table.
---
--- Worst way: `local zip = company and company.director and company.director.address and company.director.address.zipcode`
---
--- Best way: `local zip = table.get(company, 'director', 'address', 'zipcode')`
--- @param t   table
--- @param ... string
--- @return any
function table.get(t, ...)
  local args         = {...}
  local __emptyTable = { }
  for i = 1, #args do
    t = (t or __emptyTable)[args[i]]
  end
  return t
end

function table.size(t)
  local size = 0
  for _ in pairs(t) do
    size = size + 1
  end
  return size
end

function table.empty(t)
  if type(t) == 'table' then
    return next(t) == nil
  end
  return true
end

function table.clear(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

function table.copy(t, keys, copied) -- (t[, keys])
  -- Internal usage to avoid loops
  copied = copied or { }
  if copied[t] then
    return copied[t]
  end

  local ret = { }

  copied[t] = ret

  if keys then
    for _, k in ipairs(keys) do
      local v = t[k]
      if type(v) == 'table' then
        ret[k] = table.copy(v, nil, copied)
      else
        ret[k] = v
      end
    end
  else
    for k, v in pairs(t) do
      if type(v) == 'table' then
        ret[k] = table.copy(v, nil, copied)
      else
        ret[k] = v
      end
    end
  end

  local metaTable = getmetatable(t)
  if metaTable then
    setmetatable(ret, metaTable)
  end

  return ret
end



-- Find

function table.contains(t, value)
  for _, targetColumn in pairs(t) do
    if targetColumn == value then
      return true
    end
  end

  return false
end

function table.find(t, value, lowercase)
  for k, v in pairs(t) do
    if lowercase and type(value) == 'string' and type(v) == 'string' then
      if v:lower() == value:lower() then
        return k
      end
    end

    if v == value then
      return k
    end
  end
end

function table.findbykey(t, key, lowercase)
  for k, v in pairs(t) do
    if lowercase and type(key) == 'string' and type(k) == 'string' then
      if k:lower() == key:lower() then
        return v
      end
    end

    if k == key then
      return v
    end
  end
end

function table.findbyfield(t, fieldname, fieldvalue)
  for _, subTable in pairs(t) do
    if subTable[fieldname] == fieldvalue then
      return subTable
    end
  end
  return nil
end

function table.findkey(t, key)
  for k in pairs(t) do
    if k == key then
      return k
    end
  end
end

function table.haskey(...)
  return table.findkey(...) ~= nil
end



-- Comparing

function table.equals(t, otherTable)
  for k, v in pairs(t) do
    if v ~= otherTable[k] then
      return false
    end
  end
  return true
end



-- Random / shuffle

function table.random(t)
  if table.empty(t) then
    return nil
  end

  local key = math.random(#t)
  return t[key], key
end

function table.shuffle(t)
  if #t < 2 then
    return t
  end

  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

function table.getRatedValue(t) -- Table value needs to be a table which contains a rate value: { ..., rate = 100, ... }
  local _t = table.shuffle(table.copy(t)) -- Copy and randomize for avoid that first rows have more chance than the others

  local rateFactor = 0 -- (_t[1].rate + _t[2].rate + ... + _t[n].rate)
  for _, value in ipairs(_t) do
    rateFactor = rateFactor + value.rate
  end
  if rateFactor <= 0 then
    return nil -- Cannot divide by 0 or is negative
  end

  local random        = math.random()
  local percentFactor = 1 / rateFactor

  for i = 1, #_t do
    local percentPiece = 0
    for j = 1, i do
      percentPiece = percentPiece + (_t[j].rate * percentFactor)
    end

    if random <= percentPiece then
      return _t[i]
    end
  end

  return nil
end



-- Insert / remove

function table.addKeys(t, keys)
  for _, k in ipairs(keys) do
    if type(k) == 'table' then
      for _k = k.from, k.to do
        t[_k] = true
      end
    else
      t[k] = true
    end
  end
end

function table.addValues(t, values)
  for _, v in ipairs(values) do
    if type(v) == 'table' then
      for _v = v.from, v.to do
        table.insert(t, _v)
      end
    else
      table.insert(t, v)
    end
  end
end

function table.keysAsValues(t, valueAsKey)
  local ret = { }

  if valueAsKey then
    for k, v in pairs(t) do
      ret[v] = k
    end
  else
    for k in pairs(t) do
      table.insert(ret, k)
    end
  end

  return ret
end

function table.valuesAsKeys(t, keyAsValue)
  local ret = { }

  if keyAsValue then
    for k, v in pairs(t) do
      ret[v] = k
    end
  else
    for _, v in pairs(t) do
      ret[v] = true
    end
  end

  return ret
end

function table.insertChild(t, index, value)
  if index then
    table.insert(t, index, value)
  else
    table.insert(t, value)
    index = #t
  end

  if type(value) == 'table' then
    value._parent = t
    value._id = index
  end

  return index
end

function table.insertall(t, otherTable)
  for _, v in pairs(otherTable) do
    table.insert(t, v)
  end

  return res
end

function table.collect(t, func)
  local res = { }

  for k, v in pairs(t) do
    local _k, _v = func(k, v)
    if _k and _v then
      res[_k] = _v
    elseif _k ~= nil then
      table.insert(res, _k)
    end
  end

  return res
end

function table.removeChild(t, index, recursive)
  if not t then
    return false
  end

  repeat
    t[index] = nil
    if table.size(t) == 2 then -- only parent and id values
      index = t._id
      t = t._parent
    else
      break
    end
  until not t or not recursive

  return t
end

function table.removevalue(t, value, all, force)
  for k, v in pairs(t) do
    if v == value then
      if force then
        t[k] = nil
      else
        table.remove(t, k)
        if not all then
          return true
        end
      end
    end
  end

  if not force and all then
    return true
  end
  return false
end

function table.popvalue(value)
  local index

  for k, v in pairs(t) do
    if v == value or not value then
      index = k
    end
  end

  if index then
    table.remove(t, index)
    return true
  end

  return false
end

function table.merge(t, sourceTable, overwrite) -- (t, sourceTable[, overwrite])
  if overwrite then
    for k, v in pairs(sourceTable) do
      t[k] = v
    end
    return t
  end

  local _t = table.copy(t)
  for k, v in pairs(sourceTable) do
    table.insert(_t, v)
  end

  return _t
end



-- Serialize

do
  local serializationCallbacks = { -- [type] = callback
    ['nil'] = function(t, __recursive)
      return tostring(t)
    end,

    ['boolean'] = function(t, __recursive)
      return tostring(t)
    end,

    ['number'] = function(t, __recursive)
      local function isInteger(num)
        return type(num) == 'number' and num == math.floor(num)
      end
      return f(isInteger(t) and '%d' or '%a', t)
    end,

    ['string'] = function(t, __recursive)
      return f('%q', t)
    end,

    ['table'] = function(t, __recursive)
      if getmetatable(t) then
        error('Was not possible to serialize a table that has a metatable associated with it.')
      elseif table.find(__recursive, t) then -- Cannot have any table referenced twice or more
        error('Was not possible to serialize recursive tables.')
      end
      table.insert(__recursive, t)

      local s = '{ '
      for k, v in pairs(t) do
        s = f('%s[%s] = %s, ', s, table.serialize(k, __recursive), table.serialize(v, __recursive))
      end
      return f('%s}', s)
    end,
  }

  function table.serialize(t, __recursive) -- (table) -- Do not use the recursive param
    local _type = type(t)
    __recursive = __recursive or { }

    if serializationCallbacks[_type] then
      return serializationCallbacks[_type](t, __recursive)
    end

    error(f("Was not possible to serialize the value of type '%s'", _type))
  end
end

function table.unserialize(str)
  assert(type(str) == 'string', 'Expected a string to unserialize.')

  local chunk, compileError = loadstring(string.format('return %s', str))
  if not chunk then
    return nil, compileError
  end

  -- Sandbox chunk: prevents access to globals while evaluating serialized table text.
  setfenv(chunk, { })

  local ok, value = pcall(chunk)
  if not ok then
    return nil, value
  end

  return value
end



-- Format

function table.list(t, sep)
  -- e.g, 'A, B and C'
  sep = sep or ','
  return (table.concat(t, f('%s ', sep)):gsub(f('%s ([^%s]+)$', sep, sep), f(' %s %%1', loc'${CorelibInfoAnd}'))) -- Return first value of gsub only
end
