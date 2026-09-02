g_locales.loadLocales(resolvepath(''))

_G.GameBattleList = { }



battleTopMenuButton = nil
battleWindow = nil
battleHeader = nil
sortMenuButton = nil
arrowMenuButton = nil

filterPlayersButton = nil
filterNPCsButton = nil
filterMonstersButton = nil
filterOwnSummonsButton = nil
filterOtherSummonsButton = nil
filterNeutralButton = nil
filterPartyButton = nil

battlePanel = nil

mouseWidget = nil

currentTarget = nil


-- Sorting

SortType = {
  DisplayTime   = 1,
  Distance      = 2,
  HealthPercent = 3,
  Name          = 4,
}

BattleSortType = {
  [SortType.DisplayTime]   = '${SortDisplayTime}',
  [SortType.Distance]      = '${CorelibInfoDistance}',
  [SortType.HealthPercent] = '${SortHealthPercent}',
  [SortType.Name]          = '${CorelibInfoName}',
}

Order = {
  Ascending  = 1,
  Descending = 2,
}

BattleOrder = {
  [Order.Ascending]  = '${CorelibInfoAscending}',
  [Order.Descending] = '${CorelibInfoDescending}'
}

local defaultValues = {
  filterPanel = true,

  filterPlayers      = true,
  filterNPCs         = true,
  filterMonsters     = true,
  filterOwnSummons   = true,
  filterOtherSummons = true,
  filterNeutral      = true,
  filterParty        = true,

  sortType  = BattleSortType.Distance,
  sortOrder = BattleOrder.Ascending
}

-- Position checking
lastPosCheck   = g_clock.millis()
posUpdateDelay = 500

-- Action Keys
BattleActionKey     = 'Ctrl+B'
NextTargetActionKey = 'Space'
PrevTargetActionKey = 'Ctrl+Space'


