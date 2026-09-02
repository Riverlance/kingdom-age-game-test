g_locales.loadLocales(resolvepath(''))

_G.GameConsole = { }



NpcChannelName = 'NPCs' -- Do not translate it!



SpeakTypesSettings = {
  none = { },
  say = { speakType = MessageModes.Say, color = '#E0E000' },
  gamemasterSay = { speakType = MessageModes.GamemasterSay, color = '#A144FF' },
  whisper = { speakType = MessageModes.Whisper, color = '#E0E0E0' },
  yell = { speakType = MessageModes.Yell, color = '#FFAA00' },
  broadcast = { speakType = MessageModes.GamemasterBroadcast, color = '#F55E5E' },
  private = { speakType = MessageModes.PrivateTo, color = '#5FF7F7', private = true },
  privateRed = { speakType = MessageModes.GamemasterTo, color = '#F55E5E', private = true },
  privatePlayerToPlayer = { speakType = MessageModes.PrivateTo, color = '#9F9DFD', private = true },
  privatePlayerToNpc = { speakType = MessageModes.NpcTo, color = '#9F9DFD', private = true, npcChat = true },
  privateNpcToPlayer = { speakType = MessageModes.NpcFrom, color = '#5FF7F7', private = true, npcChat = true },
  channelYellow = { speakType = MessageModes.Channel, color = '#E0E000' },
  channelWhite = { speakType = MessageModes.ChannelManagement, color = '#FFFFFF' },
  channelRed = { speakType = MessageModes.GamemasterChannel, color = '#F55E5E' },
  channelOrange = { speakType = MessageModes.ChannelHighlight, color = '#FE6500' },
  barkLow = { speakType = MessageModes.BarkLow, color = '#FE6500', hideInConsole = true},
  barkLoud = { speakType = MessageModes.BarkLoud, color = '#FE6500', hideInConsole = true},
}

SpeakTypes = {
  [MessageModes.Say] = SpeakTypesSettings.say,
  [MessageModes.GamemasterSay] = SpeakTypesSettings.gamemasterSay,
  [MessageModes.Whisper] = SpeakTypesSettings.whisper,
  [MessageModes.Yell] = SpeakTypesSettings.yell,
  [MessageModes.GamemasterBroadcast] = SpeakTypesSettings.broadcast,
  [MessageModes.PrivateTo] = SpeakTypesSettings.private,
  [MessageModes.PrivateFrom] = SpeakTypesSettings.private,
  [MessageModes.GamemasterPrivateFrom] = SpeakTypesSettings.privateRed,
  [MessageModes.NpcTo] = SpeakTypesSettings.privatePlayerToNpc,
  [MessageModes.NpcFrom] = SpeakTypesSettings.privateNpcToPlayer,
  [MessageModes.Channel] = SpeakTypesSettings.channelYellow,
  [MessageModes.ChannelManagement] = SpeakTypesSettings.channelWhite,
  [MessageModes.GamemasterChannel] = SpeakTypesSettings.channelRed,
  [MessageModes.ChannelHighlight] = SpeakTypesSettings.channelOrange,
  [MessageModes.BarkLow] = SpeakTypesSettings.barkLow,
  [MessageModes.BarkLoud] = SpeakTypesSettings.barkLoud,
  [MessageModes.NpcFromStartBlock] = SpeakTypesSettings.privateNpcToPlayer,

  -- ignored types
  [MessageModes.Spell] = SpeakTypesSettings.none,
}

SayModes = {
  [1] = { speakTypeDesc = 'whisper', icon = '/images/ui/console/whisper' },
  [2] = { speakTypeDesc = 'say', icon = '/images/ui/console/say' },
  [3] = { speakTypeDesc = 'yell', icon = '/images/ui/console/yell' }
}

ChannelEventFormats = {
  [ChannelEvent.Join]    = loc'${GameConsoleChannelEventJoin}',
  [ChannelEvent.Leave]   = loc'${GameConsoleChannelEventLeave}',
  [ChannelEvent.Invite]  = loc'${GameConsoleChannelEventInvite}',
  [ChannelEvent.Exclude] = loc'${GameConsoleChannelEventExclude}',
}

CHANNEL_ID_LOOT = 2

isChatEnabled = true
consolePanel = nil
headerPanel = nil
contentPanel = nil
footerPanel = nil
consoleContentPanel = nil
consoleTabBar = nil
consoleTextEdit = nil
channels = nil
channelsWindow = nil
communicationWindow = nil
ownPrivateName = nil
currentMessageIndex = 0
ignoreNpcMessages = false
defaultTab = nil
serverTab = nil
filters = { }

local communicationSettings = {
  useIgnoreList = true,
  useWhiteList = true,
  privateMessages = false,
  yelling = false,
  allowVIPs = false,
  ignoredPlayers = { },
  whitelistedPlayers = { }
}

local consoleLog = { }
local MAX_LOGLINES = 500
local MAX_LINES = 100

cloneContentPanel = nil
cloneTabSeparator = nil
cloneTabTipArea = nil
cloneTabBar = nil
clonedTab = nil
cloneTab = nil
clonedSplitter = nil

-- Contains letter width for font 'verdana-11px-antialised' as console is based on it
local letterWidth = { -- New line (10) and Space (32) have width 1 because they are printed and not replaced with spacer
  [10] = 1, [32] = 1, [33] = 3, [34] = 6, [35] = 8, [36] = 7, [37] = 13, [38] = 9, [39] = 3, [40] = 5, [41] = 5, [42] = 6, [43] = 8, [44] = 4, [45] = 5, [46] = 3, [47] = 8,
  [48] = 7, [49] = 6, [50] = 7, [51] = 7, [52] = 7, [53] = 7, [54] = 7, [55] = 7, [56] = 7, [57] = 7, [58] = 3, [59] = 4, [60] = 8, [61] = 8, [62] = 8, [63] = 6,
  [64] = 10, [65] = 9, [66] = 7, [67] = 7, [68] = 8, [69] = 7, [70] = 7, [71] = 8, [72] = 8, [73] = 5, [74] = 5, [75] = 7, [76] = 7, [77] = 9, [78] = 8, [79] = 8,
  [80] = 7, [81] = 8, [82] = 8, [83] = 7, [84] = 8, [85] = 8, [86] = 8, [87] = 12, [88] = 8, [89] = 8, [90] = 7, [91] = 5, [92] = 8, [93] = 5, [94] = 9, [95] = 8,
  [96] = 5, [97] = 7, [98] = 7, [99] = 6, [100] = 7, [101] = 7, [102] = 5, [103] = 7, [104] = 7, [105] = 3, [106] = 4, [107] = 7, [108] = 3, [109] = 11, [110] = 7,
  [111] = 7, [112] = 7, [113] = 7, [114] = 6, [115] = 6, [116] = 5, [117] = 7, [118] = 8, [119] = 10, [120] = 8, [121] = 8, [122] = 6, [123] = 7, [124] = 4, [125] = 7, [126] = 8,
  [127] = 1, [128] = 7, [129] = 6, [130] = 3, [131] = 7, [132] = 6, [133] = 11, [134] = 7, [135] = 7, [136] = 7, [137] = 13, [138] = 7, [139] = 4, [140] = 11, [141] = 6, [142] = 6,
  [143] = 6, [144] = 6, [145] = 4, [146] = 3, [147] = 7, [148] = 6, [149] = 6, [150] = 7, [151] = 10, [152] = 7, [153] = 10, [154] = 6, [155] = 5, [156] = 11, [157] = 6, [158] = 6,
  [159] = 8, [160] = 4, [161] = 3, [162] = 7, [163] = 7, [164] = 7, [165] = 8, [166] = 4, [167] = 7, [168] = 6, [169] = 10, [170] = 6, [171] = 8, [172] = 8, [173] = 16, [174] = 10,
  [175] = 8, [176] = 5, [177] = 8, [178] = 5, [179] = 5, [180] = 6, [181] = 7, [182] = 7, [183] = 3, [184] = 5, [185] = 6, [186] = 6, [187] = 8, [188] = 12, [189] = 12, [190] = 12,
  [191] = 6, [192] = 9, [193] = 9, [194] = 9, [195] = 9, [196] = 9, [197] = 9, [198] = 11, [199] = 7, [200] = 7, [201] = 7, [202] = 7, [203] = 7, [204] = 5, [205] = 5, [206] = 6,
  [207] = 5, [208] = 8, [209] = 8, [210] = 8, [211] = 8, [212] = 8, [213] = 8, [214] = 8, [215] = 8, [216] = 8, [217] = 8, [218] = 8, [219] = 8, [220] = 8, [221] = 8, [222] = 7,
  [223] = 7, [224] = 7, [225] = 7, [226] = 7, [227] = 7, [228] = 7, [229] = 7, [230] = 11, [231] = 6, [232] = 7, [233] = 7, [234] = 7, [235] = 7, [236] = 3, [237] = 4, [238] = 4,
  [239] = 4, [240] = 7, [241] = 7, [242] = 7, [243] = 7, [244] = 7, [245] = 7, [246] = 7, [247] = 9, [248] = 7, [249] = 7, [250] = 7, [251] = 7, [252] = 7, [253] = 8, [254] = 7, [255] = 8
}



