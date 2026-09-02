g_locales.loadLocales(resolvepath(''))

_G.GameVipList = { }



local GameVipListActionKey = 'Ctrl+F'



vipWindow = nil
vipTopMenuButton = nil
addVipWindow = nil
editVipWindow = nil
contentsPanel = nil
vipInfo = { }



function GameVipList.init()
  -- Alias
  GameVipList.m = modules.game_viplist

  connect(g_game, {
    onGameStart      = GameVipList.online,
    onGameEnd        = GameVipList.offline,
    onAddVip         = GameVipList.onAddVip,
    onVipStateChange = GameVipList.onVipStateChange
  })

  g_keyboard.bindKeyDown(GameVipListActionKey, GameVipList.toggle)

  vipWindow = g_ui.loadUI('viplist')
  vipTopMenuButton = ClientTopMenu.addRightGameToggleButton('vipTopMenuButton', { loct = '${GameVipListWindowTitle} (${GameVipListActionKey})', locpar = { GameVipListActionKey = GameVipListActionKey } }, '/images/ui/top_menu/viplist', GameVipList.toggle)
  contentsPanel = vipWindow:getChildById('contentsPanel')

  vipWindow.topMenuButton = vipTopMenuButton
  contentsPanel.onMousePress = GameVipList.onVipListMousePress

  if not g_game.getFeature(GameAdditionalVipInfo) then
    GameVipList.loadVipInfo()
  end

  if g_game.isOnline() then
    GameVipList.online()
  end
end

function GameVipList.terminate()
  g_keyboard.unbindKeyDown(GameVipListActionKey)
  disconnect(g_game, {
    onGameStart      = GameVipList.online,
    onGameEnd        = GameVipList.offline,
    onAddVip         = GameVipList.onAddVip,
    onVipStateChange = GameVipList.onVipStateChange
  })

  if not g_game.getFeature(GameAdditionalVipInfo) then
    GameVipList.saveVipInfo()
  end

  if addVipWindow then
    addVipWindow:destroy()
  end

  if editVipWindow then
    editVipWindow:destroy()
  end

  vipWindow:destroy()
  vipTopMenuButton:destroy()
  vipWindow = nil
  vipTopMenuButton = nil

  _G.GameVipList = nil
end

function GameVipList.loadVipInfo()
  local settings = g_settings.getNode('VipList')
  if not settings then
    vipInfo = { }
    return
  end
  vipInfo = settings['VipInfo'] or { }
end

function GameVipList.saveVipInfo()
  settings = { }
  settings['VipInfo'] = vipInfo
  g_settings.mergeNode('VipList', settings)
end

function GameVipList.clear()
  contentsPanel:destroyChildren()
end

function GameVipList.online()
  vipWindow:setup(vipTopMenuButton)

  GameVipList.clear()
  for id,vip in pairs(g_game.getVips()) do
    GameVipList.onAddVip(id, unpack(vip))
  end
end

function GameVipList.offline()
  GameVipList.clear()
end

function GameVipList.toggle()
  GameInterface.toggleMiniWindow(vipWindow)
end

function GameVipList.createAddWindow()
  if not addVipWindow then
    addVipWindow = g_ui.displayUI('addvip')
  end
end

function GameVipList.createEditWindow(widget)
  if editVipWindow then
    return
  end

  editVipWindow = g_ui.displayUI('editvip')

  local name = widget:getText()
  local id = widget:getId():sub(4)

  local okButton = editVipWindow:getChildById('buttonOK')
  local cancelButton = editVipWindow:getChildById('buttonCancel')

  local nameLabel = editVipWindow:getChildById('nameLabel')
  nameLabel:setText(name)

  local descriptionText = editVipWindow:getChildById('descriptionText')
  descriptionText:appendText(widget:getTooltip())

  local notifyCheckBox = editVipWindow:getChildById('checkBoxNotify')
  notifyCheckBox:setChecked(widget.notifyLogin)

  local iconRadioGroup = UIRadioGroup.create()
  for i = VipIconFirst, VipIconLast do
    iconRadioGroup:addWidget(editVipWindow:recursiveGetChildById('icon' .. i))
  end
  iconRadioGroup:selectWidget(editVipWindow:recursiveGetChildById('icon' .. widget.iconId))

  local cancelFunction = function()
    editVipWindow:destroy()
    iconRadioGroup:destroy()
    editVipWindow = nil
  end

  local saveFunction = function()
    if not widget or not contentsPanel:hasChild(widget) then
      cancelFunction()
      return
    end

    local name = widget:getText()
    local state = widget.vipState
    local description = descriptionText:getText()
    local iconId = tonumber(iconRadioGroup:getSelectedWidget():getId():sub(5))
    local notify = notifyCheckBox:isChecked()

    if g_game.getFeature(GameAdditionalVipInfo) then
      g_game.editVip(id, description, iconId, notify)
    else
      if notify ~= false or #description > 0 or iconId > 0 then
        vipInfo[name] = {description = description, iconId = iconId, notifyLogin = notify}
      else
        vipInfo[name] = nil
      end
    end

    widget:destroy()
    GameVipList.onAddVip(id, name, state, description, iconId, notify)

    editVipWindow:destroy()
    iconRadioGroup:destroy()
    editVipWindow = nil
  end

  cancelButton.onClick = cancelFunction
  okButton.onClick = saveFunction

  editVipWindow.onEscape = cancelFunction
  editVipWindow.onEnter = saveFunction
