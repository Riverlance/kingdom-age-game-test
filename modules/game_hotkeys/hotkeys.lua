g_locales.loadLocales(resolvepath(''))

_G.GameHotkeys = { }



HotkeyColors = {
  Text = '#ffffff44',
  TextAutoSend = '#ffffff',
  ItemUse = '#aef2ff',
  ItemUseWith = '#f8e127',
  Power = '#cd4eff',
}



hotkeysManagerLoaded = false
hotkeysWindow = nil
assignWindow = nil
hotkeysOverwriteWindow = nil
currentHotkeyLabel = nil
hotkeyItemLabel = nil
currentItemPreview = nil
useOnSelf = nil
useOnTarget = nil
useWith = nil
useRadioGroup = nil
addHotkeyButton = nil
removeHotkeyButton = nil
hotkeyTextLabel = nil
hotkeyText = nil
sendAutomatically = nil
defaultComboKeys = nil
currentHotkeys = nil
hotkeyList = { }
lastHotkeyTime = g_clock.millis()



function GameHotkeys.init()
  -- Alias
  GameHotkeys.m = modules.game_hotkeys

  g_ui.importStyle('hotkeylabel.otui')

  hotkeysWindow = g_ui.displayUI('hotkeys')
  hotkeysWindow:setVisible(false)
  g_keyboard.bindKeyDown(GameHotkeysActionKey, GameHotkeys.toggle)

  currentHotkeys = hotkeysWindow:getChildById('currentHotkeys')
  currentHotkeys.onChildFocusChange = function(self, hotkeyLabel, unfocused) GameHotkeys.onSelectHotkeyLabel(hotkeyLabel, unfocused) end
  g_keyboard.bindKeyPress('Down', function() currentHotkeys:focusNextChild(KeyboardFocusReason) end, hotkeysWindow)
  g_keyboard.bindKeyPress('Up', function() currentHotkeys:focusPreviousChild(KeyboardFocusReason) end, hotkeysWindow)

  applyHotkeyButton = hotkeysWindow:getChildById('applyHotkeyButton')
  resetHotkeyButton = hotkeysWindow:getChildById('resetHotkeyButton')
  addHotkeyButton = hotkeysWindow:getChildById('addHotkeyButton')
  removeHotkeyButton = hotkeysWindow:getChildById('removeHotkeyButton')

  hotkeyItemLabel = hotkeysWindow:getChildById('hotkeyItemLabel')
  currentItemPreview = hotkeysWindow:getChildById('itemPreview')
  currentItemPreview.onDragEnter = GameHotkeys.dragEnterItemPreview
  currentItemPreview.onDragLeave = GameHotkeys.dragLeaveItemPreview
  currentItemPreview.onDrop = GameHotkeys.dropOnItemPreview

  useOnSelf = hotkeysWindow:recursiveGetChildById('useOnSelf')
  useOnTarget = hotkeysWindow:recursiveGetChildById('useOnTarget')
  useWith = hotkeysWindow:recursiveGetChildById('useWith')
  useRadioGroupWidget = hotkeysWindow:getChildById('useGroup')
  useRadioGroup = UIRadioGroup.create()
  useRadioGroup:addWidget(useOnSelf)
  useRadioGroup:addWidget(useOnTarget)
  useRadioGroup:addWidget(useWith)
  useRadioGroup.onSelectionChange = function(self, selected) GameHotkeys.onChangeUseType(self, selected) end

  hotkeyTextLabel = hotkeysWindow:getChildById('hotkeyTextLabel')
  hotkeyText = hotkeysWindow:getChildById('hotkeyText')
  sendAutomatically = hotkeysWindow:getChildById('sendAutomatically')

  if g_game.isOnline() then
    GameHotkeys.online()
  end

  connect(g_game, {
    onGameStart = GameHotkeys.online,
    onGameEnd   = GameHotkeys.offline
  })

  connect(GamePowers, {
    onUpdatePowerList = GameHotkeys.updateHotkeyList
  })
