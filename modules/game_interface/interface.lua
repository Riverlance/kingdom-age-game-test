g_locales.loadLocales(resolvepath(''))

_G.GameInterface = { }



WALK_STEPS_RETRY = 10

Npc.DefaultDistance = 4 -- Check also on server: lib/class/npc.lua

local cycleWalkEvent = nil

gameRootPanel = nil
gameMapPanel = nil
gameScreenArea = nil
gameRightFirstPanel = nil
gameRightSecondPanel = nil
gameRightThirdPanel = nil
gameLeftFirstPanel = nil
gameLeftSecondPanel = nil
gameLeftThirdPanel = nil
gameRightFirstPanelContainer = nil
gameRightSecondPanelContainer = nil
gameRightThirdPanelContainer = nil
gameLeftFirstPanelContainer = nil
gameLeftSecondPanelContainer = nil
gameLeftThirdPanelContainer = nil
leftPanelAddButton = nil
leftPanelRemoveButton = nil
rightPanelAddButton = nil
rightPanelRemoveButton = nil
gameBottomPanel = nil
mouseGrabberWidget = nil
countWindow = nil
logoutWindow = nil
exitWindow = nil
bottomSplitter = nil
gameExpBar = nil
leftPanelButton = nil
rightPanelButton = nil
topMenuButton = nil
chatButton = nil
currentViewMode = 0
smartWalkDirs = { }
smartWalkDir = nil
firstStep = false
hookedMenuOptions = { }
lastDirTime = g_clock.millis()
gamePanels = { }
gamePanelsContainer = { }

-- List of panels, even if panelsPriority is not set
local _gamePanels = { }
local _gamePanelsContainer = { }



-- Transposed view

local function mapWalkDirectionByCurrentView(dir)
  if not gameMapPanel or not gameMapPanel.isTransposedView or not gameMapPanel:isTransposedView() then
    return dir
  end

  return Position.transposeDirection(dir)
end



-- Look hover

local hoverLookTargetSourceUnknown    = 0
local hoverLookTargetSourceHud        = 1
local hoverLookTargetSourceGameScreen = 2

local hoverLookRefreshInterval    = 250
local hoverLookTickInterval       = 100
local hoverLookCycleEvent         = nil
local hoverLookTooltipWidget      = nil
local hoverLookTargetKey          = nil
local hoverLookTargetSource       = hoverLookTargetSourceUnknown
local hoverLookLastRequestAt      = 0
local hoverLookCurrentTooltipKey  = nil
local hoverLookCurrentTooltipText = nil
local hoverLookWasEnabled         = false

local function getDistanceBetween(p1, p2)
  return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

local function isHoverLookEnabled()
  if g_platform.isMobile() then
    return false
  end
  if not g_game.isOnline() or not gameRootPanel or not gameRootPanel:isVisible() then
    return false
  end
  local keyMods = g_window.getKeyboardModifiers()
  if keyMods ~= KeyboardShiftModifier or g_ui.isMouseGrabbed() then
    return false
  end
  if g_mouse.isPressed(MouseLeftButton) or g_mouse.isPressed(MouseRightButton) or g_mouse.isPressed(MouseMidButton) then
    return false
  end
  return true
end

local function getHoverLookTooltipType()
  return TooltipType.lookHover
end

local function getHoverLookTargetKey(thing)
  local thingId = thing:getId() or 0

  if thing:isCreature() then
    return f('creature:%d', thingId)
  end

  local pos = thing:getPosition()
  local posX = pos and pos.x or 0
  local posY = pos and pos.y or 0
  local posZ = pos and pos.z or 0

  local stackPos = thing.getStackPos and thing:getStackPos() or 0

  return f('item:%d:%d:%d:%d:%d', thingId, stackPos, posX, posY, posZ)
end

local function buildHoverLookTarget(thing, source, options)
  if not thing then
    return nil
  end

  if not thing:isItem() and not thing:isCreature() then
    return nil
  end

  options = options or {}

  return {
    thing = thing,
    source = source or hoverLookTargetSourceUnknown,
    key = getHoverLookTargetKey(thing),
    inspectNpcTrade = options.inspectNpcTrade == true
  }
end

local function hideHoverLookTooltip()
  local tooltip = Tooltip(TooltipType.lookHover)
  if tooltip then
    tooltip:hide()
  end

  if hoverLookTooltipWidget then
    hoverLookTooltipWidget:removeTooltip()
  end

  hoverLookCurrentTooltipKey = nil
  hoverLookCurrentTooltipText = nil
end

local function clearHoverLookTargetState()
  hoverLookTargetKey = nil
  hoverLookTargetSource = hoverLookTargetSourceUnknown
  hoverLookLastRequestAt = 0
  hideHoverLookTooltip()
end

local function resetHoverLookState()
  clearHoverLookTargetState()
end

local function getHoverLookCreatureFromWidget(widget)
  if not widget then
    return nil
  end

  if widget:getClassName() == 'UICreatureButton' then
    if widget.creature then
      return widget.creature
    end

    if widget.cid then
      return g_map.getCreatureById(widget.cid)
    end
  end

  if widget:getClassName() == 'UICreature' and widget.getCreature then
    local parent = widget:getParent()
    if parent and parent:getClassName() == 'UICreatureButton' then
      local creature = widget:getCreature()
      if creature then
        return creature
      end

      if parent:getClassName() == 'UICreatureButton' and parent.cid then
        return g_map.getCreatureById(parent.cid)
      end
    end
  end

  return nil
end

local function getHoverLookTarget(mousePos)
  if not mousePos or not rootWidget then
    return nil
  end

  local hoveredWidget = rootWidget:recursiveGetChildByPos(mousePos, false)
  local parentWidget = hoveredWidget
  local isGameRootBranch = false

  while parentWidget do
    if gameRootPanel and parentWidget == gameRootPanel then
      isGameRootBranch = true
    end

    local className = parentWidget:getClassName()
    local styleName = parentWidget:getStyleName()

    local creature = getHoverLookCreatureFromWidget(parentWidget)
    if creature then
      return buildHoverLookTarget(creature, hoverLookTargetSourceHud)
    end

    -- Do not fallback to gamescreen behind creature widgets when they do not resolve a creature
    if className == 'UICreatureButton' or styleName == 'CreatureButtonMinimapWidget' then
      return nil
    end

    if className == 'UIItem' then
      local allowVirtualHoverLook = not parentWidget:isVirtual() or parentWidget.hoverLookAllowVirtual
      if allowVirtualHoverLook then
        local item = parentWidget:getItem()
        if item then
          return buildHoverLookTarget(item, hoverLookTargetSourceHud, {
            inspectNpcTrade = parentWidget.hoverLookNpcTrade == true
          })
        end
        break
      end
    end

    parentWidget = parentWidget:getParent()
  end

  if not isGameRootBranch or not gameMapPanel or not gameMapPanel:containsPoint(mousePos) then
    return nil
  end

  local tile = gameMapPanel:getTile(mousePos)
  if not tile then
    return nil
  end

  local target = buildHoverLookTarget(tile:getTopLookThing(), hoverLookTargetSourceGameScreen)
  if target then
    return target
  end

  target = buildHoverLookTarget(tile:getTopCreature(), hoverLookTargetSourceGameScreen)
  if target then
    return target
  end

  return buildHoverLookTarget(tile:getTopUseThing(), hoverLookTargetSourceGameScreen)
end

local function startHoverLookCycle()
  if g_platform.isMobile() or hoverLookCycleEvent then
    return
  end

  hoverLookCycleEvent = cycleEvent(GameInterface.updateHoverLook, hoverLookTickInterval)
end

local function stopHoverLookCycle()
  if hoverLookCycleEvent then
    removeEvent(hoverLookCycleEvent)
    hoverLookCycleEvent = nil
  end

  resetHoverLookState()
end

function GameInterface.getHoverLookTooltipType()
  return getHoverLookTooltipType()
end

function GameInterface.isHoverLookTooltipOnlyMode()
  return isHoverLookEnabled()
end

function GameInterface.getHoverLookConsoleKey()
  if isHoverLookEnabled() then
    return hoverLookTargetKey
  end
  return nil
end

function GameInterface.updateHoverLook()
  local hoverLookEnabled = isHoverLookEnabled()
  if not hoverLookEnabled then
    hoverLookWasEnabled = false
    if hoverLookTargetKey or hoverLookCurrentTooltipKey then
      resetHoverLookState()
    end
    return
  end

  if not hoverLookWasEnabled then
    hoverLookWasEnabled = true
    Tooltip.hide()
  end

  local now = g_clock.millis()

  local target = getHoverLookTarget(g_window.getMousePosition())
  if not target then
    if hoverLookTargetKey or hoverLookCurrentTooltipKey then
      clearHoverLookTargetState()
    end
    return
  end

  local targetChanged = target.key ~= hoverLookTargetKey
  if targetChanged then
    local isHudTransition = hoverLookTargetSource == hoverLookTargetSourceHud or target.source == hoverLookTargetSourceHud
    if isHudTransition then
      hideHoverLookTooltip()
    end
    hoverLookTargetKey = target.key
    hoverLookTargetSource = target.source
    hoverLookLastRequestAt = 0
  elseif hoverLookCurrentTooltipKey == target.key and string.exists(hoverLookCurrentTooltipText) and hoverLookTooltipWidget then
    local tooltipObject = hoverLookTooltipWidget:getTooltipObject()
    if tooltipObject and tooltipObject.widget and (not tooltipObject.widget:isVisible() or tooltipObject.widget:getOpacity() < 0.1) then
      hoverLookTooltipWidget:setTooltip(hoverLookCurrentTooltipText, GameInterface.getHoverLookTooltipType())
      tooltipObject:show(hoverLookTooltipWidget)
    end
  end

  if now - hoverLookLastRequestAt < hoverLookRefreshInterval then
    return
  end

  if g_game.lookHover(target.thing, target.inspectNpcTrade == true) then
    hoverLookLastRequestAt = now
  end
end

function GameInterface.handleHoverLookMessage(text)
  if not string.exists(text) then
    return
  end

  if not isHoverLookEnabled() or not hoverLookTargetKey then
    return
  end

  local targetKey = hoverLookTargetKey

  if hoverLookTooltipWidget then
    local tooltipObject = hoverLookTooltipWidget:getTooltipObject()
    local tooltipHidden = tooltipObject and tooltipObject.widget and (not tooltipObject.widget:isVisible() or tooltipObject.widget:getOpacity() < 0.1)
    if tooltipObject and (hoverLookCurrentTooltipKey ~= targetKey or hoverLookCurrentTooltipText ~= text or tooltipHidden) then
      hoverLookTooltipWidget:setTooltip(text, GameInterface.getHoverLookTooltipType())
      tooltipObject:show(hoverLookTooltipWidget)
      hoverLookCurrentTooltipKey = targetKey
      hoverLookCurrentTooltipText = text
    end
  end
