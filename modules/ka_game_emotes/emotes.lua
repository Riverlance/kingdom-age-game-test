_G.GameEmotes = { }



local emoteList = nil
local emoteListByIndex = nil
local emoteWindow = nil
local consoleEmoteButton = nil

local EmoteDisable = 0
local EmoteEnable  = 1



function GameEmotes.init()
  if not GameConsole then
    return
  end

  local contentPanel = GameConsole.getContentPanel()
  if not contentPanel then
    return
  end

  -- Alias
  GameEmotes.m = modules.ka_game_emotes

  emoteList        = { }
  emoteListByIndex = { }

  emoteWindow = g_ui.loadUI('emoteWindow', contentPanel)
  GameEmotes.toggleWindow(false)
  GameEmotes.setupEmotes()
  GameEmotes.onResizeConsole(contentPanel)

  local headerPanel     = GameConsole.getHeaderPanel()
  local prevButton      = headerPanel:getChildById('channelsButton')
  local prevButtonIndex = headerPanel:getChildIndex(prevButton)
  consoleEmoteButton    = g_ui.createWidget('EmoteWindowButton', headerPanel)

  headerPanel:moveChildToIndex(consoleEmoteButton, prevButtonIndex)

  connect(g_game, {
    onGameStart = GameEmotes.online,
    onGameEnd   = GameEmotes.offline,
  })
  connect(contentPanel, {
    onGeometryChange = GameEmotes.onResizeConsole,
  })
  connect(consoleEmoteButton, {
    onHoverChange = GameEmotes.onConsoleEmoteButtonHoverChange,
  })

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeEmote, GameEmotes.parseEmote)

  g_keyboard.bindKeyDown('Escape', function() GameEmotes.toggleWindow(false) end, rootWidget)

  if g_game.isOnline() then
    GameEmotes.online()
  end
end

function GameEmotes.terminate()
  local contentPanel
  if GameConsole then
    contentPanel = GameConsole.getContentPanel()
  end

  GameEmotes.toggleWindow(false)

  GameEmotes.saveSettings()

  g_keyboard.unbindKeyDown('Escape')
  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeEmote)
  disconnect(consoleEmoteButton, {
    onHoverChange = GameEmotes.onConsoleEmoteButtonHoverChange,
  })
  if contentPanel then
    disconnect(contentPanel, {
      onGeometryChange = GameEmotes.onResizeConsole,
    })
  end
  disconnect(g_game, {
    onGameStart = GameEmotes.online,
    onGameEnd   = GameEmotes.offline,
  })

  emoteList = { }
  emoteListByIndex = { }

  if emoteWindow then
    emoteWindow:destroy()
    emoteWindow = nil
  end
  if consoleEmoteButton then
    consoleEmoteButton:destroy()
    consoleEmoteButton = nil
  end

  _G.GameEmotes = nil
end

function GameEmotes.online()
  GameEmotes.loadSettings()
  GameEmotes.sortEmoteList()
  GameEmotes.updateConsoleEmoteButtonIcon()
end

function GameEmotes.offline()
  GameEmotes.saveSettings()
end

function GameEmotes.updateConsoleEmoteButtonIcon()
  consoleEmoteButton:setIcon(f('/images/game/emote/%d', math.random(FirstEmote, LastEmote)))
  consoleEmoteButton:setIconSize({ width = 16, height = 16 })
  consoleEmoteButton:setIconOffset({ x = 3, y = 4 })
end

function GameEmotes.onConsoleEmoteButtonHoverChange(self, hovered)
  if not hovered then
    return
  end
  GameEmotes.updateConsoleEmoteButtonIcon()
end

function GameEmotes.onResizeConsole(console)
  if not emoteWindow then
    return
  end

  local realWidth = console:getWidth() - emoteWindow:getMarginRight() - emoteWindow:getMarginLeft()
  local realHeight = console:getHeight() - emoteWindow:getMarginTop() - emoteWindow:getMarginBottom()
  local area =  realWidth * realHeight
  local totalCells = emoteWindow:getChildCount()
  local cellSize = math.min(math.floor(math.sqrt(area / totalCells)), 32)
  emoteWindow:setWidth(realWidth)
  emoteWindow:getLayout():setCellSize({width = cellSize, height = cellSize})
  for _, emote in ipairs(emoteList) do
    emote:setIconSize({width = cellSize, height = cellSize})
    local lock = emote:getChildren()[1]
    lock:setSize({width = cellSize, height = cellSize})
    lock:setIconSize({width = cellSize, height = cellSize})
  end
end