function GameConsole.init()
  -- Alias
  GameConsole.m = modules.game_console

  connect(g_game, {
    onTalk                  = GameConsole.onTalk,
    onChannelList           = GameConsole.onChannelList,
    onOpenChannel           = GameConsole.onOpenChannel,
    onOpenPrivateChannel    = GameConsole.onOpenPrivateChannel,
    onOpenOwnPrivateChannel = GameConsole.onOpenOwnPrivateChannel,
    onCloseChannel          = GameConsole.onCloseChannel,
    onGameStart             = GameConsole.online,
    onGameEnd               = GameConsole.offline,
    onChannelEvent          = GameConsole.onChannelEvent,
    onClientOptionChanged   = GameConsole.onClientOptionChanged,
  })

  consolePanel = g_ui.loadUI('console', GameInterface.getBottomPanel())
  headerPanel  = consolePanel:getChildById('headerPanel')
  contentPanel = consolePanel:getChildById('contentPanel')
  footerPanel  = consolePanel:getChildById('footerPanel')

  consoleTextEdit = footerPanel:getChildById('consoleTextEdit')
  consoleContentPanel = contentPanel:getChildById('consoleContentPanel')
  consoleTabBar = headerPanel:getChildById('consoleTabBar')
  consoleTabBar:setContentWidget(consoleContentPanel)

  cloneContentPanel = contentPanel:getChildById('cloneContentPanel')
  cloneTabSeparator = headerPanel:getChildById('cloneTabSeparator')
  cloneTabTipArea = headerPanel:getChildById('cloneTabTipArea')
  cloneTabBar = headerPanel:getChildById('cloneTabBar')
  cloneTabBar:setContentWidget(cloneContentPanel)
  clonedSplitter = contentPanel:getChildById('clonedSplitter')

  cloneTabTipArea.onDoubleClick = function(mousePosition)
    if clonedTab then -- cloneTabTipArea is not visible
      return
    end
    GameConsole.toggleClonedTab(GameConsole.getCurrentTab())
  end

  channels = { }

  consolePanel.onKeyPress = function(self, keyCode, keyboardModifiers)
    if not (keyboardModifiers == KeyboardCtrlModifier and keyCode == KeyC) then
      return false
    end

    local tab = GameConsole.getCurrentTab()
    if not tab then
      return false
    end

    local selection = tab.tabPanel:getChildById('consoleBuffer').selectionText
    if not selection then
      return false
    end

    g_window.setClipboardText(selection)
    return true
  end

  g_keyboard.bindKeyPress('Shift+Up', function() GameConsole.navigateConsoleLog(1) end, consolePanel)
  g_keyboard.bindKeyPress('Shift+Down', function() GameConsole.navigateConsoleLog(-1) end, consolePanel)
  g_keyboard.bindKeyPress('Tab', function() consoleTabBar:selectNextTab() end, consolePanel)
  g_keyboard.bindKeyPress('Shift+Tab', function() consoleTabBar:selectPrevTab() end, consolePanel)
  g_keyboard.bindKeyDown('Enter', GameConsole.onEnterKeyDown, consolePanel)
  g_keyboard.bindKeyPress('Ctrl+A', function() consoleTextEdit:clearText() end, consolePanel)

  -- apply buttom functions after loaded
  consoleTabBar:setNavigation(headerPanel:getChildById('prevChannelButton'), headerPanel:getChildById('nextChannelButton'))
  consoleTabBar.onTabChange = GameConsole.onTabChange

  consoleToggleChat = footerPanel:getChildById('toggleChat')

  g_keyboard.bindKeyDown('Ctrl+O', g_game.requestChannels)

  if g_game.isOnline() then
    GameConsole.online()
  end
end

function GameConsole.terminate()
  disconnect(g_game, {
    onTalk                  = GameConsole.onTalk,
    onChannelList           = GameConsole.onChannelList,
    onOpenChannel           = GameConsole.onOpenChannel,
    onOpenPrivateChannel    = GameConsole.onOpenPrivateChannel,
    onOpenOwnPrivateChannel = GameConsole.onOpenOwnPrivateChannel,
    onCloseChannel          = GameConsole.onCloseChannel,
    onGameStart             = GameConsole.online,
    onGameEnd               = GameConsole.offline,
    onChannelEvent          = GameConsole.onChannelEvent,
    onClientOptionChanged   = GameConsole.onClientOptionChanged,
  })

  g_keyboard.unbindKeyDown('Ctrl+O')

  GameConsole.saveCommunicationSettings()
  GameConsole.closeClonedTab()

  if channelsWindow then
    channelsWindow:destroy()
  end

  if communicationWindow then
    communicationWindow:destroy()
  end

  consoleTabBar = nil
  consoleContentPanel = nil
  consoleToggleChat = nil
  consoleTextEdit = nil

  cloneTabBar = nil
  cloneTabSeparator = nil
  cloneTabTipArea = nil
  cloneContentPanel = nil
  clonedTab = nil
  cloneTab = nil

  consolePanel:destroy()
  consolePanel = nil
  ownPrivateName = nil

  _G.GameConsole = nil
end

function GameConsole.clearSelection(consoleBuffer)
  for _,label in pairs(consoleBuffer:getChildren()) do
    label:clearSelection()
  end
  consoleBuffer.selectionText = nil
  consoleBuffer.selection = nil
end

function GameConsole.selectAll(consoleBuffer)
  GameConsole.clearSelection(consoleBuffer)
  if consoleBuffer:getChildCount() > 0 then
    local text = { }
    for _,label in pairs(consoleBuffer:getChildren()) do
      label:selectAll()
      table.insert(text, label:getSelection())
    end
    consoleBuffer.selectionText = table.concat(text, '\n')
    consoleBuffer.selection = { first = consoleBuffer:getChildIndex(consoleBuffer:getFirstChild()), last = consoleBuffer:getChildIndex(consoleBuffer:getLastChild()) }
  end
end

function GameConsole.onEnableChat()
  GameInterface.unbindWalkKey('W')
  GameInterface.unbindWalkKey('A')
  GameInterface.unbindWalkKey('S')
  GameInterface.unbindWalkKey('D')

  GameInterface.unbindWalkKey('Q')
  GameInterface.unbindWalkKey('E')
  GameInterface.unbindWalkKey('Z')
  GameInterface.unbindWalkKey('C')

  g_keyboard.unbindKeyPress('Ctrl+W', gameRootPanel)
  g_keyboard.unbindKeyPress('Ctrl+A', gameRootPanel)
  g_keyboard.unbindKeyPress('Ctrl+S', gameRootPanel)
  g_keyboard.unbindKeyPress('Ctrl+D', gameRootPanel)

  g_keyboard.bindKeyDown('Ctrl+W', GameConsole.removeCurrentTab)

  signalcall(g_game.onToggleChat, true)
