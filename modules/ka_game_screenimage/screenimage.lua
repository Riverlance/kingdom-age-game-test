_G.GameScreenImage = { }



screenImages = { }



function GameScreenImage.init()
  -- Alias
  GameScreenImage.m = modules.ka_game_screenimage

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeScreenImage, GameScreenImage.parseScreenImage)

  g_ui.importStyle('screenimage.otui')

  connect(g_game, {
    onGameStart = GameScreenImage.clearImages,
    onGameEnd   = GameScreenImage.clearImages
  })

  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameScreenImage.onGeometryChange,
    onViewModeChange = GameScreenImage.onViewModeChange,
    onZoomChange     = GameScreenImage.onZoomChange,
  })
end

function GameScreenImage.terminate()
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeScreenImage)

  GameScreenImage.clearImages()

  disconnect(g_game, {
    onGameStart = GameScreenImage.clearImages,
    onGameEnd   = GameScreenImage.clearImages
  })

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameScreenImage.onGeometryChange,
    onViewModeChange = GameScreenImage.onViewModeChange,
    onZoomChange     = GameScreenImage.onZoomChange,
  })

  _G.GameScreenImage = nil
end

function GameScreenImage.getRootPath()
  return '/screenimages/'
end

function GameScreenImage.clearImages()
  for i = 1, #screenImages do
    local image = screenImages[i]

    if image then
      if image.fadeEvent then
        g_effects.cancelFade(image)
      end
      if image.destroyEvent then
        removeEvent(image.destroyEvent)
      end

      image:destroy()
    end
  end
  screenImages = { }
end

function GameScreenImage.addImage(info) -- old: path, fadeIn, position, sizeX, sizeY, sizeBasedOnGameScreen
  if not info or table.empty(info) then
    return false
  end

  local image = g_ui.createWidget('ScreenImage', GameInterface.getMapPanel())

  image.individualAnimation = info.individualAnimation or false
  image:setImageIndividualAnimation(image.individualAnimation) -- Before setImageSource

  image:setImageSource(f('%s%s', GameScreenImage.getRootPath(), info.path)) -- Before getting its width/height

  image.path                  = info.path
  image.sizeX                 = info.sizeX or 0
  image.sizeY                 = info.sizeY or 0
  image.sizeByFactor          = info.sizeByFactor ~= nil and info.sizeByFactor or false -- false as default
  image.sizeBasedOnGameScreen = info.sizeBasedOnGameScreen == nil and true or info.sizeBasedOnGameScreen -- true as default
  image.position              = info.position or ScreenImagePos.Center
  image.scale                 = info.scale or ScreenImageScale.Inside
  image.originalSizeX         = image:getWidth()
  image.originalSizeY         = image:getHeight()

  table.insert(screenImages, image)

  local fadeIn = info.fadeIn or 0
  if fadeIn ~= 0 then
    g_effects.fadeIn(image, fadeIn)
  end

  GameScreenImage.updateGeometry(image)

  return true
end

local function removeSingleImage(index, fadeOut)
  local image = screenImages[index]
  if not image --[[or image.path ~= path]] or image.destroyEvent then
    return false
  end

  if image.fadeEvent then
    -- Cancel fade, if was fading already
    g_effects.cancelFade(image)
  end

  if fadeOut == 0 then
    image:destroy()
    table.remove(screenImages, index)
  else
    g_effects.fadeOut(image, fadeOut)

    image.destroyEvent = scheduleEvent(withWeakWidget(image, function(widget)
      if widget.fadeEvent then
        g_effects.cancelFade(widget)
      end
      for i = #screenImages, 1, -1 do
        if screenImages[i] == widget then
          table.remove(screenImages, i)
          break
        end
      end
      widget:destroy()
    end), fadeOut)
  end

  return true
end

