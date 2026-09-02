g_locales.loadLocales(resolvepath(''))

_G.GameUnjustifiedPoints = { }



local updateTime = 1 -- seconds
local GameUnjustifiedPointsActionKey = 'Ctrl+U'

unjustifiedPointsWindow = nil
unjustifiedPointsHeader = nil
unjustifiedPointsFooter = nil
unjustifiedPointsTopMenuButton = nil
contentsPanel = nil

currentSkullWidget = nil
skullTimeLabel = nil

redSkullProgressBar = nil
blackSkullProgressBar = nil

redSkullSkullWidget = nil
blackSkullSkullWidget = nil

updateMainLabelEvent = nil

local unjustifiedData = {
  remainingTime = 0,
  fragsToRedSkull = 0,
  fragsToBlackSkull = 0,
  timeToRemoveFrag = 1
}

local function getColorByKills(kills, fragsTo)
  local ratio = kills / fragsTo
  if ratio == 0 then
    return 'white'
  end

  return ratio < 0.334 and 'green' or ratio < 0.667 and 'yellow' or ratio >= 0.667 and 'red' or 'white'
end

local function updateMainLabelEventFunction()
  if not g_game.isOnline() or unjustifiedData.remainingTime <= 0 then
    GameUnjustifiedPoints.stopUpdateEvent()
    return
  end

  unjustifiedData.remainingTime = math.max(0, unjustifiedData.remainingTime - updateTime)
  GameUnjustifiedPoints.refreshUI()

  if unjustifiedData.remainingTime <= 0 then
    GameUnjustifiedPoints.stopUpdateEvent()
  end
end



function GameUnjustifiedPoints.init()
  -- Alias
  GameUnjustifiedPoints.m = modules.game_unjustifiedpoints

  unjustifiedPointsWindow        = g_ui.loadUI('unjustifiedpoints')
  unjustifiedPointsHeader        = unjustifiedPointsWindow:getChildById('miniWindowHeader')
  unjustifiedPointsFooter        = unjustifiedPointsWindow:getChildById('miniWindowFooter')
  unjustifiedPointsTopMenuButton = ClientTopMenu.addRightGameToggleButton('unjustifiedPointsTopMenuButton', { loct = '${GameUnjustifiedPointsWindowTitle} (${GameUnjustifiedPointsActionKey})', locpar = { GameUnjustifiedPointsActionKey = GameUnjustifiedPointsActionKey } }, '/images/ui/top_menu/unjustifiedpoints', GameUnjustifiedPoints.toggle)

  unjustifiedPointsWindow.topMenuButton = unjustifiedPointsTopMenuButton
  unjustifiedPointsWindow:disableResize()
  unjustifiedPointsTopMenuButton:hide()

  contentsPanel = unjustifiedPointsWindow:getChildById('contentsPanel')

  skullTimeLabel = unjustifiedPointsHeader:getChildById('skullTimeLabel')
  currentSkullWidget = unjustifiedPointsFooter:getChildById('currentSkullWidget')

  redSkullProgressBar = contentsPanel:getChildById('redSkullProgressBar')
  blackSkullProgressBar = contentsPanel:getChildById('blackSkullProgressBar')
  redSkullSkullWidget = contentsPanel:getChildById('redSkullSkullWidget')
  blackSkullSkullWidget = contentsPanel:getChildById('blackSkullSkullWidget')

  GameUnjustifiedPoints.resetData()
  GameUnjustifiedPoints.refreshUI()

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeUnjustifiedPoints, GameUnjustifiedPoints.parseUnjustifiedPoints)

  connect(g_game, {
    onGameStart = GameUnjustifiedPoints.online,
    onGameEnd   = GameUnjustifiedPoints.offline
  })

  g_keyboard.bindKeyDown(GameUnjustifiedPointsActionKey, GameUnjustifiedPoints.toggle)

  if g_game.isOnline() then
    GameUnjustifiedPoints.online()
  end
end