end

function GameConsole.onDisableChat()
  g_keyboard.unbindKeyDown('Ctrl+W')

  GameInterface.bindWalkKey('W', North)
  GameInterface.bindWalkKey('A', West)
  GameInterface.bindWalkKey('S', South)
  GameInterface.bindWalkKey('D', East)

  GameInterface.bindWalkKey('Q', NorthWest)
  GameInterface.bindWalkKey('E', NorthEast)
  GameInterface.bindWalkKey('Z', SouthWest)
  GameInterface.bindWalkKey('C', SouthEast)

  GameInterface.bindTurnKey('Ctrl+W', North, true)
  GameInterface.bindTurnKey('Ctrl+A', West, true)
  GameInterface.bindTurnKey('Ctrl+S', South, true)
  GameInterface.bindTurnKey('Ctrl+D', East, true)

  signalcall(g_game.onToggleChat, false)
end

function GameConsole.onClientOptionChanged(key, value, force, wasClientSettingUp)
  if key == "enableChat" then -- chat toggle
    if value and GameConsole.isChatEnabled() then
      GameConsole.enableChat()
    else
      GameConsole.disableChat()
    end
  elseif key == "showChat" then -- panel toggle
    if value and GameConsole.isChatEnabled() then
      GameConsole.enableChat()
    else
      GameConsole.disableChat()
    end
  end
end

function GameConsole.enableChat()
  if isChatEnabled then return end

  isChatEnabled = true
  consoleTextEdit:setVisible(true)
  consoleTextEdit:setText('')
  consoleTextEdit:enable()

  consoleToggleChat:setTooltip(loc'${GameConsoleChatDisable}')

  GameConsole.onEnableChat()
end

function GameConsole.disableChat()
  if not isChatEnabled then return end

  isChatEnabled = false
  consoleTextEdit:setVisible(false)
  consoleTextEdit:setText('')
  consoleTextEdit:disable()

  consoleToggleChat:setTooltip(loc'${GameConsoleChatEnable}')

  GameConsole.onDisableChat()
end

function GameConsole.isChatEnabled()
  return ClientOptions.getOption("showChat") and ClientOptions.getOption("enableChat")
end

function GameConsole.load()
  local settings = Client.getPlayerSettings('log.console')

  -- Load kept console log after login
  consoleLog = settings:getList('consoleLog') or { }

  GameConsole.loadCommunicationSettings()
end

function GameConsole.save()
  local logSettings = Client.getPlayerSettings('log.console')

  -- Keep console log after logout
  logSettings:setList('consoleLog', consoleLog)
  logSettings:save()

  -- Save last open channels
  local settings = Client.getPlayerSettings()
  local lastChannelsOpen = settings:getNode('lastChannelsOpen') or { }
  local savedChannels = { }
  local set = false
  for channelId, channelName in pairs(channels) do
    if type(channelId) == 'number' then
      savedChannels[channelName] = channelId
      set = true
    end
  end
  if set then
    lastChannelsOpen = savedChannels
  else
    lastChannelsOpen = { }
  end
  settings:setNode('lastChannelsOpen', lastChannelsOpen)
  settings:save()
end

function GameConsole.onTabChange(tabBar, tab)
  if tab == defaultTab or tab == serverTab then
    headerPanel:getChildById('closeChannelButton'):disable()
  else
    headerPanel:getChildById('closeChannelButton'):enable()
  end
end

function GameConsole.clear()
  -- Close channels
  for _, channelName in pairs(channels) do
    local tab = consoleTabBar:getTab(channelName)
    consoleTabBar:removeTab(tab)
  end
  channels = { }

  consoleTabBar:removeTab(defaultTab)
  defaultTab = nil
  consoleTabBar:removeTab(serverTab)
  serverTab = nil

  local npcTab = consoleTabBar:getTab(NpcChannelName)
  if npcTab then
    consoleTabBar:removeTab(npcTab)
    npcTab = nil
  end

  consoleTextEdit:clearText()

  if channelsWindow then
    channelsWindow:destroy()
    channelsWindow = nil
  end
end

function GameConsole.clearChannel()
  local tab = GameConsole.getCurrentTab()
  if not tab then
    return
  end

  tab.tabPanel:getChildById('consoleBuffer'):destroyChildren()

  if tab == clonedTab then
    cloneTab.tabPanel:getChildById('consoleBuffer'):destroyChildren()
  end
end

function GameConsole.setTextEditText(text)
  consoleTextEdit:setText(text)
  consoleTextEdit:setCursorPos(-1)
end

function GameConsole.addTab(name, focus)
  local tab = GameConsole.getTab(name)
  if tab then -- opened already
    if not focus then
      focus = true
    end
  else
    tab = consoleTabBar:addTab(name, nil, GameConsole.processChannelTabMenu)

    tab.onDoubleClick = function(mousePosition)
      GameConsole.toggleClonedTab(tab)
    end
  end

  if focus then
    consoleTabBar:selectTab(tab)
  end

  return tab
end

function GameConsole.removeTab(tab)
  if not tab then
    return
  end

  if type(tab) == 'string' then
    tab = consoleTabBar:getTab(tab)
  end

  if tab == defaultTab or tab == serverTab then
    return
  end

  if tab == clonedTab then
    GameConsole.closeClonedTab(clonedTab)
  end

  if tab.channelId then
    -- notificate the server that we are leaving the channel
    for k in pairs(channels) do
      if k == tab.channelId then
        channels[k] = nil
      end
    end
    g_game.leaveChannel(tab.channelId)
  elseif tab:getText() == NpcChannelName then
    g_game.closeNpcChannel()
  end

  consoleTabBar:removeTab(tab)
end

function GameConsole.removeCurrentTab()
  GameConsole.removeTab(GameConsole.getCurrentTab())
end

function GameConsole.getTab(name)
  return consoleTabBar:getTab(name)
end

function GameConsole.getChannelTab(channelId)
  local channel = channels[channelId]
  if channel then
    return GameConsole.getTab(channel)
  end
  return nil
end

function GameConsole.getCurrentTab()
  return consoleTabBar:getCurrentTab()
end

function GameConsole.addChannel(name, id)
  channels[id] = name
  local tab = GameConsole.addTab(name, focus)
  tab.channelId = id
  return tab
end

function GameConsole.addPrivateChannel(receiver)
  channels[receiver] = receiver
  return GameConsole.addTab(receiver, false)
end

function GameConsole.addPrivateText(text, speaktype, name, isPrivateCommand, creatureName)
  local focus = false
  if speaktype.npcChat then
    name  = NpcChannelName
    focus = true
  end

  local privateTab = GameConsole.getTab(name)
  if privateTab == nil then
    if (ClientOptions.getOption('showPrivateMessagesInConsole') and not focus) or (isPrivateCommand and not privateTab) then
      privateTab = defaultTab
    else
      privateTab = GameConsole.addTab(name, focus)
      channels[name] = name
    end
    privateTab.npcChat = speaktype.npcChat
  elseif focus then
    consoleTabBar:selectTab(privateTab)
  end
  GameConsole.addTabText(text, speaktype, privateTab, creatureName)
end

function GameConsole.addText(text, speaktype, tabName, creatureName)
  local tab = GameConsole.getTab(tabName)
  if tab ~= nil then
    GameConsole.addTabText(text, speaktype, tab, creatureName)
  end
end

