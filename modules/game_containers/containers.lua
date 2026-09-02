g_locales.loadLocales(resolvepath(''))

_G.GameContainers = { }



function GameContainers.init()
  -- Alias
  GameContainers.m = modules.game_containers

  g_ui.importStyle('container')

  connect(Container, {
    onOpen       = GameContainers.onContainerOpen,
    onClose      = GameContainers.onContainerClose,
    onSizeChange = GameContainers.onContainerChangeSize,
    onUpdateItem = GameContainers.onContainerUpdateItem
  })

  connect(g_game, {
    onGameEnd = GameContainers.clean
  })

  GameContainers.reloadContainers()
end

function GameContainers.terminate()
  disconnect(g_game, {
    onGameEnd = GameContainers.clean
  })

  disconnect(Container, {
    onOpen       = GameContainers.onContainerOpen,
    onClose      = GameContainers.onContainerClose,
    onSizeChange = GameContainers.onContainerChangeSize,
    onUpdateItem = GameContainers.onContainerUpdateItem
  })

  _G.GameContainers = nil
end

function GameContainers.reloadContainers()
  GameContainers.clean()

  for _,container in pairs(g_game.getContainers()) do
    GameContainers.onContainerOpen(container)
  end
end

function GameContainers.clean()
  for containerid,container in pairs(g_game.getContainers()) do
    GameContainers.destroy(container)
  end
end

function GameContainers.destroy(container)
  local containerWindow = container.window
  if not containerWindow then
    return
  end

  -- Drop strong Lua references before destroy to avoid leaked-reference warnings
  container.window = nil
  container.itemsPanel = nil

  containerWindow.container = nil
  containerWindow.previousContainer = nil
  containerWindow.onContentsPanelGeometryChange = nil
  containerWindow:destroy()
end

function GameContainers.refreshContainerItems(container)
  for slot = 0, container:getCapacity() - 1 do
    local itemWidget = container.itemsPanel:getChildById('item' .. slot)
    itemWidget:setItem(container:getItem(slot))
    itemWidget:updateBackground()
  end

  if container:hasPages() then
    GameContainers.refreshContainerPages(container)
  end
end

function GameContainers.toggleContainerPages(containerWindow, pages)
  -- Mini window header that contains page panel
  local miniWindowHeader = containerWindow:getChildById('miniWindowHeader')
  miniWindowHeader:setHeight(pages and 28 or 0)
end

function GameContainers.refreshContainerPages(container)
  local miniWindowHeader = container.window:getChildById('miniWindowHeader')
  local pagePanel        = miniWindowHeader:getChildById('pagePanel')
  local containerId      = container:getId()

  local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
  local pages       = 1 + math.floor(math.max(0, (container:getSize() - 1)) / container:getCapacity())
  pagePanel:getChildById('pageLabel'):setText(f(loc'${GameContainersCurrentPage}', currentPage, pages))

  local prevPageButton = pagePanel:getChildById('prevPageButton')
  if currentPage == 1 then
    prevPageButton:setEnabled(false)
  else
    prevPageButton:setEnabled(true)
    prevPageButton.onClick = function()
      local _container = g_game.getContainer(containerId)
      if _container then
        g_game.seekInContainer(containerId, _container:getFirstIndex() - _container:getCapacity())
      end
    end
  end

  local nextPageButton = pagePanel:getChildById('nextPageButton')
  if currentPage >= pages then
    nextPageButton:setEnabled(false)
  else
    nextPageButton:setEnabled(true)
    nextPageButton.onClick = function()
      local _container = g_game.getContainer(containerId)
      if _container then
        g_game.seekInContainer(containerId, _container:getFirstIndex() + _container:getCapacity())
      end
    end
  end
end

function GameContainers.refreshContainerSize(containerWindow, resetToMaxHeight)
  local minimizeButton = containerWindow:getChildById('minimizeButton')
  if minimizeButton:isOn() then
    return
  end

  local contentsPanel    = containerWindow:getChildById('contentsPanel')
  local layout           = contentsPanel:getLayout()
  local cellSize         = layout:getCellSize()
  local numColumns       = layout:getNumColumns()
  local minContentHeight = cellSize.height
  local maxContentHeight = cellSize.height * layout:getNumLines()
  local realMinHeight    = containerWindow:getRealMinHeight()
  local minHeight        = realMinHeight + minContentHeight
  local maxHeight        = realMinHeight + maxContentHeight
  local containerHeight  = containerWindow:getHeight()

  -- Set minimum and maximum window height
  containerWindow:setContentMinimumHeight(minContentHeight)
  containerWindow:setContentMaximumHeight(maxContentHeight)

  -- Set window height
  -- not resetToMaxHeight or actual window size (containerHeight) exceeded the minHeight--maxHeight range of internal opened container
  if not resetToMaxHeight --[[and not containerWindow.previousContainer]] or containerHeight < minHeight or containerHeight > maxHeight then
    local newContentHeight

    -- On change the panel's width
    if resetToMaxHeight then
      newContentHeight = maxContentHeight

    -- This is useful for decay items and when the container window changes its size
    else
      local filledLines = math.max(1, math.ceil(containerWindow.container:getItemsCount() / numColumns))
      newContentHeight  = filledLines * cellSize.height
    end

    containerWindow:setContentHeight(newContentHeight)
  end