end

function GameVipList.destroyAddWindow()
  addVipWindow:destroy()
  addVipWindow = nil
end

function GameVipList.addVip()
  g_game.addVip(addVipWindow:getChildById('name'):getText())
  GameVipList.destroyAddWindow()
end

function GameVipList.removeVip(widgetOrName)
  if not widgetOrName then
    return
  end

  local widget
  if type(widgetOrName) == 'string' then
    local entries = contentsPanel:getChildren()
    for i = 1, #entries do
      if entries[i]:getText():lower() == widgetOrName:lower() then
        widget = entries[i]
        break
      end
    end
    if not widget then
      return
    end
  else
    widget = widgetOrName
  end

  if widget then
    local id = widget:getId():sub(4)
    local name = widget:getText()
    g_game.removeVip(id)
    contentsPanel:removeChild(widget)
    if vipInfo[name] and g_game.getFeature(GameAdditionalVipInfo) then
      vipInfo[name] = nil
    end
  end
end

function GameVipList.hideOffline(state)
  settings = { }
  settings['hideOffline'] = state
  g_settings.mergeNode('VipList', settings)

  GameVipList.online()
end

function GameVipList.isHiddingOffline()
  local settings = g_settings.getNode('VipList')
  if not settings then
    return false
  end
  return settings['hideOffline']
end

function GameVipList.getSortedBy()
  local settings = g_settings.getNode('VipList')
  if not settings or not settings['sortedBy'] then
    return 'status'
  end
  return settings['sortedBy']
end

function GameVipList.sortBy(state)
  settings = { }
  settings['sortedBy'] = state
  g_settings.mergeNode('VipList', settings)

  GameVipList.online()
end