-- Return information about start, end in the string and the highlighted words
function GameConsole.getHighlightedText(text)
  local tmpData = { }

  repeat
    local tmp = {string.find(text, '{([^}]+)}', tmpData[#tmpData-1])}
    for _, v in pairs(tmp) do
      table.insert(tmpData, v)
    end
  until not(string.find(text, '{([^}]+)}', tmpData[#tmpData-1]))

  return tmpData
end

function GameConsole.addTabText(text, speaktype, tab, creatureName, clone)
  if not tab or tab.locked or not text or #text == 0 then
    return
  end

  if tab == clonedTab then
    GameConsole.addTabText(text, speaktype, cloneTab, creatureName, true)
  else
    consoleTabBar:blinkTab(tab)
  end

  local lightHour = g_map.getLightHour()
  local h         = math.floor(lightHour / 60)
  local m         = lightHour % 60

  if ClientOptions.getOption('showTimestampsInConsole') then
    text = f('%.2d:%.2d %s', h, m, text)
  end

  local characterName = g_game.getCharacterName()
  local panel = clone and cloneTabBar:getTabPanel(tab) or consoleTabBar:getTabPanel(tab)
  local consoleBuffer = panel:getChildById('consoleBuffer')
  local label = g_ui.createWidget('ConsoleLabel', consoleBuffer)
  label:setId('consoleLabel' .. consoleBuffer:getChildCount())
  label:setText(text)
  label:setColor(speaktype.color)
  label.highlightWords = { }

  -- Overlay for consoleBuffer which shows highlighted words only

  if speaktype.npcChat and (characterName ~= creatureName or characterName == 'Account Manager') then
    local highlightData = GameConsole.getHighlightedText(text)

    -- Rich text messages only for non highlighted messages, as highlights are based on text positions and rich text can change them
    label:setTextRich(#highlightData < 1)

    if #highlightData > 0 then
      local labelHighlight = g_ui.createWidget('ConsolePhantomLabel', label)
      labelHighlight:fill('parent')

      labelHighlight:setId('consoleLabelHighlight' .. consoleBuffer:getChildCount())
      labelHighlight:setColor('#1f9ffe')

      -- Remove the curly braces
      for i = 1, #highlightData / 3 do
        local dataBlock = { _start = highlightData[(i - 1) * 3 + 1], _end = highlightData[(i - 1) * 3 + 2], words = highlightData[(i - 1) * 3 + 3] }
        text = text:gsub('%{(.-)%}', dataBlock.words, 1)

        -- Recalculate positions as braces are removed
        highlightData[(i - 1) * 3 + 1] = dataBlock._start - ((i - 1) * 2)
        highlightData[(i - 1) * 3 + 2] = dataBlock._end - (1 + (i - 1) * 2)
      end
      label:setText(text)

      -- Calculate the positions of the highlighted text and fill with string.char(127) [Width: 1]
      local drawText = label:getDrawText()
      local tmpText = ''
      for i = 1, #highlightData / 3 do
        local dataBlock = { _start = highlightData[(i - 1) * 3 + 1], _end = highlightData[(i - 1) * 3 + 2], words = highlightData[(i - 1) * 3 + 3] }
        local lastBlockEnd = (highlightData[(i - 2) * 3 + 2] or 1)

        for letter = lastBlockEnd, dataBlock._start - 1 do
          local tmpChar = string.byte(drawText:sub(letter, letter))
          local fillChar = (tmpChar == 10 or tmpChar == 32) and string.char(tmpChar) or string.char(127)

          tmpText = tmpText .. string.rep(fillChar, letterWidth[tmpChar])
        end
        tmpText = tmpText .. dataBlock.words
      end

      -- Fill the highlight label to the same size as default label
      local finalBlockEnd = (highlightData[(#highlightData / 3 - 1) * 3 + 2] or 1)
      for letter = finalBlockEnd, #drawText do
          local tmpChar = string.byte(drawText:sub(letter, letter))
          local fillChar = (tmpChar == 10 or tmpChar == 32) and string.char(tmpChar) or string.char(127)

          tmpText = tmpText .. string.rep(fillChar, letterWidth[tmpChar])
      end
      for i = 1, #highlightData, 3 do
        table.insert(label.highlightWords, { start = highlightData[i], last = highlightData[i + 1], word = highlightData[i + 2] } )
      end
      labelHighlight:setText(tmpText)
    end
  end

  label.name = creatureName
  consoleBuffer.onMouseRelease = function(self, mousePos, mouseButton)
    GameConsole.processMessageMenu(mousePos, mouseButton, nil, nil, nil, tab)
  end

  label.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
      local charPos = self:getTextPos(mousePos)
      for _, highlight in ipairs(self.highlightWords) do
        if charPos >= highlight.start and charPos < highlight.last then
          GameConsole.sendMessage(highlight.word)
          break
        end
      end
    elseif mouseButton == MouseRightButton then
      GameConsole.processMessageMenu(mousePos, mouseButton, creatureName, text, self, tab)
    end
  end

  label.onMousePress = function(self, mousePos, button)
    if button == MouseLeftButton then
      GameConsole.clearSelection(consoleBuffer)
    end
  end

  label.onDragEnter = function(self, mousePos)
    GameConsole.clearSelection(consoleBuffer)
    return true
  end

  label.onDragLeave = function(self, droppedWidget, mousePos)
    local text = { }
    if consoleBuffer.selection then
      for selectionChild = consoleBuffer.selection.first, consoleBuffer.selection.last do
        local label = self:getParent():getChildByIndex(selectionChild)
        table.insert(text, label:getSelection())
      end
    end
    consoleBuffer.selectionText = table.concat(text, '\n')
    return true
  end

  label.onDragMove = function(self, mousePos, mouseMoved)
    local parent = self:getParent()
    local parentRect = parent:getPaddingRect()
    local selfIndex = parent:getChildIndex(self)
    local child = parent:getChildByPos(mousePos)

    -- find bonding children
    if not child then
      if mousePos.y < self:getY() then
        for index = selfIndex - 1, 1, -1 do
          local label = parent:getChildByIndex(index)
          if label:getY() + label:getHeight() > parentRect.y then
            if (mousePos.y >= label:getY() and mousePos.y <= label:getY() + label:getHeight()) or index == 1 then
              child = label
              break
            end
          else
            child = parent:getChildByIndex(index + 1)
            break
          end
        end
      elseif mousePos.y > self:getY() + self:getHeight() then
        for index = selfIndex + 1, parent:getChildCount(), 1 do
          local label = parent:getChildByIndex(index)
          if label:getY() < parentRect.y + parentRect.height then
            if (mousePos.y >= label:getY() and mousePos.y <= label:getY() + label:getHeight()) or index == parent:getChildCount() then
              child = label
              break
            end
          else
            child = parent:getChildByIndex(index - 1)
            break
          end
        end
      else
        child = self
      end
    end

    if not child then
      return false
    end

    local childIndex = parent:getChildIndex(child)

    -- remove old selection
    GameConsole.clearSelection(consoleBuffer)

    -- update self selection
    local textBegin = self:getTextPos(self:getLastClickPosition())
    local textPos = self:getTextPos(mousePos)
    self:setSelection(textBegin, textPos)

    consoleBuffer.selection = { first = math.min(selfIndex, childIndex), last = math.max(selfIndex, childIndex) }

    -- update siblings selection
    if child ~= self then
      for selectionChild = consoleBuffer.selection.first + 1, consoleBuffer.selection.last - 1 do
        parent:getChildByIndex(selectionChild):selectAll()
      end

      local textPos = child:getTextPos(mousePos)
      if childIndex > selfIndex then
        child:setSelection(0, textPos)
      else
        child:setSelection(string.len(child:getText()), textPos)
      end
    end

    return true
  end

  if consoleBuffer:getChildCount() > MAX_LINES then
    local child = consoleBuffer:getFirstChild()
    GameConsole.clearSelection(consoleBuffer)
    child:destroy()
  end
end

function GameConsole.removeTabLabelByName(tab, name)
  local panel = consoleTabBar:getTabPanel(tab)
  local consoleBuffer = panel:getChildById('consoleBuffer')
  for _,label in pairs(consoleBuffer:getChildren()) do
    if label.name == name then
      label:destroy()
    end
  end
end

function GameConsole.openClonedTab(tab)
  if not tab then
    return
  end

  if clonedTab then
    if clonedTab == tab then
      return false
    else -- keep only one open
      GameConsole.closeClonedTab()
    end
  end

  clonedTab = tab
  cloneTab = cloneTabBar:addTab(tab:getText(), nil, GameConsole.processCloneTabMenu)

  cloneTab.onDoubleClick = function()
    GameConsole.closeClonedTab()
  end

  cloneTab:setTooltip(loc'${GameConsoleCloseTabTip}')

  cloneTabSeparator:setOn(true)
  cloneTabTipArea:setOn(true)
  cloneTabBar:setWidth(cloneTab:getWidth()) -- Set tab bar width according to clone tab
  consoleContentPanel:setOn(true)

  clonedSplitter:show()
  clonedSplitter:setMarginRight(g_settings.getNumber('clonedSplitter', contentPanel:getWidth() / 2))
  function clonedSplitter:onDoubleClick(mousePosition)
    self.currentMargin = contentPanel:getWidth() / 2
    self:setMarginRight(self.currentMargin)
  end

  GameConsole.cloneMessages(tab, cloneTab)

  return true
end

function GameConsole.closeClonedTab()
  if not clonedTab or not cloneTab then
    return
  end
  g_settings.set('clonedSplitter', clonedSplitter.currentMargin)

  cloneTabBar:removeTab(cloneTab)

  cloneTabSeparator:setOn(false)
  cloneTabTipArea:setOn(false)
  cloneTabBar:setWidth(0) -- Hide tab bar
  consoleContentPanel:setOn(false)

  clonedSplitter:setMarginRight(0)
  clonedSplitter:hide()
  cloneTab = nil
  clonedTab = nil
end

function GameConsole.toggleClonedTab(tab)
  if not tab then
    return
  end

  if clonedTab == tab then
    GameConsole.closeClonedTab()
  else
    GameConsole.openClonedTab(tab)
  end
end

function GameConsole.cloneMessages(fromTab, toTab)
  local fromBuffer = consoleTabBar:getTabPanel(fromTab):getChildById('consoleBuffer')
  local toBuffer = cloneTabBar:getTabPanel(toTab):getChildById('consoleBuffer')
  for _, label in ipairs(fromBuffer:getChildren()) do
    local cloneLabel = g_ui.createWidget('ConsoleLabel', toBuffer)
    cloneLabel:setId('consoleLabel' .. toBuffer:getChildCount())
    cloneLabel:setText(label:getText())
    cloneLabel:setColor(label:getColor())
    cloneLabel.name = label.name
    cloneLabel.onMouseRelease = label.onMouseRelease
    cloneLabel.onMousePress = label.onMousePress
    cloneLabel.onDragEnter = label.onDragEnter
    cloneLabel.onDragLeave = label.onDragLeave
    cloneLabel.onDragMove = label.onDragMove
  end
end

function GameConsole.processChannelTabMenu(tab, mousePos, mouseButton)
  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  channelName = tab:getText()
  if tab ~= defaultTab and tab ~= serverTab then
    menu:addOption(loc'${CorelibInfoClose}', function() GameConsole.removeTab(channelName) end)
    --menu:addOption(loc'${GameConsoleTabServerMsgs}', function() --[[TODO]] end)
    menu:addSeparator()
  end

  local _tab = GameConsole.getCurrentTab()
  if _tab and _tab == tab then
    menu:addOption(loc'${GameConsoleTabClearMsgs}', function() GameConsole.clearChannel() end)
    menu:addOption(loc'${GameConsoleTabSaveMsgs}', function()
      local panel = consoleTabBar:getTabPanel(tab)
      local consoleBuffer = panel:getChildById('consoleBuffer')
      local lines = { }
      for _,label in pairs(consoleBuffer:getChildren()) do
        table.insert(lines, label:getText())
      end

      local characterName = g_game.getCharacterName()
      local filename = characterName .. ' - ' .. channelName .. '.txt'
      local filepath = '/' .. filename

      -- extra information at the beginning
      table.insert(lines, 1, f(loc'\n${GameConsoleTabSavedAt}', os.date('%a %b %d %H:%M:%S %Y')))

      if g_resources.fileExists(filepath) then
        table.insert(lines, 1, protectedcall(g_resources.readFileContents, filepath) or '')
      end

      g_resources.writeFileContents(filepath, table.concat(lines, '\n'))
      if modules.game_textmessage then
        GameTextMessage.displayStatusMessage(f(loc'${GameConsoleTabAppendedTo}', filename))
      end
    end)

    menu:addSeparator()
    if clonedTab == tab then
      menu:addOption(loc'${GameConsoleTabCloneClose}', function() GameConsole.closeClonedTab() end)
    else
      menu:addOption(loc'${GameConsoleTabClone}', function() GameConsole.openClonedTab(GameConsole.getCurrentTab()) end)
    end
  end

  menu:display(mousePos)
end

function GameConsole.processMessageMenu(mousePos, mouseButton, creatureName, text, label, tab)
  local localPlayer = g_game.getLocalPlayer()
  if mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    if creatureName and #creatureName > 0 then
      if creatureName ~= g_game.getCharacterName() then
        menu:addOption(f(loc'${GameConsoleMessageTo}', creatureName), function () g_game.openPrivateChannel(creatureName) end)
        if not localPlayer:hasVip(creatureName) then
          menu:addOption(loc'${GameConsoleAddVIP}', function () g_game.addVip(creatureName) end)
        end
        if GameConsole.getOwnPrivateTab() then
          menu:addSeparator()
          menu:addOption(loc'${GameConsoleInviteToChat}', function() g_game.inviteToOwnChannel(creatureName) end)
          menu:addOption(loc'${GameConsoleExcludeFromChat}', function() g_game.excludeFromOwnChannel(creatureName) end)
        end
        if GameConsole.isIgnored(creatureName) then
          menu:addOption(f(loc'${GameConsoleUnignore}', creatureName), function() GameConsole.removeIgnoredPlayer(creatureName) end)
        else
          menu:addOption(f(loc'${GameConsoleIgnore}', creatureName), function() GameConsole.addIgnoredPlayer(creatureName) end)
        end
        menu:addSeparator()

        if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
          menu:addOption(loc'${GameConsoleAddRuleViolation}', function() if modules.game_ruleviolation then GameRuleViolation.showViewWindow(creatureName, text:sub(0, 255)) end end)
        end

        local REPORT_TYPE_STATEMENT = 1
        menu:addOption(loc'${GameConsoleReportStatement}', function() if modules.game_ruleviolation then GameRuleViolation.showRuleViolationReportWindow(REPORT_TYPE_STATEMENT, creatureName, text:match('.+%:%s(.+)')) end end)
        menu:addSeparator()
      end
    end

    local selection = tab.tabPanel:getChildById('consoleBuffer').selectionText
    if selection and #selection > 0 then
      menu:addOption(loc'${GameConsoleCopy}', function() g_window.setClipboardText(selection) end, '(Ctrl+C)')
    end
    if text then
      menu:addOption(loc'${GameConsoleCopyMsg}', function() g_window.setClipboardText(text) end)
    end
    if creatureName and #creatureName > 0 then
      menu:addOption(loc'${GameConsoleCopyName}', function () g_window.setClipboardText(creatureName) end)
    end
    menu:addOption(loc'${GameConsoleSelectAll}', function() GameConsole.selectAll(tab.tabPanel:getChildById('consoleBuffer')) end)
    menu:display(mousePos)
  end
end

function GameConsole.processCloneTabMenu(tab, mousePos, mouseButton)
  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  menu:addOption(loc'${GameConsoleTabCloneClose}', function() GameConsole.closeClonedTab() end)

  menu:display(mousePos)
end

function GameConsole.onEnterKeyDown()
  local message = consoleTextEdit:getText()

  if #message == 0 then
    ClientOptions.setOption('enableChat', not ClientOptions.getOption('enableChat'))
    return
  end

  if #message > 0 then
    GameConsole.sendMessage(message)

    if ClientOptions.getOption('autoDisableChatOnSendMessage') then
      ClientOptions.setOption('enableChat', false)
    end
  end

  consoleTextEdit:clearText()
end

function GameConsole.addFilter(filter)
  table.insert(filters, filter)
end

function GameConsole.removeFilter(filter)
  table.removevalue(filters, filter)
end

function GameConsole.sendMessage(message, tab)
  local tab = tab or GameConsole.getCurrentTab()
  if not tab then
    return false -- No filter results
  end

  for k,func in pairs(filters) do
    if func(message) then
      return true -- Filter worked
    end
  end

  local localPlayer = g_game.getLocalPlayer()

  -- when talking on server log, the message goes to default channel
  local name = tab:getText()
  if tab == serverTab then
    tab = defaultTab
    name = defaultTab:getText()
  end

  -- handling chat commands
  local channel = tab.channelId
  local originalMessage = message
  local chatCommandSayMode
  local chatCommandPrivate
  local chatCommandPrivateReady
  local chatCommandMessage

  -- player used yell command
  chatCommandMessage = message:match('^%#%w*[y|Y]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'yell'
    channel = 0
    message = chatCommandMessage
  end

   -- player used whisper
  chatCommandMessage = message:match('^%#%w*[w|W]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'whisper'
    message = chatCommandMessage
    channel = 0
  end

  -- player say
  chatCommandMessage = message:match('^%#%w*[s|S]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'say'
    message = chatCommandMessage
    channel = 0
  end

  -- player red talk on channel
  chatCommandMessage = message:match('^%#%w*[c|C]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'channelRed'
    message = chatCommandMessage
  end

  -- player broadcast
  chatCommandMessage = message:match('^%#%w*[b|B]%w* (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'broadcast'
    message = chatCommandMessage
    channel = 0
  end

  local findIni, findEnd, chatCommandInitial, chatCommandPrivate, chatCommandEnd, chatCommandMessage = message:find('([%*%@])(.+)([%*%@])(.*)')
  if findIni ~= nil and findIni == 1 then -- player used private chat command
    if chatCommandInitial == chatCommandEnd then
      chatCommandPrivateRepeat = false
      if chatCommandInitial == '*' then
        GameConsole.setTextEditText('*'.. chatCommandPrivate .. '* ')
      end
      message = chatCommandMessage:trim()
      chatCommandPrivateReady = true
    end
  end

  message = message:gsub('^(%s*)(.*)', '%2') -- remove space characters from message init
  if #message == 0 then
    return false -- No filter results
  end

  -- Add new command to console log
  currentMessageIndex = 0
  if table.empty(consoleLog) or consoleLog[#consoleLog] ~= originalMessage then -- Empty or last message is different to sent message
    table.insert(consoleLog, originalMessage)
    -- If is full, remove first
    if #consoleLog > MAX_LOGLINES then
      table.remove(consoleLog, 1)
    end
  end

  local speaktypedesc
  if (channel or tab == defaultTab) and not chatCommandPrivateReady then
    if tab == defaultTab then
      speaktypedesc = chatCommandSayMode or SayModes[footerPanel:getChildById('sayModeButton').sayMode].speakTypeDesc
      if speaktypedesc ~= 'say' then -- head back to say mode
        GameConsole.sayModeChange(2)
      end
    else
      speaktypedesc = chatCommandSayMode or 'channelYellow'
    end

    g_game.talkChannel(SpeakTypesSettings[speaktypedesc].speakType, channel, message)

  else
    local isPrivateCommand = false
    local priv = true
    local tabname = name
    if chatCommandPrivateReady then
      speaktypedesc = 'privatePlayerToPlayer'
      name = chatCommandPrivate
      isPrivateCommand = true
    elseif tab.npcChat then
      speaktypedesc = 'privatePlayerToNpc'
    else
      speaktypedesc = 'privatePlayerToPlayer'
    end

    local speaktype = SpeakTypesSettings[speaktypedesc]
    g_game.talkPrivate(speaktype.speakType, name, message)

    message = GameConsole.applyMessagePrefixies(g_game.getCharacterName(), localPlayer:getLevel(), message)
    GameConsole.addPrivateText(message, speaktype, tabname, isPrivateCommand, g_game.getCharacterName())
  end

  return false -- No filter results
end

function GameConsole.sayModeChange(sayMode)
  local button = footerPanel:getChildById('sayModeButton')
  if sayMode == nil then
    sayMode = button.sayMode + 1
  end

  if sayMode > #SayModes then
    sayMode = 1
  end

  button:setIcon(SayModes[sayMode].icon)
  button.sayMode = sayMode
end

function GameConsole.getOwnPrivateTab()
  if not ownPrivateName then
    return
  end

  return GameConsole.getTab(ownPrivateName)
end

function GameConsole.setIgnoreNpcMessages(ignore)
  ignoreNpcMessages = ignore
end

function GameConsole.navigateConsoleLog(step)
  if not GameConsole.isChatEnabled() then
    return
  end

  local numCommands = #consoleLog
  if numCommands > 0 then
    currentMessageIndex = math.min(math.max(currentMessageIndex + step, 0), numCommands)
    if currentMessageIndex > 0 then
      local command = consoleLog[numCommands - currentMessageIndex + 1]
      GameConsole.setTextEditText(command)
    else
      consoleTextEdit:clearText()
    end
  end
end

function GameConsole.applyMessagePrefixies(name, level, message)
  if name and #name > 0 then
    if ClientOptions.getOption('showLevelsInConsole') and level > 0 then
      message = '[' .. level .. '] ' .. name .. ': ' .. message
    else
      message = name .. ': ' .. message
    end
  end
  return message
end

function GameConsole.onTalk(name, level, mode, message, channelId, creaturePos)
  if mode == MessageModes.GamemasterBroadcast then
    if modules.game_textmessage then
      GameTextMessage.displayBroadcastMessage(name .. ': ' .. message)
    end
    return
  end

  local isNpcMode = (mode == MessageModes.NpcFromStartBlock or mode == MessageModes.NpcFrom)

  if ignoreNpcMessages and isNpcMode then
    return
  end

  speaktype = SpeakTypes[mode]

  if not speaktype then
    perror(f(loc'${GameConsoleErrorUnhandledMsgMode}: %s', mode, message))
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if name ~= g_game.getCharacterName()
      and GameConsole.isUsingIgnoreList()
        and not(GameConsole.isUsingWhiteList()) or (GameConsole.isUsingWhiteList() and not(GameConsole.isWhitelisted(name)) and not(GameConsole.isAllowingVIPs() and localPlayer:hasVip(name))) then

    if mode == MessageModes.Yell and GameConsole.isIgnoringYelling() then
      return
    elseif speaktype.private and GameConsole.isIgnoringPrivate() and not isNpcMode then
      return
    elseif GameConsole.isIgnored(name) then
      return
    end
  end

  if (mode == MessageModes.Say or mode == MessageModes.GamemasterSay or mode == MessageModes.Whisper or mode == MessageModes.Yell or
      mode == MessageModes.Spell or
      mode == MessageModes.NpcFrom or mode == MessageModes.BarkLow or mode == MessageModes.BarkLoud or
      mode == MessageModes.NpcFromStartBlock) and creaturePos
  then
    local staticText = StaticText.create()
    -- Remove curly braces from screen message
    local staticMessage = message
    if isNpcMode then
      local highlightData = GameConsole.getHighlightedText(staticMessage)

      -- Rich text messages only for non highlighted messages, as highlights are based on text positions and rich text can change them
      staticText:setTextRich(#highlightData < 1)

      if #highlightData > 0 then
        for i = 1, #highlightData / 3 do
          local dataBlock = { _start = highlightData[(i - 1) * 3 + 1], _end = highlightData[(i - 1) * 3 + 2], words = highlightData[(i - 1) * 3 + 3] }
          staticMessage = staticMessage:gsub('{'..dataBlock.words..'}', dataBlock.words)
        end
      end
    end

    if speaktype.color then
      staticText:setColor(speaktype.color)
    end
    staticText:addMessage(name, mode, staticMessage)
    g_map.addStaticText(staticText, creaturePos)
  end

  local defaultMessage = mode <= 3 or mode == MessageModes.GamemasterSay

  if speaktype == SpeakTypesSettings.none then
    return
  end

  if speaktype.hideInConsole then
    return
  end

  local composedMessage = GameConsole.applyMessagePrefixies(name, level, message)

  if speaktype.private then
    local tab     = GameConsole.getCurrentTab()
    local tabText = tab:getText()

    GameConsole.addPrivateText(composedMessage, speaktype, name, false, name)

    -- Current tab is not from the player that you received the message
    if tabText ~= name and (not clonedTab or clonedTab:getText() ~= name) and speaktype ~= SpeakTypesSettings.privateNpcToPlayer then
      g_sounds.getChannel(AudioChannels.Gui):play(f('%s/msg_private.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)

      if ClientOptions.getOption('showPrivateMessagesOnScreen') and modules.game_textmessage then
        GameTextMessage.displayPrivateMessage(f('%s:\n%s', name, message))
      end
    end

  else
    local channel = loc'${CorelibInfoDefault}'
    if not defaultMessage then
      channel = channels[channelId]

      -- If Loot tab is closed, send loot messages to Server tab
      if not channel and channelId == CHANNEL_ID_LOOT then
        channel = serverTab:getText()
      end
    end

    if channel then
      GameConsole.addText(composedMessage, speaktype, channel, name)
    else
      -- server sent a message on a channel that is not open
      pwarning(f(loc'${GameConsoleUnknownMsg}', channelId))
    end
  end
end

function GameConsole.onOpenChannel(channelId, channelName)
  GameConsole.addChannel(channelName, channelId)
end

function GameConsole.onOpenPrivateChannel(receiver)
  GameConsole.addPrivateChannel(receiver)
end

function GameConsole.onOpenOwnPrivateChannel(channelId, channelName)
  local privateTab = GameConsole.getTab(channelName)
  if privateTab == nil then
    GameConsole.addChannel(channelName, channelId)
  end
  ownPrivateName = channelName
end

function GameConsole.onCloseChannel(channelId)
  local channel = channels[channelId]
  if channel then
    local tab = GameConsole.getTab(channel)
    if tab then
      consoleTabBar:removeTab(tab)
      for k, _ in pairs(channels) do
        if (k == tab.channelId) then
          channels[k] = nil
        end
      end
    end
  end
end

function GameConsole.doChannelListSubmit()
  local channelListPanel = channelsWindow:getChildById('channelList')
  local openPrivateChannelWith = channelsWindow:getChildById('openPrivateChannelWith'):getText()
  if openPrivateChannelWith ~= '' then
    if openPrivateChannelWith:lower() ~= g_game.getCharacterName():lower() then
      g_game.openPrivateChannel(openPrivateChannelWith)
    else
      if modules.game_textmessage then
        GameTextMessage.displayFailureMessage(loc'${GameConsoleChatWithYourself}')
      end
    end
  else
    local selectedChannelLabel = channelListPanel:getFocusedChild()
    if not selectedChannelLabel then
      return
    end

    if selectedChannelLabel.channelId == 0xFFFF then
      g_game.openOwnChannel()
    else
      g_game.joinChannel(selectedChannelLabel.channelId)
    end
  end

  channelsWindow:destroy()
end

function GameConsole.onChannelList(channelList)
  if channelsWindow then
    channelsWindow:destroy()
  end

  channelsWindow = g_ui.displayUI('channelswindow')
  local channelListPanel = channelsWindow:getChildById('channelList')
  channelsWindow.onEnter = GameConsole.doChannelListSubmit
  channelsWindow.onDestroy = function() channelsWindow = nil end
  g_keyboard.bindKeyPress('Down', function() channelListPanel:focusNextChild(KeyboardFocusReason) end, channelsWindow)
  g_keyboard.bindKeyPress('Up', function() channelListPanel:focusPreviousChild(KeyboardFocusReason) end, channelsWindow)

  for k,v in pairs(channelList) do
    local channelId = v[1]
    local channelName = v[2]

    if #channelName > 0 then
      local label = g_ui.createWidget('ChannelListLabel', channelListPanel)
      label.channelId = channelId
      label:setText(channelName)

      label:setPhantom(false)
      label.onDoubleClick = GameConsole.doChannelListSubmit
    end
  end
end

function GameConsole.loadCommunicationSettings()
  communicationSettings.whitelistedPlayers = { }
  communicationSettings.ignoredPlayers = { }

  local ignoreNode = g_settings.getNode('IgnorePlayers')
  if ignoreNode then
    for _, player in pairs(ignoreNode) do
      table.insert(communicationSettings.ignoredPlayers, player)
    end
  end

  local whitelistNode = g_settings.getNode('WhitelistedPlayers')
  if whitelistNode then
    for _, player in pairs(whitelistNode) do
      table.insert(communicationSettings.whitelistedPlayers, player)
    end
  end

  communicationSettings.useIgnoreList = g_settings.getBoolean('UseIgnoreList')
  communicationSettings.useWhiteList = g_settings.getBoolean('UseWhiteList')
  communicationSettings.privateMessages = g_settings.getBoolean('IgnorePrivateMessages')
  communicationSettings.yelling = g_settings.getBoolean('IgnoreYelling')
  communicationSettings.allowVIPs = g_settings.getBoolean('AllowVIPs')
end

function GameConsole.saveCommunicationSettings()
  local tmpIgnoreList = { }
  local ignoredPlayers = GameConsole.getIgnoredPlayers()
  for i = 1, #ignoredPlayers do
    table.insert(tmpIgnoreList, ignoredPlayers[i])
  end

  local tmpWhiteList = { }
  local whitelistedPlayers = GameConsole.getWhitelistedPlayers()
  for i = 1, #whitelistedPlayers do
    table.insert(tmpWhiteList, whitelistedPlayers[i])
  end

  g_settings.set('UseIgnoreList', communicationSettings.useIgnoreList)
  g_settings.set('UseWhiteList', communicationSettings.useWhiteList)
  g_settings.set('IgnorePrivateMessages', communicationSettings.privateMessages)
  g_settings.set('IgnoreYelling', communicationSettings.yelling)
  g_settings.setNode('IgnorePlayers', tmpIgnoreList)
  g_settings.setNode('WhitelistedPlayers', tmpWhiteList)
end

function GameConsole.getIgnoredPlayers()
  return communicationSettings.ignoredPlayers
end

function GameConsole.getWhitelistedPlayers()
  return communicationSettings.whitelistedPlayers
end

function GameConsole.isUsingIgnoreList()
  return communicationSettings.useIgnoreList
end

function GameConsole.isUsingWhiteList()
  return communicationSettings.useWhiteList
end

function GameConsole.isIgnored(name)
  return table.find(communicationSettings.ignoredPlayers, name, true)
end

function GameConsole.addIgnoredPlayer(name)
  if GameConsole.isIgnored(name) then
    return
  end

  table.insert(communicationSettings.ignoredPlayers, name)
end

function GameConsole.removeIgnoredPlayer(name)
  table.removevalue(communicationSettings.ignoredPlayers, name)
end

function GameConsole.isWhitelisted(name)
  return table.find(communicationSettings.whitelistedPlayers, name, true)
end

function GameConsole.addWhitelistedPlayer(name)
  if GameConsole.isWhitelisted(name) then
    return
  end

  table.insert(communicationSettings.whitelistedPlayers, name)
end

function GameConsole.removeWhitelistedPlayer(name)
  table.removevalue(communicationSettings.whitelistedPlayers, name)
end

function GameConsole.isIgnoringPrivate()
  return communicationSettings.privateMessages
end

function GameConsole.isIgnoringYelling()
  return communicationSettings.yelling
end

function GameConsole.isAllowingVIPs()
  return communicationSettings.allowVIPs
end

function GameConsole.onClickIgnoreButton()
  if communicationWindow then
    return
  end

  communicationWindow = g_ui.displayUI('communicationwindow')
  local ignoreListPanel = communicationWindow:getChildById('ignoreList')
  local whiteListPanel = communicationWindow:getChildById('whiteList')
  communicationWindow.onDestroy = function() communicationWindow = nil end

  local useIgnoreListBox = communicationWindow:getChildById('checkboxUseIgnoreList')
  useIgnoreListBox:setChecked(communicationSettings.useIgnoreList)
  local useWhiteListBox = communicationWindow:getChildById('checkboxUseWhiteList')
  useWhiteListBox:setChecked(communicationSettings.useWhiteList)

  local removeIgnoreButton = communicationWindow:getChildById('buttonIgnoreRemove')
  removeIgnoreButton:disable()
  ignoreListPanel.onChildFocusChange = function() removeIgnoreButton:enable() end
  removeIgnoreButton.onClick = function()
    local selection = ignoreListPanel:getFocusedChild()
    if selection then
      ignoreListPanel:removeChild(selection)
      selection:destroy()
    end
    removeIgnoreButton:disable()
  end

  local removeWhitelistButton = communicationWindow:getChildById('buttonWhitelistRemove')
  removeWhitelistButton:disable()
  whiteListPanel.onChildFocusChange = function() removeWhitelistButton:enable() end
  removeWhitelistButton.onClick = function()
    local selection = whiteListPanel:getFocusedChild()
    if selection then
      whiteListPanel:removeChild(selection)
      selection:destroy()
    end
    removeWhitelistButton:disable()
  end

  local newlyIgnoredPlayers = { }
  local addIgnoreName = communicationWindow:getChildById('ignoreNameEdit')
  local addIgnoreButton = communicationWindow:getChildById('buttonIgnoreAdd')
  local addIgnoreFunction = function()
      local newEntry = addIgnoreName:getText()
      if newEntry == '' then
        return
      end

      if table.find(GameConsole.getIgnoredPlayers(), newEntry) then
        return
      end

      if table.find(newlyIgnoredPlayers, newEntry) then
        return
      end

      local label = g_ui.createWidget('IgnoreListLabel', ignoreListPanel)
      label:setText(newEntry)
      table.insert(newlyIgnoredPlayers, newEntry)
      addIgnoreName:setText('')
    end
  addIgnoreButton.onClick = addIgnoreFunction

  local newlyWhitelistedPlayers = { }
  local addWhitelistName = communicationWindow:getChildById('whitelistNameEdit')
  local addWhitelistButton = communicationWindow:getChildById('buttonWhitelistAdd')
  local addWhitelistFunction = function()
      local newEntry = addWhitelistName:getText()
      if newEntry == '' then
        return
      end

      if table.find(GameConsole.getWhitelistedPlayers(), newEntry) then
        return
      end

      if table.find(newlyWhitelistedPlayers, newEntry) then
        return
      end

      local label = g_ui.createWidget('WhiteListLabel', whiteListPanel)
      label:setText(newEntry)
      table.insert(newlyWhitelistedPlayers, newEntry)
      addWhitelistName:setText('')
    end
  addWhitelistButton.onClick = addWhitelistFunction

  communicationWindow.onEnter = function()
      if addWhitelistName:isFocused() then
        addWhitelistFunction()
      elseif addIgnoreName:isFocused() then
        addIgnoreFunction()
      end
    end

  local ignorePrivateMessageBox = communicationWindow:getChildById('checkboxIgnorePrivateMessages')
  ignorePrivateMessageBox:setChecked(communicationSettings.privateMessages)
  local ignoreYellingBox = communicationWindow:getChildById('checkboxIgnoreYelling')
  ignoreYellingBox:setChecked(communicationSettings.yelling)
  local allowVIPsBox = communicationWindow:getChildById('checkboxAllowVIPs')
  allowVIPsBox:setChecked(communicationSettings.allowVIPs)

  local saveButton = communicationWindow:recursiveGetChildById('buttonSave')
  saveButton.onClick = function()
      communicationSettings.ignoredPlayers = { }
      for i = 1, ignoreListPanel:getChildCount() do
        GameConsole.addIgnoredPlayer(ignoreListPanel:getChildByIndex(i):getText())
      end

      communicationSettings.whitelistedPlayers = { }
      for i = 1, whiteListPanel:getChildCount() do
        GameConsole.addWhitelistedPlayer(whiteListPanel:getChildByIndex(i):getText())
      end

      communicationSettings.useIgnoreList = useIgnoreListBox:isChecked()
      communicationSettings.useWhiteList = useWhiteListBox:isChecked()
      communicationSettings.yelling = ignoreYellingBox:isChecked()
      communicationSettings.privateMessages = ignorePrivateMessageBox:isChecked()
      communicationSettings.allowVIPs = allowVIPsBox:isChecked()
      communicationWindow:destroy()
    end

  local cancelButton = communicationWindow:recursiveGetChildById('buttonCancel')
  cancelButton.onClick = function()
      communicationWindow:destroy()
    end

  local ignoredPlayers = GameConsole.getIgnoredPlayers()
  for i = 1, #ignoredPlayers do
    local label = g_ui.createWidget('IgnoreListLabel', ignoreListPanel)
    label:setText(ignoredPlayers[i])
  end

  local whitelistedPlayers = GameConsole.getWhitelistedPlayers()
  for i = 1, #whitelistedPlayers do
    local label = g_ui.createWidget('WhiteListLabel', whiteListPanel)
    label:setText(whitelistedPlayers[i])
  end
end

function GameConsole.online()
  defaultTab = GameConsole.addTab(loc'${CorelibInfoDefault}', true)
  serverTab = GameConsole.addTab(loc'${GameConsoleTabNameServer}', false) -- Server Log

  -- Open last channels
  local settings = Client.getPlayerSettings()
  for _, channelId in pairs(settings:getNode('lastChannelsOpen') or { }) do
    channelId = tonumber(channelId)
    if channelId ~= -1 and not table.find(channels, channelId) then
      g_game.joinChannel(channelId)
    end
  end

  GameConsole.load()
end

function GameConsole.offline()
  GameConsole.closeClonedTab()
  GameConsole.save()
  GameConsole.clear()
end

function GameConsole.onChannelEvent(channelId, name, type)
  local fmt = ChannelEventFormats[type]
  if not fmt then
    print(f(loc'${GameConsoleUnknownChatEventType}', type))
    return
  end

  local channel = channels[channelId]
  if channel then
    local tab = GameConsole.getTab(channel)
    if tab then
      GameConsole.addTabText(f(fmt, name), SpeakTypesSettings.channelOrange, tab)
    end
  end
end

function GameConsole.getConsolePanel()
  return consolePanel
end

function GameConsole.getHeaderPanel()
  return headerPanel
end

function GameConsole.getContentPanel()
  return contentPanel
end

function GameConsole.getFooterPanel()
  return footerPanel
end

function GameConsole.greetNpc(npc)
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeGreetNpc)

  msg:addU32(npc:getId())

  protocolGame:send(msg)
end