end

function GameHotkeys.terminate()
  if g_game.isOnline() then
    GameHotkeys.offline()
  end

  disconnect(GamePowers, {
    onUpdatePowerList = GameHotkeys.updateHotkeyList
  })

  disconnect(g_game, {
    onGameStart = GameHotkeys.online,
    onGameEnd   = GameHotkeys.offline
  })

  g_keyboard.unbindKeyDown(GameHotkeysActionKey)

  if useRadioGroup then
    useRadioGroup:destroy()
    useRadioGroup = nil
  end

  if assignWindow then
    assignWindow:destroy()
    assignWindow = nil
  end

  if hotkeysOverwriteWindow then
    hotkeysOverwriteWindow:destroy()
    hotkeysOverwriteWindow = nil
  end

  hotkeysWindow:destroy()

  hotkeyList = { }

  hotkeysWindow      = nil
  currentHotkeyLabel = nil
  hotkeyItemLabel    = nil
  currentItemPreview = nil
  useOnSelf          = nil
  useOnTarget        = nil
  useWith            = nil
  addHotkeyButton    = nil
  removeHotkeyButton = nil
  hotkeyTextLabel    = nil
  hotkeyText         = nil
  sendAutomatically  = nil
  defaultComboKeys   = nil
  currentHotkeys     = nil

  _G.GameHotkeys = nil
end

function GameHotkeys.online()
  GameHotkeys.reload()
  GameHotkeys.hide()
end

function GameHotkeys.offline()
  GameHotkeys.save()
  GameHotkeys.unload()
  GameHotkeys.hide()
end

function GameHotkeys.isOpen()
  return hotkeysWindow:isVisible()
end

