g_mouseicon = { }

-- private variables
local fadeOutTime = 50
local mouseMoveDelay = 25
local defaultSize = { width = 32, height = 32 }
local defaultIconOpacity = 30 -- %
local defaultItemIconOpacity = 30 -- %
local mouseIcon
local mouseMoveEvent
local lastMouseIconPosX = -1
local lastMouseIconPosY = -1

-- private functions
local function moveIcon(mousePos, isFirstDisplay)
  if not mouseIcon or not isFirstDisplay and not mouseIcon:isVisible() then
    return
  end

  local pos       = mousePos and { x = mousePos.x, y = mousePos.y } or g_window.getMousePosition()
  local rootSize  = rootWidget:getSize()
  local labelSize = mouseIcon:getSize()
  local uiScale   = math.max(1, g_app.getResolvedUiScale())

  local probeOffset = math.max(1, math.round(1 / uiScale))
  local sideOffset  = math.max(1, math.round(10 / uiScale))
  local hoverOffset = math.max(1, math.round(10 / uiScale))

  pos.x = pos.x + probeOffset
  pos.y = pos.y + probeOffset

  if rootSize.width - (pos.x + labelSize.width) < hoverOffset then
    pos.x = pos.x - labelSize.width - sideOffset
  else
    pos.x = pos.x + hoverOffset
  end

  if rootSize.height - (pos.y + labelSize.height) < hoverOffset then
    pos.y = pos.y - labelSize.height
  end

  local maxX = math.max(0, rootSize.width - labelSize.width)
  local maxY = math.max(0, rootSize.height - labelSize.height)
  pos.x = math.max(0, math.min(pos.x, maxX))
  pos.y = math.max(0, math.min(pos.y, maxY))

  if pos.x == lastMouseIconPosX and pos.y == lastMouseIconPosY then
    return
  end

  mouseIcon:setPosition(pos)
  lastMouseIconPosX = pos.x
  lastMouseIconPosY = pos.y
end

local function onWidgetMouseRelease(widget, mousePos, mouseButton)
  g_mouseicon.hide()
end

-- public functions
function g_mouseicon.init()
  connect(UIWidget, {
    onMouseRelease = onWidgetMouseRelease
  })

  addEvent(function()
    mouseIcon = g_ui.createWidget('UIItem', rootWidget)
    mouseIcon:setFocusable(false)
    mouseIcon:setId('mouseIcon')
    mouseIcon:setPhantom(true)
    mouseIcon:hide()

    -- For item only
    mouseIcon:setVirtual(true)
    mouseIcon:setFont('verdana-11px-rounded')
    mouseIcon:setBorderColor('white')
    mouseIcon:setColor('white')
  end)
end

function g_mouseicon.terminate()
  disconnect(UIWidget, {
    onMouseRelease = onWidgetMouseRelease
  })

  removeEvent(mouseMoveEvent)
  mouseMoveEvent = nil
  mouseIcon:destroy()
  mouseIcon = nil

  g_mouseicon = nil
end

function g_mouseicon.display(filePath, opacity, size, subType, text) -- (filePath[, opacity = defaultIconOpacity[, size = defaultSize[, subType = 1 [, text = '']]]])
  --reset
  mouseIcon:setIcon('')
  mouseIcon:setText('')
  mouseIcon:setItemId(0)
  mouseIcon:setItemSubType(0)

  if tonumber(filePath) then --item
    mouseIcon:setItemId(filePath)
    mouseIcon:setItemSubType(subType or 1)
  elseif string.exists(text) then --text
    mouseIcon:setText(text)
  else --power
    mouseIcon:setIcon(resolvepath(filePath))
  end

  mouseIcon:setSize(size or defaultSize)
  mouseIcon:setIconSize(size or defaultSize)
  mouseIcon:setOpacity(opacity or defaultIconOpacity / 100)

  mouseIcon:raise()
  mouseIcon:show()
  mouseIcon:enable()

  lastMouseIconPosX = -1
  lastMouseIconPosY = -1
  moveIcon(g_window.getMousePosition(), true)
  if not mouseMoveEvent then
    mouseMoveEvent = cycleEvent(moveIcon, mouseMoveDelay)
  end
end

function g_mouseicon.displayItem(item, opacity, size, subType) -- (item[, opacity = option or defaultItemIconOpacity[, size = defaultSize[, subType = 1]]])
  if not ClientOptions.getOption('showMouseItemIcon') then
    return
  end
  g_mouseicon.display(item:getId(), opacity or (ClientOptions.getOption('mouseItemIconOpacity') or defaultItemIconOpacity) / 100, size, subType or item:isStackable() and (g_keyboard and g_keyboard.isAltPressed() and 1 or item:getCount()) or item:getSubType())
end

function g_mouseicon.displayText(text)
  g_mouseicon.display(nil, nil, nil, nil, text)
end

function g_mouseicon.hide()
  g_effects.cancelFade(mouseIcon) -- Because g_mouseicon.hide() can be called multiple times in a row
  g_effects.fadeOut(mouseIcon, fadeOutTime)

  removeEvent(mouseMoveEvent)
  mouseMoveEvent = nil
  lastMouseIconPosX = -1
  lastMouseIconPosY = -1
end

g_mouseicon.init()
connect(g_app, {
  onTerminate = g_mouseicon.terminate
})
