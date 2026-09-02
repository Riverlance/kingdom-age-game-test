#

-- Methods

local stringMetatable = getmetatable('')

-- local helloString = 'Hello'

--[[
  local dateString = '03/15/94'
  print(dateString()) --> nil
  print(dateString('(%d+)/(%d+)/(%d+)')) --> 03 15 94
  local weirdString = 'A 789 C A 789 A'
  print(weirdString('(%d+)')) --> 789 (same as weirdString:match('(%d+)'); match first '789')
  print(weirdString('(%d+)', 4)) --> 89 (same as weirdString:match('(%d+)', 4); match sliced '789' from pos 4)
  print(weirdString('(%d+)', 6)) --> 89 (same as weirdString:match('(%d+)', 6); match complete '789' from pos 6)
]]
if not stringMetatable.isset__call then
  local stringMetamethodCall = stringMetatable.__call
  stringMetatable.__call = function(self, ...)
    local args = {...}
    if #args > 0 and type(args[1]) == 'string' then
      return self:match(...)
    end
    if stringMetamethodCall then
      return stringMetamethodCall(self, ...)
    end
    return nil
  end
  stringMetatable.isset__call = true -- Set only once
end

--[[
  print(helloString[1]) --> H
  print(helloString[2]) --> e
  print(helloString[{1,2}]) --> He
  print(('Hello, world!')[{'world', 'Lua'}]) --> Hello, Lua!
  print(('A B C A B A')[{'A', '_', 2}]) --> _ B C _ B A
]]
if not stringMetatable.isset__index then
  local stringMetamethodIndex = stringMetatable.__index
  stringMetatable.__index = function(self, v)
    if type(v) == 'table' then
      if type(v[1]) == 'number' then
        return self:sub(v[1], v[2])
      elseif type(v[1]) == 'string' then
        return self:gsub(unpack(v))
      end
    elseif type(v) == 'number' then
      return self:sub(v, v)
    end
    return stringMetamethodIndex[v]
  end
  stringMetatable.isset__index = true -- Set only once
end

--[[
  print(helloString + ', world!') --> Hello, world!
  print(helloString + 7) --> Hello7
  print(helloString + true) --> Hellotrue
]]
stringMetatable.__add = function(self, value)
  return f('%s%s', self, tostring(value))
end

-- print(helloString - 3) --> He
stringMetatable.__sub = function(self, value)
  local size = #self - value
  return size > 0 and self:sub(1, size) or ''
end

--[[
  print(helloString * 3) --> HelloHelloHello
  print(helloString * -1) --> olleH
  print(helloString * -3) --> olleHolleHolleH
]]
stringMetatable.__mul = function(self, value)
  return (value < 0 and self:reverse() or self):rep(math.abs(value))
end

-- print_r('Have a nice day' / ' ') --> { 'Have', 'a', 'nice', 'day' }
stringMetatable.__div = function(self, value)
  return self:split(value)
end

--[[
  print('Have a nice day' % 'Have') --> true
  print('Have a nice day' % 'Has') --> false
  print('Have a nice day' % {'Has', 'Have'}) --> true
  print('Have a nice day' % {}) --> false
  print('Have a nice day' % nil) --> false
]]
stringMetatable.__mod = function(self, value)
  if type(value) == 'table' then
    return self:contains(unpack(value or { }))
  end
  return self:contains(value)
end

--[[
  print('abc' == 'abc') --> true
  print('abc' < 'def') --> true
  print('abc' > 'def') --> false
]]



-- Special functions

-- f(formatString, ...)
-- Inspired by 'f-string' of Python
-- e.g, f('My %s value is %.2f.', 'foo', 7.8) --> My foo value is 7.80.
f = string.format

-- r-string
-- Use your string between [[]]
-- e.g, [[Hello, world.\nThis is my literal string.]]

--- Returns a table of a binary version of a string.
---
--- IMPORTANT: This idiom only works for strings somewhat shorter than 1MB.
---
--- Inspired by `b-string` of Python.
---
--- e.g, b'Hello!' --> { 72, 101, 108, 108, 111, 33 }
--- @param str string
--- @return table
function b(str)
  return { str:byte(1, -1) }
end



-- Base

function string.exists(self)
  return self and self ~= ''
end

function string:split(delim)
  local start = 1
  local results = { }
  while true do
    local pos = self:find(delim, start, true)
    if not pos then
      break
    end
    table.insert(results, self:sub(start, pos-1))
    start = pos + #delim
  end
  table.insert(results, self:sub(start))
  table.removevalue(results, '', true)
  return results
end



-- Find

function string:contains(...)
  for _, keyword in ipairs{ ... } do
    if (' ' .. self .. ' '):find('%s+' .. keyword .. '[%s%p]+') then
      return true
    end
  end
  -- return message:find(keyword) and not message:find('(%w+)' .. keyword)
  return false
end