function GameHotkeys.show()
  if not g_game.isOnline() then
    return
  end

  local wasOpened = hotkeysWindow:isVisible()

  hotkeysWindow:show()
  hotkeysWindow:raise()
  hotkeysWindow:focus()
  local firstChild = currentHotkeys:getChildren()[1]
  if firstChild then
    firstChild:focus()
  end

  if not wasOpened then
    g_sounds.getChannel(AudioChannels.Gui):play(f('%s/hotkeys_open.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
  end
end

function GameHotkeys.hide()
  local wasOpened = hotkeysWindow:isVisible()

  hotkeysWindow:hide()

  if assignWindow then
    signalcall(GameHotkeys.onAssignHotkey, assignWindow.keySettings, false)
    assignWindow:destroy()
    assignWindow = nil
  end

  if hotkeysOverwriteWindow then
    hotkeysOverwriteWindow:destroy()
    hotkeysOverwriteWindow = nil
  end

  if wasOpened then
    g_sounds.getChannel(AudioChannels.Gui):play(f('%s/hotkeys_close.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
  end
end

function GameHotkeys.toggle()
  if not hotkeysWindow:isVisible() then
    GameHotkeys.show()
  else
    GameHotkeys.hide()
  end
end

function GameHotkeys.setStatus(hotkeyLabel, status)
  hotkeyLabel.status = status
  GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  GameHotkeys.updateHotkeyForm()
end

function GameHotkeys.apply(hotkeyLabel, save, sort)
  hotkeyLabel = hotkeyLabel or currentHotkeyLabel
  if not hotkeyLabel then
    return
  end
  local keySettings = hotkeyLabel.settings
  local keyCombo = keySettings.keyCombo
  if hotkeyLabel.status == HotkeyStatus.Deleted then
    g_keyboard.unbindKeyDown(keyCombo, GameHotkeys.onKeyDown)
    g_keyboard.unbindKeyUp(keyCombo, GameHotkeys.onKeyUp)
    hotkeyList[keyCombo] = nil
    currentHotkeyLabel = nil
    currentHotkeys:focusNextChild(OtherFocusReason)
    hotkeyLabel:destroy()
    signalcall(GameHotkeys.onRemoveHotkey, keyCombo)
  else
    hotkeyList[keyCombo] = table.copy(keySettings)
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Applied)
    signalcall(GameHotkeys.onApplyHotkey, hotkeyLabel)
  end
  sort = (sort == nil) and true
  if sort then
    GameHotkeys.sort()
  end
  if save then
    GameHotkeys.save()
  end
end

function GameHotkeys.applyChanges()
  for _, hotkeyLabel in ipairs(currentHotkeys:getChildren()) do
    if hotkeyLabel.status ~= HotkeyStatus.Applied then
      GameHotkeys.apply(hotkeyLabel, false, false)
    end
    GameHotkeys.sort()
  end
end

function GameHotkeys.resetHotkey(hotkeyLabel)
  hotkeyLabel = hotkeyLabel or currentHotkeyLabel
  if not hotkeyLabel then
    return
  end
  local keyCombo = hotkeyLabel.settings.keyCombo
  if hotkeyLabel.status == HotkeyStatus.Added then
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Deleted)
    hotkeyLabel:destroy()
    hotkeyLabel = nil
    signalcall(GameHotkeys.onRemoveHotkey, keyCombo)
  elseif hotkeyLabel.status ~= HotkeyStatus.Applied then
    hotkeyLabel.settings = table.copy(hotkeyList[keyCombo])
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Applied)
    signalcall(GameHotkeys.onApplyHotkey, hotkeyLabel)
  end
end

function GameHotkeys.discardChanges()
  for _, hotkey in ipairs(currentHotkeys:getChildren()) do
    GameHotkeys.resetHotkey(hotkey)
  end
end

function GameHotkeys.sort()
  local hotkeys = currentHotkeys:getChildren()
  table.sort(hotkeys, function(a,b)
    if #a:getId() < #b:getId() then
      return true
    elseif #a:getId() == #b:getId() then
      return a:getId() < b:getId()
    else
      return false
    end
  end)
  for newIndex, hotkey in ipairs(hotkeys) do
    currentHotkeys:moveChildToIndex(hotkey, newIndex)
  end
end

function GameHotkeys.ok()
  GameHotkeys.applyChanges()
  GameHotkeys.save()
  GameHotkeys.hide()
end

function GameHotkeys.cancel()
  GameHotkeys.discardChanges()
  GameHotkeys.hide()
end

function GameHotkeys.load(forceDefaults)
  hotkeysManagerLoaded = false
  local hotkeySettings = Client.getPlayerSettings():getNode('Hotkeys') or { }
  if not table.empty(hotkeySettings) then
    for _, settings in pairs(hotkeySettings) do
      local keySettings = { }
      keySettings.keyCombo = string.exists(settings.keyCombo) and tostring(settings.keyCombo) or nil
      keySettings.text = string.exists(settings.text) and tostring(settings.text) or nil
      keySettings.autoSend = string.exists(settings.text) and toboolean(settings.autoSend) or nil
      keySettings.itemId = tonumber(settings.itemId) or nil
      keySettings.subType = tonumber(settings.subType) or nil
      keySettings.useType = tonumber(settings.useType) or nil
      keySettings.powerId = tonumber(settings.powerId) or nil
      GameHotkeys.addKeyCombo(keySettings)
    end
  else --retrocompatibility
    local hotkeySettings = Client.getPlayerSettings():getNode('hotkeys') or { }
    if table.empty(hotkeySettings) then
      GameHotkeys.loadDefaultComboKeys()
    end
    for index, keySettings in pairs(hotkeySettings) do
      if string.exists(keySettings.value) then
        keySettings.powerId = tonumber(keySettings.value:match('/power (%d+)')) or nil
        keySettings.text = not keySettings.powerId and tostring(keySettings.value) or nil -- parse numeric text
      end
      if tonumber(index) then
        GameHotkeys.addKeyCombo(keySettings)
      else --retrocompatibility
        keySettings.keyCombo = tostring(index)
        GameHotkeys.addKeyCombo(keySettings)
      end
    end
    Client.getPlayerSettings():remove('hotkeys') --remove old config
  end
  GameHotkeys.sort()
  hotkeysManagerLoaded = true
end

function GameHotkeys.unload()
  for _, hotkeyLabel in ipairs(currentHotkeys:getChildren()) do
    local keySettings = hotkeyLabel.settings
    g_keyboard.unbindKeyDown(keySettings.keyCombo, GameHotkeys.onKeyDown)
    g_keyboard.unbindKeyUp(keySettings.keyCombo, GameHotkeys.onKeyUp)
  end
  currentHotkeys:destroyChildren()
  currentHotkeyLabel = nil
  hotkeyList = { }
  GameHotkeys.updateHotkeyForm(true)
end

function GameHotkeys.reset()
  GameHotkeys.unload()
  GameHotkeys.load(true)
end

function GameHotkeys.reload()
  GameHotkeys.unload()
  GameHotkeys.load()
end

function GameHotkeys.save()
  local settings = Client.getPlayerSettings()
  local hotkeys = { }

  GameHotkeys.sort()
  for index, hotkeyLabel in ipairs(currentHotkeys:getChildren()) do
    hotkeys[index] = hotkeyLabel.settings
  end
  settings:setNode('Hotkeys', hotkeys)
  settings:save()
end

function GameHotkeys.loadDefaultComboKeys()
  if not defaultComboKeys then
    for i=1,12 do
      GameHotkeys.addKeyCombo({keyCombo = 'F' .. i})
    end
    for i=1,12 do
      GameHotkeys.addKeyCombo({keyCombo = 'Shift+F' .. i})
    end
    for i=1,12 do
      GameHotkeys.addKeyCombo({keyCombo = 'Ctrl+F' .. i})
    end
  else
    for _, keySettings in pairs(defaultComboKeys) do
      GameHotkeys.addKeyCombo(keySettings)
    end
  end
end

function GameHotkeys.setDefaultComboKeys(combo)
  defaultComboKeys = combo
end

function GameHotkeys.assignHotkey(keySettings)
  if assignWindow then
    return
  end

  assignWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
  assignWindow.keySettings = keySettings
  assignWindow:grabKeyboard()

  local keySettings = keySettings or { }

  local comboLabel = assignWindow:getChildById('comboPreview')
  comboLabel.keyCombo = ''
  assignWindow.onKeyDown = GameHotkeys.hotkeyCapture

  local addButtonWidget = assignWindow:getChildById('addButton')
  addButtonWidget.onClick = function(widget, mousePos)
    local keyCombo = assignWindow:getChildById('comboPreview').keyCombo

    local function applyAssign()
      keySettings.keyCombo = keyCombo
      local applied = GameHotkeys.addKeyCombo(keySettings, true)
      signalcall(GameHotkeys.onAssignHotkey, keySettings, applied)
    end

    -- Assigned already
    if hotkeyList[keyCombo] and (hotkeyList[keyCombo].power or string.exists(hotkeyList[keyCombo].text) or hotkeyList[keyCombo].itemId) then
      if hotkeysOverwriteWindow then
        return
      end

      local yesCallback = function()
        applyAssign()
        hotkeysOverwriteWindow:destroy()
        hotkeysOverwriteWindow = nil
      end

      local noCallback = function()
        signalcall(GameHotkeys.onAssignHotkey, keySettings, false)
        hotkeysOverwriteWindow:destroy()
        hotkeysOverwriteWindow = nil
      end

      hotkeysOverwriteWindow = displayGeneralBox(loc'${GameHotkeysAssignWindowOverwriteTitle}', loc'${GameHotkeysAssignWindowOverwriteMsg}', {
        { text = loc'${CorelibInfoYes}', callback = yesCallback },
        { text = loc'${CorelibInfoNo}', callback = noCallback },
        anchor = AnchorHorizontalCenter}, yesCallback, noCallback)

    -- Not assigned yet
    else
      applyAssign()
    end

    assignWindow:destroy()
    assignWindow = nil
  end

  local destroyFunc = function (widget, mousePos)
    signalcall(GameHotkeys.onAssignHotkey, keySettings, false)
    assignWindow:destroy()
    assignWindow = nil
  end

  assignWindow.onEscape = destroyFunc

  local cancelButton = assignWindow:getChildById('cancelButton')
  cancelButton.onClick = destroyFunc
end

function GameHotkeys.canUseHotkey(keySettings)
  local keyAlone = translateKeyCombo({ backtranslateKeyComboDesc(keySettings.keyCombo).keyCode })
  if GameConsole.isChatEnabled() and (string.match(keyAlone, '^%C$') or keyAlone == "Space" or keyAlone == "Backspace") then
    return false
  end
  return true
end

function GameHotkeys.onKeyDown(rootWidget, keyCode, keyboardModifiers)
  local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
  local keySettings = hotkeyList[keyCombo]
  if keySettings and GameHotkeys.canUseHotkey(keySettings) then
    GameHotkeys.doAction(keySettings)
  end
end

function GameHotkeys.onKeyUp(rootWidget, keyCode, keyboardModifiers)
  local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
  local keySettings = hotkeyList[keyCombo]
  if keySettings and keySettings.powerId then
    local mapWidget = GameInterface.getMapPanel()
    local mousePosition = g_window.getMousePosition()
    local pos

    -- Creature button (battle list button, party list button, any UICreatureButton widget)
    local posWidget = g_game.getWidgetByPos(mousePosition)
    if posWidget and posWidget:getClassName() == 'UICreatureButton' then
      local creature = posWidget.creature
      if creature then
        local creaturePos = creature:getPosition()
        if creaturePos then
          pos = creaturePos
        end
      end
    -- Game screen
    else
      pos = mapWidget and mapWidget:getPosition(mousePosition)
    end

    GamePowers.castPower(pos or { x = 0, y = 0, z = 0 })
  end
end

function GameHotkeys.addKeyCombo(keySettings, focus)
  local keyCombo = keySettings.keyCombo
  if not string.exists(keyCombo) then
    return
  end
  hotkeyList[keyCombo] = table.copy(keySettings) or { }

  local hotkeyLabel = currentHotkeys:getChildById('Hotkey_' .. keyCombo)
  if not hotkeyLabel then
    hotkeyLabel = g_ui.createWidget('HotkeyListLabel')
    hotkeyLabel:setId('Hotkey_' .. keyCombo)
    hotkeyLabel.settings = keySettings
    if hotkeysManagerLoaded then --adding new hotkey
      GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Added)
      currentHotkeys:insertChild(1, hotkeyLabel)
    else --loading hotkey
      GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Applied)
      currentHotkeys:addChild(hotkeyLabel)
    end
    GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  end
  hotkeyLabel.settings = keySettings
  currentHotkeyLabel = hotkeyLabel
  if keySettings.hotkeyBarId then
    GameHotkeys.apply(hotkeyLabel, true, true)
  end

  g_keyboard.bindKeyDown(keyCombo, GameHotkeys.onKeyDown)
  g_keyboard.bindKeyUp(keyCombo, GameHotkeys.onKeyUp)

  GameHotkeys.onEdit(hotkeyLabel)
  GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  if focus then
    currentHotkeys:focusChild(hotkeyLabel)
    currentHotkeys:ensureChildVisible(hotkeyLabel)
    GameHotkeys.updateHotkeyForm(true)
  end
  return true
