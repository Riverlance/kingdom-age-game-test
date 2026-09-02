-- @docclass UIWidget

function UIWidget:onSetup()
  local id = self:getId()

  local isMiniWindowHeader = id == 'miniWindowHeader'
  local isMiniWindowFooter = id == 'miniWindowFooter'

  if isMiniWindowHeader or isMiniWindowFooter then
    local miniWindow          = self:getParent()
    local miniwindowScrollBar = miniWindow:getChildById('miniwindowScrollBar') -- We use scrollbar because contentsPanel follow its top/down anchors

    local isMiniWindowHeaderCreated = isMiniWindowHeader or miniWindow:getChildById('miniWindowHeader') ~= nil
    local isMiniWindowFooterCreated = isMiniWindowFooter or miniWindow:getChildById('miniWindowFooter') ~= nil

    miniwindowScrollBar:breakAnchors()

    miniwindowScrollBar:addAnchor(AnchorTop, isMiniWindowHeaderCreated and 'miniWindowHeader' or 'miniwindowTopBar', AnchorOutsideBottom)
    miniwindowScrollBar:addAnchor(AnchorBottom, isMiniWindowFooterCreated and 'miniWindowFooter' or 'bottomResizeBorder', AnchorOutsideTop)

    miniwindowScrollBar:addAnchor(AnchorRight, 'parent', AnchorRight)
  end

  self:updateLocale(self.locpar)
end

function UIWidget:setMargin(...)
  local params = {...}
  if #params == 1 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[1])
    self:setMarginBottom(params[1])
    self:setMarginLeft(params[1])
  elseif #params == 2 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[2])
    self:setMarginBottom(params[1])
    self:setMarginLeft(params[2])
  elseif #params == 4 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[2])
    self:setMarginBottom(params[3])
    self:setMarginLeft(params[4])
  end
end

function UIWidget:getContentsSize()
  local pos = self:getPosition()

  -- Get position of child which is far at south east corner
  local x = 0
  local y = 0

  for _, child in ipairs(self:getChildren()) do
    if child:isExplicitlyVisible() then
      local childPos          = child:getPosition()
      local childSize         = child:getSize()
      local childSECornerPosX = math.max(0, childPos.x + childSize.width - 1)
      local childSECornerPosY = math.max(0, childPos.y + childSize.height - 1)

      if x < childSECornerPosX then
        x = childSECornerPosX
      end

      if y < childSECornerPosY then
        y = childSECornerPosY
      end
    end
  end

  -- Relative position of south east corner according to parent, which means the contents dimension
  return { width = math.max(0, x - (pos.x + self:getPaddingLeft())), height = math.max(0, y - (pos.y + self:getPaddingTop())) }
end

function UIWidget:getHorizontalMargin(withoutWidth)
  return (not withoutWidth and self:getWidth() or 0) + self:getMarginLeft() + self:getMarginRight()
end

function UIWidget:getHorizontalPadding(withoutWidth)
  return (not withoutWidth and self:getWidth() or 0) + self:getPaddingLeft() + self:getPaddingRight()
end

function UIWidget:getHorizontalLength(marginOnly)
  return self:getWidth() + self:getHorizontalMargin(true) + (not marginOnly and self:getHorizontalPadding(true) or 0)
end

function UIWidget:getVerticalMargin(withoutHeight)
  return (not withoutHeight and self:getHeight() or 0) + self:getMarginTop() + self:getMarginBottom()
end

function UIWidget:getVerticalPadding(withoutHeight)
  return (not withoutHeight and self:getHeight() or 0) + self:getPaddingTop() + self:getPaddingBottom()
end

function UIWidget:getVerticalLength(marginOnly)
  return self:getHeight() + self:getVerticalMargin(true) + (not marginOnly and self:getVerticalPadding(true) or 0)
end