function GameBattleList.init()
  -- Alias
  GameBattleList.m = modules.game_battlelist

  battleList        = { }
  battleListByIndex = { }

  g_ui.importStyle('battlelistbutton')
  g_keyboard.bindKeyDown(BattleActionKey, GameBattleList.toggle)

  battleWindow = g_ui.loadUI('battlelist')
  battleTopMenuButton = ClientTopMenu.addRightGameToggleButton('battleTopMenuButton', { loct = '${BattleWindowTitle} (${BattleActionKey})', locpar = { BattleActionKey = BattleActionKey } }, '/images/ui/top_menu/battle_list', GameBattleList.toggle)

  battleWindow.topMenuButton = battleTopMenuButton

  battleHeader = battleWindow:getChildById('miniWindowHeader')

  battleWindow:setScrollBarAutoHiding(false)

  sortMenuButton = battleWindow:getChildById('sortMenuButton')
  sortMenuButton.loct = '${CorelibInfoSortingBy}: ${BattleSortType} (${BattleOrder})'
  sortMenuButton.locpar = function()
    return {
      BattleSortType = BattleSortType[GameBattleList.getSortType()],
      BattleOrder = BattleOrder[GameBattleList.getSortOrder()]
    }
  end

  GameBattleList.setSortType(GameBattleList.getSortType())
  GameBattleList.setSortOrder(GameBattleList.getSortOrder())

  arrowMenuButton = battleWindow:getChildById('arrowMenuButton')
  arrowMenuButton:setOn(not g_settings.getValue('BattleList', 'filterPanel', defaultValues.filterPanel))
  GameBattleList.onClickArrowMenuButton(arrowMenuButton)

  local _filterPanel       = battleHeader:getChildById('filterPanel')
  filterPlayersButton      = _filterPanel:getChildById('filterPlayers')
  filterNPCsButton         = _filterPanel:getChildById('filterNPCs')
  filterMonstersButton     = _filterPanel:getChildById('filterMonsters')
  filterOwnSummonsButton   = _filterPanel:getChildById('filterOwnSummons')
  filterOtherSummonsButton = _filterPanel:getChildById('filterOtherSummons')
  filterNeutralButton      = _filterPanel:getChildById('filterNeutral')
  filterPartyButton        = _filterPanel:getChildById('filterParty')
  filterPlayersButton:setOn(not g_settings.getValue('BattleList', 'filterPlayers', defaultValues.filterPlayers))
  filterNPCsButton:setOn(not g_settings.getValue('BattleList', 'filterNPCs', defaultValues.filterNPCs))
  filterMonstersButton:setOn(not g_settings.getValue('BattleList', 'filterMonsters', defaultValues.filterMonsters))
  filterOwnSummonsButton:setOn(not g_settings.getValue('BattleList', 'filterOwnSummons', defaultValues.filterOwnSummons))
  filterOtherSummonsButton:setOn(not g_settings.getValue('BattleList', 'filterOtherSummons', defaultValues.filterOtherSummons))
  filterNeutralButton:setOn(not g_settings.getValue('BattleList', 'filterNeutral', defaultValues.filterNeutral))
  filterPartyButton:setOn(not g_settings.getValue('BattleList', 'filterParty', defaultValues.filterParty))
  GameBattleList.onClickFilterPlayers(filterPlayersButton)
  GameBattleList.onClickFilterNPCs(filterNPCsButton)
  GameBattleList.onClickFilterMonsters(filterMonstersButton)
  GameBattleList.onClickFilterOwnSummons(filterOwnSummonsButton)
  GameBattleList.onClickFilterOtherSummons(filterOtherSummonsButton)
  GameBattleList.onClickFilterNeutral(filterNeutralButton)
  GameBattleList.onClickFilterParty(filterPartyButton)

  battlePanel = battleWindow:getChildById('contentsPanel'):getChildById('battlePanel')

  mouseWidget = g_ui.createWidget('UIButton')
  mouseWidget:setVisible(false)
  mouseWidget:setFocusable(false)
  mouseWidget.cancelNextRelease = false

  connect(Creature, {
    onAppear              = GameBattleList.onAppear,
    onDisappear           = GameBattleList.onDisappear,
    onPositionChange      = GameBattleList.onPositionChange,
    onTypeChange          = GameBattleList.onTypeChange,
    onOutfitChange        = GameBattleList.onOutfitChange,
    onShieldChange        = GameBattleList.onShieldChange,
    onSkullChange         = GameBattleList.onSkullChange,
    onEmblemChange        = GameBattleList.onEmblemChange,
    onSpecialIconChange   = GameBattleList.onSpecialIconChange,
    onHealthPercentChange = GameBattleList.onHealthPercentChange,
    onNicknameChange      = GameBattleList.onNicknameChange
  })

  connect(LocalPlayer, {
    onPositionChange = GameBattleList.onPositionChange
  })

  connect(g_game, {
    onAttackingCreatureChange = GameBattleList.onAttackingCreatureChange,
    onFollowingCreatureChange = GameBattleList.onFollowingCreatureChange,
    onGameStart               = GameBattleList.online,
    onGameEnd                 = GameBattleList.offline,
    onTrackCreature           = GameBattleList.onTrackCreature,
    onTrackCreatureEnd        = GameBattleList.onTrackCreature,
    onUpdateTrackColor        = GameBattleList.onUpdateTrackColor,
    onToggleChat              = GameBattleList.onToggleChat,
  })

	connect(GameInterface.getMapPanel(), {
		onZoomChange = GameBattleList.onZoomChange
	})

  if g_game.isOnline() then
    GameBattleList.online()
  end
end