end



-- Side panel resize border

function GameInterface.clampSidePanelWidthSlots(value)
  return math.min(math.max(math.round(tonumber(value) or GameSidePanelWidthMinimumSlots), GameSidePanelWidthMinimumSlots), GameSidePanelWidthMaximumSlots)
end

function GameInterface.getSidePanelWidthFromSlots(value)
  return GameInterface.clampSidePanelWidthSlots(value) * GameSidePanelWidthFactor + GameSidePanelWidthOffset
end

function GameInterface.getSidePanelWidthSlotsFromPixels(width)
  local value = (width - GameSidePanelWidthOffset) / GameSidePanelWidthFactor
  return GameInterface.clampSidePanelWidthSlots(value)
end

local function setupSidePanelResizeBorder(panel, borderId, optionKey)
  local resizeBorder = panel:getChildById(borderId)
  if not resizeBorder then
    return
  end

  resizeBorder:setMinimum(GameInterface.getSidePanelWidthFromSlots(GameSidePanelWidthMinimumSlots))
  resizeBorder:setMaximum(GameInterface.getSidePanelWidthFromSlots(GameSidePanelWidthMaximumSlots))
  resizeBorder.vertical = false

  resizeBorder.onMouseMove = function(self, mousePos, mouseMoved)
    local moved = UIResizeBorder.onMouseMove(self, mousePos, mouseMoved)
    if not moved then
      return false
    end

    local slots = GameInterface.getSidePanelWidthSlotsFromPixels(panel:getWidth())
    local width = GameInterface.getSidePanelWidthFromSlots(slots)

    if panel:getWidth() ~= width then
      panel:setWidth(width)
    end

    if ClientOptions.getOption(optionKey) ~= slots then
      ClientOptions.setOption(optionKey, slots)
    end

    return true
  end
end



function GameInterface.init()
  -- Alias
  GameInterface.m = modules.game_interface

  g_ui.importStyle('styles/countwindow')

  rootWidget:setImageSource('/images/ui/_background/panel_root')

  gameRootPanel = g_ui.displayUI('interface')
  gameRootPanel:hide()
  gameRootPanel:lower()

  mouseGrabberWidget = gameRootPanel:getChildById('mouseGrabber')

  bottomSplitter = gameRootPanel:getChildById('bottomSplitter')
  gameExpBar = gameRootPanel:getChildById('gameExpBar')
  leftPanelButton = gameRootPanel:getChildById('leftPanelButton')
  rightPanelButton = gameRootPanel:getChildById('rightPanelButton')
  topMenuButton = gameRootPanel:getChildById('topMenuButton')
  chatButton = gameRootPanel:getChildById('chatButton')
  gameMapPanel = gameRootPanel:getChildById('gameMapPanel')
  gameScreenArea = gameRootPanel:getChildById('gameScreenArea')
  gameRightFirstPanel = gameRootPanel:getChildById('gameRightFirstPanel')
  gameRightSecondPanel = gameRootPanel:getChildById('gameRightSecondPanel')
  gameRightThirdPanel = gameRootPanel:getChildById('gameRightThirdPanel')
  gameLeftFirstPanel = gameRootPanel:getChildById('gameLeftFirstPanel')
  gameLeftSecondPanel = gameRootPanel:getChildById('gameLeftSecondPanel')
  gameLeftThirdPanel = gameRootPanel:getChildById('gameLeftThirdPanel')
  gameRightFirstPanelContainer = gameRightFirstPanel:getChildById('gameRightFirstPanelContainer')
  gameRightSecondPanelContainer = gameRightSecondPanel:getChildById('gameRightSecondPanelContainer')
  gameRightThirdPanelContainer = gameRightThirdPanel:getChildById('gameRightThirdPanelContainer')
  gameLeftFirstPanelContainer = gameLeftFirstPanel:getChildById('gameLeftFirstPanelContainer')
  gameLeftSecondPanelContainer = gameLeftSecondPanel:getChildById('gameLeftSecondPanelContainer')
  gameLeftThirdPanelContainer = gameLeftThirdPanel:getChildById('gameLeftThirdPanelContainer')
  leftPanelAddButton = gameRootPanel:getChildById('leftPanelAddButton')
  leftPanelRemoveButton = gameRootPanel:getChildById('leftPanelRemoveButton')
  rightPanelAddButton = gameRootPanel:getChildById('rightPanelAddButton')
  rightPanelRemoveButton = gameRootPanel:getChildById('rightPanelRemoveButton')
  gameBottomPanel = gameRootPanel:getChildById('gameBottomPanel')

  -- Look hover
  -- Helper for positioning
  g_ui.importStyle('styles/hoverlooktooltip')
  hoverLookTooltipWidget = g_ui.createWidget('HoverLookTooltip', gameRootPanel)

  ClientOptions.setupPanelAddRemoveButtons()

  setupSidePanelResizeBorder(gameLeftFirstPanel, 'leftFirstPanelResizeBorder', 'leftFirstPanelWidth')
  setupSidePanelResizeBorder(gameLeftSecondPanel, 'leftSecondPanelResizeBorder', 'leftSecondPanelWidth')
  setupSidePanelResizeBorder(gameLeftThirdPanel, 'leftThirdPanelResizeBorder', 'leftThirdPanelWidth')
  setupSidePanelResizeBorder(gameRightFirstPanel, 'rightFirstPanelResizeBorder', 'rightFirstPanelWidth')
  setupSidePanelResizeBorder(gameRightSecondPanel, 'rightSecondPanelResizeBorder', 'rightSecondPanelWidth')
  setupSidePanelResizeBorder(gameRightThirdPanel, 'rightThirdPanelResizeBorder', 'rightThirdPanelWidth')

  _gamePanels = {
    gameRightFirstPanel,
    gameLeftFirstPanel,
    gameRightSecondPanel,
    gameLeftSecondPanel,
    gameRightThirdPanel,
    gameLeftThirdPanel,
  }
  _gamePanelsContainer = {
    gameRightFirstPanelContainer,
    gameLeftFirstPanelContainer,
    gameRightSecondPanelContainer,
    gameLeftSecondPanelContainer,
    gameRightThirdPanelContainer,
    gameLeftThirdPanelContainer,
  }

  UIMiniWindow.initDropPreviewSingleton()
  GameInterface.setupPanels()

  -- Call load AFTER game window has been created and
  -- resized to a stable state, otherwise the saved
  -- settings can get overridden by false onGeometryChange
  -- events
  connect(g_app, {
    onRun  = GameInterface.load,
    onExit = GameInterface.save,
  })

  connect(g_game, {
    onGameStart               = GameInterface.onGameStart,
    onGameEnd                 = GameInterface.onGameEnd,
    onLoginAdvice             = GameInterface.onLoginAdvice,
    onAttackingCreatureChange = GameInterface.onAttackingCreatureChange,
    onFollowingCreatureChange = GameInterface.onFollowingCreatureChange,
    onTrackCreature           = GameInterface.onTrackCreature,
    onTrackCreatureEnd        = GameInterface.onTrackCreature,
    onTrackPosition           = GameInterface.onTrackPosition,
    onTrackPositionEnd        = GameInterface.onTrackPositionEnd,
    onUpdateTrackColor        = GameInterface.onUpdateTrackColor
  }, true)

  connect(gameRootPanel, {
    onGeometryChange = GameInterface.updateStretchShrink,
    onFocusChange    = GameInterface.stopSmartWalk,
    onMouseMove      = GameInterface.updateHoverLook,
  })

  connect(gameMapPanel, {
    onGeometryChange = GameInterface.updateTrackArrows,
    onViewModeChange = GameInterface.updateTrackArrows,
    onZoomChange     = GameInterface.updateTrackArrows,
  })

  connect(gameScreenArea, {
    onGeometryChange = GameInterface.updateTrackArrows,
  })

  connect(mouseGrabberWidget, {
    onMouseRelease = GameInterface.onMouseGrabberRelease,
  })

  for i = 1, #_gamePanelsContainer do
    connect(_gamePanelsContainer[i], {
      onFitAll = GameInterface.fitAllPanelChildren,
    })
  end

  connect(bottomSplitter, {
    onDoubleClick = GameInterface.onSplitterDoubleClick,
  })

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeWidgetLock, GameInterface.parseWidgetLock)

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeCreatureOutline, GameInterface.setCreatureOutline)

  ClientEnterGame.createEnterGameButton()

  GameInterface.bindKeys()

  if g_game.isOnline() then
    GameInterface.show()
  end
end

function GameInterface.bindWalkKey(key, dir)
  g_keyboard.bindKeyDown(key, function() GameInterface.onWalkKeyDown(dir) end, gameRootPanel, true)
  g_keyboard.bindKeyUp(key, function() GameInterface.changeWalkDir(dir, true) end, gameRootPanel, true)
  g_keyboard.bindKeyPress(key, function() GameInterface.smartWalk(dir) end, gameRootPanel)
end

function GameInterface.unbindWalkKey(key)
  g_keyboard.unbindKeyDown(key, gameRootPanel)
  g_keyboard.unbindKeyUp(key, gameRootPanel)
  g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function GameInterface.bindTurnKey(key, dir, checkConsole)
  local function callback(widget, code, repeatTicks)
    if checkConsole and GameConsole and GameConsole.isChatEnabled() then
      return
    end

    if g_clock.millis() - lastDirTime >= ClientOptions.getOption('turnDelay') then
      local mappedDir = mapWalkDirectionByCurrentView(dir)
      g_game.turn(mappedDir)
      GameInterface.changeWalkDir(dir)
      lastDirTime = g_clock.millis()
    end
  end
  g_keyboard.bindKeyPress(key, callback, gameRootPanel)
end

function GameInterface.bindActionKeyUp(key)
  g_keyboard.bindKeyUp(key, function() if g_game.isOnline() then g_game.sendActionKey(key, true) end end)
end

function GameInterface.bindActionKeyDown(key)
  g_keyboard.bindKeyDown(key, function() if g_game.isOnline() then g_game.sendActionKey(key, false) end end)
end