end

function GameHotkeys.doAction(keySettings)
  if GameHotkeys.isOpen() then
    return
  end

  if not g_game.canPerformGameAction() then
    return
  end

  if keySettings.powerId then
    GamePowers.chargePower(keySettings.powerId)
    return
  end

  local currentTime = g_clock.millis()
  if currentTime - lastHotkeyTime < ClientOptions.getOption('hotkeyDelay') then
    return
  end
  lastHotkeyTime = currentTime

  if keySettings.text then
    if keySettings.autoSend then
      GameConsole.sendMessage(keySettings.text)
    else
      GameConsole.setTextEditText(keySettings.text)
    end
    return
  end

  if keySettings.itemId then
    if keySettings.useType == HotkeyItemUseType.Default then
      g_game.useInventoryItem(keySettings.itemId)
    elseif keySettings.useType == HotkeyItemUseType.Crosshair then
      local item = Item.create(keySettings.itemId)
      GameInterface.startUseWith(item)
    elseif keySettings.useType == HotkeyItemUseType.Target then
      local attackingCreature = g_game.getAttackingCreature()
      if not attackingCreature then GameInterface.startUseWith(item) end
      if attackingCreature:getTile() then g_game.useInventoryItemWith(keySettings.itemId, attackingCreature) end
    elseif keySettings.useType == HotkeyItemUseType.Self then
      g_game.useInventoryItemWith(keySettings.itemId, g_game.getLocalPlayer())
    end
  end