function GameEmotes.toggleWindow(force)
  if not GameConsole then
    return
  end

  local contentPanel = GameConsole.getContentPanel()
  if not contentPanel then
    return
  end

  local isForceBool = type(force) == 'boolean'
  local condition   = emoteWindow:isHidden()

  local consoleContentPanel = contentPanel:getChildById('consoleContentPanel')
  local cloneContentPanel   = contentPanel:getChildById('cloneContentPanel')

  -- Show
  if force == true or not isForceBool and condition then
    emoteWindow:show()

    consoleContentPanel:addAnchor(AnchorTop, 'emoteWindow', AnchorOutsideBottom)
    cloneContentPanel:addAnchor(AnchorTop, 'emoteWindow', AnchorOutsideBottom)

  -- Hide
  elseif force == false or not isForceBool and not condition then
    emoteWindow:hide()

    consoleContentPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    cloneContentPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
  end
end

function GameEmotes.setupEmotes()
  for id = FirstEmote, LastEmote do
    local emote = g_ui.createWidget('EmoteButton', emoteWindow)
    emote:setId(f('EmoteButton_%d', id))
    emote:setIcon(f('/images/game/emote/%d', id))
    emote:setTooltip(emotes[id].name)
    emote.id = id
    emote.timesUsed = 0
    emote.lastUsed = 0
    emote.locked = true
    emoteList[id] = emote
    table.insert(emoteListByIndex, emote)
  end
end

function GameEmotes.unlockEmote(id)
  local emote = emoteList[id]
  local lock = emote:getChildren()[1]
  lock:setIcon(nil)
  emote.locked = false
  emote.onClick = function() GameEmotes.useEmote(id) end
end

function GameEmotes.lockEmote(id)
  local emote = emoteList[id]
  local lock = emote:getChildren()[1]
  lock:setIcon('/images/game/emote/locked')
  emote.timesUsed = 0
  emote.lastUsed = 0
  emote.locked = true
  emote.onClick = nil
end

function GameEmotes.isLocked(id)
  local emote = emoteList[id]
  return emote.locked
end

function GameEmotes.getTimesUsed(id)
  local emote = emoteList[id]
  return not GameEmotes.isLocked(id) and emote.timesUsed or -1
end

-- Settings
function GameEmotes.loadSettings()
  local settings      = Client.getPlayerSettings()
  local emoteSettings = settings:getNode('emotes') or { }

  for id, _ in pairs(emoteSettings) do
    local emoteId = tonumber(id)
    if emoteList[emoteId] then
      emoteList[emoteId].timesUsed = emoteSettings[id].timesUsed
      emoteList[emoteId].lastUsed  = emoteSettings[id].lastUsed
      emoteList[emoteId].locked    = emoteSettings[id].locked
    end
  end
end

function GameEmotes.saveSettings()
  local settings      = Client.getPlayerSettings()
  local emoteSettings = { }

  for id, emote in pairs(emoteList) do
    emoteSettings[id] = { }
    emoteSettings[id].timesUsed = emote.timesUsed
    emoteSettings[id].lastUsed  = emote.lastUsed
    emoteSettings[id].locked    = emote.locked
  end
  settings:setNode('emotes', emoteSettings)
  settings:save()
end

-- Network
function GameEmotes.useEmote(id)
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeEmote)
  msg:addString(tostring(id))
  protocolGame:send(msg)

  emoteList[id].timesUsed = emoteList[id].timesUsed + 1
  emoteList[id].lastUsed = os.time()
  GameEmotes.sortEmoteList()
end

function GameEmotes.sortEmoteList()
  table.sort(emoteListByIndex, (function(a,b) return GameEmotes.getTimesUsed(a.id) > GameEmotes.getTimesUsed(b.id) or (GameEmotes.getTimesUsed(a.id) == GameEmotes.getTimesUsed(b.id) and a.lastUsed > b.lastUsed) or (GameEmotes.getTimesUsed(a.id) == GameEmotes.getTimesUsed(b.id) and a.lastUsed == b.lastUsed and a.id < b.id) end))
  for i = 1, #emoteListByIndex do
    emoteWindow:moveChildToIndex(emoteListByIndex[i], i)
  end
end

function GameEmotes.parseEmote(protocol, msg)
  local total = msg:getU8()
  for _ = 1, total do
    local emoteId = msg:getU8()
    local action  = msg:getU8()
    if action == EmoteEnable then
      GameEmotes.unlockEmote(emoteId)
    elseif action == EmoteDisable then
      GameEmotes.lockEmote(emoteId)
    end
  end
  if total == 1 then
    GameEmotes.sortEmoteList()
  end
end