function GameInterface.bindKeys()
  gameRootPanel:setAutoRepeatDelay(50)

  GameInterface.bindWalkKey('Up', North)
  GameInterface.bindWalkKey('Right', East)
  GameInterface.bindWalkKey('Down', South)
  GameInterface.bindWalkKey('Left', West)
  GameInterface.bindWalkKey('Numpad8', North)
  GameInterface.bindWalkKey('Numpad9', NorthEast)
  GameInterface.bindWalkKey('Numpad6', East)
  GameInterface.bindWalkKey('Numpad3', SouthEast)
  GameInterface.bindWalkKey('Numpad2', South)
  GameInterface.bindWalkKey('Numpad1', SouthWest)
  GameInterface.bindWalkKey('Numpad4', West)
  GameInterface.bindWalkKey('Numpad7', NorthWest)

  GameInterface.bindTurnKey('Ctrl+Up', North)
  GameInterface.bindTurnKey('Ctrl+Left', West)
  GameInterface.bindTurnKey('Ctrl+Down', South)
  GameInterface.bindTurnKey('Ctrl+Right', East)
  GameInterface.bindTurnKey('Ctrl+Numpad8', North)
  GameInterface.bindTurnKey('Ctrl+Numpad4', West)
  GameInterface.bindTurnKey('Ctrl+Numpad2', South)
  GameInterface.bindTurnKey('Ctrl+Numpad6', East)

  g_keyboard.bindKeyDown('Escape', function()
    if not g_ui.resetDraggingWidget() then
      if selectedThing then
        GameInterface.onMouseGrabberRelease(mouseGrabberWidget)
      elseif not GamePowers.cancelPower() then
        g_game.cancelAttackAndFollow()
      end
    end
  end, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+=', function() gameMapPanel:zoomIn() ClientOptions.setOption('gameScreenSize', gameMapPanel:getZoom(), false) end, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+-', function() gameMapPanel:zoomOut() ClientOptions.setOption('gameScreenSize', gameMapPanel:getZoom(), false) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+L', function() GameInterface.tryLogout(false) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+.', GameInterface.nextViewMode, gameRootPanel)

  g_keyboard.bindKeyDown('Ctrl+Shift+Q', function() ClientOptions.setOption('showTopMenu', not ClientOptions.getOption('showTopMenu')) end)
  g_keyboard.bindKeyDown('Ctrl+Shift+W', function() ClientOptions.setOption('showChat', not ClientOptions.getOption('showChat')) end)
  g_keyboard.bindKeyDown('Ctrl+Shift+A', function() ClientOptions.setOption('showLeftPanel', not ClientOptions.getOption('showLeftPanel')) end)
  g_keyboard.bindKeyDown('Ctrl+Shift+S', function() ClientOptions.setOption('showRightPanel', not ClientOptions.getOption('showRightPanel')) end)
  GameInterface.bindActionKeyUp('Insert')
  GameInterface.bindActionKeyUp('Delete')
  GameInterface.bindActionKeyUp('Home')
  GameInterface.bindActionKeyUp('End')
  GameInterface.bindActionKeyUp('PageUp')
  GameInterface.bindActionKeyUp('PageDown')
  GameInterface.bindActionKeyDown('Insert')
  GameInterface.bindActionKeyDown('Delete')
  GameInterface.bindActionKeyDown('Home')
  GameInterface.bindActionKeyDown('End')
  GameInterface.bindActionKeyDown('PageUp')
  GameInterface.bindActionKeyDown('PageDown')
end

function GameInterface.terminate()
  GameInterface.hide()

  hookedMenuOptions = { }
  GameInterface.stopSmartWalk()

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeCreatureOutline)

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeWidgetLock)

  disconnect(bottomSplitter, {
    onDoubleClick = GameInterface.onSplitterDoubleClick,
  })

  for i = #_gamePanelsContainer, 1, -1 do
    disconnect(_gamePanelsContainer[i], {
      onFitAll = GameInterface.fitAllPanelChildren,
    })
  end

  disconnect(mouseGrabberWidget, {
    onMouseRelease = GameInterface.onMouseGrabberRelease,
  })

  disconnect(gameScreenArea, {
    onGeometryChange = GameInterface.updateTrackArrows,
  })

  disconnect(gameMapPanel, {
    onGeometryChange = GameInterface.updateTrackArrows,
    onViewModeChange = GameInterface.updateTrackArrows,
    onZoomChange     = GameInterface.updateTrackArrows,
  })

  disconnect(gameRootPanel, {
    onGeometryChange = GameInterface.updateStretchShrink,
    onFocusChange    = GameInterface.stopSmartWalk,
    onMouseMove      = GameInterface.updateHoverLook,
  })

  disconnect(g_game, {
    onGameStart               = GameInterface.onGameStart,
    onGameEnd                 = GameInterface.onGameEnd,
    onLoginAdvice             = GameInterface.onLoginAdvice,
    onAttackingCreatureChange = GameInterface.onAttackingCreatureChange,
    onFollowingCreatureChange = GameInterface.onFollowingCreatureChange,
    onTrackCreature           = GameInterface.onTrackCreature,
    onTrackCreatureEnd        = GameInterface.onTrackCreature,
    onTrackPosition           = GameInterface.onTrackPosition,
    onTrackPositionEnd        = GameInterface.onTrackPositionEnd,
    onUpdateTrackColor        = GameInterface.onUpdateTrackColor
  })

  disconnect(g_app, {
    onRun  = GameInterface.load,
    onExit = GameInterface.save,
  })

  _gamePanelsContainer = { }
  _gamePanels          = { }
  gamePanelsContainer  = { }
  gamePanels           = { }

  -- Look hover
  hoverLookTooltipWidget:destroy()
  hoverLookTooltipWidget = nil

  gameRootPanel:destroy()
  gameRootPanel = nil

  _G.GameInterface = nil
end

function GameInterface.onGameStart()
  local localPlayer = g_game.getLocalPlayer()

  connect(localPlayer, {
    onVocationChange = GameInterface.onVocationChange,
  })

  g_window.setTitle(g_app.getName() .. (localPlayer and ' - ' .. localPlayer:getName() or ''))
  GameInterface.show()

  g_game.enableFeature(GameForceFirstAutoWalkStep)

  -- April Fools'

  local aprilFoolsEnabled = true -- todo: get flag from player on server
  if aprilFoolsEnabled then
    local todayDate = os.date('*t')
    if todayDate.month == 4 and todayDate.day == 1 then

      local ignoredClasses = {
        ['UITextEdit'] = true,
      }

      local ignoredStyles = {
        ['TerminalLabel'] = true,
      }

      local ignoredParentClasses = {
        ['UIMoveableTabBar'] = true,
      }

      local ignoredParentStyles = {
        ['TextList'] = true,
      }

      -- local ignoredIds = {
      -- }

      function UIWidget:getAutoText(text, oldText)
        if ignoredClasses[self:getClassName()] or ignoredStyles[self:getStyleName()] --[[or ignoredIds[self:getId()] ]] then
          return nil -- Do nothing
        end

        local parent = self:getParent()
        if parent and (ignoredParentClasses[parent:getClassName()] or ignoredParentStyles[parent:getStyleName()]) then
          return nil -- Do nothing
        end

        return string.exists(text) and text:mix(true) or text
      end

    else
      UIWidget.getAutoText = nil
    end
  end
end

function GameInterface.onGameEnd()
  -- Release dragging
  g_ui.resetDraggingWidget()

  local localPlayer = g_game.getLocalPlayer()

  disconnect(localPlayer, {
    onVocationChange = GameInterface.onVocationChange,
  })

  g_window.setTitle(g_app.getName())
  GameInterface.hide()
end

function GameInterface.show()
  local localPlayer = g_game.getLocalPlayer()

  connect(g_app, {
    onClose = GameInterface.tryExit
  })

  ClientBackground.hide()
  gameRootPanel:show()
  gameRootPanel:focus()
  gameMapPanel:followCreature(g_game.getLocalPlayer())
  GameInterface.updateStretchShrink()

  GameInterface.updateManaBar()

  -- Update panels
  GameInterface.setLeftPanels()
  GameInterface.setRightPanels()

  -- Look hover
  startHoverLookCycle()
  GameInterface.updateHoverLook()
end

function GameInterface.hide()
  -- Look hover
  stopHoverLookCycle()

  disconnect(g_app, {
    onClose = GameInterface.tryExit
  })

  if logoutWindow then
    logoutWindow:destroy()
    logoutWindow = nil
  end
  if exitWindow then
    exitWindow:destroy()
    exitWindow = nil
  end
  if countWindow then
    countWindow:destroy()
    countWindow = nil
  end
  gameRootPanel:hide()
  ClientBackground.show()
end

function GameInterface.save()
  local settings = { }
  settings.splitterMarginBottom = bottomSplitter.currentMargin
  g_settings.setNode('game_interface', settings)
end

function GameInterface.load()
  local settings = g_settings.getNode('game_interface')

  bottomSplitter.currentMargin = settings and settings.splitterMarginBottom or bottomSplitter.defaultMargin
  bottomSplitter:updateMargin()
end

function GameInterface.onLoginAdvice(message)
  displayInfoBox(loc'${GameInterfaceFYI}', message)
end

function GameInterface.forceExit()
  g_game.cancelLogin()
  scheduleEvent(exit, 10)
  return true
end

function GameInterface.tryExit()
  if exitWindow then
    return true
  end

  local exitFunc = function() g_game.safeLogout() GameInterface.forceExit() end
  local logoutFunc = function() g_game.safeLogout() exitWindow:destroy() exitWindow = nil end
  local cancelFunc = function() exitWindow:destroy() exitWindow = nil end

  exitWindow = displayGeneralBox(loc'${CorelibInfoExit}', loc'${GameInterfaceExitWindowMsg}', {
    { text = loc'${GameInterfaceExitWindowButtonForceExit}', callback = exitFunc },
    { text = loc'${CorelibInfoLogout}', callback = logoutFunc },
    { text = loc'${CorelibInfoCancel}', callback = cancelFunc },
    anchor = AnchorHorizontalCenter
  }, logoutFunc, cancelFunc, 100)

  return true
end

function GameInterface.tryLogout(prompt)
  if type(prompt) ~= 'boolean' then
    prompt = true
  end
  if not g_game.isOnline() then
    exit()
    return
  end

  if logoutWindow then
    return
  end

  local msg, yesCallback
  if not g_game.isConnectionOk() then
    msg = loc'${GameInterfaceLogoutWindowFailingConnectionMsg}'

    yesCallback = function()
      g_game.forceLogout()
      if logoutWindow then
        logoutWindow:destroy()
        logoutWindow=nil
      end
    end
  else
    msg = loc'${GameInterfaceLogoutWindowRequestMsg}'

    yesCallback = function()
      g_game.safeLogout()
      if logoutWindow then
        logoutWindow:destroy()
        logoutWindow=nil
      end
    end
  end

  local noCallback = function()
    logoutWindow:destroy()
    logoutWindow=nil
  end

  if prompt then
    logoutWindow = displayGeneralBox(loc'${CorelibInfoLogout}', msg, {
      { text = loc'${CorelibInfoYes}', callback = yesCallback },
      { text = loc'${CorelibInfoNo}', callback = noCallback },
      anchor = AnchorHorizontalCenter
    }, yesCallback, noCallback)
  else
     yesCallback()
  end