function GameBattleList.terminate()
  battleList        = { }
  battleListByIndex = { }

	disconnect(GameInterface.getMapPanel(), {
		onZoomChange = GameBattleList.onZoomChange
	})

  disconnect(g_game, {
    onAttackingCreatureChange = GameBattleList.onAttackingCreatureChange,
    onFollowingCreatureChange = GameBattleList.onFollowingCreatureChange,
    onGameStart               = GameBattleList.online,
    onGameEnd                 = GameBattleList.offline,
    onTrackCreature           = GameBattleList.onTrackCreature,
    onTrackCreatureEnd        = GameBattleList.onTrackCreature,
    onUpdateTrackColor        = GameBattleList.onUpdateTrackColor,
    onToggleChat              = GameBattleList.onToggleChat,
  })

  disconnect(LocalPlayer, {
    onPositionChange = GameBattleList.onPositionChange
  })

  disconnect(Creature, {
    onAppear              = GameBattleList.onAppear,
    onDisappear           = GameBattleList.onDisappear,
    onPositionChange      = GameBattleList.onPositionChange,
    onTypeChange          = GameBattleList.onTypeChange,
    onOutfitChange        = GameBattleList.onOutfitChange,
    onShieldChange        = GameBattleList.onShieldChange,
    onSkullChange         = GameBattleList.onSkullChange,
    onEmblemChange        = GameBattleList.onEmblemChange,
    onSpecialIconChange   = GameBattleList.onSpecialIconChange,
    onHealthPercentChange = GameBattleList.onHealthPercentChange,
    onNicknameChange      = GameBattleList.onNicknameChange
  })

  mouseWidget:destroy()

  battleTopMenuButton:destroy()
  battleWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+B')

  _G.GameBattleList = nil
end

function GameBattleList.online()
  battleWindow:setup(battleTopMenuButton)
end

function GameBattleList.offline()
  GameBattleList.clearList()
  currentTarget = nil
end

function GameBattleList.toggle()
  GameInterface.toggleMiniWindow(battleWindow)
end



-- Button

function GameBattleList.getButtonIndex(cid)
  for k, button in ipairs(battleListByIndex) do
    if cid == button.creature:getId() then
      return k
    end
  end
  return nil
end

function GameBattleList.getFirstVisibleButton()
  for _, button in ipairs(battleListByIndex) do
    if button:isOn() then
      return button
    end
  end
  return nil
end

function GameBattleList.getLastVisibleButton()
  for i = #battleListByIndex, 1, -1 do
    local button = battleListByIndex[i]
    if button:isOn() then
      return button
    end
  end
  return nil
end

function GameBattleList.add(creature)
  if not g_game.getLocalPlayer() or
     creature:isLocalPlayer() or
     creature:isDead() or
     creature:getName() == ""
  then
    return
  end

  local cid    = creature:getId()
  local button = battleList[cid]
  if button then
    return
  end

  -- Register first time creature adding

  button            = g_ui.createWidget('BattleButton')
  button.onlyOutfit = true
  button:setup(creature)

  button.onHoverChange  = GameBattleList.onBattleButtonHoverChange
  button.onMouseRelease = GameBattleList.onBattleButtonMouseRelease

  battleList[cid] = button
  table.insert(battleListByIndex, battleList[cid])

  if creature == g_game.getAttackingCreature() then
    GameBattleList.onAttackingCreatureChange(creature)
  end
  if creature == g_game.getFollowingCreature() then
    GameBattleList.onFollowingCreatureChange(creature)
  end

  battlePanel:addChild(button)
  GameBattleList.updateList()
end

function GameBattleList.remove(creature)
  local cid   = creature:getId()
  local index = GameBattleList.getButtonIndex(cid)

  if not index then
    -- print('Trying to remove invalid battleButton')
    return
  end

  if currentTarget and battlePanel:getChildIndex(currentTarget) == index then
    currentTarget = nil
  end

  if battleList[cid] then
    battleList[cid]:destroy()
    battleList[cid] = nil
  end
  table.remove(battleListByIndex, index)
end

function GameBattleList.updateBattleButtons()
  for _, button in ipairs(battleListByIndex) do
    button:update()
  end