function GameUnjustifiedPoints.terminate()
  GameUnjustifiedPoints.stopUpdateEvent()

  disconnect(g_game, {
    onGameStart = GameUnjustifiedPoints.online,
    onGameEnd   = GameUnjustifiedPoints.offline
  })

  g_keyboard.unbindKeyDown(GameUnjustifiedPointsActionKey)

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeUnjustifiedPoints)

  unjustifiedPointsWindow:destroy()
  unjustifiedPointsTopMenuButton:destroy()

  _G.GameUnjustifiedPoints = nil
end

function GameUnjustifiedPoints.onMiniWindowOpen()
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then
    return
  end

  GameUnjustifiedPoints.updateWindowUI()
  g_game.sendUnjustifiedPointsBuffer()
end

function GameUnjustifiedPoints.onMiniWindowClose()
end

function GameUnjustifiedPoints.toggle()
  if not unjustifiedPointsTopMenuButton:isVisible() then
    return
  end

  GameInterface.toggleMiniWindow(unjustifiedPointsWindow)
end

function GameUnjustifiedPoints.online()
  if g_game.getFeature(GameUnjustifiedPointsPacket) then
    unjustifiedPointsWindow:setup(unjustifiedPointsTopMenuButton)
    GameUnjustifiedPoints.refreshUI()
    g_game.sendUnjustifiedPointsBuffer()
  else
    GameUnjustifiedPoints.resetData()
    GameUnjustifiedPoints.stopUpdateEvent()
    GameUnjustifiedPoints.refreshUI()
  end
end

function GameUnjustifiedPoints.offline()
  GameUnjustifiedPoints.resetData()
  GameUnjustifiedPoints.stopUpdateEvent()
  GameUnjustifiedPoints.refreshUI()
end

function GameUnjustifiedPoints.startUpdateEvent()
  if updateMainLabelEvent or not g_game.isOnline() or unjustifiedData.remainingTime <= 0 then
    return
  end

  updateMainLabelEvent = cycleEvent(updateMainLabelEventFunction, updateTime * 1000)
end

function GameUnjustifiedPoints.stopUpdateEvent()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil
end

function GameUnjustifiedPoints.hasFragTime()
  return unjustifiedData.remainingTime > 0
end

function GameUnjustifiedPoints.resetData()
  unjustifiedData = {
    remainingTime = 0,
    fragsToRedSkull = 0,
    fragsToBlackSkull = 0,
    timeToRemoveFrag = 1
  }
end

function GameUnjustifiedPoints.updateTopMenuButtonVisibility()
  local shouldShowButton = g_game.isOnline() and g_game.getFeature(GameUnjustifiedPointsPacket) and GameUnjustifiedPoints.hasFragTime()

  if shouldShowButton then
    unjustifiedPointsTopMenuButton:show()
  else
    unjustifiedPointsTopMenuButton:hide()
    unjustifiedPointsWindow:close()
  end
end