end

function GameInterface.stopSmartWalk()
  smartWalkDirs = { }
  smartWalkDir = nil
end

function GameInterface.onWalkKeyDown(dir)
  if ClientOptions.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(DontChase)
    end
  end
  firstStep = true
  GameInterface.changeWalkDir(dir)
end

function GameInterface.changeWalkDir(dir, pop)
  dir = mapWalkDirectionByCurrentView(dir)

  while table.removevalue(smartWalkDirs, dir) do end
  if pop then
    if #smartWalkDirs == 0 then
      GameInterface.stopSmartWalk()
      return
    end
  else
    table.insert(smartWalkDirs, 1, dir)
  end

  smartWalkDir = smartWalkDirs[1]
  if ClientOptions.getOption('smartWalk') and #smartWalkDirs > 1 then
    for _,d in pairs(smartWalkDirs) do
      if (smartWalkDir == North and d == West) or (smartWalkDir == West and d == North) then
        smartWalkDir = NorthWest
        break
      elseif (smartWalkDir == North and d == East) or (smartWalkDir == East and d == North) then
        smartWalkDir = NorthEast
        break
      elseif (smartWalkDir == South and d == West) or (smartWalkDir == West and d == South) then
        smartWalkDir = SouthWest
        break
      elseif (smartWalkDir == South and d == East) or (smartWalkDir == East and d == South) then
        smartWalkDir = SouthEast
        break
      end
    end
  end
end

function GameInterface.smartWalk(dir)
  if g_keyboard.getModifiers() ~= KeyboardNoModifier then
    return false
  end

  local _dir = smartWalkDir or mapWalkDirectionByCurrentView(dir)
  g_game.walk(_dir, firstStep)
  firstStep = false
  return true
end

function GameInterface.updateStretchShrink()
  if alternativeView or currentViewMode ~= 0 then
    ClientOptions.setOption('dontStretchShrink', false)
    return
  elseif not ClientOptions.getOption('dontStretchShrink') then
    return
  end

  ClientOptions.setOption('gameScreenSize', 19) -- Height of 19 SQMs

  local gameMapMargin = gameMapPanel:getHeight() - gameMapPanel:getMapHeight()
  bottomSplitter:setMarginBottom(bottomSplitter:getMarginBottom() + gameMapPanel:getHeight() - (32 * 19 + gameMapMargin))
end

function GameInterface.onSplitterDoubleClick(mousePosition)
  bottomSplitter:setMarginBottom(bottomSplitter.defaultMargin)
end

local function tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
  local oldChildrenHeight = childrenHeight

  local childList = { }

  for i = #_childList, 1, -1 do
    local child = _childList[i]

    local childOldHeight      = child:getHeight()
    local otherChildrenHeight = childrenHeight - childOldHeight

    if changeValidateCondition(child, childOldHeight, otherChildrenHeight) then
      childrenHeight = changeConditionValidated(child, childOldHeight, otherChildrenHeight, childList)
    end

    -- If fits enough, then resize all of childList (if not, do not resize any)
    if childrenHeight <= selfHeight then
      for _, childValue in ipairs(childList) do
        changeCondition(childValue)
      end
      return childrenHeight
    end
  end

  return oldChildrenHeight
end
local function tryResizeChildList(selfHeight, childrenHeight, _childList, noRemoveChild, resizeCondition)
  local changeValidateCondition = function(child, childOldHeight, otherChildrenHeight)
    local availableHeight = selfHeight - otherChildrenHeight -- Possible child new height
    return child:isVisible() and child:isResizeable() and child:getMinimumHeight() <= availableHeight and child:getMaximumHeight() >= availableHeight and availableHeight ~= childOldHeight and (not resizeCondition or resizeCondition(child, noRemoveChild))
  end

  local changeConditionValidated = function(child, childOldHeight, otherChildrenHeight, childList)
    local availableHeight = selfHeight - otherChildrenHeight -- Child new height
    table.insert(childList, { widget = child, height = availableHeight })
    return otherChildrenHeight + availableHeight
  end

  local changeCondition = function(childValue)
    -- addEvent(function() childValue.widget:setHeight(childValue.height) end)
    childValue.widget:setHeight(childValue.height, false, true)
  end

  return tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
end
local function tryMinimizeChildList(selfHeight, childrenHeight, _childList, noRemoveChild, minimizeCondition)
  local changeValidateCondition = function(child, childOldHeight, otherChildrenHeight)
    local minimizeButton = child:getChildById('minimizeButton')
    return child:isVisible() and not minimizeButton:isOn() and (not minimizeCondition or minimizeCondition(child, noRemoveChild))
  end

  local changeConditionValidated = function(child, childOldHeight, otherChildrenHeight, childList)
    table.insert(childList, child)
    return otherChildrenHeight + child.minimizedHeight
  end

  local changeCondition = function(childValue)
    childValue:minimize(false, true)
  end

  return tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
end
local function tryCloseChildList(selfHeight, childrenHeight, _childList, noRemoveChild, closeCondition)
  local changeValidateCondition = function(child, childOldHeight, otherChildrenHeight)
    return child:isVisible() and (not closeCondition or closeCondition(child, noRemoveChild))
  end

  local changeConditionValidated = function(child, childOldHeight, otherChildrenHeight, childList)
    table.insert(childList, child)
    return otherChildrenHeight
  end

  local changeCondition = function(childValue)
    childValue:close(false)
  end

  return tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
end
local function isNoRemoveChild(child, noRemoveChild)
  return child == noRemoveChild
end
local function isUnsavableChildren(child, noRemoveChild)
  return child ~= noRemoveChild and not child.save
end
local function isSavableChildren(child, noRemoveChild)
  return child ~= noRemoveChild and child.save
end
-- TODO: connect to window onResize event?
function GameInterface.fitAllPanelChildren(miniWindowContainer, noRemoveChild)
  local children = miniWindowContainer:getChildren()

  local hadNoRemoveChild = noRemoveChild ~= nil

  if not noRemoveChild then
    if #children == 0 then
      return
    end

    noRemoveChild = children[#children]
  end

  local selfHeight     = miniWindowContainer:getSpaceHeight()
  local childrenHeight = miniWindowContainer:getChildrenSpaceHeight()



  -- Try to resize noRemoveChild
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryResizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isNoRemoveChild)

  -- Try to resize unsavable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryResizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isUnsavableChildren)

  -- Try to resize savable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryResizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isSavableChildren)



  -- Try move noRemoveChild (useful for savable widgets that are always loaded on same panel)
  if childrenHeight <= selfHeight then
    return
  end
  if hadNoRemoveChild then
    local panel, panelKey = GameInterface.getAvailablePanel(noRemoveChild, miniWindowContainer)
    if panel then
      noRemoveChild:setParent(gamePanelsContainer[panelKey])
      return
    end
  end



  -- Try to minimize unsavable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryMinimizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isUnsavableChildren)

  -- Try to remove unsavable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryCloseChildList(selfHeight, childrenHeight, children, noRemoveChild, isUnsavableChildren)



  -- Try to minimize savable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryMinimizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isSavableChildren)

  -- Try to remove savable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryCloseChildList(selfHeight, childrenHeight, children, noRemoveChild, isSavableChildren)
end

function GameInterface.setupPanels()
  local panelsPriority = ClientOptions.getOption('panelsPriority')

  -- Right
  if panelsPriority == 1 then
    -- Priority order
    gamePanels[1]          = gameRightFirstPanel
    gamePanels[2]          = gameRightSecondPanel
    gamePanels[3]          = gameRightThirdPanel
    gamePanels[4]          = gameLeftFirstPanel
    gamePanels[5]          = gameLeftSecondPanel
    gamePanels[6]          = gameLeftThirdPanel
    gamePanelsContainer[1] = gameRightFirstPanelContainer
    gamePanelsContainer[2] = gameRightSecondPanelContainer
    gamePanelsContainer[3] = gameRightThirdPanelContainer
    gamePanelsContainer[4] = gameLeftFirstPanelContainer
    gamePanelsContainer[5] = gameLeftSecondPanelContainer
    gamePanelsContainer[6] = gameLeftThirdPanelContainer

  -- Left
  elseif panelsPriority == -1 then
    -- Priority order
    gamePanels[1]          = gameLeftFirstPanel
    gamePanels[2]          = gameLeftSecondPanel
    gamePanels[3]          = gameLeftThirdPanel
    gamePanels[4]          = gameRightFirstPanel
    gamePanels[5]          = gameRightSecondPanel
    gamePanels[6]          = gameRightThirdPanel
    gamePanelsContainer[1] = gameLeftFirstPanelContainer
    gamePanelsContainer[2] = gameLeftSecondPanelContainer
    gamePanelsContainer[3] = gameLeftThirdPanelContainer
    gamePanelsContainer[4] = gameRightFirstPanelContainer
    gamePanelsContainer[5] = gameRightSecondPanelContainer
    gamePanelsContainer[6] = gameRightThirdPanelContainer

  -- None
  else
    gamePanels          = { }
    gamePanelsContainer = { }
  end
end

function GameInterface.getNextPanel(condition)
  condition = condition or function(_gamePanel, k) return _gamePanel:isVisible() end

  for gamePanelKey, gamePanel in ipairs(gamePanels) do
    if condition(gamePanel, gamePanelKey) then
      return gamePanel, gamePanelKey
    end
  end
  return nil, -1
end

function GameInterface.getAvailablePanel(miniWindow, miniWindowContainer) -- (miniWindow = nil, miniWindowContainer = nil)
  local nextAvailablePanel, nextAvailablePanelKey = GameInterface.getNextPanel(function(_gamePanel, k) return (not miniWindowContainer or gamePanelsContainer[k] ~= miniWindowContainer) and _gamePanel:isVisible() and (not miniWindow or gamePanelsContainer[k]:getEmptySpaceHeight() - miniWindow:getHeight() >= 0) end)
  return nextAvailablePanel, nextAvailablePanelKey
end

function GameInterface.addToPanels(miniWindow, force)
  if #gamePanels == 0 then
    return false
  end

  -- Mini window within panel container already
  local parent = miniWindow:getParent()
  if not force and parent and parent:getClassName() == 'UIMiniWindowContainer' then
    return false
  end

  local panel, panelKey = GameInterface.getAvailablePanel(miniWindow)

  -- No available panel
  if not panel then
    return false
  end

  -- Attach it to available panel
  miniWindow:setParent(gamePanelsContainer[panelKey])

  return true
