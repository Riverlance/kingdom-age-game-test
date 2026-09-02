-- @docclass
UIButton = extends(UIWidget, 'UIButton')

function UIButton.create()
  local button = UIButton.internalCreate()
  button:setFocusable(false)
  return button
end

function UIButton:onMouseRelease(pos, button)
  if g_tooltip then
    g_tooltip.onWidgetMouseRelease(self, pos, button)
  end

  g_sounds.getChannel(AudioChannels.Gui):play(f('%s/button_1.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)

  return self:isPressed()
end

function UIButton:onDestroy()
  if g_tooltip then
    g_tooltip.onWidgetDestroy(self)
  end
end
