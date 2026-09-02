UIGameMap = extends(UIMap, 'UIGameMap')

function UIGameMap.create()
  local gameMap = UIGameMap.internalCreate()
  gameMap:setKeepAspectRatio(true)
  gameMap:setVisibleDimension({width = 15, height = 11})
  gameMap:setDrawLights(true)
  return gameMap
end

function UIGameMap:onDragEnter(mousePos)
  local tile = self:getTile(mousePos)
  if not tile then
    return false
  end

  local thing = tile:getTopMoveThing()
  if not thing then
    return false
  end

  self.currentDragThing = thing

  if thing:isItem() and thing:isPickupable() then
    g_mouseicon.displayItem(thing)
  end
  g_mouse.pushCursor('target')
  self.allowNextRelease = false
  return true
end

function UIGameMap:onDragLeave(droppedWidget, mousePos)
  self.currentDragThing = nil
  self.hoveredWho = nil
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  return true
end

function UIGameMap:onDrop(widget, mousePos)
  if not self:canAcceptDrop(widget, mousePos) then
    return false
  end

  local tile = self:getTile(mousePos)
  if not tile then
    return false
  end

  local thing = widget.currentDragThing
  local thingPos = thing:getPosition()
  if not thingPos then
    return false
  end

  local thingTile = thing:getTile()
  if thingPos.x ~= 65535 and not thingTile then
    return false
  end

  local toPos = tile:getPosition()
  if thingPos.x == toPos.x and thingPos.y == toPos.y and thingPos.z == toPos.z then
    return false
  end

  if thing:isItem() and thing:getCount() > 1 then
    GameInterface.moveStackableItem(thing, toPos)
  else
    g_game.move(thing, toPos, 1)
  end

  return true
end

function UIGameMap:onMousePress()
  if not self:isDragging() then
    self.allowNextRelease = true
  end

  -- Cycle walk
  if g_keyboard.getModifiers() == KeyboardNoModifier and g_mouse.isPressed(MouseMidButton) then
    GameInterface.initCycleWalkEvent()
  end
end

function UIGameMap:onMouseMove()
  return false
end

function UIGameMap:onMouseRelease(mousePosition, mouseButton)
  GameInterface.stopCycleWalkEvent()

  if not self.allowNextRelease then
    return true
  end

  -- Happens when clicking outside of map boundaries
  local autoWalkPos = self:getPosition(mousePosition)
  if not autoWalkPos or (autoWalkPos.x == 0 and autoWalkPos.y == 0 and autoWalkPos.z == 0) then
    return false
  end

  -- Auto walk pos is mouse pos behind walls
  local playerPos = g_game.getLocalPlayer():getPosition()
  if autoWalkPos.z ~= playerPos.z then
    local dz = autoWalkPos.z - playerPos.z
    autoWalkPos.x = autoWalkPos.x + dz
    autoWalkPos.y = autoWalkPos.y + dz
    autoWalkPos.z = playerPos.z
  end

  local lookThing
  local useThing
  local creatureThing
  local multiUseThing
  local wrapThing

  local tile = self:getTile(mousePosition)
  if tile then
    lookThing = tile:getTopLookThing()
    useThing = tile:getTopUseThing()
    creatureThing = tile:getTopCreature()
    wrapThing = tile:getTopWrapThing()
  end

  if not creatureThing then
    local autoWalkTile = g_map.getTile(autoWalkPos)
    if autoWalkTile then
      creatureThing = autoWalkTile:getTopCreature()
    end
  end

  local ret = GameInterface.processMouseAction(mousePosition, mouseButton, autoWalkPos, lookThing, useThing, wrapThing, creatureThing)
  if ret then
    self.allowNextRelease = false
  end

  return ret
end

function UIGameMap:onMouseWheel(mousePos, direction)
  if g_keyboard.getModifiers() == KeyboardCtrlModifier then
    if direction == MouseWheelUp then
      self:zoomIn()
    elseif direction == MouseWheelDown then
      self:zoomOut()
    end
  end
  ClientOptions.setOption('gameScreenSize', self:getZoom(), false) -- See 'Ctrl+=' & 'Ctrl+-' interface.lua
  return true
end

function UIGameMap:canAcceptDrop(widget, mousePos)
  if not widget or not widget.currentDragThing then
    return false
  end

  local children = rootWidget:recursiveGetChildrenByPos(mousePos)
  for i=1,#children do
    local child = children[i]
    if child == self then
      return true
    elseif not child:isPhantom() then
      return false
    end
  end

  error(f('Widget %s not in drop list.', self:getId()))
  return false
end

function UIGameMap:changeViewMode(newMode, oldMode)
  if self.onViewModeChange then
    signalcall(self.onViewModeChange, self, newMode, oldMode)
  end
end

function UIGameMap:getPosition(mousePosition)
  local tile = self:getTile(mousePosition)
  if not tile then
    return { x = 0, y = 0, z = 0 }
  end

  return tile:getPosition()
end
