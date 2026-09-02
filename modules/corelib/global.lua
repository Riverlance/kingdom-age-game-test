-- @docvars @{

-- root widget
rootWidget = g_ui.getRootWidget()
modules = package.loaded

-- G is used as a global table to save variables in memory between reloads
G = G or { }

-- @}

-- @docfuncs @{

function scheduleEvent(callback, delay)
  local event = g_dispatcher.scheduleEvent(callback, delay)
  -- must hold a reference to the callback, otherwise it would be collected
  event._callback = callback
  return event
end

function addEvent(callback, front)
  local event = g_dispatcher.addEvent(callback, front)
  -- must hold a reference to the callback, otherwise it would be collected
  event._callback = callback
  return event
end

function cycleEvent(callback, interval)
  local event = g_dispatcher.cycleEvent(callback, interval)
  -- must hold a reference to the callback, otherwise it would be collected
  event._callback = callback
  return event
end

function periodicalEvent(eventFunc, conditionFunc, delay, autoRepeatDelay)
  delay = delay or 30
  autoRepeatDelay = autoRepeatDelay or delay

  local func
  func = function()
    if conditionFunc and not conditionFunc() then
      func = nil
      return
    end
    eventFunc()
    scheduleEvent(func, delay)
  end

  scheduleEvent(function()
    func()
  end, autoRepeatDelay)
end

function removeEvent(event)
  if event then
    event:cancel()
    event._callback = nil
  end
end

local function createWeakRef(value)
  return setmetatable({ value = value }, { __mode = 'v' })
end

-- Keep only a weak handle to the widget to avoid retaining destroyed widget references through timer callback closures
function withWeakWidget(widget, callback)
  local weakWidget = createWeakRef(widget)
  return function(...)
    local currentWidget = weakWidget.value
    if isWidgetAlive(currentWidget) then
      return callback(currentWidget, ...)
    end
  end
end

function isWidget(widget)
  return type(widget) == 'userdata' and type(widget.getStyleName) == 'function'
end

function isWidgetAlive(widget)
  return widget and not widget:isDestroyed()
end

dofile 'compat'

if not json then
  json = require 'json'
end

-- @}