end

function GameInterface.onContainerMiniWindowOpen(containerWindow, previousContainer)
  if not previousContainer then -- Opened in new window
    GameInterface.addToPanels(containerWindow) -- Attempt to add to panels
  end
end

function GameInterface.toggleMiniWindow(miniWindow) -- To use on each top menu mini window
  if miniWindow:isVisible() then
    miniWindow:close()
  else
    if not miniWindow:getSettings(true) or not miniWindow:getParent() then -- Opened for the first time or has not parent
      if not GameInterface.addToPanels(miniWindow) then
        return
      end
    end

    miniWindow:open()
  end
end

function GameInterface.isRightPanel(panel)
  return panel.sidePanelId % 2 == 1
end

function GameInterface.isLeftPanel(panel)
  return panel.sidePanelId % 2 == 0
end

function GameInterface.isDefaultPanel(panel)
  return gamePanels[1] and panel == gamePanels[1]
end

function GameInterface.isRightPanelContainer(panelContainer)
  return isRightPanel(panelContainer:getParent())
end

function GameInterface.isLeftPanelContainer(panelContainer)
  return GameInterface.isLeftPanel(panelContainer:getParent())
end

function GameInterface.getDefaultPanel()
  return gamePanels[1]
end

function GameInterface.getDefaultPanelContainer()
  return gamePanelsContainer[1]
end

function GameInterface.setRightPanels(on)
  if on == nil then
    on = ClientOptions.getOption('showRightPanel')
  end

  if on and GameInterface.isPanelEnabled(gameRightFirstPanel) then
    gameRightFirstPanel:setVisible(true)
    gameRightFirstPanel:setWidth(GameInterface.getSidePanelWidthFromSlots(ClientOptions.getOption('rightFirstPanelWidth')))
  else
    gameRightFirstPanel:setVisible(false)
  end

  if on and GameInterface.isPanelEnabled(gameRightSecondPanel) then
    gameRightSecondPanel:setVisible(true)
    gameRightSecondPanel:setWidth(GameInterface.getSidePanelWidthFromSlots(ClientOptions.getOption('rightSecondPanelWidth')))
  else
    gameRightSecondPanel:setVisible(false)
  end

  if on and GameInterface.isPanelEnabled(gameRightThirdPanel) then
    gameRightThirdPanel:setVisible(true)
    gameRightThirdPanel:setWidth(GameInterface.getSidePanelWidthFromSlots(ClientOptions.getOption('rightThirdPanelWidth')))
  else
    gameRightThirdPanel:setVisible(false)
  end

  rightPanelButton:setOn(on)
end

function GameInterface.setLeftPanels(on)
  if on == nil then
    on = ClientOptions.getOption('showLeftPanel')
  end

  if on and GameInterface.isPanelEnabled(gameLeftFirstPanel) then
    gameLeftFirstPanel:setVisible(true)
    gameLeftFirstPanel:setWidth(GameInterface.getSidePanelWidthFromSlots(ClientOptions.getOption('leftFirstPanelWidth')))
  else
    gameLeftFirstPanel:setVisible(false)
  end

  if on and GameInterface.isPanelEnabled(gameLeftSecondPanel) then
    gameLeftSecondPanel:setVisible(true)
    gameLeftSecondPanel:setWidth(GameInterface.getSidePanelWidthFromSlots(ClientOptions.getOption('leftSecondPanelWidth')))
  else
    gameLeftSecondPanel:setVisible(false)
  end

  if on and GameInterface.isPanelEnabled(gameLeftThirdPanel) then
    gameLeftThirdPanel:setVisible(true)
    gameLeftThirdPanel:setWidth(GameInterface.getSidePanelWidthFromSlots(ClientOptions.getOption('leftThirdPanelWidth')))
  else
    gameLeftThirdPanel:setVisible(false)
  end

  leftPanelButton:setOn(on)
end

function GameInterface.movePanelMiniWindows(panelContainer)
  local children = panelContainer:getChildren()
  for _, child in ipairs(children) do
    GameInterface.addToPanels(child, true)
  end
end

function GameInterface.moveHiddenPanelMiniWindows()
  for i = 1, #gamePanelsContainer do
    if not gamePanels[i]:isVisible() then
      GameInterface.movePanelMiniWindows(gamePanelsContainer[i])
    end
  end
end

function GameInterface.isPanelEnabled(panel)
  if GameInterface.isLeftPanel(panel) then
    return panel.sidePanelId / 2 <= (ClientOptions.getOption('enabledLeftPanels') or 0)
  end
  return math.floor(panel.sidePanelId / 2) + 1 <= (ClientOptions.getOption('enabledRightPanels') or 0)
end

function GameInterface.onMouseGrabberRelease(self, mousePosition, mouseButton)
  if selectedThing == nil then
    return false
  end

  if mouseButton == MouseLeftButton then
    local clickedWidget = gameRootPanel:recursiveGetChildByPos(mousePosition, false)
    if clickedWidget then
      if selectedType == 'use' then
        GameInterface.onUseWith(clickedWidget, mousePosition)
      elseif selectedType == 'trade' then
        GameInterface.onTradeWith(clickedWidget, mousePosition)
      end
    end
  end

  selectedThing = nil
  g_mouse.popCursor('target')
  self:ungrabMouse()
  return true
end

function GameInterface.onUseWith(clickedWidget, mousePosition)
  if clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      if selectedThing:isFluidContainer() or selectedThing:isMultiUse() then
        g_game.useWith(selectedThing, tile:getTopMultiUseThing())
      else
        g_game.useWith(selectedThing, tile:getTopUseThing())
      end
    end
  elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
    g_game.useWith(selectedThing, clickedWidget:getItem())
  elseif clickedWidget:getClassName() == 'UICreatureButton' then
    local creature = clickedWidget.creature
    if creature and not creature:isPlayer() then
      -- Make possible to use with on UICreatureButton (battle window)
      g_game.useWith(selectedThing, creature)
    end
  end
end

function GameInterface.onTradeWith(clickedWidget, mousePosition)
  if clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      g_game.requestTrade(selectedThing, tile:getTopCreature())
    end
  elseif clickedWidget:getClassName() == 'UICreatureButton' then
    local creature = clickedWidget.creature
    if creature then
      g_game.requestTrade(selectedThing, creature)
    end
  end
end

function GameInterface.startUseWith(thing)
  if not thing then
    return
  end

  if g_ui.isMouseGrabbed() then
    if selectedThing then
      selectedThing = thing
      selectedType = 'use'
    end
    return
  end
  selectedType = 'use'
  selectedThing = thing
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
end

function GameInterface.startTradeWith(thing)
  if not thing then
    return
  end

  if g_ui.isMouseGrabbed() then
    if selectedThing then
      selectedThing = thing
      selectedType = 'trade'
    end
    return
  end
  selectedType = 'trade'
  selectedThing = thing
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
end

function GameInterface.isMenuHookCategoryEmpty(category)
  if category then
    for _,opt in pairs(category) do
      if opt then
        return false
      end
    end
  end
  return true
end

function GameInterface.addMenuHook(category, name, callback, condition, shortcut)
  if not hookedMenuOptions[category] then
    hookedMenuOptions[category] = { }
  end
  hookedMenuOptions[category][name] = {
    callback = callback,
    condition = condition,
    shortcut = shortcut
  }
end

function GameInterface.removeMenuHook(category, name)
  if not name then
    hookedMenuOptions[category] = { }
  else
    hookedMenuOptions[category][name] = nil
  end
end