end

function GameBattleList.onBattleButtonHoverChange(self, hovered)
  if self.isBattleButton then
    self.isHovered = hovered
    self:update()
    if not self.isTarget and not self.isFollowed then
      if hovered then
        self.creature:showStaticCircle(UICreatureButton.getStaticCircleTargetColor().hovered)
      else
        self.creature:hideStaticCircle()
      end
    end
  end
end

function GameBattleList.onBattleButtonMouseRelease(self, mousePosition, mouseButton)
  if mouseWidget.cancelNextRelease then
    mouseWidget.cancelNextRelease = false
    return false
  end
  if mouseButton == MouseLeftButton and g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed() then
    g_game.follow(self.creature)
  elseif mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
    GameInterface.createThingMenu(mousePosition, nil, nil, self.creature)
    return true
  elseif mouseButton == MouseLeftButton and not g_mouse.isPressed(MouseRightButton) then
    g_game.attack(self.creature)
    return true
  end
  return false
end

function GameBattleList.updateStaticCircle()
  for _, button in pairs(battleList) do
    if button.isTarget then
      button:update()
    end
  end
end



-- Filtering

function GameBattleList.onClickArrowMenuButton(self)
  local newState = not self:isOn()
  arrowMenuButton:setOn(newState)
  battleHeader:setOn(not newState)
  g_settings.setValue('BattleList', 'filterPanel', newState)
end

function GameBattleList.buttonFilter(button)
  local filterPlayers      = not filterPlayersButton:isOn()
  local filterNPCs         = not filterNPCsButton:isOn()
  local filterMonsters     = not filterMonstersButton:isOn()
  local filterOwnSummons   = not filterOwnSummonsButton:isOn()
  local filterOtherSummons = not filterOtherSummonsButton:isOn()
  local filterNeutral      = not filterNeutralButton:isOn()
  local filterParty        = not filterPartyButton:isOn()

  local creature     = button.creature
  local creatureType = creature:getType()
  return filterPlayers and creature:isPlayer() or
         filterNPCs and creature:isNpc() or
         filterMonsters and creature:isMonster() or
         filterOwnSummons and creatureType == CreatureTypeSummonOwn or
         filterOtherSummons and creatureType == CreatureTypeSummonOther or
         filterNeutral and (creature:isPlayer() and (creature:getSkull() == SkullNone or creature:getSkull() == SkullProtected)) or
         filterParty and creature:getShield() > ShieldWhiteBlue or false
end

function GameBattleList.filterButtons()
  local mapPanel = GameInterface.getMapPanel()
  if not mapPanel then
    return
  end

  for _, _button in pairs(battleList) do
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then
      break -- Do nothing if player is not online
    end
    local creature = _button.creature

    local on          = not GameBattleList.buttonFilter(_button)
    local playerPos   = localPlayer:getPosition()
    local creaturePos = creature:getPosition()

    if creature:isLocalPlayer() or
       creature:isDead() or
       not playerPos or
       not creaturePos or
       playerPos.z ~= creaturePos.z or
       not creature:canBeSeen() or -- Handles invisible state also
       not mapPanel:isInRange(creaturePos)
    then
      on = false
    end

    _button:setOn(on)
  end
end

function GameBattleList.onClickFilterPlayers(self)
  local newState = not self:isOn()
  filterPlayersButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterPlayers', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterNPCs(self)
  local newState = not self:isOn()
  filterNPCsButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterNPCs', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterMonsters(self)
  local newState = not self:isOn()
  filterMonstersButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterMonsters', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterOwnSummons(self)
  local newState = not self:isOn()
  filterOwnSummonsButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterOwnSummons', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterOtherSummons(self)
  local newState = not self:isOn()
  filterOtherSummonsButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterOtherSummons', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterNeutral(self)
  local newState = not self:isOn()
  filterNeutralButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterNeutral', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterParty(self)
  local newState = not self:isOn()
  filterPartyButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterParty', newState)
  GameBattleList.filterButtons()
