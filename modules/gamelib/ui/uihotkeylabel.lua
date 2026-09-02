UIHotkeyLabel = extends(UILabel, 'UIHotkeyLabel')

function UIHotkeyLabel:onDragEnter(mousePos)
  if self.status ~= HotkeyStatus.Applied then
    return false
  end

  self:setBorderWidth(1)
  g_mouse.pushCursor('target')
  local keySettings = self.settings
  if tonumber(keySettings.powerId) then
    g_mouseicon.display(f('/images/ui/power/%d_off', keySettings.powerId))
  elseif tonumber(keySettings.itemId) then
    g_mouseicon.display(keySettings.itemId, nil, nil, keySettings.subType)
  elseif string.exists(keySettings.text) then
    g_mouseicon.displayText('(...)')
  end
  return true
end

function UIHotkeyLabel:onDragLeave(droppedWidget, mousePos)
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  return true
end

function UIHotkeyLabel:onDestroy()
  if self.hoverTarget then
    self.hoverTarget:onHoverChange(false)
  end

  g_mouse.popCursor('target')
end

function UIHotkeyLabel:onMouseRelease(mousePosition, mouseButton)
  if not self:containsPoint(mousePosition) then
    return false
  end
  return false
end