function GameInterface.createThingMenu(menuPosition, lookThing, useThing, creatureThing, wrapThing)
  if not g_game.isOnline() then
    return
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  local classic = ClientOptions.getOption('classicControl')
  local shortcut = nil

  if not classic then
    shortcut = '(Ctrl)'
  else
    shortcut = nil
  end

  if wrapThing then
    local onWrapItem = function() g_game.wrap(wrapThing) end

    if wrapThing:isUnwrappable() then
      menu:addOption(loc'${GameInterfaceContextMenuUnwrap}', onWrapItem)
    end

    if wrapThing:isWrappable() then
      menu:addOption(loc'${GameInterfaceContextMenuWrap}', onWrapItem)
    end
  end

  if useThing then
    if useThing:isContainer() then
      if useThing:getParentContainer() then
        menu:addOption(loc'${CorelibInfoOpen}', function() g_game.open(useThing, useThing:getParentContainer()) end, shortcut)
        menu:addOption(loc'${GameInterfaceContextMenuOpenInNewWindow}', function() g_game.open(useThing) end)
      else
        menu:addOption(loc'${CorelibInfoOpen}', function() g_game.open(useThing) end, shortcut)
      end
    else
      if useThing:isMultiUse() then
        menu:addOption(loc'${GameInterfaceContextMenuUseWith}', function() GameInterface.startUseWith(useThing) end, shortcut)
      else
        menu:addOption(loc'${GameInterfaceContextMenuUse}', function() g_game.use(useThing) end, shortcut)
      end
    end

    if useThing:isRotateable() then
      menu:addOption(loc'${GameInterfaceContextMenuRotate}', function() g_game.rotate(useThing) end)
    end

  end

  if lookThing and not lookThing:isCreature() and not lookThing:isNotMoveable() and lookThing:isPickupable() then
    menu:addSeparator()
    menu:addOption(loc'${GameInterfaceContextMenuTradeWith}', function() GameInterface.startTradeWith(lookThing) end)
  end

  if lookThing then
    local parentContainer = lookThing:getParentContainer()
    if parentContainer and parentContainer:hasParent() then
      menu:addOption(loc'${GameInterfaceContextMenuMoveUp}', function() g_game.moveToParentContainer(lookThing, lookThing:getCount()) end)
    end
  end

  if creatureThing then
    local localPlayer = g_game.getLocalPlayer()
    local creatureName = creatureThing:getName()
    menu:addSeparator()

    if creatureThing:isLocalPlayer() then
      menu:addOption(loc'${GameInterfaceContextMenuSetOutfit}', function() g_game.requestOutfit() end)

      if g_game.getFeature(GamePlayerMounts) then
        if not localPlayer:isMounted() then
          menu:addOption(loc'${GameInterfaceContextMenuMount}', function() localPlayer:mount() end)
        else
          menu:addOption(loc'${GameInterfaceContextMenuDismount}', function() localPlayer:dismount() end)
        end
      end

      if creatureThing:isPartyMember() then
        if creatureThing:isPartyLeader() then
          if creatureThing:isPartySharedExperienceActive() then
            menu:addOption(loc'${GameInterfaceContextMenuSharedXPDisable}', function() g_game.partyShareExperience(false) end)
          else
            menu:addOption(loc'${GameInterfaceContextMenuSharedXPEnable}', function() g_game.partyShareExperience(true) end)
          end
        end
        menu:addOption(loc'${GameInterfaceContextMenuLeaveParty}', function() g_game.partyLeave() end)
      end

      if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
        menu:addSeparator()

        menu:addOption(loc'${GameInterfaceContextMenuRuleViolations}', function() if modules.game_ruleviolation then GameRuleViolation.showViewWindow() end end)
      end

    else
      local localPosition = localPlayer:getPosition()
      if creatureThing:getPosition().z == localPosition.z then
        if not classic then
          shortcut = '(Alt)'
        else
          shortcut = nil
        end

        if g_game.getAttackingCreature() ~= creatureThing then
          menu:addOption(loc'${GameInterfaceContextMenuAttack}', function() g_game.attack(creatureThing) end, shortcut)
        else
          menu:addOption(loc'${GameInterfaceContextMenuAttackStop}', function() g_game.cancelAttack() end, shortcut)
        end

        if not classic then
          shortcut = '(Ctrl+Shift)'
        else
          shortcut = nil
        end

        if g_game.getFollowingCreature() ~= creatureThing then
          menu:addOption(loc'${GameInterfaceContextMenuFollow}', function() g_game.follow(creatureThing) end, shortcut)
        else
          menu:addOption(loc'${GameInterfaceContextMenuFollowStop}', function() g_game.cancelFollow() end, shortcut)
        end

        if GameTracker then
          if not classic then
            shortcut = '(Alt+Shift)'
          else
            shortcut = nil
          end

          if not GameTracker.isTracked(creatureThing) then
            menu:addOption(loc'${GameInterfaceContextMenuTrack}', function() GameTracker.startTrackCreature(creatureThing) end, shortcut)
          else
            menu:addOption(loc'${GameInterfaceContextMenuTrackStop}', function() GameTracker.stopTrackCreature(creatureThing) end, shortcut)
            menu:addOption(loc'${GameInterfaceContextMenuTrackEdit}', function() GameTracker.createEditTrackWindow(creatureThing:getTrackInfo()) end)
          end
        end

        local creatureDistance = getDistanceBetween(creatureThing:getPosition(), localPosition)
        if GameConsole and creatureThing:isNpc() and creatureDistance <= Npc.DefaultDistance then
          menu:addOption(loc'${GameInterfaceContextMenuTalk}', function() if GameConsole then GameConsole.greetNpc(creatureThing) end end)
        end
      end

      if creatureThing:isPlayer() then
        menu:addSeparator()

        menu:addOption(f(loc'${GameInterfaceContextMenuMsgTo}', creatureName), function() g_game.openPrivateChannel(creatureName) end)

        if GameConsole and GameConsole.getOwnPrivateTab() then
          menu:addOption(loc'${GameInterfaceContextMenuPrivateChatInvite}', function() g_game.inviteToOwnChannel(creatureName) end)
          menu:addOption(loc'${GameInterfaceContextMenuPrivateChatExclude}', function() g_game.excludeFromOwnChannel(creatureName) end) -- [TODO] must be removed after message's popup labels been implemented
        end
        if not localPlayer:hasVip(creatureName) then
          menu:addOption(loc'${GameInterfaceContextMenuVipListAdd}', function() g_game.addVip(creatureName) end)
        end

        if GameConsole and GameConsole.isIgnored(creatureName) then
          menu:addOption(f(loc'${GameInterfaceContextMenuPlayerUnignore}', creatureName), function() if GameConsole then GameConsole.removeIgnoredPlayer(creatureName) end end)
        else
          menu:addOption(f(loc'${GameInterfaceContextMenuPlayerIgnore}', creatureName), function() if GameConsole then GameConsole.addIgnoredPlayer(creatureName) end end)
        end

        local localPlayerShield = localPlayer:getShield()
        local creatureShield = creatureThing:getShield()

        if localPlayerShield == ShieldNone or localPlayerShield == ShieldWhiteBlue then
          if creatureShield == ShieldWhiteYellow then
            menu:addOption(f(loc'${GameInterfaceContextMenuPartyJoin}', creatureThing:getName()), function() g_game.partyJoin(creatureThing:getId()) end)
          else
            menu:addOption(loc'${GameInterfaceContextMenuPartyInvite}', function() g_game.partyInvite(creatureThing:getId()) end)
          end
        elseif localPlayerShield == ShieldWhiteYellow then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(f(loc'${GameInterfaceContextMenuPartyRevokeInvitation}', creatureThing:getName()), function() g_game.partyRevokeInvitation(creatureThing:getId()) end)
          end
        elseif localPlayerShield == ShieldYellow or localPlayerShield == ShieldYellowSharedExp or localPlayerShield == ShieldYellowNoSharedExpBlink or localPlayerShield == ShieldYellowNoSharedExp then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(f(loc'${GameInterfaceContextMenuPartyRevokeInvitation}', creatureThing:getName()), function() g_game.partyRevokeInvitation(creatureThing:getId()) end)
          elseif creatureShield == ShieldBlue or creatureShield == ShieldBlueSharedExp or creatureShield == ShieldBlueNoSharedExpBlink or creatureShield == ShieldBlueNoSharedExp then
            menu:addOption(f(loc'${GameInterfaceContextMenuPartyPassLeadership}', creatureThing:getName()), function() g_game.partyPassLeadership(creatureThing:getId()) end)
          else
            menu:addOption(loc'${GameInterfaceContextMenuPartyInvite}', function() g_game.partyInvite(creatureThing:getId()) end)
          end
        end

        if localPlayer ~= creatureThing then
          menu:addSeparator()

          if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
            menu:addOption(loc'${GameInterfaceContextMenuAddRuleViolation}', function() if modules.game_ruleviolation then GameRuleViolation.showViewWindow(creatureName) end end)
          end

          local REPORT_TYPE_NAME      = 0
          local REPORT_TYPE_VIOLATION = 2
          menu:addOption(loc'${GameInterfaceContextMenuReportName}', function() if modules.game_ruleviolation then GameRuleViolation.showRuleViolationReportWindow(REPORT_TYPE_NAME, creatureName) end end)
          menu:addOption(loc'${GameInterfaceContextMenuReportViolation}', function() if modules.game_ruleviolation then GameRuleViolation.showRuleViolationReportWindow(REPORT_TYPE_VIOLATION, creatureName) end end)
        end
      end
    end

    menu:addSeparator()

    menu:addOption(loc'${GameInterfaceContextMenuCopyName}', function() g_window.setClipboardText(creatureName) end)
  end

  -- hooked menu options
  for _, category in pairs(hookedMenuOptions) do
    if not GameInterface.isMenuHookCategoryEmpty(category) then
      menu:addSeparator()
      for name, opt in pairs(category) do
        if opt and opt.condition(menuPosition, lookThing, useThing, creatureThing) then
          menu:addOption(name, function() opt.callback(menuPosition,
            lookThing, useThing, creatureThing) end, opt.shortcut)
        end
      end
    end
  end

  menu:display(menuPosition)
end

function GameInterface.processMouseAction(menuPosition, mouseButton, autoWalkPos, lookThing, useThing, wrapThing, creatureThing)
  local player = g_game.getLocalPlayer()
  if not player then
    return false
  end

  local pos = player:getPosition()
  if not pos then
    return false
  end

  local keyCtrl      = g_keyboard.isCtrlPressed()
  local keyShift     = g_keyboard.isShiftPressed()
  local keyAlt       = g_keyboard.isAltPressed()
  local keyMods      = g_keyboard.getModifiers()
  local keyNoMods    = keyMods == KeyboardNoModifier
  -- local keyCtrlOnly  = keyMods == KeyboardCtrlModifier
  -- local keyShiftOnly = keyMods == KeyboardShiftModifier
  local keyAltOnly   = keyMods == KeyboardAltModifier

  local mouseLeft         = mouseButton == MouseLeftButton
  local mouseRight        = mouseButton == MouseRightButton
  -- local mouseMid          = mouseButton == MouseMidButton
  local mouseLeftOnly     = mouseLeft and not g_mouse.isPressed(MouseRightButton)
  local mouseRightOnly    = mouseRight and not g_mouse.isPressed(MouseLeftButton)
  local mouseLeftOrRight  = mouseLeft or mouseRight
  local mouseLeftAndRight = g_mouse.isPressed(MouseLeftButton) and mouseRight or g_mouse.isPressed(MouseRightButton) and mouseLeft

  -- Near, but not on same player position
  local creatureDistance = creatureThing and getDistanceBetween(creatureThing:getPosition(), pos) or 0
  local isCreatureNear   = creatureThing and creatureThing:getPosition().z == autoWalkPos.z and creatureDistance > 0

  local isMultiUse = useThing:isMultiUse()

  -- Classic controls
  if ClientOptions.getOption('classicControl') then

    -- Main action
    local mainShortcut = keyNoMods and mouseRightOnly or keyAltOnly and mouseLeftOnly

    -- Attack 'creatureThing'
    if creatureThing and mainShortcut and creatureThing ~= player and isCreatureNear then
      g_game.attack(creatureThing)
      return true

    -- Open container (same window, or in new window if no parent)
    elseif useThing and mainShortcut and useThing:isContainer() then
      g_game.open(useThing, useThing:getParentContainer() or nil)
      return true

    -- Use with
    elseif useThing and mainShortcut and isMultiUse then
      GameInterface.startUseWith(useThing)
      return true

    -- Force use: Open container in new window or use it
    elseif useThing and mainShortcut and not isMultiUse then
      g_game.use(useThing)
      return true

    -- Greet NPC
    elseif creatureThing and GameConsole and keyNoMods and mouseLeft and creatureThing:isNpc() and isCreatureNear and creatureDistance <= Npc.DefaultDistance then
      GameConsole.greetNpc(creatureThing)
      return true

    -- Tracker
    elseif creatureThing and GameTracker and keyShift and keyAlt and mouseLeftOrRight then
      GameTracker.toggleTracking(creatureThing)
      return true

    -- Context menu
    elseif useThing and keyCtrl and mouseLeftOrRight then
      GameInterface.createThingMenu(menuPosition, lookThing, useThing, creatureThing, wrapThing)
      return true
    end

  -- Normal controls
  else

    -- Context menu
    if keyNoMods and mouseRightOnly then
      GameInterface.createThingMenu(menuPosition, lookThing, useThing, creatureThing, wrapThing)
      return true

    -- Tracker
    elseif creatureThing and GameTracker and keyShift and keyAlt and mouseLeftOrRight then
      GameTracker.toggleTracking(creatureThing)
      return true

    -- Greet NPC
    elseif creatureThing and GameConsole and keyNoMods and mouseLeft and creatureThing:isNpc() and isCreatureNear and creatureDistance <= Npc.DefaultDistance then
      GameConsole.greetNpc(creatureThing)
      return true

    -- Follow 'creatureThing'
    elseif creatureThing and (keyCtrl and keyShift and mouseLeftOrRight or keyNoMods and mouseLeftAndRight and not creatureThing:isMonster()) and isCreatureNear then
      g_game.follow(creatureThing)
      return true

    -- Attack 'creatureThing'
    elseif creatureThing and (keyAlt and mouseLeftOrRight or keyNoMods and mouseLeftAndRight and creatureThing:isMonster()) and isCreatureNear then
      g_game.attack(creatureThing)
      return true

    -- Open container
    -- Left or Right = same window, or in new window if no parent
    -- Left and Right = new window
    elseif useThing and (keyCtrl and mouseLeftOrRight or keyNoMods and mouseLeftAndRight) and useThing:isContainer() then
      g_game.open(useThing, not mouseLeftAndRight and useThing:getParentContainer() or nil)
      return true

    -- Use with
    elseif useThing and keyCtrl and mouseLeftOrRight and isMultiUse then
      GameInterface.startUseWith(useThing)
      return true

    -- Force use: Open container in new window or use it
    elseif useThing and ((keyCtrl or keyAlt) and mouseLeftOrRight or keyNoMods and mouseLeftAndRight) and not isMultiUse then
      g_game.use(useThing)
      return true

    end
  end

  player:stopAutoWalk()
  if autoWalkPos and keyNoMods and mouseLeft then
    player:autoWalk(autoWalkPos)
    return true
  end

  return false
