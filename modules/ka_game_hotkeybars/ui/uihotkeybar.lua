UIHotkeyBar = extends(UIWidget, 'UIHotkeyBar')

local containersLimit       = 10
local defaultTooltip        = loc'${GameHotkeyBarsDefaultTooltip}'
local hotkeyManagerKeyCombo = 'Ctrl+K'
local powerListKeyCombo     = 'Ctrl+Shift+P'
local allowedDrops          = { 'UIHotkeyLabel', 'UIHotkeyBarContainer', 'UIPowerButton', 'UIItem', 'UIGameMap' }

local BGColors = {
  Open        = '#00000077',
  Closed      = '#00000000',
  Highlighted = '#ffffff77'
}

function UIHotkeyBar.create()
  local obj = UIHotkeyBar.internalCreate()
  obj:setId('hotkeybar_none')
  obj.hotkeyList = { }
  obj:setTooltip(f(defaultTooltip, hotkeyManagerKeyCombo, powerListKeyCombo), TooltipType.textBlock)
  return obj
end

function UIHotkeyBar:onSetup()
  self.visibilityButton = self:getChildById('visibilityButton')
  self.onClick = function() if not self.visibilityButton:isOn() then self:toggle() end end
  self.visibilityButton.onClick = function() self:toggle() end
  self.visibilityButton.onHoverChange = function(button, hovered)
    UIWidget.onHoverChange(button, hovered)
    button:setOpacity(hovered and 1 or 0)
  end
end

function UIHotkeyBar:unload()
  -- Clear previous hotkeys
  if self.hotkeyList then
    for keyCombo, widget in pairs(self.hotkeyList) do
      if isWidgetAlive(widget) then
        widget.settings = nil
      end
      self.hotkeyList[keyCombo] = nil
    end
  end

  self.hotkeyList = { }
  self.tempContainer = nil

  local hotkeyList = self:getHotkeyList()
  hotkeyList:destroyChildren()
  hotkeyList:updateLayout()
end

function UIHotkeyBar:load(settings)
  local settings = settings or { }
  if settings.visible == nil then
    settings.visible = true
  end

  self:setup(settings.visible)
  settings.visible = nil

  local hotkeyList = {}

  -- Preload
  for index, keyCombo in pairs(settings) do
    hotkeyList[tonumber(index)] = tostring(keyCombo)
  end

  -- Create widgets
  local index = 1
  for _, keyCombo in ipairs(hotkeyList) do
    local keySettings = GameHotkeys.getHotkey(keyCombo)
    if keySettings then
      keySettings.loading = true
      self:addHotkey(index, keySettings)
      index = index + 1
    else
      perror(f("Hotkey '%s' does not exist.", keyCombo))
    end
  end
end

function UIHotkeyBar:getHotkeyList()
  return self:getChildById('hotkeyBarList')
end

function UIHotkeyBar:setup(visible)
  local highlighted = self:isOn()
  local bg = not visible and BGColors.Closed or highlighted and BGColors.Highlighted or BGColors.Open
  self:setBackgroundColor(bg)
  self:getHotkeyList():setVisible(visible)
  self.visibilityButton:setOn(visible)
  self.visibilityButton:setTooltip(visible and loc'${GameHotkeyBarsButtonVisibilityHide}' or loc'${GameHotkeyBarsButtonVisibilityShow}')
end