function GameUnjustifiedPoints.updateWindowUI()
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or not localPlayer:isLocalPlayer() then
    return
  end

  local remainingTime = unjustifiedData.remainingTime
  local fragsToRedSkull = unjustifiedData.fragsToRedSkull
  local fragsToBlackSkull = unjustifiedData.fragsToBlackSkull
  local timeToRemoveFrag = unjustifiedData.timeToRemoveFrag
  local fragsCount  = math.ceil(remainingTime / timeToRemoveFrag)
  local skull       = localPlayer:getSkull()

  redSkullProgressBar:setPhases(fragsToRedSkull)
  blackSkullProgressBar:setPhases(fragsToBlackSkull)

  local nextFragRemainingTime = remainingTime % timeToRemoveFrag
  skullTimeLabel:setText(f(loc'%.2d:%.2d (${GameUnjustifiedPointsInfoFrags}: %d)', math.floor(nextFragRemainingTime / (60 * 60)), math.floor(nextFragRemainingTime / 60) % 60, fragsCount))

  local nextFragRemainingTimeTooltip = f(loc'${GameUnjustifiedPointsInfoNextFragTime}: %.2d:%.2d:%.2d', math.floor(nextFragRemainingTime / (60 * 60)), math.floor(nextFragRemainingTime / 60) % 60, nextFragRemainingTime % 60)
  skullTimeLabel:setTooltip(f(loc'${GameUnjustifiedPointsInfoTotalFrags}: %d\n%s\n${GameUnjustifiedPointsInfoFragsRemainingTime}: %.2d:%.2d:%.2d', fragsCount, nextFragRemainingTimeTooltip, math.floor(remainingTime / (60 * 60)), math.floor(remainingTime / 60) % 60, remainingTime % 60))

  if remainingTime >= 1 and table.contains({SkullWhite, SkullRed, SkullBlack}, skull) then
    currentSkullWidget:setIcon(getSkullImagePath(skull))
    currentSkullWidget:setTooltip(loc'${GameUnjustifiedPointsInfoCurrentSkull}')
  else
    currentSkullWidget:setIcon('')
    currentSkullWidget:setTooltip(loc'${GameUnjustifiedPointsInfoNoSkull}')
  end

  if fragsToRedSkull ~= 0 then
    redSkullProgressBar:setValue(fragsCount, 0, fragsToRedSkull)
    redSkullProgressBar:setFillerBackgroundColor(getColorByKills(fragsCount, fragsToRedSkull))
  else
    redSkullProgressBar:setValue(0, 0, 1)
  end
  redSkullProgressBar:setTooltip(loc'${GameUnjustifiedPointsInfoFragsUntilSkullRed}: ' .. math.max(0, fragsToRedSkull - fragsCount))

  if fragsToBlackSkull ~= 0 then
    blackSkullProgressBar:setValue(fragsCount, 0, fragsToBlackSkull)
    blackSkullProgressBar:setFillerBackgroundColor(getColorByKills(fragsCount, fragsToBlackSkull))
  else
    blackSkullProgressBar:setValue(0, 0, 1)
  end
  blackSkullProgressBar:setTooltip(loc'${GameUnjustifiedPointsInfoFragsUntilSkullBlack}: ' .. math.max(0, fragsToBlackSkull - fragsCount))
end

function GameUnjustifiedPoints.refreshUI()
  GameUnjustifiedPoints.updateTopMenuButtonVisibility()
  GameUnjustifiedPoints.updateWindowUI()
end

function GameUnjustifiedPoints.onUnjustifiedPoints(remainingTime, fragsToRedSkull, fragsToBlackSkull, timeToRemoveFrag)
  unjustifiedData.remainingTime = math.max(0, math.floor(remainingTime or 0))
  unjustifiedData.fragsToRedSkull = math.max(0, math.floor(fragsToRedSkull or 0))
  unjustifiedData.fragsToBlackSkull = math.max(0, math.floor(fragsToBlackSkull or 0))
  unjustifiedData.timeToRemoveFrag = math.max(1, math.floor(timeToRemoveFrag or 1))

  if g_game.isOnline() and g_game.getFeature(GameUnjustifiedPointsPacket) and GameUnjustifiedPoints.hasFragTime() then
    GameUnjustifiedPoints.startUpdateEvent()
  else
    GameUnjustifiedPoints.stopUpdateEvent()
  end

  GameUnjustifiedPoints.refreshUI()
end

function GameUnjustifiedPoints.parseUnjustifiedPoints(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = buffer / ':'

  local remainingTime     = tonumber(params[1])
  local fragsToRedSkull   = tonumber(params[2])
  local fragsToBlackSkull = tonumber(params[3])
  local timeToRemoveFrag  = tonumber(params[4])
  if not remainingTime or not fragsToRedSkull or not fragsToBlackSkull or not timeToRemoveFrag then
    return
  end

  GameUnjustifiedPoints.onUnjustifiedPoints(remainingTime, fragsToRedSkull, fragsToBlackSkull, timeToRemoveFrag)
end