function GameScreenImage.removeImage(path, fadeOut, mode) -- (path, [fadeOut = 0 [, mode = ScreenImageRemoveMode.All]])
  if not path or #screenImages < 1 then
    return false
  end

  fadeOut = fadeOut or 0
  mode    = mode or ScreenImageRemoveMode.All

  -- Remove last added of path
  if mode == 1 then
    local found = nil
    for i = #screenImages, 1, -1 do
      if screenImages[i].path == path then
        found = i
        break
      end
    end
    if found then
      if not removeSingleImage(found, fadeOut) then
        return false
      end
    end

  -- Remove first added of path
  elseif mode == -1 then
    local found = nil
    for i = 1, #screenImages do
      if screenImages[i].path == path then
        found = i
        break
      end
    end
    if found then
      if not removeSingleImage(found, fadeOut) then
        return false
      end
    end

  -- Remove all of path
  else
    for i = #screenImages, 1, -1 do
      if screenImages[i].path == path then
        removeSingleImage(i, fadeOut)
      end
    end
  end

  return true
end



-- Geometry

function GameScreenImage.onGeometryChange(self)
  GameScreenImage.updateGeometry()
end

function GameScreenImage.onViewModeChange(mapWidget, newMode, oldMode)
  GameScreenImage.updateGeometry()
end

function GameScreenImage.onZoomChange(self, oldZoom, newZoom)
  GameScreenImage.updateGeometry()
end

local function adjustPosition(image)
  local hasMarginLeft  = false
  local hasMarginRight = false

  image:breakAnchors()

  if table.contains({ ScreenImageScale.None, ScreenImageScale.Fit, ScreenImageScale.Inside }, image.scale) then
    if image.position == ScreenImagePos.Center then
      image:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
      image:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)

    elseif image.position == ScreenImagePos.Top then
      image:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
      image:addAnchor(AnchorTop, 'parent', AnchorTop)

    elseif image.position == ScreenImagePos.TopRight then
      image:addAnchor(AnchorRight, 'parent', AnchorRight)
      image:addAnchor(AnchorTop, 'parent', AnchorTop)
      hasMarginRight = true

    elseif image.position == ScreenImagePos.Right then
      image:addAnchor(AnchorRight, 'parent', AnchorRight)
      image:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      hasMarginRight = true

    elseif image.position == ScreenImagePos.BottomRight then
      image:addAnchor(AnchorRight, 'parent', AnchorRight)
      image:addAnchor(AnchorBottom, 'parent', AnchorBottom)
      hasMarginRight = true

    elseif image.position == ScreenImagePos.Bottom then
      image:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
      image:addAnchor(AnchorBottom, 'parent', AnchorBottom)

    elseif image.position == ScreenImagePos.BottomLeft then
      image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      image:addAnchor(AnchorBottom, 'parent', AnchorBottom)
      hasMarginLeft = true

    elseif image.position == ScreenImagePos.Left then
      image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      image:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      hasMarginLeft = true

    elseif image.position == ScreenImagePos.TopLeft then
      image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      image:addAnchor(AnchorTop, 'parent', AnchorTop)
      hasMarginLeft = true
    end

  elseif image.scale == ScreenImageScale.FitXY then
    hasMarginLeft  = true
    hasMarginRight = true
  end

  if hasMarginLeft or hasMarginRight then
    local mapWidget = GameInterface.getMapPanel()
    if hasMarginLeft then
      image:setMarginLeft(mapWidget:getMapLeftSide() - (mapWidget:getLeftSide() + mapWidget:getPaddingLeft()))
    end
    if hasMarginRight then
      image:setMarginRight(mapWidget:getRightSide() - (mapWidget:getMapRightSide() + mapWidget:getPaddingRight()))
    end
  end
end

local function adjustSize(image)
  local mapWidget = GameInterface.getMapPanel()

  if image.sizeX > 0 then
    local strecthRatio = mapWidget:getStretchRatio()

    if image.sizeByFactor then
      local size = image.originalSizeX * image.sizeX
      image:setWidth(image.sizeBasedOnGameScreen and size * strecthRatio or size)
    else
      image:setWidth(image.sizeBasedOnGameScreen and image.sizeX * strecthRatio or image.sizeX)
    end

  elseif image.sizeX == 0 and image:getWidth() ~= image.originalSizeX then
    image:setWidth(image.originalSizeX)
  end

  if image.sizeY > 0 then
    local strecthRatio = mapWidget:getStretchRatio()

    if image.sizeByFactor then
      local size = image.originalSizeY * image.sizeY
      image:setHeight(image.sizeBasedOnGameScreen and size * strecthRatio or size)
    else
      image:setHeight(image.sizeBasedOnGameScreen and image.sizeY * strecthRatio or image.sizeY)
    end

  elseif image.sizeY == 0 and image:getHeight() ~= image.originalSizeY then
    image:setHeight(image.originalSizeY)
  end