end



-- Sorting

function GameBattleList.getSortType()
  return g_settings.getValue('BattleList', 'sortType', defaultValues.sortType)
end

function GameBattleList.setSortType(state)
  g_settings.setValue('BattleList', 'sortType', state)
  sortMenuButton:updateLocale(sortMenuButton.locpar)
  GameBattleList.updateList()
end

function GameBattleList.getSortOrder()
  return g_settings.getValue('BattleList', 'sortOrder', defaultValues.sortOrder)
end

function GameBattleList.setSortOrder(state)
  g_settings.setValue('BattleList', 'sortOrder', state)
  sortMenuButton:updateLocale(sortMenuButton.locpar)
  GameBattleList.updateList()
end

function GameBattleList.createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = GameBattleList.getSortOrder()
  local sortType  = GameBattleList.getSortType()

  if sortOrder ~= Order.Ascending then
    menu:addOption(loc('${BattleOrderTooltip}', { BattleOrder = BattleOrder[Order.Ascending] }), function() GameBattleList.setSortOrder(Order.Ascending) end)
  elseif sortOrder ~= Order.Descending then
    menu:addOption(loc('${BattleOrderTooltip}', { BattleOrder = BattleOrder[Order.Descending] }), function() GameBattleList.setSortOrder(Order.Descending) end)
  end

  menu:addSeparator()

  if sortType ~= SortType.DisplayTime then
    menu:addOption(loc('${CorelibInfoSortBy}: ${BattleSortType}', { BattleSortType = BattleSortType[SortType.DisplayTime] }), function() GameBattleList.setSortType(SortType.DisplayTime) end)
  end
  if sortType ~= SortType.Distance then
    menu:addOption(loc('${CorelibInfoSortBy}: ${BattleSortType}', { BattleSortType = BattleSortType[SortType.Distance] }), function() GameBattleList.setSortType(SortType.Distance) end)
  end
  if sortType ~= SortType.HealthPercent then
    menu:addOption(loc('${CorelibInfoSortBy}: ${BattleSortType}', { BattleSortType = BattleSortType[SortType.HealthPercent] }), function() GameBattleList.setSortType(SortType.HealthPercent) end)
  end
  if sortType ~= SortType.Name then
    menu:addOption(loc('${CorelibInfoSortBy}: ${BattleSortType}', { BattleSortType = BattleSortType[SortType.Name] }), function() GameBattleList.setSortType(SortType.Name) end)
  end

  menu:display()
end

function GameBattleList.sortList()
  local sortFunction

  local sortOrder = GameBattleList.getSortOrder()
  local sortType  = GameBattleList.getSortType()

  if sortOrder == Order.Ascending then
    -- Ascending - Appear
    if sortType == SortType.DisplayTime then
      sortFunction = function(a,b) return a.lastAppear < b.lastAppear end

    -- Ascending - Distance
    elseif sortType == SortType.Distance then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()

        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.creature:getPosition()) < getDistanceTo(localPlayerPos, b.creature:getPosition()) end
      end

    -- Ascending - Health
    elseif sortType == SortType.HealthPercent then
      sortFunction = function(a,b) return a.creature:getHealthPercent() < b.creature:getHealthPercent() end

    -- Ascending - Name
    elseif sortType == SortType.Name then
      sortFunction = function(a,b) return a.creature:getName() < b.creature:getName() end
    end

  elseif sortOrder == Order.Descending then
    -- Descending - Appear
    if sortType == SortType.DisplayTime then
      sortFunction = function(a,b) return a.lastAppear > b.lastAppear end

    -- Descending - Distance
    elseif sortType == SortType.Distance then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()

        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.creature:getPosition()) > getDistanceTo(localPlayerPos, b.creature:getPosition()) end
      end

    -- Descending - Health
    elseif sortType == SortType.HealthPercent then
      sortFunction = function(a,b) return a.creature:getHealthPercent() > b.creature:getHealthPercent() end

    -- Descending - Name
    elseif sortType == SortType.Name then
      sortFunction = function(a,b) return a.creature:getName() > b.creature:getName() end
    end
  end

  if sortFunction then
    table.sort(battleListByIndex, sortFunction)
  end

  if modules.ka_game_tracker then
    local indexList = { }
    for i = #battleListByIndex, -1, 1 do
      local creature = battleListByIndex[i]
      if GameTracker.isTracked(creature) then
        table.insert(indexList, 1, creature)
      else
        table.insert(indexList, creature)
      end
    end
  end
