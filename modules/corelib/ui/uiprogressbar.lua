-- @docclass
UIProgressBar = extends(UIWidget, 'UIProgressBar')

function UIProgressBar.create()
  local progressbar = UIProgressBar.internalCreate()
  progressbar:setFocusable(false)
  progressbar:setOn(true)
  progressbar.min = 0
  progressbar.max = 100
  progressbar.value = 0
  progressbar.valueDelayedStartEventId = nil
  progressbar.valueDelayedEventId = nil
  progressbar.fillerBackgroundWidget = nil
  progressbar.bgBorderLeft = 0
  progressbar.bgBorderRight = 0
  progressbar.bgBorderTop = 0
  progressbar.bgBorderBottom = 0
  progressbar.bgColor = 'alpha'
  progressbar.bgAreaColor = 'alpha'
  progressbar.imageSource = ''
  progressbar.imageBorder = 0
  progressbar.phases = 0
  progressbar.phasesBorderWidth = 1
  progressbar.phasesBorderColor = '#98885e88'
  return progressbar
end

function UIProgressBar:setMinimum(minimum)
  self.minimum = minimum
  if self.value < minimum then
    self:setValue(minimum)
  end
end

function UIProgressBar:setMaximum(maximum)
  self.maximum = maximum
  if self.value > maximum then
    self:setValue(maximum)
  end
end

function UIProgressBar:setValue(value, minimum, maximum)
  if minimum and minimum ~= self.minimum then
    self:setMinimum(minimum)
  end

  if maximum and maximum ~= self.maximum then
    self:setMaximum(maximum)
  end

  self.value = math.max(math.min(value, self.maximum), self.minimum)
  self:updateBackground()
end

function UIProgressBar:setValueDelayed(value, minimum, maximum, delayDuration, delayTicks, delayStartDuration, positiveChanges, negativeChanges)
  delayStartDuration = delayStartDuration or 0
  if positiveChanges == nil then
    positiveChanges = true
  end
  if negativeChanges == nil then
    negativeChanges = true
  end

  -- Stop previous animation
  removeEvent(self.valueDelayedStartEventId)
  removeEvent(self.valueDelayedEventId)
  self.valueDelayedStartEventId = nil
  self.valueDelayedEventId = nil

  local changeMinimum = minimum and minimum ~= self.minimum
  if changeMinimum then
    self:setMinimum(minimum)
  end

  local changeMaximum = maximum and maximum ~= self.maximum
  if changeMaximum then
    self:setMaximum(maximum)
  end

  local targetValue = math.max(math.min(value, self.maximum), self.minimum)
  local valueDiff = targetValue - self.value -- final - initial

  if changeMinimum or changeMaximum or -- Changed minimum or maximum
     not positiveChanges and not negativeChanges or -- No animation enabled
     valueDiff > 0 and not positiveChanges or valueDiff < 0 and not negativeChanges -- Positive and should not animate on positive changes or negative and should not animate on negative changes
  then
    -- Cannot execute delayed effect, then set it right away
    self.value = math.max(math.min(value, self.maximum), self.minimum)
    self:updateBackground()
    return
  end

  if self.maximum == 0 then
    return -- There is no range to do an animation at all
  end

  local valuePerTicks = (valueDiff * delayTicks) / delayDuration

  local function onSetValueDelayed(widget)
    local nextValue = math.max(math.min(widget.value + valuePerTicks, widget.maximum), widget.minimum)

    -- If next value difference is less than valuePerTicks
    if math.abs(nextValue - targetValue) < math.abs(valuePerTicks) then
      widget.value = targetValue
      widget:updateBackground()
      widget.valueDelayedEventId = nil
      return
    end

    if widget.value == targetValue then
      widget.valueDelayedEventId = nil
      return
    end

    widget.value = nextValue
    widget:updateBackground()

    widget.valueDelayedEventId = scheduleEvent(function()
      if isWidgetAlive(widget) then
        onSetValueDelayed(widget)
      end
    end, delayTicks)
  end

  self.valueDelayedStartEventId = scheduleEvent(function()
    if isWidgetAlive(self) then
      onSetValueDelayed(self)
    end
  end, delayStartDuration)
end

function UIProgressBar:setPercent(percent)
  self:setValue(percent, 0, 100)
end

function UIProgressBar:setPhases(value)
  self.phases = value
  self:updateBackground()
end

function UIProgressBar:setPhasesBorderWidth(value)
  self.phasesBorderWidth = value
  self:updateBackground()
end

function UIProgressBar:setPhasesBorderColor(value)
  self.phasesBorderColor = value
  self:updateBackground()
end

function UIProgressBar:getPercent()
  return self.value
end

function UIProgressBar:getPercentPixels()
  return (self.maximum - self.minimum) / self:getWidth()
end

