-- @docclass
UIMiniWindowContainer = extends(UIWidget, 'UIMiniWindowContainer')

function UIMiniWindowContainer.create()
  local container = UIMiniWindowContainer.internalCreate()
  container.scheduledWidgets = { }
  container:setFocusable(false)
  container:setPhantom(true)
  return container
end

function UIMiniWindowContainer:onVisibilityChange(visible)
  signalcall(self.onFitAll, self)
end

function UIMiniWindowContainer:getSpaceHeight()
  return self:getHeight() - (self:getPaddingTop() + self:getPaddingBottom())
end

function UIMiniWindowContainer:getChildrenSpaceHeight()
  local sumHeight = 0
  local children = self:getChildren()
  for i = 1, #children do
    if children[i]:isVisible() then
      sumHeight = sumHeight + children[i]:getHeight()
    end
  end
  return sumHeight
end

function UIMiniWindowContainer:getEmptySpaceHeight()
  return self:getSpaceHeight() - self:getChildrenSpaceHeight()
end

function UIMiniWindowContainer:onDrop(widget, mousePos)
  if widget:getClassName() == 'UIMiniWindow' then
    local oldParent = widget:getParent()
    if oldParent == self then
      return true
    end

    if oldParent then
      oldParent:removeChild(widget)
    end

    if widget.movedWidget then
      local index = self:getChildIndex(widget.movedWidget)
      self:insertChild(index + widget.movedIndex, widget)
    else
      self:addChild(widget)
    end

    signalcall(self.onFitAll, self, widget)
    return true
  end
end

function UIMiniWindowContainer:swapInsert(widget, index)
  local oldParent = widget:getParent()
  local oldIndex = self:getChildIndex(widget)

  if oldParent == self and oldIndex ~= index then
    local oldWidget = self:getChildByIndex(index)
    if oldWidget then
      self:removeChild(oldWidget)
      self:insertChild(oldIndex, oldWidget)
    end
    self:removeChild(widget)
    self:insertChild(index, widget)
  end
end

function UIMiniWindowContainer:scheduleInsert(widget, index)
  if index - 1 > self:getChildCount() then
    for scheduledIndex, scheduledWidget in pairs(self.scheduledWidgets) do
      if scheduledWidget == widget then
        self.scheduledWidgets[scheduledIndex] = nil
      end
    end

    if self.scheduledWidgets[index] then
      pdebug('replacing scheduled widget id ' .. widget:getId())
    end
    self.scheduledWidgets[index] = widget

  else
    local oldParent = widget:getParent()
    if oldParent ~= self then
      if oldParent then
        oldParent:removeChild(widget)
      end
      self:insertChild(index, widget)

      while true do
        local placed = false
        for nIndex, nWidget in pairs(self.scheduledWidgets) do
          if nIndex - 1 <= self:getChildCount() then
            local nParent = nWidget and nWidget:getParent()

            if nParent == self then
              self:removeChild(nWidget)
            elseif nParent then
              nParent:removeChild(nWidget)
            end

            self:insertChild(nIndex, nWidget)
            self.scheduledWidgets[nIndex] = nil
            placed = true
            break
          end
        end

        if not placed then
          break
        end
      end
    end
  end
end

function UIMiniWindowContainer:order()
  local children = self:getChildren()
  for i = 1, #children do
    if not children[i].miniLoaded then
      return
    end
  end

  for i = 1, #children do
    if children[i].miniIndex then
      self:swapInsert(children[i], children[i].miniIndex)
    end
  end
end

function UIMiniWindowContainer:saveChildren()
  local children = self:getChildren()
  local ignoreIndex = 0
  for i = 1, #children do
    if children[i].save then
      children[i]:saveParentIndex(self:getId(), i - ignoreIndex)
    else
      ignoreIndex = ignoreIndex + 1
    end
  end
end