end

function GameBattleList.updateList()
  GameBattleList.sortList()
  for i = 1, #battleListByIndex do
    battlePanel:moveChildToIndex(battleListByIndex[i], i)
  end
  GameBattleList.filterButtons()
end

function GameBattleList.clearList()
  battleList         = { }
  battleListByIndex  = { }
  battlePanel:destroyChildren()
end

function GameBattleList.refreshList()
  GameBattleList.clearList()

  for _, creature in pairs(GameInterface.getMapPanel():getSpectators()) do
    GameBattleList.add(creature)
  end

  if modules.ka_game_tracker then
    for id, trackNode in pairs(GameTracker.getTrackList()) do
      if trackNode.id then
        GameBattleList.onTrackCreature(trackNode)
      end
    end
  end
end



-- Events

function GameBattleList.onAttackingCreatureChange(creature, prevCreature)
  local button, prevButton
  if battleWindow:isVisible() then
    button = creature and battleList[creature:getId()]
    prevButton = prevCreature and battleList[prevCreature:getId()]
  end

  currentTarget = button
  if button then
    button.isTarget   = creature and true or false
    button.isFollowed = false
    button:update()
  end

  if prevButton then
    prevButton.isTarget = false
    prevButton.isFollowed = false
    prevButton:update()
    GameBattleList.onBattleButtonHoverChange(prevButton, prevButton.isHovered)
  end

end

function GameBattleList.onFollowingCreatureChange(creature, prevCreature)
  local button, prevButton
  if battleWindow:isVisible() then
    button = creature and battleList[creature:getId()]
    prevButton = prevCreature and battleList[prevCreature:getId()]
  end

  if button then
    button.isFollowed = creature and true or false
    button.isTarget   = false
    button:update()
  end

  if prevButton then
    prevButton.isTarget = false
    prevButton.isFollowed = false
    prevButton:update()
  end
end

function GameBattleList.onAppear(creature)
  if creature:isLocalPlayer() then
    addEvent(function()
      GameBattleList.updateStaticCircle()
    end)
  end

  GameBattleList.add(creature)

  if modules.ka_game_tracker then
    if GameTracker.isTracked(creature) then
      GameBattleList.onTrackCreature(GameTracker.getTrackList()[creature:getId()])
    end
  end
end

function GameBattleList.onDisappear(creature)
  GameBattleList.remove(creature)
end

function GameBattleList.onPositionChange(creature, pos, oldPos)
  local button = battleList[creature:getId()]
  local mapPanel = GameInterface.getMapPanel()
  local posCheck = g_clock.millis()
  local diffTime = posCheck - lastPosCheck

  if creature:isLocalPlayer() or (GameBattleList.getSortType() == SortType.Distance and diffTime > posUpdateDelay) or (button and not button:isOn() and mapPanel and mapPanel:isInRange(pos)) then
    GameBattleList.updateList()
    lastPosCheck = posCheck
  end
end

function GameBattleList.onTypeChange(creature, typeId, oldTypeId)
  local button = battleList[creature:getId()]
  if button then
    button:updateCreatureType(typeId)
  end
end

