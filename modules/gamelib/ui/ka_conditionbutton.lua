-- @docclass
UIConditionButton = extends(UIWidget, 'UIConditionButton')

local barColors = { } -- Must be sorted by percentAbove
table.insert(barColors, { percentAbove = 95, color = '#00BC00' } )
table.insert(barColors, { percentAbove = 90, color = '#07B301' } )
table.insert(barColors, { percentAbove = 85, color = '#0EA901' } )
table.insert(barColors, { percentAbove = 80, color = '#15A002' } )
table.insert(barColors, { percentAbove = 75, color = '#1C9703' } )
table.insert(barColors, { percentAbove = 70, color = '#238E03' } )
table.insert(barColors, { percentAbove = 65, color = '#2A8404' } )
table.insert(barColors, { percentAbove = 60, color = '#317B04' } )
table.insert(barColors, { percentAbove = 55, color = '#387205' } )
table.insert(barColors, { percentAbove = 50, color = '#3F6906' } )
table.insert(barColors, { percentAbove = 45, color = '#465F06' } )
table.insert(barColors, { percentAbove = 40, color = '#4D5607' } )
table.insert(barColors, { percentAbove = 35, color = '#544D08' } )
table.insert(barColors, { percentAbove = 30, color = '#5B4408' } )
table.insert(barColors, { percentAbove = 25, color = '#623A09' } )
table.insert(barColors, { percentAbove = 20, color = '#693109' } )
table.insert(barColors, { percentAbove = 15, color = '#70280A' } )
table.insert(barColors, { percentAbove = 10, color = '#771F0B' } )
table.insert(barColors, { percentAbove =  5, color = '#7E150B' } )
table.insert(barColors, { percentAbove = -1, color = '#850C0C' } )

UIConditionButton.boostColors    = { }
UIConditionButton.boostColors[0] = '#88888877' -- No boost
UIConditionButton.boostColors[1] = '#9E9A3277'
UIConditionButton.boostColors[2] = '#B770FF77'
UIConditionButton.boostColors[3] = '#70B8FF77'

UIConditionButton.boostNames    = { }
UIConditionButton.boostNames[0] = ''
UIConditionButton.boostNames[1] = loc'${CorelibInfoNone}'
UIConditionButton.boostNames[2] = loc'${GamelibInfoBoostLow}'
UIConditionButton.boostNames[3] = loc'${GamelibInfoBoostHigh}'

local function setConditionBarColor(conditionBarWidget, color)
  -- UIProgressBar rebuilds its filler on geometry/style updates using bgColor.
  -- Keep bgColor in sync to avoid one-frame fallback to style gray.
  conditionBarWidget.bgColor = color
  conditionBarWidget:setFillerBackgroundColor(color)
end

function UIConditionButton.create()
  local button = UIConditionButton.internalCreate()
  button:setFocusable(false)
  return button
end

function UIConditionButton:setup(condition)
  self:setId(f('ConditionButton(%d,%d)', condition.id, condition.subId))

  local conditionBarWidget = self:getChildById('conditionBar')
  conditionBarWidget:setPhases(condition.turns or 0)
  conditionBarWidget:setPhasesBorderWidth(1)
  conditionBarWidget:setPhasesBorderColor('#ffffff77')
  conditionBarWidget:setPercent(100)
  setConditionBarColor(conditionBarWidget, barColors[1].color)

  if type(condition.remainingTime) == 'number' and condition.remainingTime > 0 then
    local timer = { }
    self.clock = Timer.new(timer, condition.remainingTime, '!%M:%S')
    self.clock.updateTicks = 0.1

    self.clock.onUpdate = withWeakWidget(self, function(widget)
      widget:updateConditionClock()
    end)
  else
    conditionBarWidget:hide()
  end

  self.condition = condition
  self:updateData(condition)
end

function UIConditionButton:updateData(condition)
  -- Setup icon
  local conditionItemIconWidget = self:getChildById('conditionItemIcon')
  if condition.itemId then
    conditionItemIconWidget:setItemId(condition.itemId)
  else
    conditionItemIconWidget:setWidth(0)
  end

  local conditionPowerIconWidget = self:getChildById('conditionPowerIcon')
  if condition.powerId then
    conditionPowerIconWidget:setIcon(f('/images/ui/power/%d_off', condition.powerId))
    conditionPowerIconWidget:setBackgroundColor(UIConditionButton.boostColors[condition.boost])
  else
  -- For debug
    -- conditionIconWidget:setText(f('%d,%d', condition.id, condition.subId))
  -- Else, remove the icon
    conditionPowerIconWidget:setWidth(0) -- Comment this line if you want the debug above to work
  end

  if condition.name then
    local conditionAuxiliarWidget = self:getChildById('conditionAuxiliar')
    conditionAuxiliarWidget:setText(f('%s', condition.name))
  end

  -- Setup aggressive type
  local conditionTypeWidget = self:getChildById('conditionType')
  conditionTypeWidget:setImageSource(condition.aggressive and '/images/game/creature/condition/type_aggressive' or '/images/game/creature/condition/type_non_aggressive')

  -- Setup clock
  local conditionClockWidget = self:getChildById('conditionClock')
  if condition.remainingTime and self.clock then
    self.clock:start()
    conditionClockWidget:setText(self.clock:getString())
  else
    conditionClockWidget:setText('')
  end

  self:setTooltipText()
end

function UIConditionButton:updateConditionClock()
  if self.clock then
    local conditionClockWidget = self:getChildById('conditionClock')
    conditionClockWidget:setText(self.clock:getString())

    local conditionBarWidget = self:getChildById('conditionBar')
    local percent = self.clock:getPercent()
    conditionBarWidget:setPercent(percent)

    for _, v in ipairs(barColors) do
      if percent > v.percentAbove then
        setConditionBarColor(conditionBarWidget, v.color)
        return
      end
    end
  end
end

function UIConditionButton:onDestroy()
  -- Tooltip
  if g_tooltip and g_tooltip.onWidgetDestroy then
    g_tooltip.onWidgetDestroy(self)
  end

  -- Timer
  if self.clock then
    self.clock:destroy()
    self.clock = nil
  end

  -- Condition
  if type(self.condition) == 'table' then
    if self.condition.button == self then
      self.condition.button = nil
    end
    self.condition = nil
  end
end

function UIConditionButton:setTooltipText()
  self:setTooltip(true, TooltipType.conditionButton)
end
