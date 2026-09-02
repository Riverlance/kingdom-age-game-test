-- @docclass
function g_mouse.bindAutoPress(widget, callback, delay, button)
  local button = button or MouseLeftButton
  connect(widget, {
    onMousePress = function(widget, mousePos, mouseButton)
      if mouseButton ~= button then
        return false
      end

      local startTime = g_clock.millis()

      local function invokeCallback(currentMousePos, currentMouseButton, elapsed)
        if not isWidgetAlive(widget) then
          return
        end

        callback(widget, currentMousePos, currentMouseButton, elapsed)
      end

      local function isButtonPressed(currentMouseButton)
        if not isWidgetAlive(widget) then
          return false
        end

        return g_mouse.isPressed(currentMouseButton)
      end

      invokeCallback(mousePos, mouseButton, 0)

      periodicalEvent(function()
        invokeCallback(g_window.getMousePosition(), mouseButton, g_clock.millis() - startTime)
      end, function()
        return isButtonPressed(mouseButton) == true
      end, 30, delay)
      return true
    end
  })
end

function g_mouse.bindPressMove(widget, callback)
  connect(widget, {
    onMouseMove = function(widget, mousePos, mouseMoved)
      if widget:isPressed() then
        callback(mousePos, mouseMoved)
        return true
      end
    end
  })
end

function g_mouse.bindMove(widget, callback)
  connect(widget, {
    onMouseMove = function(widget, mousePos, mouseMoved)
      callback(mousePos, mouseMoved)
      return true
    end
  })
end

function g_mouse.bindPress(widget, callback, button)
  connect(widget, {
    onMousePress = function(widget, mousePos, mouseButton)
      if not button or button == mouseButton then
        callback(mousePos, mouseButton)
        return true
      end
      return false
    end
  })
end

function g_mouse.bindOnDrop(widget, callback)
  connect(widget, {
    onDrop = function(widget, mousePos)
      callback(mousePos, mouseButton)
      return true
    end
  })
end