end

function GameHotkeys.getHotkey(keyCombo)
  if not g_game.isOnline() then
    return nil
  end
  return hotkeyList[keyCombo] or nil
end

function GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  if not hotkeyLabel then
    return
  end
  hotkeyLabel:setBackgroundColor(hotkeyLabel:isFocused() and hotkeyLabel.status.focusColor or hotkeyLabel.status.color)

  local keySettings = hotkeyLabel.settings
  if string.exists(keySettings.text) then
    hotkeyLabel:setText(f(loc'%s: ${GameHotkeysLabelText}', keySettings.keyCombo, keySettings.text))
    if keySettings.autoSend then
      hotkeyLabel:setColor(HotkeyColors.TextAutoSend)
    else
      hotkeyLabel:setColor(HotkeyColors.Text)
    end
  elseif tonumber(keySettings.itemId) then
    if keySettings.useType == HotkeyItemUseType.Crosshair then
      hotkeyLabel:setText(f(loc'%s: ${GameHotkeysItemCrosshair}', keySettings.keyCombo))
      hotkeyLabel:setColor(HotkeyColors.ItemUseWith)
    elseif keySettings.useType == HotkeyItemUseType.Target then
      hotkeyLabel:setText(f(loc'%s: ${GameHotkeysItemTarget}', keySettings.keyCombo))
      hotkeyLabel:setColor(HotkeyColors.ItemUseWith)
    elseif keySettings.useType == HotkeyItemUseType.Self then
      hotkeyLabel:setText(f(loc'%s: ${GameHotkeysItemYourself}', keySettings.keyCombo))
      hotkeyLabel:setColor(HotkeyColors.ItemUse)
    else
      hotkeyLabel:setText(f(loc'%s: ${GameHotkeysItemUse}', keySettings.keyCombo))
      hotkeyLabel:setColor(HotkeyColors.ItemUse)
    end
  elseif tonumber(keySettings.powerId) then
    local info = modules.ka_game_powers and GamePowers.getPowerInfo(keySettings.powerId) or nil
    if info then
      hotkeyLabel:setText(f(loc'%s: ${GameHotkeysPower}', keySettings.keyCombo, info.name, info.level))
    else
      hotkeyLabel:setText(f(loc'%s: ${GameHotkeysPowerNotApplicable}', keySettings.keyCombo))
    end
    hotkeyLabel:setColor(HotkeyColors.Power)
  else
    hotkeyLabel:setText(f('%s:', keySettings.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.Text)
  end
end

function GameHotkeys.updateHotkeyList()
  for _, hotkey in ipairs(currentHotkeys:getChildren()) do
    GameHotkeys.updateHotkeyLabel(hotkey)
  end
end

function GameHotkeys.updateHotkeyForm(reset)
  local enableText = function()
    hotkeyTextLabel:enable()
    hotkeyText:enable()
    hotkeyText:focus()
    sendAutomatically:enable()
  end

  local disableText = function()
    hotkeyTextLabel:disable()
    hotkeyText:clearText()
    hotkeyText:disable()
    sendAutomatically:setChecked(false)
    sendAutomatically:disable()
  end

  local switchItemPreview = function(on, useType)
    hotkeyItemLabel:setEnabled(on)
    currentItemPreview:setVisible(on)
    currentItemPreview:setIcon('')
    currentItemPreview:clearItem()
    useRadioGroupWidget:setVisible(on and useType)
  end

  if currentHotkeyLabel then
    resetHotkeyButton:setEnabled(currentHotkeyLabel.status ~= HotkeyStatus.Applied)
    applyHotkeyButton:setEnabled(currentHotkeyLabel.status ~= HotkeyStatus.Applied)
    removeHotkeyButton:setEnabled(currentHotkeyLabel.status ~= HotkeyStatus.Deleted)

    local keySettings = currentHotkeyLabel.settings
    if string.exists(keySettings.text) then
      enableText()
      hotkeyText:setText(keySettings.text)
      sendAutomatically:setChecked(keySettings.autoSend)
      switchItemPreview(false)
    elseif keySettings.itemId then --TODO: isValidItem
      disableText()
      switchItemPreview(true, keySettings.useType)
      currentItemPreview:setItemId(keySettings.itemId)
      if keySettings.subType then
        currentItemPreview:setItemSubType(keySettings.subType)
      end
      if keySettings.useType then
        if keySettings.useType == HotkeyItemUseType.Crosshair then
          selectedWidget = useWith
        elseif keySettings.useType == HotkeyItemUseType.Target then
          selectedWidget = useOnTarget
        elseif keySettings.useType == HotkeyItemUseType.Self then
          selectedWidget = useOnSelf
        else
          selectedWidget = nil
        end
        useRadioGroup:selectWidget(selectedWidget)
      end
    elseif keySettings.powerId then --TODO: isValidPower
      disableText()
      switchItemPreview(true)
      currentItemPreview:setIcon('/images/ui/power/' .. keySettings.powerId .. '_off')
    else
      enableText()
      hotkeyText:clearText()
      switchItemPreview(true)
    end
  else
    disableText()
    switchItemPreview(false)
  end

  if reset then
    hotkeyText:setCursorPos(-1)
  end
end

function GameHotkeys.removeHotkey()
  if not currentHotkeyLabel then
    return
  end
  GameHotkeys.setStatus(currentHotkeyLabel, HotkeyStatus.Deleted)
end

function GameHotkeys.clearObject()
  if not currentHotkeyLabel then
    return
  end
  local keyCombo = currentHotkeyLabel.settings.keyCombo
  currentHotkeyLabel.settings = { keyCombo = keyCombo }
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm(true)
end

function GameHotkeys.onHotkeyTextChange(value)
  if not hotkeysManagerLoaded or not currentHotkeyLabel then
    return
  end
  local keySettings = currentHotkeyLabel.settings
  keySettings.text = string.exists(value) and value or nil
  keySettings.autoSend = string.exists(value) and keySettings.autoSend or nil
  GameHotkeys.onEdit(currentHotkeyLabel)
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm()
end

function GameHotkeys.onSendAutomaticallyChange(autoSend)
  if not hotkeysManagerLoaded or not currentHotkeyLabel then
    return
  end
  local keySettings = currentHotkeyLabel.settings
  keySettings.autoSend = string.exists(keySettings.text) and autoSend or nil
  GameHotkeys.onEdit(currentHotkeyLabel)
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm()
end

function GameHotkeys.onSelectHotkeyLabel(hotkeyLabel, unfocused)
  if hotkeyLabel then
    currentHotkeyLabel = hotkeyLabel
    currentHotkeyLabel:setBackgroundColor(currentHotkeyLabel.status.focusColor)
  end
  if unfocused then
    unfocused:setBackgroundColor(unfocused.status.color)
  end
  GameHotkeys.updateHotkeyForm(true)
end

function GameHotkeys.hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
  local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
  local comboPreview = assignWindow:getChildById('comboPreview')
  comboPreview:setText(f(loc'${GameHotkeysAssignWindowCurrentHotkey}: %s', keyCombo))
  comboPreview.keyCombo = keyCombo
  comboPreview:resizeToText()
  assignWindow:getChildById('addButton'):enable()
  return true
end

function GameHotkeys.onEdit(hotkeyLabel)
  if not hotkeysManagerLoaded or hotkeyLabel.status == HotkeyStatus.Added or hotkeyLabel.status == HotkeyStatus.Deleted then
    return
  end
  local keySettings = hotkeyLabel.settings        --current values
  local hotkey = hotkeyList[keySettings.keyCombo] --applied
  if (not keySettings.autoSend ~= not hotkey.autoSend) or keySettings.itemId ~= hotkey.itemId or keySettings.subType ~= hotkey.subType or keySettings.useType ~= hotkey.useType or keySettings.powerId ~= hotkey.powerId then
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Edited)
  elseif (hotkey.text and keySettings.text ~= hotkey.text) or (not hotkey.text and string.exists(keySettings.text)) then
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Edited)
  else
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Applied)
  end