end

function GameContainers.onContainerOpen(container, previousContainer)
  local panel, panelKey = GameInterface.getAvailablePanel()
  if not panel then
    -- Send close container
    g_game.close(container)

    -- Send error message
    GameTextMessage.displayStatusMessage(loc'${GamelibInfoNoOpenedPanel}')
    return
  end

  local containerWindow
  if previousContainer then -- Opened on same window
    containerWindow = previousContainer.window
    previousContainer.window = nil
    previousContainer.itemsPanel = nil
  else
    containerWindow = g_ui.createWidget('ContainerWindow')
  end

  local containerId = container:getId()
  containerWindow:setId('container' .. containerId)
  containerWindow.container = container
  containerWindow.previousContainer = previousContainer



  containerWindow:setScrollBarAutoHiding(false)

  -- onClose callback
  connect(containerWindow, {
    onClose = function(self)
      local _container = g_game.getContainer(containerId)
      if _container then
        g_game.close(_container)
      end
      self:hide()
    end
  })

  -- Refresh container size on change panel of container
  connect(containerWindow, {
    onChangeWindowPanel = function(self, newParent)
      local lastPanel = self.lastPanel
      if lastPanel and newParent:getWidth() == lastPanel:getWidth() then
        return
      end
      GameContainers.refreshContainerSize(self)
    end
  })

  local contentsPanel = containerWindow:getChildById('contentsPanel')
  containerWindow.onContentsPanelGeometryChange = withWeakWidget(containerWindow, function(window)
    GameContainers.refreshContainerSize(window, true)
  end)
  connect(contentsPanel, {
    onGeometryChange = containerWindow.onContentsPanelGeometryChange
  })

  -- upArrowMenuButton callback
  local upArrowMenuButton = containerWindow:getChildById('upArrowMenuButton')
  upArrowMenuButton.onClick = function()
    local _container = g_game.getContainer(containerId)
    if _container then
      g_game.openParent(_container)
    end
  end
  upArrowMenuButton:setVisible(container:hasParent())
  upArrowMenuButton:setTooltip(loc'${GameContainersArrowUpButton}')

  -- Set item widget
  local containerItemWidget = containerWindow:getChildById('containerItemWidget')
  containerItemWidget:setItem(container:getContainerItem())
  containerItemWidget:setPhantom(true)

  -- Set item name

  local name = container:getName()
  name       = f('%s%s', name:sub(1, 1):upper(), name:sub(2))

  if #name > 11 then
    name = f('%s%s', name:sub(1, #name - 3), '...')
  end

  containerWindow:setText(name)



  -- Setup children
  contentsPanel:destroyChildren()
  for slot = 0, container:getCapacity() - 1 do
    local itemWidget = g_ui.createWidget('Item', contentsPanel)
    itemWidget:setId('item' .. slot)
    itemWidget:setItem(container:getItem(slot))
    itemWidget:setMargin(0)
    itemWidget:updateBackground()
    itemWidget.position = container:getSlotPosition(slot)

    if not container:isUnlocked() then
      itemWidget:setBorderColor('red')
    end
  end

  -- Update container's window and itemsPanel
  container.window     = containerWindow
  container.itemsPanel = contentsPanel

  -- Update pages bar
  GameContainers.toggleContainerPages(containerWindow, container:hasPages())
  GameContainers.refreshContainerPages(container)



  -- Setup window
  containerWindow:setup()

  GameInterface.onContainerMiniWindowOpen(containerWindow, previousContainer)

  -- Update size
  GameContainers.refreshContainerSize(containerWindow)
end

function GameContainers.onContainerClose(container)
  GameContainers.destroy(container)
end

function GameContainers.onContainerChangeSize(container, size)
  if not container.window then
    return
  end

  GameContainers.refreshContainerItems(container)
end

function GameContainers.onContainerUpdateItem(container, slot, item, oldItem)
  if not container.window then
    return
  end

  local itemWidget = container.itemsPanel:getChildById('item' .. slot)
  itemWidget:setItem(item)
  itemWidget:updateBackground()
end
