-- @docclass
UICheckBox = extends(UIWidget, 'UICheckBox')

function UICheckBox.create()
  local checkbox = UICheckBox.internalCreate()
  checkbox:setFocusable(false)
  checkbox:setTextAlign(AlignLeft)
  return checkbox
end

function UICheckBox:onClick()
  self:setChecked(not self:isChecked())
end

function UICheckBox:onMouseRelease(mousePos, mouseButton)
  if g_tooltip then
    g_tooltip.onWidgetMouseRelease(self, mousePos, mouseButton)
  end

  g_sounds.getChannel(AudioChannels.Gui):play(f('%s/mouse_click.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)

  return self:isPressed()
end

function UICheckBox:onDestroy()
  if g_tooltip then
    g_tooltip.onWidgetDestroy(self)
  end
end
