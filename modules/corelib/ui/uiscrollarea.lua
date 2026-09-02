-- @docclass
UIScrollArea = extends(UIWidget, 'UIScrollArea')

-- public functions
function UIScrollArea.create()
  local scrollarea = UIScrollArea.internalCreate()
  scrollarea:setClipping(true)
  scrollarea.inverted = false
  scrollarea.alwaysScrollMaximum = false
  return scrollarea
end

function UIScrollArea:onStyleApply(styleName, styleNode)
  for name, value in pairs(styleNode) do
    if name == 'vertical-scrollbar' then
      addEvent(function()
        if not isWidgetAlive(self) then
          return
        end

        local parent = self:getParent()
        if parent then
          self:setVerticalScrollBar(parent:getChildById(value))
        end
      end)
    elseif name == 'horizontal-scrollbar' then
      addEvent(function()
        if not isWidgetAlive(self) then
          return
        end

        local parent = self:getParent()
        if parent then
          self:setHorizontalScrollBar(parent:getChildById(value))
        end
      end)
    elseif name == 'inverted-scroll' then
      self:setInverted(value)
    elseif name == 'always-scroll-maximum' then
      self:setAlwaysScrollMaximum(value)
    end
  end
end

function UIScrollArea:updateScrollBars()
  local scrollWidth = math.max(self:getChildrenRect().width - self:getPaddingRect().width, 0)
  local scrollHeight = math.max(self:getChildrenRect().height - self:getPaddingRect().height, 0)

  local scrollbar = self.verticalScrollBar
  if scrollbar then
    if self.inverted then
      scrollbar:setMinimum(-scrollHeight)
      scrollbar:setMaximum(0)
    else
      scrollbar:setMinimum(0)
      scrollbar:setMaximum(scrollHeight)
    end
  end

  local scrollbar = self.horizontalScrollBar
  if scrollbar then
    if self.inverted then
      scrollbar:setMinimum(-scrollWidth)
      scrollbar:setMaximum(0)
    else
      scrollbar:setMinimum(0)
      scrollbar:setMaximum(scrollWidth)
    end
  end

  if self.lastScrollWidth ~= scrollWidth then
    self:onScrollWidthChange()
  end
  if self.lastScrollHeight ~= scrollHeight then
    self:onScrollHeightChange()
  end

  self.lastScrollWidth = scrollWidth
  self.lastScrollHeight = scrollHeight
end

function UIScrollArea:setVerticalScrollBar(scrollbar)
  self.verticalScrollBar = scrollbar
  local callback = function(scrollbar, value)
    if not isWidgetAlive(self) then
      return
    end

    local virtualOffset = self:getVirtualOffset()
    virtualOffset.y = value
    self:setVirtualOffset(virtualOffset)
    signalcall(self.onScrollChange, self, virtualOffset)
  end
  connect(self.verticalScrollBar, {
    onValueChange = callback
  })
  self:updateScrollBars()
end

function UIScrollArea:setHorizontalScrollBar(scrollbar)
  self.horizontalScrollBar = scrollbar
  local callback = function(scrollbar, value)
    if not isWidgetAlive(self) then
      return
    end

    local virtualOffset = self:getVirtualOffset()
    virtualOffset.x = value
    self:setVirtualOffset(virtualOffset)
    signalcall(self.onScrollChange, self, virtualOffset)
  end
  connect(self.horizontalScrollBar, {
    onValueChange = callback
  })
  self:updateScrollBars()
end

function UIScrollArea:setInverted(inverted)
  self.inverted = inverted
end

function UIScrollArea:setAlwaysScrollMaximum(value)
  self.alwaysScrollMaximum = value
end

function UIScrollArea:onLayoutUpdate()
  self:updateScrollBars()
end

function UIScrollArea:onMouseWheel(mousePos, mouseWheel)
  if self.verticalScrollBar then
    if not self.verticalScrollBar:isOn() then
      return false
    end
    if mouseWheel == MouseWheelUp then
      local minimum = self.verticalScrollBar:getMinimum()
      if self.verticalScrollBar:getValue() <= minimum then
        return false
      end
      self.verticalScrollBar:onDecrement()
    else
      local maximum = self.verticalScrollBar:getMaximum()
      if self.verticalScrollBar:getValue() >= maximum then
        return false
      end
      self.verticalScrollBar:onIncrement()
    end
  elseif self.horizontalScrollBar then
    if not self.horizontalScrollBar:isOn() then
      return false
    end
    if mouseWheel == MouseWheelUp then
      local maximum = self.horizontalScrollBar:getMaximum()
      if self.horizontalScrollBar:getValue() >= maximum then
        return false
      end
      self.horizontalScrollBar:onIncrement()
    else
      local minimum = self.horizontalScrollBar:getMinimum()
      if self.horizontalScrollBar:getValue() <= minimum then
        return false
      end
      self.horizontalScrollBar:onDecrement()
    end
  end
  return true
end

function UIScrollArea:ensureChildVisible(child)
  if not child or not self:hasChild(child) then
    return
  end

  local paddingRect = self:getPaddingRect()
  if self.verticalScrollBar then
    local viewTop     = paddingRect.y
    local viewHeight  = paddingRect.height
    local viewBottom  = viewTop + viewHeight
    local childTop    = child:getY()
    local childHeight = child:getHeight()
    local childBottom = childTop + childHeight

    if childHeight > viewHeight then
      -- Avoid jumping to the end for oversized focus targets (e.g. tab content containers).
      if childTop < viewTop then
        self.verticalScrollBar:decrement(viewTop - childTop)
      elseif childTop > viewTop then
        self.verticalScrollBar:increment(childTop - viewTop)
      end
    else
      local deltaY = viewTop - childTop
      if deltaY > 0 then
        self.verticalScrollBar:decrement(deltaY)
      else
        deltaY = childBottom - viewBottom
        if deltaY > 0 then
          self.verticalScrollBar:increment(deltaY)
        end
      end
    end
  elseif self.horizontalScrollBar then
    local viewLeft   = paddingRect.x
    local viewWidth  = paddingRect.width
    local viewRight  = viewLeft + viewWidth
    local childLeft  = child:getX()
    local childWidth = child:getWidth()
    local childRight = childLeft + childWidth

    if childWidth > viewWidth then
      if childLeft < viewLeft then
        self.horizontalScrollBar:decrement(viewLeft - childLeft)
      elseif childLeft > viewLeft then
        self.horizontalScrollBar:increment(childLeft - viewLeft)
      end
    else
      local deltaX = viewLeft - childLeft
      if deltaX > 0 then
        self.horizontalScrollBar:decrement(deltaX)
      else
        deltaX = childRight - viewRight
        if deltaX > 0 then
          self.horizontalScrollBar:increment(deltaX)
        end
      end
    end
  end
end

function UIScrollArea:onChildFocusChange(focusedChild, oldFocused, reason)
  if focusedChild and (reason == MouseFocusReason or reason == KeyboardFocusReason) then
    self:ensureChildVisible(focusedChild)
  end
end

function UIScrollArea:onScrollWidthChange()
  if self.alwaysScrollMaximum and self.horizontalScrollBar then
    self.horizontalScrollBar:setValue(self.horizontalScrollBar:getMaximum())
  end
end

function UIScrollArea:onScrollHeightChange()
  if self.alwaysScrollMaximum and self.verticalScrollBar then
    self.verticalScrollBar:setValue(self.verticalScrollBar:getMaximum())
  end
end
