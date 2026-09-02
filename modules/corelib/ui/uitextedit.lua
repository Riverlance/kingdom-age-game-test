function UITextEdit:setVerticalScrollBar(scrollbar)
  self.verticalScrollBar = scrollbar
  self.verticalScrollBar.onValueChange = function(scrollbar, value)
    if not isWidgetAlive(self) then
      return
    end

    local virtualOffset = self:getTextVirtualOffset()
    virtualOffset.y = value
    self:setTextVirtualOffset(virtualOffset)
  end
  self:updateScrollBars()
end

function UITextEdit:setHorizontalScrollBar(scrollbar)
  self.horizontalScrollBar = scrollbar
  self.horizontalScrollBar.onValueChange = function(scrollbar, value)
    if not isWidgetAlive(self) then
      return
    end

    local virtualOffset = self:getTextVirtualOffset()
    virtualOffset.x = value
    self:setTextVirtualOffset(virtualOffset)
  end
  self:updateScrollBars()
end

function UITextEdit:updateScrollBars()
  local scrollSize = self:getTextTotalSize()
  local scrollWidth = math.max(scrollSize.width - self:getTextVirtualSize().width, 0)
  local scrollHeight = math.max(scrollSize.height - self:getTextVirtualSize().height, 0)

  local scrollbar = self.verticalScrollBar
  if scrollbar then
    scrollbar:setMinimum(0)
    scrollbar:setMaximum(scrollHeight)
    scrollbar:setValue(self:getTextVirtualOffset().y)
  end

  local scrollbar = self.horizontalScrollBar
  if scrollbar then
    scrollbar:setMinimum(0)
    scrollbar:setMaximum(scrollWidth)
    scrollbar:setValue(self:getTextVirtualOffset().x)
  end
end

function UITextEdit:updatePlaceholder(text) -- ([text])
  local placeholder = self.placeholder
  if not placeholder then
    return
  end

  text = text or self:getText()

  placeholder:setTextWrap(self:isMultiline())

  placeholder:setVisible(not string.exists(text))
end

function UITextEdit:setPlaceholderText(text, update) -- ([text[, update = true]])
  local placeholder = self.placeholder
  if not placeholder then
    return false
  end

  text = text or ''
  if update == nil then
    update = true
  end

  placeholder:setText(text)

  if update then
    self:updatePlaceholder()
  end

  return true
end



-- Event

function UITextEdit:onStyleApply(styleName, styleNode)
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

    -- Placeholder
    elseif name == 'placeholdertext' then
      addEvent(function()
        if not isWidgetAlive(self) then
          return
        end

        local placeholder = self.placeholder
        if placeholder then
          placeholder:setText(value)
          self:updatePlaceholder()
        end
      end)
    end
  end
end

function UITextEdit:onMouseWheel(mousePos, mouseWheel)
  if self.verticalScrollBar and self:isMultiline() then
    if mouseWheel == MouseWheelUp then
      self.verticalScrollBar:onDecrement()
    else
      self.verticalScrollBar:onIncrement()
    end
    return true

  elseif self.horizontalScrollBar then
    if mouseWheel == MouseWheelUp then
      self.horizontalScrollBar:onIncrement()
    else
      self.horizontalScrollBar:onDecrement()
    end
    return true
  end
end

function UITextEdit:onTextAreaUpdate(virtualOffset, virtualSize, totalSize)
  self:updateScrollBars()
end

function UITextEdit:onTextChange(newText, oldText)
  local function onError(text)
    text = text or oldText
    self:setText(text, true)
    self:updatePlaceholder(text)
  end

  -- Max characters
  if (self.maxChars or 0) > 0 and #newText > self.maxChars then
    return onError()

  -- Regex
  elseif string.exists(self.regex) and string.exists(newText) then
    local formattedText = newText:match(self.regex)

    if string.exists(formattedText) then
      if formattedText ~= newText then
        return onError(formattedText)
      end
    else
      return onError()
    end
  end

  if newText ~= oldText then
    self:updatePlaceholder(newText)
  end
end



-- todo: focus to cursor
