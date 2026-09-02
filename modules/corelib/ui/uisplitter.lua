-- @docclass
UISplitter = extends(UIWidget, 'UISplitter')

function UISplitter.create()
  local splitter = UISplitter.internalCreate()
  splitter:setFocusable(false)
  return splitter
end

function UISplitter:onHoverChange(hovered)
  -- Check if margin can be changed
  local margin = (self.vertical and self:getMarginBottom() or self:getMarginRight())
  if hovered and (self:canUpdateMargin(margin + 1) ~= margin or self:canUpdateMargin(margin - 1) ~= margin) then
    if g_mouse.isCursorChanged() or g_mouse.isPressed() then
      return
    end

    if self:getWidth() > self:getHeight() then
      self.vertical = true
      self.cursortype = 'vertical'
    else
      self.vertical = false
      self.cursortype = 'horizontal'
    end
    self.hovering = true
    g_mouse.pushCursor(self.cursortype)
    if not self:isPressed() then
      g_effects.fadeIn(self, 75)
    end
  else
    if not self:isPressed() and self.hovering then
      g_mouse.popCursor(self.cursortype)
      g_effects.fadeOut(self, 150)
      self.hovering = false
    end
  end
end

function UISplitter:onMouseMove(mousePos, mouseMoved)
  if self:isPressed() then
    -- local currentmargin, newmargin, delta
    if self.vertical then
      local delta = mousePos.y - self:getY() - self:getHeight()/2
      local newMargin = self:canUpdateMargin(self:getMarginBottom() - delta)
      local currentMargin = self:getMarginBottom()
      if newMargin ~= currentMargin then
        self.currentMargin = newMargin
        if not self.event or self.event:isExecuted() then
          self.event = addEvent(function()
            if isWidgetAlive(self) then
              self:setMarginBottom(self.currentMargin)
            end
          end)
        end
      end

    else
      local delta = mousePos.x - self:getX() - self:getWidth()/2
      local newMargin = self:canUpdateMargin(self:getMarginRight() - delta)
      local currentMargin = self:getMarginRight()
      if newMargin ~= currentMargin then
        self.currentMargin = newMargin
        if not self.event or self.event:isExecuted() then
          self.event = addEvent(function()
            if isWidgetAlive(self) then
              self:setMarginRight(self.currentMargin)
            end
          end)
        end
      end
    end
    return true
  end
end

function UISplitter:onMouseRelease(mousePos, mouseButton)
  if not self:isHovered() then
    g_mouse.popCursor(self.cursortype)
    g_effects.fadeOut(self, 150)
    self.hovering = false
  end
end

function UISplitter:updateMargin(visible)
  local _visible = self:isVisible()
  if visible ~= nil then
    _visible = visible
  end

  local _currentMargin = tonumber(self.currentMargin) and self.currentMargin > 0 and self.currentMargin or self.defaultMargin
  if _visible then
    if self:getWidth() > self:getHeight() then
      self:setMarginBottom(_currentMargin)
    else
      self:setMarginRight(_currentMargin)
    end
  else
    if self:getWidth() > self:getHeight() then
      local margin = self:getMarginBottom()
      self.currentMargin = margin > 0 and margin or _currentMargin
      self:setMarginBottom(0)
    else
      local margin = self:getMarginRight()
      self.currentMargin = margin > 0 and margin or _currentMargin
      self:setMarginRight(0)
    end
  end
end

function UISplitter:onVisibilityChange(visible)
  self:updateMargin(visible)
end

function UISplitter:canUpdateMargin(newMargin)
  return newMargin
end
