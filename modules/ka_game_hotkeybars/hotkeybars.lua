g_locales.loadLocales(resolvepath(''))

_G.GameHotkeyBars = { }

dofiles('ui')



hotkeyBarList = { }

function GameHotkeyBars.init()
  -- Alias
  GameHotkeyBars.m = modules.ka_game_hotkeybars

  g_ui.importStyle('hotkeybars')

  connect(g_game, {
    onGameStart           = GameHotkeyBars.online,
    onGameEnd             = GameHotkeyBars.offline,
    onClientOptionChanged = GameHotkeyBars.onClientOptionChanged,
  })

  connect(g_ui, {
    onDragReset = GameHotkeyBars.onDragReset
  })

  connect(GamePowers, {
    onUpdatePowerList = GameHotkeyBars.onUpdateHotkeys
  })

  connect(GameHotkeys, {
    onAssignHotkey = GameHotkeyBars.onAssignHotkey,
    onApplyHotkey  = GameHotkeyBars.onApplyHotkey,
    onRemoveHotkey = GameHotkeyBars.onRemoveHotkey,
  })

  connect(GameHotkeys.m.hotkeysWindow, {
    onVisibilityChange = GameHotkeyBars.onToggleHotkeyWindow
  })

  GameHotkeyBars.initHotkeyBars()

  if g_game.isOnline() then
    GameHotkeyBars.online()
  end
end

function GameHotkeyBars.terminate()
  if g_game.isOnline() then
    GameHotkeyBars.offline()
  end

  GameHotkeyBars.deinitHotkeyBars()

  disconnect(GameHotkeys.m.hotkeysWindow, {
    onVisibilityChange = GameHotkeyBars.onToggleHotkeyWindow
  })

  disconnect(GameHotkeys, {
    onAssignHotkey = GameHotkeyBars.onAssignHotkey,
    onApplyHotkey  = GameHotkeyBars.onApplyHotkey,
    onRemoveHotkey = GameHotkeyBars.onRemoveHotkey,
  })

  disconnect(GamePowers, {
    onUpdatePowerList = GameHotkeyBars.onUpdateHotkeys
  })

  disconnect(g_ui, {
    onDragReset = GameHotkeyBars.onDragReset
  })

  disconnect(g_game, {
    onGameStart           = GameHotkeyBars.online,
    onGameEnd             = GameHotkeyBars.offline,
    onClientOptionChanged = GameHotkeyBars.onClientOptionChanged,
  })

  _G.GameHotkeyBars = nil
end

function GameHotkeyBars.online()
  GameHotkeyBars.loadHotkeyBars()
  GameHotkeyBars.onToggleHotkeyWindow(nil, GameHotkeys.isOpen())
end

function GameHotkeyBars.offline()
  GameHotkeyBars.saveHotkeyBars()
  GameHotkeyBars.unloadHotkeyBars()
end

function GameHotkeyBars.onToggleHotkeyWindow(widget, visible)
  GameHotkeyBars.updateDraggable(visible)
  local screen = rootWidget:recursiveGetChildById('textMessageArea')
  if screen then
    screen:setBackgroundColor(visible and '#000000cc' or 'alpha')
  end
  GameHotkeyBars.setHighlight(visible)
end

function GameHotkeyBars.initHotkeyBars()
  for i = AnchorTop, AnchorRight do
    local hotkeyBar = g_ui.createWidget('HotkeyBar' .. (math.ceil(i/2) == 2 and 'Vertical' or 'Horizontal'), GameInterface.getRootPanel())
    hotkeyBar:setId('HotkeyBar' .. i)
    hotkeyBar:addAnchor(i, 'gameScreenArea', i)
    hotkeyBar.id = i
    hotkeyBarList[i] = hotkeyBar
  end
end

function GameHotkeyBars.deinitHotkeyBars()
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:destroy()
    hotkeyBarList[i] = nil
  end
end

function GameHotkeyBars.saveHotkeyBars()
  local settings = Client.getPlayerSettings()
  local hotkeyBars = { }
  for id, hotkeyBar in ipairs(hotkeyBarList) do
    hotkeyBars[id] = { }
    hotkeyBars[id].visible = hotkeyBar.visibilityButton:isOn()
    for index, widget in ipairs(hotkeyBar:getHotkeyList():getChildren()) do
      hotkeyBars[id][index] = widget.settings.keyCombo
    end
  end
  settings:setNode('HotkeyBars', hotkeyBars)
  settings:save()
end

function GameHotkeyBars.loadHotkeyBars()
  local settings = Client.getPlayerSettings()
  local hotkeyBars = settings:getNode('hotkeybars')
  if hotkeyBars then
    settings:remove('hotkeybars') --remove old config
  end

  hotkeyBars = settings:getNode('HotkeyBars') or { }
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:load(hotkeyBars[tostring(i)])
  end
end

function GameHotkeyBars.unloadHotkeyBars()
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:unload()
  end
end

function GameHotkeyBars.updateHotkey(hotkey)
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:updateHotkey(hotkey)
  end
end

function GameHotkeyBars.onAssignHotkey(keySettings, applied)
  if keySettings.hotkeyBarId then
    local hotkeyBar = hotkeyBarList[keySettings.hotkeyBarId]
    keySettings.hotkeyBarId = nil

    hotkeyBar:onAssignHotkey(keySettings, applied)
    if applied and keySettings.powerId then
      g_sounds.getChannel(AudioChannels.Gui):play(f('%s/power_drop.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
    end
  end
end

function GameHotkeyBars.addHotkey(hotkeyBarId, index, hotkey)
  if hotkeyBarList[hotkeyBarId] then
    hotkeyBarList[hotkeyBarId]:addHotkey(index, hotkey)
  end
end

function GameHotkeyBars.removeHotkey(keyCombo)
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:removeHotkey(keyCombo)
  end
end

--Module game_hotkeys has changes
function GameHotkeyBars.onApplyHotkey(hotkey)
  GameHotkeyBars.updateHotkey(hotkey)
end

function GameHotkeyBars.onRemoveHotkey(keyCombo)
  GameHotkeyBars.removeHotkey(keyCombo)
end

function GameHotkeyBars.onUpdateHotkeys()
  GameHotkeyBars.updateHotkey()
end

function GameHotkeyBars.getHotkeyBars()
  return hotkeyBarList
end


function GameHotkeyBars.toggleHotkeybars(show)
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:setVisible(show)
  end
end

function GameHotkeyBars.updateDraggable(bool)
  for i = 1, #hotkeyBarList do
    hotkeyBarList[i]:updateDraggable(bool)
  end
end

function GameHotkeyBars.setHighlight(highlight)
  for _, hotkeyBar in ipairs(hotkeyBarList) do
    hotkeyBar:setHighlight(highlight)
  end
end

function GameHotkeyBars.onDragReset()
  for _, hotkeyBar in ipairs(hotkeyBarList) do
    hotkeyBar:resetTempContainer()
  end
  return true
end

function GameHotkeyBars.onDisplay(show)
  showHotkeybars = show
  GameHotkeyBars.toggleHotkeybars(show)
end

function GameHotkeyBars.isHotkeybarsVisible()
  return showHotkeybars
end