function GameBattleList.onOutfitChange(creature, outfit, oldOutfit)
  local button = battleList[creature:getId()]
  if button then
    button:updateCreature(true)
  end
end

function GameBattleList.onShieldChange(creature, shieldId)
  local button = battleList[creature:getId()]
  if button then
    button:updateShield(shieldId)
  end
end

function GameBattleList.onSkullChange(creature, skullId, oldSkullId)
  local button = battleList[creature:getId()]
  if button then
    button:updateSkull(skullId)
  end
end

function GameBattleList.onEmblemChange(creature, emblemId)
  local button = battleList[creature:getId()]
  if button then
    button:updateEmblem(emblemId)
  end
end

function GameBattleList.onSpecialIconChange(creature, specialIconId)
  local button = battleList[creature:getId()]
  if button then
    button:updateSpecialIcon(specialIconId)
  end
end

function GameBattleList.onHealthPercentChange(creature, healthPercent, oldHealthPercent)
  local button = battleList[creature:getId()]
  if button then
    button:updateHealthPercent(healthPercent)

    if GameBattleList.getSortType() == SortType.HealthPercent then
      GameBattleList.updateList()
    end
  end
end

function GameBattleList.onNicknameChange(creature, nickname)
  local button = battleList[creature:getId()]
  if button then
    button:updateLabelText(nickname ~= '' and nickname or creature:getName())

    if GameBattleList.getSortType() == SortType.Name then
      GameBattleList.updateList()
    end
  end
end

function GameBattleList.onUpdateTrackColor(trackNode)
  local button = battleList[trackNode.id]
  if button then
    button:updateTrackIcon(trackNode.color)
  end
end

function GameBattleList.onTrackCreature(trackNode)
  GameBattleList.updateList()

  local TrackingInfo = GameTracker.m.TrackingInfo
  local button = battleList[trackNode.id]
  if not button then
    return
  end
  local color = trackNode.color
  if trackNode.status == TrackingInfo.Stop or trackNode.status == TrackingInfo.Paused then
    color = nil
  end
  button:updateTrackIcon(color)
end

function GameBattleList.onZoomChange(self, oldZoom, newZoom)
  if newZoom == oldZoom then
    return
  end

  GameBattleList.refreshList()
end



-- Select next target (see NextTargetActionKey/PrevTargetActionKey)

function GameBattleList.selectNextTarget(widget, keyCode, keyboardModifiers, reverse)
  if not GameCharacter.m or table.empty(battleListByIndex) then
    return
  end
  local currentIndex = currentTarget and battlePanel:getChildIndex(currentTarget) or 0
  local nextIndex = reverse and (currentIndex - 1) or (currentIndex + 1)
  if nextIndex == 0 then
    nextIndex = reverse and -1 or 1
  end

  local nextTarget = battlePanel:getChildByIndex(nextIndex) or nil
  currentTarget = nextTarget
  if currentTarget and currentTarget:isOn() then
    -- Disable chase mode (this is the price to use the select target shortcut feature)
    GameCharacter.onSetChaseMode(GameCharacter.m.chaseModeButton, false)
    g_game.attack(currentTarget.creature)
  else
    GameBattleList.selectNextTarget(widget, keyCode, keyboardModifiers, reverse)
  end
end

function GameBattleList.selectPrevTarget(widget, keyCode, keyboardModifiers)
  GameBattleList.selectNextTarget(widget, keyCode, keyboardModifiers, true)
end

function GameBattleList.onToggleChat(enabled)
  if enabled then -- Disable next target shortcut
    g_keyboard.unbindKeyDown(NextTargetActionKey)
    g_keyboard.unbindKeyDown(PrevTargetActionKey)
  else -- Enable next target shortcut
    g_keyboard.bindKeyDown(NextTargetActionKey, GameBattleList.selectNextTarget)
    g_keyboard.bindKeyDown(PrevTargetActionKey, GameBattleList.selectPrevTarget)
  end
end