function UIProgressBar:getProgress()
  if self.minimum == self.maximum then
    return 1
  end

  return (self.value - self.minimum) / (self.maximum - self.minimum)
end

function UIProgressBar:getPhases()
  return self.phases
end

function UIProgressBar:getPhasesBorderWidth()
  return self.phasesBorderWidth
end

function UIProgressBar:getPhasesBorderColor()
  return self.phasesBorderColor
end

function UIProgressBar:setFillerBackgroundColor(color)
  if not self.fillerBackgroundWidget then
    return
  end

  self.fillerBackgroundWidget:setBackgroundColor(color)
end

function UIProgressBar:updateFillerBackground() -- Should destroy children before at UIProgressBar:updateBackground()
  self.fillerBackgroundWidget = g_ui.createWidget('UIWidget', self)
  self.fillerBackgroundWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
  self.fillerBackgroundWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  self.fillerBackgroundWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  self.fillerBackgroundWidget:setMarginLeft(self.bgBorderLeft)
  self.fillerBackgroundWidget:setMarginRight(self.bgBorderRight)
  self.fillerBackgroundWidget:setMarginTop(self.bgBorderTop)
  self.fillerBackgroundWidget:setMarginBottom(self.bgBorderBottom)
  self.fillerBackgroundWidget:setWidth(math.round(math.max(self:getProgress() * (self:getWidth() - self.bgBorderLeft - self.bgBorderRight), 1)))
  self.fillerBackgroundWidget:setBackgroundColor(self.bgColor)
  self.fillerBackgroundWidget:setImageSource(self.imageSource)
  self.fillerBackgroundWidget:setImageBorder(self.imageBorder)
  self.fillerBackgroundWidget:setPhantom(true)
end

function UIProgressBar:updatePhases()
  if self.phases < 2 or self.phasesBorderWidth < 1 then
    return
  end

  local phaseWidth = (self:getWidth() - (self.bgBorderLeft + self.bgBorderRight)) / self.phases
  local phaseHeight = math.max( (self:getHeight() - (self.bgBorderTop + self.bgBorderBottom)) / 4, 3)
  phaseHeight = math.min(self:getHeight(), phaseHeight)

  for i = 1, self.phases - 1 do
    local rect = { x = 0, y = 0, width = self.phasesBorderWidth, height = phaseHeight }
    local widget = g_ui.createWidget('UIWidget', self)
    widget:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)

    widget:setMarginLeft((i * phaseWidth) + self.bgBorderLeft)

    widget:setRect(rect)
    widget:setBackgroundColor(self.phasesBorderColor)
    widget:setPhantom(true)
  end
end

function UIProgressBar:updateBackground()
  if self:isOn() then
    -- Remove old widgets
    self:destroyChildren()
    self.fillerBackgroundWidget = nil

    -- Background area
    self:setBackgroundColor(self.bgAreaColor)
    self:setImageSource('')
    self:setImageBorder(0)

    -- Filler background
    self:updateFillerBackground()

    -- Phases
    self:updatePhases()
  end
end

function UIProgressBar:onSetup()
  self:updateBackground()
end

function UIProgressBar:onDestroy()
  removeEvent(self.valueDelayedStartEventId)
  removeEvent(self.valueDelayedEventId)

  self.fillerBackgroundWidget = nil
  self.valueDelayedStartEventId = nil
  self.valueDelayedEventId = nil
end

function UIProgressBar:onStyleApply(name, node)
  for name, value in pairs(node) do
    if name == 'background-padding-left' then
      self.bgBorderLeft = tonumber(value)
    elseif name == 'background-padding-right' then
      self.bgBorderRight = tonumber(value)
    elseif name == 'background-padding-top' then
      self.bgBorderTop = tonumber(value)
    elseif name == 'background-padding-bottom' then
      self.bgBorderBottom = tonumber(value)
    elseif name == 'background-padding' then
      self.bgBorderLeft = tonumber(value)
      self.bgBorderRight = tonumber(value)
      self.bgBorderTop = tonumber(value)
      self.bgBorderBottom = tonumber(value)
    elseif name == 'background-area-color' then
      self.bgAreaColor = tostring(value)
    elseif name == 'background-color' then
      self.bgColor = tostring(value)

    elseif name == 'image-source' then
      self.imageSource = tostring(value)
    elseif name == 'image-border' then
      self.imageBorder = tonumber(value)

    elseif name == 'phases' then
      self:setPhases(tonumber(value))
    elseif name == 'phases-border-width' then
      self:setPhasesBorderWidth(tonumber(value))
    elseif name == 'phases-border-color' then
      self:setPhasesBorderColor(tostring(value))
    end
  end
end

function UIProgressBar:onGeometryChange(newRect, oldRect)
  if not self:isOn() then
    self:setHeight(0)
  end
  self:updateBackground()
end
