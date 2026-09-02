_G.UIHotkeyBarContainer = extends(UIWidget, 'UIHotkeyBarContainer')

local powerEffectDelay = 1000
local powerEffectStyle = {
  [1] = 'PowerSendingParticlesBoost1',
  [2] = 'PowerSendingParticlesBoost2',
  [3] = 'PowerSendingParticlesBoost3',
}

function UIHotkeyBarContainer:onSetup()
  self.cbChargePower = function(powerId, boost) self:onChargePower(powerId, boost) end
  self.cbCastPower   = function(powerId, exhaustTime, boost) self:onCastPower(powerId, exhaustTime, boost) end
  self.cbCancelPower = function() self:onCancelPower() end

  connect(g_game, {
    onChargePower = self.cbChargePower,
    onCastPower   = self.cbCastPower,
    onCancelPower = self.cbCancelPower
  })
end

function UIHotkeyBarContainer:onDestroy()
  disconnect(g_game, {
    onChargePower = self.cbChargePower,
    onCastPower   = self.cbCastPower,
    onCancelPower = self.cbCancelPower
  })

  if self.powerProgressEvent then
    removeEvent(self.powerProgressEvent)
    self.powerProgressEvent = nil
  end

  self:clearPowerEffect()

  self.cbChargePower = nil
  self.cbCastPower   = nil
  self.cbCancelPower = nil
  self.settings      = nil
end

function UIHotkeyBarContainer:getParentBar()
  return self:getParent():getParent()
end

function UIHotkeyBarContainer:updateLook()
  local keySettings = self.settings
  if not keySettings then
    g_logger.error(f('[UIHotkeyBarContainer.updateLook] missing field `settings` (%s)', self:getId()))
    return
  end

  -- reset look

  local hasTooltip = true
  local tooltipText = ''
  self:setText('')

  local itemWidget = self:getChildById('item')
  itemWidget:setVisible(false)

  local powerWidget = self:getChildById('power')
  powerWidget:setVisible(false)

  if not keySettings.powerId then
    if self.powerProgressEvent then
      removeEvent(self.powerProgressEvent)
      self.powerProgressEvent = nil
    end
    self:clearPowerEffect()
  end

  -- update look

  if string.exists(keySettings.keyCombo) then
    tooltipText = f('[%s]', keySettings.keyCombo)
  else
    hasTooltip = false
  end
  tooltipType = TooltipType.default

  if string.exists(keySettings.text) then
    self:setText('(...)')
    tooltipText = f(loc'%s ${GameHotkeyBarsInfoContainerTooltipSendMessage}%s:\n%s', tooltipText, keySettings.autoSend and loc' (${GameHotkeyBarsInfoContainerTooltipAuto})' or '', keySettings.text)

    tooltipType = TooltipType.textBlock

  elseif keySettings.powerId and powerWidget then
    powerWidget:setVisible(true)
    powerWidget:setImageSource('/images/ui/power/' .. keySettings.powerId .. '_off')

    local power = GamePowers.getPowerInfo(keySettings.powerId)
    if power and power.name and power.level then
      tooltipText = f(loc'%s %s (${GameHotkeyBarsInfoContainerTooltipLevel})', tooltipText, power.name, power.level)
    end

  elseif keySettings.itemId and itemWidget then
    itemWidget:setVisible(true)
    itemWidget:setItemId(keySettings.itemId)
    itemWidget:setItemSubType(keySettings.subType)
    if keySettings.useType == HotkeyItemUseType.Default then
      tooltipText = f(loc'%s ${GameHotkeyBarsInfoContainerUseItem}', tooltipText)
    elseif keySettings.useType == HotkeyItemUseType.Self then
      tooltipText = f(loc'%s ${GameHotkeyBarsInfoContainerUseOnYourself}', tooltipText)
    elseif keySettings.useType == HotkeyItemUseType.Target then
      tooltipText = f(loc'%s ${GameHotkeyBarsInfoContainerUseOnTarget}', tooltipText)
    elseif keySettings.useType == HotkeyItemUseType.Crosshair then
      tooltipText = f(loc'%s ${GameHotkeyBarsInfoContainerUseWith}', tooltipText)
    end
  end
  self:setTooltip(hasTooltip and tooltipText or '', tooltipType)
end


--[[ Mouse Events ]]

function UIHotkeyBarContainer:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)

  if g_ui.getDraggingWidget() then
    if not hovered and self:containsPoint(g_window.getMousePosition()) then
      self:getParentBar():resetTempContainer()

    else
      self:getParentBar():onHoverChange(hovered)
    end
  end
end

