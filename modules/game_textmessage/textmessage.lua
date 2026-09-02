g_locales.loadLocales(resolvepath(''))

_G.GameTextMessage = { }



DefaultFont = 'verdana-11px-rounded'

MessageSettings = {
  none            = { },
  consoleRed      = { color = TextColors.red,       consoleTab = loc'${CorelibInfoDefault}' },
  consoleOrange   = { color = TextColors.orange,    consoleTab = loc'${CorelibInfoDefault}' },
  consoleBlue     = { color = TextColors.blue,      consoleTab = loc'${CorelibInfoDefault}' },
  centerRed       = { color = TextColors.red,       consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'lowCenterLabel' },
  centerGreen     = { color = TextColors.green,     consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'highCenterLabel',   consoleOption = 'showInfoMessagesInConsole' },
  centerWhite     = { color = TextColors.white,     consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'middleCenterLabel', consoleOption = 'showEventMessagesInConsole' },
  bottomWhite     = { color = TextColors.white,     consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel',       consoleOption = 'showEventMessagesInConsole' },
  status          = { color = TextColors.white,     consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel',       consoleOption = 'showStatusMessagesInConsole' },
  statusSmall     = { color = TextColors.white,                                                    screenTarget = 'statusLabel' },
  loot            = { color = TextColors.green,     consoleTab = loc'${GameConsoleTabNameServer}' },
  private         = { color = TextColors.lightblue,                                                  screenTarget = 'privateLabel' },
  statusBigTop    = { color = '#e1e1e1',            consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'privateLabel',      consoleOption = 'showStatusMessagesInConsole', font = 'martel-20px' },
  statusBigCenter = { color = '#e1e1e1',            consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'middleCenterLabel', consoleOption = 'showStatusMessagesInConsole', font = 'martel-20px' },
  statusBigBottom = { color = '#e1e1e1',            consoleTab = loc'${GameConsoleTabNameServer}', screenTarget = 'statusLabel',       consoleOption = 'showStatusMessagesInConsole', font = 'martel-20px' },
  look            = { color = '#e6db74',            consoleTab = loc'${GameConsoleTabNameServer}',                                     consoleOption = 'showInfoMessagesInConsole' },
}

MessageTypes = {
  [MessageModes.BarkLow] = MessageSettings.consoleOrange,
  [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
  [MessageModes.Failure] = MessageSettings.statusSmall,
  [MessageModes.Login] = MessageSettings.bottomWhite,
  [MessageModes.Game] = MessageSettings.centerWhite,
  [MessageModes.Status] = MessageSettings.status,
  [MessageModes.Warning] = MessageSettings.centerRed,
  [MessageModes.Loot] = MessageSettings.loot,
  [MessageModes.PrivateFrom] = MessageSettings.consoleBlue,

  [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

  [MessageModes.DamageDealed] = MessageSettings.status,
  [MessageModes.DamageReceived] = MessageSettings.status,
  [MessageModes.Heal] = MessageSettings.status,
  [MessageModes.Exp] = MessageSettings.status,

  [MessageModes.DamageOthers] = MessageSettings.none,
  [MessageModes.HealOthers] = MessageSettings.none,
  [MessageModes.ExpOthers] = MessageSettings.none,

  [MessageModes.TradeNpc] = MessageSettings.centerWhite,
  [MessageModes.Guild] = MessageSettings.centerWhite,
  [MessageModes.Party] = MessageSettings.centerGreen,
  [MessageModes.PartyManagement] = MessageSettings.centerWhite,
  [MessageModes.TutorialHint] = MessageSettings.centerWhite,
  [MessageModes.Report] = MessageSettings.consoleRed,
  [MessageModes.HotkeyUse] = MessageSettings.centerGreen,

  [MessageModes.GameBigTop] = MessageSettings.statusBigTop,
  [MessageModes.GameBigCenter] = MessageSettings.statusBigCenter,
  [MessageModes.GameBigBottom] = MessageSettings.statusBigBottom,

  [MessageModes.Look] = MessageSettings.look,

  [254] = MessageSettings.private
}

messagesPanel = nil
statusLabel = nil

-- Look hover
lookLastConsoleKey  = nil
lookLastConsoleText = nil



function GameTextMessage.init()
  -- Alias
  GameTextMessage.m = modules.game_textmessage

  for messageMode in pairs(MessageTypes) do
    registerMessageMode(messageMode, GameTextMessage.displayMessage)
  end

  connect(g_game, {
    onClientOptionChanged = GameTextMessage.onClientOptionChanged,
    onGameEnd             = GameTextMessage.clearMessages,
  })
  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameTextMessage.onGeometryChange,
    onViewModeChange = GameTextMessage.onViewModeChange,
    onZoomChange     = GameTextMessage.onZoomChange,
  })

  messagesPanel = g_ui.loadUI('textmessage', GameInterface.getRootPanel())
  statusLabel = messagesPanel:getChildById('statusLabel')
end

function GameTextMessage.terminate()
  for messageMode in pairs(MessageTypes) do
    unregisterMessageMode(messageMode, GameTextMessage.displayMessage)
  end

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameTextMessage.onGeometryChange,
    onViewModeChange = GameTextMessage.onViewModeChange,
    onZoomChange     = GameTextMessage.onZoomChange,
  })
  disconnect(g_game, {
    onClientOptionChanged = GameTextMessage.onClientOptionChanged,
    onGameEnd             = GameTextMessage.clearMessages,
  })

  GameTextMessage.clearMessages()
  messagesPanel:destroy()
  messagesPanel = nil

  _G.GameTextMessage = nil