function string:starts(start)
  return self:sub(1, #start) == start
end

function string:ends(test)
  return test == '' or self:sub(-#test) == test
end



-- Format

function string:trim()
  return self:match('^%s*(.*%S)') or ''
end

function string:getCompactPath() -- path/file.ext to path/file
  return self:match('(.+)%..-$')
end

function string:removeBorders(begin, final) -- ([begin], [final])
  return self:match((begin or '') .. '(.+)' .. (final or ''))
end

function string:comma() -- Tip: You probably want to use tr(...) / loc(...) instead
  local left, num, right = self:match('^([^%d]*%d)(%d*)(.-)$')
  return left .. num:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. right
end

function string:getArticle()
  return self:find('[AaEeIiOoUuYy]') == 1 and 'an' or 'a'
end

function string:getMonthDayEnding() -- You can use as string.getMonthDayEnding(1) too
  local number = tonumber(self)
  if number then
    if number == 1 or number == 21 or number == 31 then
      return 'st'
    elseif number == 2 or number == 22 then
      return 'nd'
    elseif number == 3 or number == 23 then
      return 'rd'
    end
  end
  return 'th'
end

function string:getMonthString() -- You can use as string.getMonthString(1) too
  return os.date('%B', os.time{year = 1970, month = self, day = 1})
end

function string:eval(params)
  local result, occurrences = self:gsub('${(%w+)}', params)
  if occurrences == 0 then
    return result
  end
  return result:eval(params)
end



-- Iterator

--- Traverses all words of a string.
---
--- e.g, for w in ('Lorem ipsum dolor sit amet.'):words() do print(w) end --> Lorem; ipsum; dolor; sit; amet
--- @param startPos number
--- @return function
function string:words(startPos)
  local pos = startPos or 1 -- Current position in the string
  return function() -- Iterator function
    local word, _pos = self:match('(%w+)()', pos) -- '()' returns the position after the word
    if word then
      pos = _pos -- Next position is after this word
      return word
    end
    return nil
  end
end



-- Randomize / shuffle

local function getFatorial(n)
  return n == 0 and 1 or n * getFatorial(n - 1)
end

local function randomizeTable(_table, begin, final) -- (_table[, begin[, final]])
  -- math.randomseed(os.time()) -- do not use
  if not _table or type(_table) ~= 'table' or table.empty(_table) then
    return nil
  end
  if begin == -1 or final == -1 then
    return _table
  end

  local sequence, ret = { }, { }
  -- Randomize Table Positions
  local size = begin and final and final-begin+1 or #_table
  while #sequence ~= size do
    local random = begin and final and math.random(begin, final) or math.random(#_table)
    if not table.contains(sequence, random) then
      table.insert(sequence, random)
    end
  end

  -- Copy table
  local cache = { }
  for i = 1, #_table do
    cache[i] = _table[i]
  end

  for k1, _ in pairs(_table) do
    for k2, v2 in pairs(sequence) do
      if k1 == k2 + (begin and begin - 1 or 0) then
        _table[k1] = cache[v2]
      end
    end
  end
  return _table
end

function string:getCombinations(begin, final, size, result) -- ([begin[, final[, size])
  result = result or 1

  local letters, combinations = { }, { }

  local length = #self
  for i = 1, length do
    table.insert(letters, self:sub(i, i))
  end

  local _result = 0
  while true do
    local str = table.concat(randomizeTable(letters, begin, final) or { }, '')

    -- Slice
    if type(size) == 'number' and size > 0 and size < #str then
      str = str:sub(1, size)
    end

    -- Combine
    if not table.contains(combinations, str) then
      table.insert(combinations, str)
    end
    if #combinations == getFatorial(length) then
      break
    end

    _result = _result + 1
    if _result >= result then
      break
    end
  end

  table.sort(combinations)
  -- print(table.concat(combinations, '\n')) -- For debugging

  return combinations
end

function string:mix(lockBorders, decrease)
  if decrease then
    lockBorders = false
  end

  local str = self
  if #str < 1 then
    return str
  end

  local cursorPos = 1

  repeat
    -- Crossed the string
    if cursorPos > #str then
      break
    end

    -- Search for letters to mix
    local lettersLeftPos, lettersRightPos, letters = str:find('[^%a]*([%a]+)[^%a]*', cursorPos)

    -- No letters to mix were found
    if not lettersLeftPos then
      break
    end

    -- Found letters to mix
    local lettersAmount = #letters
    local newAmount     = decrease and math.random(lettersAmount) or lettersAmount
    if lockBorders and lettersAmount > 3 then -- We need at least 2 internal characters to mix (it means 4 characters on total)
      str = str:gsub(letters, letters:getCombinations(2, lettersAmount - 1, newAmount)[1], 1)

    elseif not lockBorders and lettersAmount > 1 then
      str = str:gsub(letters, letters:getCombinations(1, lettersAmount, newAmount)[1], 1)
    end

    -- Update lettersRightPos
    if newAmount < lettersAmount then
      lettersRightPos = lettersRightPos - (lettersAmount - newAmount)
    end

    -- Update cursorPos
    cursorPos = lettersRightPos + 1
  until false

  return str
end