function UIHotkeyBarContainer:onDragEnter(mousePos)
  self:setOpacity(0.5)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')

  local keySettings = self.settings
  if tonumber(keySettings.itemId) then
    g_mouseicon.displayItem(Item.create(keySettings.itemId))

  elseif tonumber(keySettings.powerId) then
    g_mouseicon.display(f('/images/ui/power/%d_off', keySettings.powerId))
  end

  return true
end

function UIHotkeyBarContainer:onDragLeave(droppedWidget, mousePos)
  self:setOpacity(1)
  self:setBorderWidth(0)
  g_mouseicon.hide()
  g_mouse.popCursor('target')

  if not droppedWidget or droppedWidget ~= self:getParentBar() then
    self:getParentBar():removeHotkey(self.settings.keyCombo)
    g_sounds.getChannel(AudioChannels.Gui):play(f('%s/power_popout.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
  end

  return true
end

function UIHotkeyBarContainer:onMousePress(mousePos, mouseButton)
  if self.settings.powerId and not GameHotkeys.isOpen() then
    GamePowers.chargePower(self.settings.powerId)
  end
end

function UIHotkeyBarContainer:onMouseRelease(mousePos, mouseButton)
  if self.settings.powerId then
    local mapWidget = GameInterface.getMapPanel()
    local pos = mapWidget and mapWidget:getPosition(mousePos)
    GamePowers.castPower(pos)
  else
    GameHotkeys.doAction(self.settings)
  end
end


--[[ Power Events ]]

function UIHotkeyBarContainer:onChargePower(powerId, boostLevel)
  if powerId == self.settings.powerId then
    self:setPowerIcon(powerId, true)
  end
end

function UIHotkeyBarContainer:onCastPower(powerId, exhaustTime, boostLevel)
  if powerId ~= self.settings.powerId then
    return
  end
  self:setPowerIcon(powerId, false)
  if boostLevel ~= 0 then
    --self:setPowerEffect(boostLevel)
  end
  if exhaustTime ~= 0 then
    self:setPowerProgressShader(exhaustTime)
  end
end

function UIHotkeyBarContainer:onCancelPower()
  local powerId = self.settings.powerId
  if powerId then
    self:setPowerIcon(powerId, false)
  end

  if self.powerProgressEvent then
    removeEvent(self.powerProgressEvent)
    self.powerProgressEvent = nil
  end

  local powerWidget = self:getChildById('power')
  if powerWidget then
    powerWidget:setShader('Widget - None')
  end
end

--[[ Power Effects ]]

function UIHotkeyBarContainer:setPowerIcon(powerId, enabled)
  local path = f('/images/ui/power/%d_%s', powerId, enabled and 'on' or 'off')
  self:getChildById('power'):setImageSource(path)
end

function UIHotkeyBarContainer:clearPowerEffect()
  if self.powerEffectDestroyEvent then
    removeEvent(self.powerEffectDestroyEvent)
    self.powerEffectDestroyEvent = nil
  end

  if self.powerEffectWidget then
    self.powerEffectWidget:destroy()
    self.powerEffectWidget = nil
  end
end

function UIHotkeyBarContainer:setPowerEffect(boostLevel)
  local style = powerEffectStyle[tonumber(boostLevel) or 0]
  if not style then
    return
  end

  local powerWidget = self:getChildById('power')
  if not powerWidget or not powerWidget:isVisible() then
    return
  end

  -- Avoid destroying an unfinished effect; wait for it to finish naturally.
  if self.powerEffectWidget then
    return
  end

  local particle = g_ui.createWidget(style, powerWidget)
  self.powerEffectWidget = particle
  self.powerEffectDestroyEvent = scheduleEvent(function()
    self.powerEffectDestroyEvent = nil
    self.powerEffectWidget = nil
    particle:destroy()
  end, powerEffectDelay)
end

function UIHotkeyBarContainer:setPowerProgressShader(exhaustTime)
  local powerWidget = self:getChildById('power')
  if not powerWidget then
    print_traceback("UIHotkeyBarContainer:setPowerProgressShader - Power widget not found")
    return
  end

  if self.powerProgressEvent then
    removeEvent(self.powerProgressEvent)
    self.powerProgressEvent = nil
  end

  powerWidget:setShader('Widget - Angular')
  powerWidget:setShaderUniform(ShaderUniforms.Progress, 0)

  powerWidget.endTime = g_clock.millis() + exhaustTime

  local function updateShader()
    local widget = self:getChildById('power')
    if not widget then
      return
    end

    local percent = 1 - (widget.endTime - g_clock.millis()) / exhaustTime
    widget:setShaderUniform(ShaderUniforms.Progress, percent)
    if percent > 1 then
      widget:setShader('Widget - None')
      self.powerProgressEvent = nil
    else
      self.powerProgressEvent = scheduleEvent(function() updateShader() end, 50)
    end
  end

  self.powerProgressEvent = scheduleEvent(function() updateShader() end, 50)
end