end

local function updateStatusLabelPosition(label)
  local margin = GameInterface.m.chatButton:getHeight() + 4

  -- Hotkey bar
  local bottomHotkeyBar = modules.ka_game_hotkeybars and GameHotkeyBars.getHotkeyBars()[AnchorBottom] or nil
  if bottomHotkeyBar and bottomHotkeyBar:isVisible() then
    margin = margin + bottomHotkeyBar:getHeight()
  end

  -- Experience bar
  if GameInterface.m.gameExpBar:isOn() then
    margin = margin + GameInterface.m.gameExpBar:getHeight()
  end

  label:setMarginBottom(margin)
end

function GameTextMessage.onGeometryChange(mapPanel)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onViewModeChange(mapWidget, viewMode, oldViewMode)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onClientOptionChanged(key, value, force, wasClientSettingUp)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end

  addEvent(withWeakWidget(statusLabel, function(widget) updateStatusLabelPosition(widget) end))
end

function GameTextMessage.calculateVisibleTime(text)
  return math.max(#text * 100, 4000)
end

function GameTextMessage.displayMessage(mode, text)
  if not g_game.isOnline() then
    return
  end

  local msgtype = MessageTypes[mode]
  if not msgtype then
    return
  end

  if msgtype == MessageSettings.none then
    return
  end

  local skipConsole = false

  -- Look hover
  if mode == MessageModes.Look then
    GameInterface.handleHoverLookMessage(text)

    -- If the text is the same as the last one, skip the console
    local lookConsoleKey = GameInterface.getHoverLookConsoleKey()
    if lookConsoleKey then
      skipConsole = lookLastConsoleKey == lookConsoleKey and lookLastConsoleText == text

      if not skipConsole then
        lookLastConsoleKey  = lookConsoleKey
        lookLastConsoleText = text
      end
    else
      lookLastConsoleKey  = nil
      lookLastConsoleText = nil
    end
  end

  if not skipConsole and msgtype.consoleTab ~= nil and (msgtype.consoleOption == nil or ClientOptions.getOption(msgtype.consoleOption)) then
    GameConsole.addText(text, msgtype, msgtype.consoleTab)
  end

  if msgtype.screenTarget then
    local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
    label:setText(text)
    label:setColor(msgtype.color)
    label:setFont(msgtype.font or DefaultFont)
    label:setVisible(true)
    if msgtype.screenTarget == 'statusLabel' then
      updateStatusLabelPosition(label)
    end
    removeEvent(label.hideEvent)
    label.hideEvent = scheduleEvent(function()
      if isWidgetAlive(label) then
        label:setVisible(false)
      end
    end, GameTextMessage.calculateVisibleTime(text))
  end
end

function GameTextMessage.displayPrivateMessage(text)
  GameTextMessage.displayMessage(254, text)
end

function GameTextMessage.displayStatusMessage(text)
  GameTextMessage.displayMessage(MessageModes.Status, text)
end

function GameTextMessage.displayFailureMessage(text)
  GameTextMessage.displayMessage(MessageModes.Failure, text)
end

function GameTextMessage.displayGameMessage(text)
  GameTextMessage.displayMessage(MessageModes.Game, text)
end

function GameTextMessage.displayBroadcastMessage(text)
  GameTextMessage.displayMessage(MessageModes.Warning, text)
end

function GameTextMessage.clearMessages()
  -- Look hover
  lookLastConsoleKey  = nil
  lookLastConsoleText = nil

  for _i,child in pairs(messagesPanel:recursiveGetChildren()) do
    if child:getId():match('Label') then
      child:hide()
      removeEvent(child.hideEvent)
    end
  end
end



function LocalPlayer:onAutoWalkFail(player)
  if modules.game_textmessage then
    GameTextMessage.displayFailureMessage(loc'${GameTextMessageErrorNoWay}')
  end
end