end

function GameInterface.moveStackableItem(item, toPos)
  if countWindow then
    return
  end
  if g_keyboard.isAltPressed() then
    g_game.move(item, toPos, 1)
    return
  end
  local count = item:getCount()
  if g_keyboard.isCtrlPressed() ~= ClientOptions.getOption('moveFullStack') then
    g_game.move(item, toPos, count)
    return
  end

  countWindow     = g_ui.createWidget('CountWindow', rootWidget)
  local itembox   = countWindow.item
  local scrollbar = countWindow.countScrollBar
  itembox:setItemId(item:getId())
  itembox:setItemCount(count)
  scrollbar:setMaximum(count)
  scrollbar:setMinimum(1)
  scrollbar:setValue(count)

  local spinbox = countWindow.spinBox
  spinbox:setMaximum(count)
  spinbox:setMinimum(0)
  spinbox:setValue(0)
  spinbox:hideButtons()
  spinbox:focus()
  spinbox.firstEdit = true

  local spinBoxValueChange = function(_, value)
    if not isWidgetAlive(spinbox) then
      return
    end
    spinbox.firstEdit = false
    scrollbar:setValue(value)
  end
  spinbox.onValueChange = spinBoxValueChange

  local check = function(widget)
    if widget.firstEdit then
      widget:setValue(widget:getMaximum())
      widget.firstEdit = false
    end
  end
  g_keyboard.bindKeyPress('Up', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:up() end end, spinbox)
  g_keyboard.bindKeyPress('Right', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:up() end end, spinbox)
  g_keyboard.bindKeyPress('Down', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:down() end end, spinbox)
  g_keyboard.bindKeyPress('Left', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:down() end end, spinbox)
  g_keyboard.bindKeyPress('PageUp', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:setValue(spinbox:getValue() + 10) end end, spinbox)
  g_keyboard.bindKeyPress('Shift+Up', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:setValue(spinbox:getValue() + 10) end end, spinbox)
  g_keyboard.bindKeyPress('Shift+Right', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:setValue(spinbox:getValue() + 10) end end, spinbox)
  g_keyboard.bindKeyPress('PageDown', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:setValue(spinbox:getValue() - 10) end end, spinbox)
  g_keyboard.bindKeyPress('Shift+Down', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:setValue(spinbox:getValue() - 10) end end, spinbox)
  g_keyboard.bindKeyPress('Shift+Left', function() if isWidgetAlive(spinbox) then check(spinbox) spinbox:setValue(spinbox:getValue() - 10) end end, spinbox)

  scrollbar.onValueChange = function(_, value)
    if not isWidgetAlive(countWindow) then
      return
    end

    local window = countWindow
    window.item:setItemCount(value)

    local currentSpinbox = window.spinBox
    if not isWidgetAlive(currentSpinbox) then
      return
    end

    currentSpinbox.onValueChange = nil
    currentSpinbox:setValue(value)
    currentSpinbox.onValueChange = spinBoxValueChange
  end

  scrollbar.onClick = function()
    if not isWidgetAlive(countWindow) then
      return
    end

    local window = countWindow
    local mousePos = g_window.getMousePosition()
    local currentScrollbar = window.countScrollBar
    local currentSpinbox = window.spinBox

    if not isWidgetAlive(currentScrollbar) then
      return
    end

    if not isWidgetAlive(currentSpinbox) then
      return
    end

    local slider = currentScrollbar:getChildById('sliderButton')
    check(currentSpinbox)
    if slider:getPosition().x > mousePos.x then
      currentSpinbox:setValue(currentSpinbox:getValue() - 10)
    elseif slider:getPosition().x < mousePos.x then
      currentSpinbox:setValue(currentSpinbox:getValue() + 10)
    end
  end

  local moveFunc = function()
    if not isWidgetAlive(countWindow) then
      return
    end

    local window = countWindow
    local moveCount = math.floor(tonumber(window.countScrollBar:getValue()) or 1)
    moveCount = math.max(1, math.min(moveCount, count))

    g_game.move(item, toPos, moveCount)
    window:destroy()
    if countWindow == window then
      countWindow = nil
    end
  end
  local cancelFunc = function()
    if not isWidgetAlive(countWindow) then
      return
    end

    local window = countWindow
    window:destroy()
    if countWindow == window then
      countWindow = nil
    end
  end

  countWindow.onEnter = moveFunc
  countWindow.onEscape = cancelFunc

  countWindow:getChildById('buttonOk').onClick = moveFunc
  countWindow:getChildById('buttonCancel').onClick = cancelFunc
end

function GameInterface.getRootPanel()
  return gameRootPanel
end

function GameInterface.getMapPanel()
  return gameMapPanel
end

function GameInterface.getGameScreenArea()
  return gameScreenArea
end

function GameInterface.getRightFirstPanel()
  return gameRightFirstPanel
end

function GameInterface.getRightSecondPanel()
  return gameRightSecondPanel
end

function GameInterface.getRightThirdPanel()
  return gameRightThirdPanel
end

function GameInterface.getLeftFirstPanel()
  return gameLeftFirstPanel
end

function GameInterface.getLeftSecondPanel()
  return gameLeftSecondPanel
end

function GameInterface.getLeftThirdPanel()
  return gameLeftThirdPanel
end

function GameInterface.getRightFirstPanelContainer()
  return gameRightFirstPanelContainer
end

function GameInterface.getRightSecondPanelContainer()
  return gameRightSecondPanelContainer
end

function GameInterface.getRightThirdPanelContainer()
  return gameRightThirdPanelContainer
end

function GameInterface.getLeftFirstPanelContainer()
  return gameLeftFirstPanelContainer
end

function GameInterface.getLeftSecondPanelContainer()
  return gameLeftSecondPanelContainer
end

function GameInterface.getLeftThirdPanelContainer()
  return gameLeftThirdPanelContainer
end

function GameInterface.getLeftPanelAddButton()
  return leftPanelAddButton
end

function GameInterface.getLeftPanelRemoveButton()
  return leftPanelRemoveButton
end

function GameInterface.getRightPanelAddButton()
  return rightPanelAddButton
end

function GameInterface.getRightPanelRemoveButton()
  return rightPanelRemoveButton
end

function GameInterface.getBottomPanel()
  return gameBottomPanel
end

function GameInterface.getSplitter()
  return bottomSplitter
end

function GameInterface.getGameExpBar()
  return gameExpBar
end

function GameInterface.getLeftPanelButton()
  return leftPanelButton
end

function GameInterface.getRightPanelButton()
  return rightPanelButton
end

function GameInterface.getTopMenuButton()
  return topMenuButton
end

function GameInterface.getChatButton()
  return chatButton
end

function GameInterface.getCurrentViewMode()
  return currentViewMode
end

function GameInterface.isViewModeFull()
  return ViewModes[currentViewMode].isFull
end

function GameInterface.nextViewMode()
  if g_app.isScaled() then
    return
  end

  ClientOptions.setOption('viewMode', (currentViewMode + 1) % table.size(ViewModes))
end

function GameInterface.setupViewMode(mode)
  if mode == currentViewMode then
    return
  end

  g_game.changeMapAwareRange(25, 19) -- Max viewport x & y

  local viewMode = ViewModes[mode]

  -- Anchor
  gameMapPanel:breakAnchors()
  -- Full
  if viewMode.id == 3 then
    gameMapPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    gameMapPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    gameMapPanel:addAnchor(AnchorLeft, 'gameLeftThirdPanel', AnchorOutsideRight)
    gameMapPanel:addAnchor(AnchorRight, 'gameRightThirdPanel', AnchorOutsideLeft)
    gameBottomPanel:setOn(true)

  -- Crop Full
  elseif viewMode.id == 2 then
    gameMapPanel:fill('parent')
    gameBottomPanel:setOn(true)

  -- Crop (1) or Normal (0)
  else
    gameMapPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    gameMapPanel:addAnchor(AnchorBottom, 'gameBottomPanel', AnchorOutsideTop)
    gameMapPanel:addAnchor(AnchorLeft, 'gameLeftThirdPanel', AnchorOutsideRight)
    gameMapPanel:addAnchor(AnchorRight, 'gameRightThirdPanel', AnchorOutsideLeft)
    gameBottomPanel:setOn(false)
  end

  -- Range
  gameMapPanel:setKeepAspectRatio(not viewMode.isCropped)
  gameMapPanel:setLimitVisibleRange(viewMode.isCropped)

  local panelsColor      = viewMode.id == 2 and '#ffffff66' or 'white'
  local bottomPanelColor = viewMode.isFull and '#ffffff66' or 'white'

  gameLeftFirstPanel:setImageColor(panelsColor)
  gameLeftSecondPanel:setImageColor(panelsColor)
  gameLeftThirdPanel:setImageColor(panelsColor)
  gameRightFirstPanel:setImageColor(panelsColor)
  gameRightSecondPanel:setImageColor(panelsColor)
  gameRightThirdPanel:setImageColor(panelsColor)

  -- Event
  gameMapPanel:changeViewMode(mode, currentViewMode)
  currentViewMode = mode