function UIHotkeyBar:toggle()
  self:setup(not self.visibilityButton:isOn())
  g_sounds.getChannel(AudioChannels.Gui):play(f('%s/hotkeybar.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
end

function UIHotkeyBar:setHighlight(highlight)
  self:setOn(highlight)
  local open = self.visibilityButton:isOn()
  self:setup(highlight or not self.autoClose)
  self.autoClose = highlight and not open or nil
  self.visibilityButton:setVisible(not highlight)
  for _, hotkey in ipairs(self:getHotkeyList():getChildren()) do
    hotkey:getChildById('deleteButton'):setVisible(highlight)
  end
end

function UIHotkeyBar:getIndexByPos(mousePos)
  local isVertical   = self:getStyleName() == 'HotkeyBarVertical'
  local isHorizontal = self:getStyleName() == 'HotkeyBarHorizontal'
  local hotkeyWidgets = self:getHotkeyList():getChildren()
  local index = 1
  for i, w in ipairs(hotkeyWidgets) do
    if isVertical and mousePos.y <= w:getY() + math.floor(w:getHeight() / 2) then
      index = i
      break
    elseif isHorizontal and mousePos.x <= w:getX() + math.floor(w:getWidth() / 2) then
      index = i
      break
    end
    index = i + 1
  end
  return index
end

function UIHotkeyBar:addHotkeyButton(index, hotkeyWidget)
  if #self.hotkeyList >= containersLimit then
    return
  end

  local keyCombo = hotkeyWidget.settings and hotkeyWidget.settings.keyCombo or nil
  if keyCombo and self.hotkeyList[keyCombo] then
    return
  end

  self:getHotkeyList():insertChild(index, hotkeyWidget)
  hotkeyWidget:getChildById('deleteButton'):setVisible(self:isOn())
end

function UIHotkeyBar:addHotkey(index, keySettings)
  if #self.hotkeyList >= containersLimit then
    return
  end

  if keySettings and keySettings.keyCombo and self.hotkeyList[keySettings.keyCombo] then
    return
  end

  local hotkeyWidget = g_ui.createWidget('HotkeyBarContainer')
  self:addHotkeyButton(index, hotkeyWidget)
  self:updateDraggable(self:isOn())
  hotkeyWidget:setOpacity(0.5)
  hotkeyWidget.settings = keySettings
  hotkeyWidget:updateLook()

  self.tempContainer = hotkeyWidget
  self.tempContainer:setId('temp')

  if keySettings.loading then
    self:onAssignHotkey(keySettings, true, hotkeyWidget)
    keySettings.loading = nil
  end
end

function UIHotkeyBar:onAssignHotkey(keySettings, applied, hotkeyWidget)
  if not keySettings then
    perror("Error: no keySettings!")
    return
  end

  if not hotkeyWidget then
    hotkeyWidget = self.tempContainer
    hotkeyWidget.locked = false
  end

  if hotkeyWidget then
    if applied then
      local keyCombo = keySettings.keyCombo
      --remove existing container of same keyCombo to prioritize the new position
      local existingContainer = self.hotkeyList[keyCombo]
      if existingContainer then
        existingContainer:destroy()
      end

      hotkeyWidget:setId(self:getId() .. "_" .. keyCombo)
      hotkeyWidget:setOpacity(1)
      hotkeyWidget:setDraggable(self:isOn())
      self.hotkeyList[keyCombo] = hotkeyWidget
      hotkeyWidget:updateLook()
      self.tempContainer = nil

    elseif self.tempContainer then
      self.tempContainer.locked = false
      self:resetTempContainer()
    end
  end
end

function UIHotkeyBar:configHotkey(widget)
  local keySettings = {}
  local widgetClass = widget:getClassName()

  if widgetClass == 'UIPowerButton' then
    keySettings.powerId = widget.power.id

  elseif widgetClass == 'UIItem' then
    keySettings.itemId = widget:getItemId()
    keySettings.subType = widget:getItemSubType()

    if widget:getItem():isMultiUse() then
      keySettings.useType = HotkeyItemUseType.Crosshair
    end

  elseif widgetClass == 'UIGameMap' then
    local item = widget.currentDragThing
    if item:isPickupable() then
      keySettings.itemId = item:getId()
      keySettings.subType = item:getSubType()
      if item:isMultiUse() then
        keySettings.useType = HotkeyItemUseType.Crosshair
      end
    end

  elseif widgetClass == 'UIHotkeyLabel' or widgetClass == 'UIHotkeyBarContainer' then
    keySettings = widget.settings
  end

  keySettings.hotkeyBarId = self.id
  return keySettings
end

function UIHotkeyBar:removeHotkey(keyCombo)
  if self.hotkeyList[keyCombo] then
    self.hotkeyList[keyCombo]:destroy()
    self.hotkeyList[keyCombo] = nil
  end
end

function UIHotkeyBar:resetTempContainer()
   if self.tempContainer and not self.tempContainer.locked then
    self.tempContainer:destroy()
    self.tempContainer = nil
  end
end

-- mouse events

function UIHotkeyBar:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)
  self.visibilityButton:setOpacity(hovered and 1 or 0)

  local mousePos = g_window.getMousePosition()
  if not hovered then
    if not self:containsPoint(mousePos) then
      self:resetTempContainer()
    end
    return
  end

  local draggingWidget = g_ui.getDraggingWidget()
  if not draggingWidget then
    self:resetTempContainer()
    return
  end

  if not self:canAcceptDrop(draggingWidget) or self.tempContainer then
    return
  end

  local index = self:getIndexByPos(mousePos)
  local widgetClass = draggingWidget:getClassName()
  if widgetClass == 'UIHotkeyBarContainer' and draggingWidget:getParentBar() == self then
    return

  elseif widgetClass == 'UIGameMap' then
    if not draggingWidget.currentDragThing:isPickupable() then
      return
    end
  end

  local keySettings = self:configHotkey(draggingWidget)
  self:addHotkey(index, keySettings)
end

function UIHotkeyBar:onMouseMove(mousePos, mouseMoved)
  local draggingWidget = g_ui.getDraggingWidget()
  if draggingWidget then
    local moveWidget = self.tempContainer
    if draggingWidget:getClassName() == 'UIHotkeyBarContainer' and draggingWidget:getParentBar() == self then
      moveWidget = draggingWidget
    end

    if moveWidget and not moveWidget.locked then --only drag and drop
      local parent = moveWidget:getParent()
      local index =  self:getIndexByPos(mousePos)
      if index <= parent:getChildCount() then
        parent:moveChildToIndex(moveWidget, index)
      end
    end

    return
  end

  self:resetTempContainer()
end

function UIHotkeyBar:onDrop(widget, mousePos)
  self:updateDraggable(self:isOn())

  if not self.tempContainer then
    return true

  elseif not self:canAcceptDrop(widget) then
    return false
  end

  local keySettings = self.tempContainer.settings
  if keySettings.keyCombo then
    self:onAssignHotkey(keySettings, true)
    if keySettings.powerId then
      g_sounds.getChannel(AudioChannels.Gui):play(f('%s/power_drop.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
    end

  else
    self.tempContainer.locked = true
    GameHotkeys.assignHotkey(keySettings)
  end

  return true
end

function UIHotkeyBar:canAcceptDrop(widget)
  if not widget then
    return false
  end

  if widget:getId() == 'itemPreview' then
    return false
  end

  if not self.visibilityButton:isOn() then
    return false
  end

  if not table.contains(allowedDrops, widget:getClassName()) then
    return false
  end

  if self.tempContainer and self.tempContainer.locked then
    return false
  end
  return true
end

-- update functions
function UIHotkeyBar:updateHotkey(hotkey)
  if not hotkey or not hotkey.settings then
    local children = self:getHotkeyList():getChildren()
    for _, widget in ipairs(children) do
      if widget:getClassName() == 'UIHotkeyBarContainer' then
        widget:updateLook()
      end
    end
    return
  end

  local keyCombo = hotkey.settings.keyCombo
  if keyCombo and self.hotkeyList[keyCombo] then
    self.hotkeyList[keyCombo].settings = hotkey.settings
    self.hotkeyList[keyCombo]:updateLook(keyCombo)
  end
end

function UIHotkeyBar:updateDraggable(draggable)
  local children = self:getHotkeyList():getChildren()
  for _, widget in ipairs(children) do
    if widget:getClassName() == 'UIHotkeyBarContainer' then
      widget:setDraggable(draggable)
    end
  end
end