end

local function adjustScale(image)
  local mapWidget = GameInterface.getMapPanel()

  if image.scale == ScreenImageScale.FitXY then
    image:breakAnchors()

    image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    image:addAnchor(AnchorRight, 'parent', AnchorRight)
    image:addAnchor(AnchorTop, 'parent', AnchorTop)
    image:addAnchor(AnchorBottom, 'parent', AnchorBottom)

  elseif image.scale == ScreenImageScale.Fit or image.scale == ScreenImageScale.Inside then
    local width  = image:getWidth()
    local height = image:getHeight()

    local borderLeft = mapWidget:getMapLeftSide() - (mapWidget:getLeftSide() + mapWidget:getPaddingLeft())
    local borderTop  = mapWidget:getMapTopSide() - (mapWidget:getTopSide() + mapWidget:getPaddingTop())

    local mapWidth  = mapWidget:getMapWidth() + (borderLeft * 2)
    local mapHeight = mapWidget:getMapHeight() + (borderTop * 2)

    -- Scale inside - If inside already, keep it its original size; else, decrease as ScreenImageScale.Fit
    if image.scale == ScreenImageScale.Inside and width <= mapWidth and height <= mapHeight then
      return
    end

    -- If fit already
    if width == mapWidth and height <= mapHeight or height == mapHeight and width <= mapWidth then
      return
    end

    -- Increase
    if width < mapWidth and height < mapHeight then
      local ratio
      -- Width diff < height diff
      if mapWidth - width < mapHeight - height then
        ratio = width ~= 0 and mapWidth / width or 0
      else
        ratio = height ~= 0 and mapHeight / height or 0
      end
      image:setWidth(math.round(width * ratio))
      image:setHeight(math.round(height * ratio))

    -- Decrease
    else
      --[[
        Possible cases:

        width > mapWidth and height > mapHeight

        width > mapWidth and height < mapHeight
        width < mapWidth and height > mapHeight

        width == mapWidth and height > mapHeight
        width > mapWidth and height == mapHeight
      ]]

      -- Fake calculus to figure out if width is higher than mapWidth
      -- How it works: we get a stretched/shrinked image making the height be equals to mapHeight, then we decide if width > mapWidth or not
      local _ratio        = height ~= 0 and mapHeight / height or 0 -- height * _ratio = mapHeight --> _ratio = mapHeight / height
      local _width        = width * _ratio -- New width in which height == mapHeight
      local widthIsHigher = _width > mapWidth

      local ratio
      if widthIsHigher then
        ratio = mapWidth ~= 0 and width / mapWidth or 0
      else
        ratio = mapHeight ~= 0 and height / mapHeight or 0
      end
      image:setWidth(math.round(width / ratio))
      image:setHeight(math.round(height / ratio))
    end
  end
end

function GameScreenImage.updateGeometry(image) -- ([image])
  for _, _image in ipairs(image and { image } or screenImages) do
    addEvent(withWeakWidget(_image, function(widget)
      adjustPosition(widget)
      adjustSize(widget)
      adjustScale(widget)
    end))
  end
end



-- Protocol

function GameScreenImage.parseScreenImage(protocolGame, opcode, msg)
  local action = msg:getU8()

  if action == ScreenImageAction.Add then
    local info                 = { }
    info.path                  = msg:getString()
    info.individualAnimation   = msg:getU8() == 1
    info.fadeIn                = msg:getU16()
    info.sizeX                 = msg:getU8()
    info.sizeY                 = msg:getU8()
    info.sizeByFactor          = msg:getU8() == 1
    info.sizeBasedOnGameScreen = msg:getU8() == 1
    info.position              = msg:getU8()
    info.scale                 = msg:getU8()

    GameScreenImage.addImage(info)

  elseif action == ScreenImageAction.Remove then
    local path       = msg:getString()
    local fadeOut    = msg:getU16()
    local removeMode = msg:getU8()

    GameScreenImage.removeImage(path, fadeOut, removeMode)
  end
end