end

function GameInterface.onVocationChange(creature, vocation, oldVocation)
  local localPlayer = g_game.getLocalPlayer()
  if creature ~= localPlayer then
    return
  end

  GameInterface.updateManaBar()
end

function GameInterface.updateManaBar(on)
  local localPlayer = g_game.getLocalPlayer()

  if on == nil then
    on = ClientOptions.getOption('showMana')
  end
  if localPlayer and localPlayer:isWarrior() then -- Disable mana for Warrior
    on = false
  end

  gameMapPanel:setDrawManaBar(on)
end

function GameInterface.onTrackCreature(trackNode) -- todo: review function, since trackNode.id can be nil -- attempt to concatenate field 'id' (a nil value)
  local TrackingInfo = GameTracker.m.TrackingInfo

  local mapCreature = g_map.getCreatureById(trackNode.id)
  if mapCreature then
    mapCreature:showTrackRing(trackNode.color)
  end

  if not trackNode.widget then
    trackNode.widget = g_ui.createWidget('TrackerWidget', gameScreenArea)
    trackNode.widget:setId('tracked_creature_' .. trackNode.id)
  end

  if trackNode.status == TrackingInfo.Stop then
    if mapCreature then
      mapCreature:hideTrackRing()
    end
    trackNode.widget:destroy()
    trackNode.widget = nil
    return
  end

  if trackNode.status == TrackingInfo.Paused then
    if mapCreature then
      mapCreature:hideTrackRing()
    end
    trackNode.widget:hide()
  else
    trackNode.widget:show()
  end

  updateTrackArrow(trackNode)
end

function GameInterface.onTrackPosition(posNode, remove)
  if not posNode.widget then
    local pos = posNode.position
    posNode.widget = g_ui.createWidget('TrackerWidget', gameScreenArea)
    posNode.widget:setId(f('tracked_position_%d_%d_%d', pos.x, pos.y, pos.z))
    g_game.sendMagicEffect(g_game.getLocalPlayer():getPosition(), 347)
  end

  local trackWidget = posNode.widget
  addEvent(withWeakWidget(trackWidget, function(widget)
    if posNode.widget == widget then
      updateTrackArrow(posNode)
    end
  end))
end

function GameInterface.onTrackPositionEnd(posNode)
  if not posNode.widget then
    return
  end
  if posNode.cycleEvent then
    removeEvent(posNode.cycleEvent)
    posNode.cycleEvent = nil
  end
  g_game.sendMagicEffect(posNode.position, 348)
  posNode.widget:destroy()
  posNode.widget = nil
end

-- Tracker widget orbit radius around the local player in SQMs.
local trackerWidgetOrbitRadiusSqm = 3

function updateTrackArrow(trackNode)
  if not trackNode.widget then
    return
  end

  local playerPos = g_game.getLocalPlayer():getPosition()
  local trackPos = trackNode.position

  trackNode.widget:setVisible(not Position.isInRange(playerPos, trackPos, trackerWidgetOrbitRadiusSqm - 1, trackerWidgetOrbitRadiusSqm - 1))

  if not trackNode.id then -- only on track position
    if Position.isInRange(playerPos, trackPos, ScreenRangeX, ScreenRangeY) and playerPos.z == trackPos.z then
      if not trackNode.cycleEvent then
        g_game.sendMagicEffect(trackPos, 346)
        trackNode.cycleEvent = cycleEvent(function()
          g_game.sendMagicEffect(trackPos, 346)
        end, 1000)
      end
    else
      removeEvent(trackNode.cycleEvent)
      trackNode.cycleEvent = nil
    end
  end

  local distance  = Position.distance(playerPos, trackPos)
  local _distance = math.floor(distance)
  if not trackNode.id and not trackNode.auto then
    if distance == 0 and trackPos.z == playerPos.z then
      GameTracker.stopTrackPosition(trackNode.position)
      return
    end
  end

  local trackerLabel = trackNode.widget:getChildById('distance')
  trackerLabel:setText(f('%d m', _distance))
  trackerLabel:setVisible(_distance > 0)

  local dx = trackPos.x - playerPos.x
  local dy = trackPos.y - playerPos.y

  if gameMapPanel:isTransposedView() then
    -- Match transposed map orientation for tracker vectors
    dx, dy = dy, dx
  end

  local orientation = math.atan2(dy, dx)
  local trackerArrow = trackNode.widget:getChildById('arrow')
  trackerArrow:setRotation(_distance > 0 and math.deg(orientation) or (trackPos.z < playerPos.z and -135 or trackPos.z > playerPos.z and 45) or 0)

  if trackNode.color then
    trackerLabel:setColor(trackNode.color)
    trackerArrow:setImageColor(_distance <= 0 and (trackPos.z ~= playerPos.z and '#38aa34') or trackNode.color)
  end

  trackerLabel:breakAnchors()
  local xDiff = -dx
  local yDiff = -dy
  if yDiff < 0 then
    trackerLabel:addAnchor(AnchorBottom, 'arrow', AnchorOutsideTop)
  elseif yDiff > 0 then
    trackerLabel:addAnchor(AnchorTop, 'arrow', AnchorOutsideBottom)
  else
    trackerLabel:addAnchor(AnchorVerticalCenter, 'arrow', AnchorVerticalCenter)
  end
  if xDiff < 0 then
    trackerLabel:addAnchor(AnchorRight, 'arrow', AnchorOutsideLeft)
  elseif xDiff > 0 then
    trackerLabel:addAnchor(AnchorLeft, 'arrow', AnchorOutsideRight)
  else
    trackerLabel:addAnchor(AnchorHorizontalCenter, 'arrow', AnchorHorizontalCenter)
  end

  local mapSize = gameMapPanel:getVisibleDimension()
  local viewWidth = mapSize.width
  local viewHeight = mapSize.height
  if gameMapPanel:isTransposedView() then
    -- MapView swaps source target size in transposed mode.
    viewWidth = mapSize.height
    viewHeight = mapSize.width
  end

  local tileX = gameMapPanel:getMapWidth() / viewWidth
  local tileY = gameMapPanel:getMapHeight() / viewHeight

  local px = gameMapPanel:getX() + (gameMapPanel:getWidth() - gameMapPanel:getMapWidth()) / 2 + (tileX * (viewWidth - 1) / 2)
  local py = gameMapPanel:getY() + (gameMapPanel:getHeight() - gameMapPanel:getMapHeight()) / 2 + (tileY * (viewHeight - 1) / 2)

  local orbitDistance = math.min(distance, trackerWidgetOrbitRadiusSqm)
  local orbitSteps = math.max(orbitDistance - 1, 0)
  local radiusX = orbitSteps * tileX
  local radiusY = orbitSteps * tileY

  local centerX = px + (radiusX * math.cos(orientation))
  local centerY = py + (radiusY * math.sin(orientation))

  trackNode.widget:setX(centerX - trackNode.widget:getWidth() / 2)
  trackNode.widget:setY(centerY - trackNode.widget:getHeight() / 2)
end

function GameInterface.updateTrackArrows()
  for _, trackNode in pairs(GameTracker.getTrackList()) do
    updateTrackArrow(trackNode)
  end
end

function GameInterface.onUpdateTrackColor(trackNode)
  updateTrackArrow(trackNode)
  if trackNode.id then
    local mapCreature = g_map.getCreatureById(trackNode.id)
    if mapCreature then
      mapCreature:showTrackRing(trackNode.color)
    end
  end
end

-- Cycle walk

function GameInterface.initCycleWalkEvent()
  GameInterface.stopCycleWalkEvent()

  if not ClientOptions.getOption('cycleWalk') then
    return
  end

  cycleWalkEvent = cycleEvent(function()
    local player = g_game.getLocalPlayer()
    if not player then
      return
    end

    -- Happens when clicking outside of map boundaries
    local autoWalkPos = gameMapPanel:getPosition(g_window.getMousePosition())
    if not autoWalkPos or (autoWalkPos.x == 0 and autoWalkPos.y == 0 and autoWalkPos.z == 0) then
      return
    end

    local keyMods = g_window.getKeyboardModifiers()
    if keyMods ~= KeyboardNoModifier or not g_mouse.isPressed(MouseMidButton) then
      GameInterface.stopCycleWalkEvent()
      return
    end

    -- Auto walk pos is mouse pos behind walls
    local playerPos = player:getPosition()
    if autoWalkPos.z ~= playerPos.z then
      local dz = autoWalkPos.z - playerPos.z
      autoWalkPos.x = autoWalkPos.x + dz
      autoWalkPos.y = autoWalkPos.y + dz
      autoWalkPos.z = playerPos.z
    end

    player:autoWalk(autoWalkPos)

  end, ClientOptions.getOption('cycleWalkDelay'))
end

function GameInterface.stopCycleWalkEvent()
  if not cycleWalkEvent then
    return
  end

  removeEvent(cycleWalkEvent)
  cycleWalkEvent = nil
end

-- Widget lock

function GameInterface.parseWidgetLock(protocolGame, opcode, msg)
  local widgetId   = msg:getString()
  local actionFlag = msg:getU8()

  local widget = rootWidget:recursiveGetChildById(widgetId)
  if not widget then
    return
  end

  if actionFlag == WidgetLockActionFlag.Unlock then
    widget:unlock()
  elseif actionFlag == WidgetLockActionFlag.Lock then
    widget:lock()
  end
end

-- Static Circles
function GameInterface.onAttackingCreatureChange(creature, prevCreature)
  if prevCreature then
    prevCreature:hideStaticCircle()
  end

  if creature then
    creature:showStaticCircle(UICreatureButton.getStaticCircleTargetColor().notHovered)
    g_game.sendDistanceEffect(creature:getPosition(), 41)
  end
end

function GameInterface.onFollowingCreatureChange(creature, prevCreature)
  if prevCreature then
    prevCreature:hideStaticCircle()
  end

  if creature then
    creature:showStaticCircle(UICreatureButton.getStaticCircleFollowColor().notHovered)
  end
end

function GameInterface.toggleDealsButton()
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeDeals)

  protocolGame:send(msg)
end

local alpha = { r = 0, g = 0, b = 0, a = 0 }

function GameInterface.setCreatureOutline(protocol, msg)
  local creatureId = msg:getU32()
  local outlineColor = msg:getColor()
  local creature = g_map.getCreatureById(creatureId)
  if creature then
    creature:setShader("Outfit - Outline")
  end
end
