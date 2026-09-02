function dumpvar(data)
  local padder = '  '

  local cache  = { }
  local buffer = ''

  local function _dumpvar(d, depth)
    local t   = type(d)
    local str = tostring(d)
    if t == 'table' then
      if cache[str] then
        buffer = f('%s<%s>\n', buffer, str) -- Table dumped already: don't dump it again, mention it instead
      else
        cache[str] = true
        buffer = f('%s(%s)\n%s{\n', buffer, str, padder * depth)
        for k, v in pairs(d) do
          buffer = f('%s%s[%s] = ', buffer, padder * (depth + 1), type(k) == 'string' and f('"%s"', k) or tostring(k))
          _dumpvar(v, depth + 1)
        end
        buffer = f('%s%s}\n', buffer, padder * depth)
      end
    elseif t == 'number' then
      buffer = f('%s%s (%s)\n', buffer, str, t)
    elseif t == 'userdata' or t == 'function' or t == 'thread' then
      buffer = f('%s(%s)\n', buffer, str)
    elseif t == 'nil' then
      buffer = f('%s(%s)\n', buffer, t)
    else
      buffer = f('%s"%s" (%s)\n', buffer, str, t)
    end
  end

  _dumpvar(data, 0)
  return buffer
end

function print_r(...) -- Supports nil parameters
  for i = 1, select('#', ...) do
    print(dumpvar((select(i, ...))))
  end
  return true
end

function print_widget(widget)
  if not isWidget(widget) then
    print('Not a widget.')
    return
  end

  print(f('Id: %s | Class: %s | Style: %s', widget:getId(), widget:getClassName(), widget:getStyleName()))
end