end

function GameHotkeys.onChangeUseType(self, selectedWidget)
  local keySettings = currentHotkeyLabel.settings
  if selectedWidget == useWith then
    keySettings.useType = HotkeyItemUseType.Crosshair
  elseif selectedWidget == useOnTarget then
    keySettings.useType = HotkeyItemUseType.Target
  elseif selectedWidget == useOnSelf then
    keySettings.useType = HotkeyItemUseType.Self
  else
    keySettings.useType = HotkeyItemUseType.Default
  end
  GameHotkeys.onEdit(currentHotkeyLabel)
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm(true)
end

function GameHotkeys.dragEnterItemPreview(self, mousePos)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')
  local keySettings = currentHotkeyLabel.settings
  local item = self:getItem()
  if item then
    g_mouseicon.displayItem(item)
  elseif tonumber(keySettings.powerId) then
    g_mouseicon.display(f('/images/ui/power/%d_off', keySettings.powerId))
  end
  return true
end

function GameHotkeys.dragLeaveItemPreview(self, droppedWidget, mousePos)
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  if droppedWidget ~= self then
    GameHotkeys.clearObject()
  end
  if not currentHotkeyLabel then return end
  GameHotkeys.onEdit(currentHotkeyLabel)
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm(true)
  return true
end

function GameHotkeys.dropOnItemPreview(self, widget, mousePos)
  if not currentHotkeyLabel then
    return false
  end
  local keySettings = { }
  if widget == self then
    keySettings = currentHotkeyLabel.settings
  end
  local item = nil
  local widgetClass = widget:getClassName()
  if widgetClass == 'UIItem' then
    item = widget:getItem()
  elseif widgetClass == 'UIGameMap' then
    item = widget.currentDragThing
  elseif widgetClass == 'UIPowerButton' then
    keySettings.powerId = widget.power.id
  end
  if item then
    keySettings.itemId = item:getId()
    keySettings.subType = item:getSubType() or 0
    if item:isMultiUse() then
      keySettings.useType = HotkeyItemUseType.Crosshair
    else
      keySettings.useType = HotkeyItemUseType.Default
    end
  end
  keySettings.keyCombo = currentHotkeyLabel.settings.keyCombo --only keep keyCombo
  currentHotkeyLabel.settings = keySettings
  GameHotkeys.onEdit(currentHotkeyLabel)
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm(true)
  return true
end