function GameVipList.onAddVip(id, name, state, description, iconId, notify)
  local label = contentsPanel:getChildById('vip' .. id)
  if not label then
    label = g_ui.createWidget('VipListLabel')
    label.onMousePress = GameVipList.onVipListLabelMousePress
    label:setId('vip' .. id)
    label:setText(name)
  else
    return
  end

  if not g_game.getFeature(GameAdditionalVipInfo) then
    local tmpVipInfo = vipInfo[name]
    label.iconId = 0
    label.notifyLogin = false
    if tmpVipInfo then
      if tmpVipInfo.iconId then
        label:setImageClip(torect((tmpVipInfo.iconId * 12) .. ' 0 12 12'))
        label.iconId = tmpVipInfo.iconId
      end
      if tmpVipInfo.description then
        label:setTooltip(tmpVipInfo.description)
      end
      label.notifyLogin = tmpVipInfo.notifyLogin or false
    end
  else
    label:setTooltip(description)
    label:setImageClip(torect((iconId * 12) .. ' 0 12 12'))
    label.iconId = iconId
    label.notifyLogin = notify
  end

  if state == VipState.Online then
    label:setColor('#00ff00')
  elseif state == VipState.Pending then
    label:setColor('#ffca38')
  else
    label:setColor('#ff0000')
  end

  label.vipState = state

  label:setPhantom(false)

  connect(label, {
    onDoubleClick = function()
      g_game.openPrivateChannel(label:getText())
      return true
    end
  })

  if state == VipState.Offline and GameVipList.isHiddingOffline() then
    label:setVisible(false)
  end

  local nameLower = name:lower()
  local childrenCount = contentsPanel:getChildCount()

  for i = 1, childrenCount do
    local child = contentsPanel:getChildByIndex(i)
    if (state == VipState.Online and child.vipState ~= VipState.Online and GameVipList.getSortedBy() == 'status')
        or (label.iconId > child.iconId and GameVipList.getSortedBy() == 'type') then
      contentsPanel:insertChild(i, label)
      return
    end

    if (((state ~= VipState.Online and child.vipState ~= VipState.Online) or (state == VipState.Online and child.vipState == VipState.Online)) and GameVipList.getSortedBy() == 'status')
        or (label.iconId == child.iconId and GameVipList.getSortedBy() == 'type') or GameVipList.getSortedBy() == 'name' then

      local childText = child:getText():lower()
      local length = math.min(#childText, #nameLower)

      for j=1,length do
        if nameLower:byte(j) < childText:byte(j) then
          contentsPanel:insertChild(i, label)
          return
        elseif nameLower:byte(j) > childText:byte(j) then
          break
        elseif j == #nameLower then -- We are at the end of nameLower, and its shorter than childText, thus insert before
          contentsPanel:insertChild(i, label)
          return
        end
      end
    end
  end

  contentsPanel:insertChild(childrenCount+1, label)
end

function GameVipList.onVipStateChange(id, state)
  local label = contentsPanel:getChildById('vip' .. id)
  local name = label:getText()
  local description = label:getTooltip()
  local iconId = label.iconId
  local notify = label.notifyLogin
  label:destroy()

  GameVipList.onAddVip(id, name, state, description, iconId, notify)

  if notify and state ~= VipState.Pending then
    if modules.game_textmessage then
      GameTextMessage.displayFailureMessage(state == VipState.Online and f(loc'${GameVipListInfoPlayerLoggedIn}', name) or f(loc'${GameVipListInfoPlayerLoggedOut}', name))
    end
  end
end

function GameVipList.onVipListMousePress(widget, mousePos, mouseButton)
  if mouseButton ~= MouseRightButton then
    return
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)
  menu:addOption(loc'${GameVipListContextMenuAddVip}', function() GameVipList.createAddWindow() end)

  menu:addSeparator()
  if not GameVipList.isHiddingOffline() then
    menu:addOption(loc'${GameVipListContextMenuOfflineHide}', function() GameVipList.hideOffline(true) end)
  else
    menu:addOption(loc'${GameVipListContextMenuOfflineShow}', function() GameVipList.hideOffline(false) end)
  end

  if not(GameVipList.getSortedBy() == 'name') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoName}':lower()), function() GameVipList.sortBy('name') end)
  end

  if not(GameVipList.getSortedBy() == 'status') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoStatus}':lower()), function() GameVipList.sortBy('status') end)
  end

  if not(GameVipList.getSortedBy() == 'type') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoType}':lower()), function() GameVipList.sortBy('type') end)
  end

  menu:display(mousePos)

  return true
end

function GameVipList.onVipListLabelMousePress(widget, mousePos, mouseButton)
  if mouseButton ~= MouseRightButton then
    return
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)
  menu:addOption(loc'${GameVipListContextMenuSendMsg}', function() g_game.openPrivateChannel(widget:getText()) end)
  menu:addOption(loc'${GameVipListContextMenuVipAdd}', function() GameVipList.createAddWindow() end)
  menu:addOption(f(loc'${GameVipListContextMenuVipEdit}', widget:getText()), function() if widget then GameVipList.createEditWindow(widget) end end)
  menu:addOption(f(loc'${GameVipListContextMenuVipRemove}', widget:getText()), function() if widget then GameVipList.removeVip(widget) end end)
  menu:addSeparator()
  menu:addOption(loc'${GameVipListContextMenuCopyName}', function() g_window.setClipboardText(widget:getText()) end)

  if GameConsole and GameConsole.getOwnPrivateTab() then
    menu:addSeparator()
    menu:addOption(loc'${GameVipListContextMenuPrivateChatInvite}', function() g_game.inviteToOwnChannel(widget:getText()) end)
    menu:addOption(loc'${GameVipListContextMenuPrivateChatExclude}', function() g_game.excludeFromOwnChannel(widget:getText()) end)
  end

  if not GameVipList.isHiddingOffline() then
    menu:addOption(loc'${GameVipListContextMenuOfflineHide}', function() GameVipList.hideOffline(true) end)
  else
    menu:addOption(loc'${GameVipListContextMenuOfflineShow}', function() GameVipList.hideOffline(false) end)
  end

  if not(GameVipList.getSortedBy() == 'name') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoName}':lower()), function() GameVipList.sortBy('name') end)
  end

  if not(GameVipList.getSortedBy() == 'status') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoStatus}':lower()), function() GameVipList.sortBy('status') end)
  end

  if not(GameVipList.getSortedBy() == 'type') then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', loc'${CorelibInfoType}':lower()), function() GameVipList.sortBy('type') end)
  end

  menu:display(mousePos)

  return true
end
