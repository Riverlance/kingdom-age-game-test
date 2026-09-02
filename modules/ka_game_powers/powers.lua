g_locales.loadLocales(resolvepath(''))

_G.GamePowers = { }



local GamePowersActionKey = 'Ctrl+Shift+P'



powersWindow = nil
powersTopMenuButton = nil
powersHeader = nil
sortMenuButton = nil
arrowMenuButton = nil

filterPanel = nil
filterOffensiveButton = nil
filterDefensiveButton = nil
filterNonPremiumButton = nil
filterPremiumButton = nil

powersPanel = nil

POWERS_SORT_NAME  = 1
POWERS_SORT_CLASS = 2
POWERS_SORT_LEVEL = 3

POWERS_ORDER_ASCENDING  = 1
POWERS_ORDER_DESCENDING = 2

local powersSortStr = {
  [POWERS_SORT_NAME]  = loc'${CorelibInfoName}',
  [POWERS_SORT_CLASS] = loc'${CorelibInfoClass}',
  [POWERS_SORT_LEVEL] = loc'${CorelibInfoLevel}',
}

local powersOrderStr = {
  [POWERS_ORDER_ASCENDING]  = loc'${CorelibInfoAscending}',
  [POWERS_ORDER_DESCENDING] = loc'${CorelibInfoDescending}',
}

local defaultValues = {
  filterPanel = true,
  filterOffensive = true,
  filterDefensive = true,
  filterNonPremium = true,
  filterPremium = true,
  sortType = POWERS_SORT_LEVEL,
  sortOrder = POWERS_ORDER_ASCENDING
}

local POWER_CLASS_ALL       = 0
local POWER_CLASS_OFFENSIVE = 1
local POWER_CLASS_DEFENSIVE = 2
local POWER_CLASS_SUPPORT   = 3
local POWER_CLASS_SPECIAL   = 4

local power_flag_updateList             = -3
local power_flag_updateNonConstantPower = -4



function GamePowers.init()
  -- Alias
  GamePowers.m = modules.ka_game_powers

  powersList       = { }
  powerListByIndex = { }
  powerInfo        = { }

  g_ui.importStyle('powersbutton')
  g_keyboard.bindKeyDown(GamePowersActionKey, GamePowers.toggle)

  powersWindow        = g_ui.loadUI('powers')
  powersHeader        = powersWindow:getChildById('miniWindowHeader')
  powersTopMenuButton = ClientTopMenu.addRightGameToggleButton('powersTopMenuButton', { loct = '${GamePowersWindowTitle} (${GamePowersActionKey})', locpar = { GamePowersActionKey = GamePowersActionKey } }, '/images/ui/top_menu/powers', GamePowers.toggle)

  powersWindow.topMenuButton = powersTopMenuButton

  powersWindow:setScrollBarAutoHiding(false)

  sortMenuButton = powersWindow:getChildById('sortMenuButton')
  GamePowers.setSortType(GamePowers.getSortType())
  GamePowers.setSortOrder(GamePowers.getSortOrder())

  arrowMenuButton = powersWindow:getChildById('arrowMenuButton')
  arrowMenuButton:setOn(not g_settings.getValue('Powers', 'filterPanel', defaultValues.filterPanel))
  GamePowers.onClickArrowMenuButton(arrowMenuButton)

  filterPanel = powersHeader:getChildById('filterPanel')

  filterOffensiveButton  = filterPanel:getChildById('filterOffensive')
  filterDefensiveButton  = filterPanel:getChildById('filterDefensive')
  filterNonPremiumButton = filterPanel:getChildById('filterNonPremium')
  filterPremiumButton    = filterPanel:getChildById('filterPremium')
  filterOffensiveButton:setOn(not g_settings.getValue('Powers', 'filterOffensive', defaultValues.filterOffensive))
  filterDefensiveButton:setOn(not g_settings.getValue('Powers', 'filterDefensive', defaultValues.filterDefensive))
  filterNonPremiumButton:setOn(not g_settings.getValue('Powers', 'filterNonPremium', defaultValues.filterNonPremium))
  filterPremiumButton:setOn(not g_settings.getValue('Powers', 'filterPremium', defaultValues.filterPremium))
  GamePowers.onClickFilterOffensive(filterOffensiveButton)
  GamePowers.onClickFilterDefensive(filterDefensiveButton)
  GamePowers.onClickFilterNonPremium(filterNonPremiumButton)
  GamePowers.onClickFilterPremium(filterPremiumButton)

  powersPanel = powersWindow:getChildById('contentsPanel'):getChildById('powersPanel')

  connect(g_game, {
    onGameStart        = GamePowers.online,
    onGameEnd          = GamePowers.offline,
    onPlayerPowersList = GamePowers.onPlayerPowersList
  })

  if g_game.isOnline() then
    GamePowers.online()
  end
  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodePowerCast, GamePowers.parsePower)
  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodePowerList, GamePowers.parsePowerList)
end

function GamePowers.terminate()
  powersList = { }
  powerListByIndex = { }

  if g_game.isOnline() then
    GamePowers.offline()
  end

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodePowerCast)
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodePowerList)

  disconnect(g_game, {
    onGameStart        = GamePowers.online,
    onGameEnd          = GamePowers.offline,
    onPlayerPowersList = GamePowers.onPlayerPowersList
  })

  powersTopMenuButton:destroy()
  powersWindow:destroy()

  g_keyboard.unbindKeyDown(GamePowersActionKey)

  _G.GamePowers = nil
end

function GamePowers.online()
  powersWindow:setup(powersTopMenuButton)
  GamePowers.refreshList()
end

function GamePowers.offline()
  GamePowers.clearList()
  GamePowers.onCancelPower()
end

function GamePowers.toggle()
  GameInterface.toggleMiniWindow(powersWindow)
end

-- Filtering
function GamePowers.onClickArrowMenuButton(self)
  local newState = not self:isOn()
  arrowMenuButton:setOn(newState)
  powersHeader:setOn(not newState)
  g_settings.setValue('Powers', 'filterPanel', newState)
end

function GamePowers.powersButtonFilter(powerButton)
  local filterOffensive  = not filterOffensiveButton:isOn()
  local filterDefensive  = not filterDefensiveButton:isOn()
  local filterNonPremium = not filterNonPremiumButton:isOn()
  local filterPremium    = not filterPremiumButton:isOn()

  local power = powerButton.power
  return filterOffensive and power.aggressive or filterDefensive and not power.aggressive or filterNonPremium and not power.premium or filterPremium and power.premium or false
end

function GamePowers.filterPowersButtons()
  for _, powerButton in pairs(powersList) do
    powerButton:setOn(not GamePowers.powersButtonFilter(powerButton))
  end
end

function GamePowers.onClickFilterOffensive(self)
  local newState = not self:isOn()
  filterOffensiveButton:setOn(newState)
  g_settings.setValue('Powers', 'filterOffensive', newState)
  GamePowers.filterPowersButtons()
end

function GamePowers.onClickFilterDefensive(self)
  local newState = not self:isOn()
  filterDefensiveButton:setOn(newState)
  g_settings.setValue('Powers', 'filterDefensive', newState)
  GamePowers.filterPowersButtons()
end

function GamePowers.onClickFilterNonPremium(self)
  local newState = not self:isOn()
  filterNonPremiumButton:setOn(newState)
  g_settings.setValue('Powers', 'filterNonPremium', newState)
  GamePowers.filterPowersButtons()
end

function GamePowers.onClickFilterPremium(self)
  local newState = not self:isOn()
  filterPremiumButton:setOn(newState)
  g_settings.setValue('Powers', 'filterPremium', newState)
  GamePowers.filterPowersButtons()
end

-- Sorting
function GamePowers.getSortType()
  return g_settings.getValue('Powers', 'sortType', defaultValues.sortType)
end

function GamePowers.setSortType(state)
  g_settings.setValue('Powers', 'sortType', state)
  sortMenuButton:setTooltip(f(loc'${CorelibInfoSortBy}: %s (%s)', powersSortStr[state] or '', powersOrderStr[GamePowers.getSortOrder()] or ''))
  GamePowers.updatePowersList()
end

function GamePowers.getSortOrder()
  return g_settings.getValue('Powers', 'sortOrder', defaultValues.sortOrder)
end

function GamePowers.setSortOrder(state)
  g_settings.setValue('Powers', 'sortOrder', state)
  sortMenuButton:setTooltip(f(loc'${CorelibInfoSortBy}: %s (%s)', powersSortStr[GamePowers.getSortType()] or '', powersOrderStr[state] or ''))
  GamePowers.updatePowersList()
end

function GamePowers.createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = GamePowers.getSortOrder()
  if sortOrder == POWERS_ORDER_ASCENDING then
    menu:addOption(f(loc'${GamePowersInfoOrder}', powersOrderStr[POWERS_ORDER_DESCENDING]), function() GamePowers.setSortOrder(POWERS_ORDER_DESCENDING) end)
  elseif sortOrder == POWERS_ORDER_DESCENDING then
    menu:addOption(f(loc'${GamePowersInfoOrder}', powersOrderStr[POWERS_ORDER_ASCENDING]), function() GamePowers.setSortOrder(POWERS_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  local sortType = GamePowers.getSortType()
  if sortType ~= POWERS_SORT_NAME then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', powersSortStr[POWERS_SORT_NAME]), function() GamePowers.setSortType(POWERS_SORT_NAME) end)
  end
  if sortType ~= POWERS_SORT_CLASS then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', powersSortStr[POWERS_SORT_CLASS]), function() GamePowers.setSortType(POWERS_SORT_CLASS) end)
  end
  if sortType ~= POWERS_SORT_LEVEL then
    menu:addOption(f(loc'${CorelibInfoSortBy} %s', powersSortStr[POWERS_SORT_LEVEL]), function() GamePowers.setSortType(POWERS_SORT_LEVEL) end)
  end

  menu:display()
end

function GamePowers.sortPowers()
  local sortFunction
  local sortOrder = GamePowers.getSortOrder()
  local sortType  = GamePowers.getSortType()

  if sortOrder == POWERS_ORDER_ASCENDING then
    if sortType == POWERS_SORT_NAME then
      sortFunction = function(a,b)
        return a.power.name < b.power.name
      end

    elseif sortType == POWERS_SORT_CLASS then
      sortFunction = function(a,b)
        return a.power.class < b.power.class
      end

    elseif sortType == POWERS_SORT_LEVEL then
      sortFunction = function(a,b)
        return a.power.level < b.power.level
      end
    end

  elseif sortOrder == POWERS_ORDER_DESCENDING then
    if sortType == POWERS_SORT_NAME then
      sortFunction = function(a,b)
        return a.power.name > b.power.name
      end

    elseif sortType == POWERS_SORT_CLASS then
      sortFunction = function(a,b)
        return a.power.class > b.power.class
      end

    elseif sortType == POWERS_SORT_LEVEL then
      sortFunction = function(a,b)
        return a.power.level > b.power.level
      end
    end

  end

  if sortFunction then
    table.sort(powerListByIndex, sortFunction)
  end
end

function GamePowers.updatePowersList()
  GamePowers.sortPowers()
  for i = 1, #powerListByIndex do
    powersPanel:moveChildToIndex(powerListByIndex[i], i)
    powerListByIndex[i].index = i
  end
  GamePowers.filterPowersButtons()
  signalcall(GamePowers.onUpdatePowerList)
end

function GamePowers.clearList()
  powersList = { }
  powerListByIndex = { }
  powersPanel:destroyChildren()
end

function GamePowers.refreshList()
  if not g_game.isOnline() then
    return
  end

  GamePowers.clearList()

  local ignoreMessage = 1
  g_game.sendPowerBuffer(f('%d:%d:%d:%d', power_flag_updateList, ignoreMessage, 0, 0))
end

function GamePowers.add(power)
  local powerButton = powersList[power.id]
  if powerButton then
    return false -- Already added
  end

  -- Add
  powerButton = g_ui.createWidget('PowersListButton')
  powerButton:setup(power)

  -- powerButton.onMouseRelease = onPowerButtonMouseRelease

  powersList[power.id] = powerButton
  table.insert(powerListByIndex, powersList[power.id])

  powersPanel:addChild(powerButton)

  return true -- New added successfully
end

function GamePowers.update(power)
  local powerButton = powersList[power.id]
  if not powerButton then
    return false
  end

  powerButton:updateData(power)

  return true -- Updated successfully
end

function GamePowers.remove(powerId)
  if not powersList[powerId] then
    return false
  end

  powerListByIndex[powersList[powerId].index] = nil
  local widget = powersList[powerId]
  powersList[powerId] = nil
  widget:destroy()

  return true -- Removed successfully
end

function GamePowers.requestNonConstantPowerChanges(power)
  if not g_game.isOnline() then
    return
  end

  g_game.sendPowerBuffer(f('%d:%d:%d:%d', power_flag_updateNonConstantPower, power.id or 0, 0, 0))
end

function GamePowers.onPlayerPowersList(powers, updateNonConstantPower, ignoreMessage)
  local hasAdded   = false
  local hasRemoved = false

  -- Remove old buttons, if will update all powers
  if not updateNonConstantPower then
    GamePowers.clearList()
  end

  -- For add and update
  for _, powerData in ipairs(powers) do
    local power = { }

    power.id                   = powerData[1]
    power.name                 = powerData[2]
    power.level                = powerData[3]
    power.class                = powerData[4]
    power.aggressive           = power.class == POWER_CLASS_OFFENSIVE -- If power is offensive, it is aggressive on combat
    power.mana                 = powerData[5]
    power.exhaustTime          = powerData[6]
    power.vocations            = powerData[7]
    power.premium              = powerData[8]
    power.description          = powerData[9]
    power.descriptionBoostNone = powerData[10]
    power.descriptionBoostLow  = powerData[11]
    power.descriptionBoostHigh = powerData[12]
    power.constant             = powerData[13]

    power.onTooltipHoverChange =
    function(widget, hovered)
      if not g_app.isOnInputEvent() then
        return hovered
      end
      if hovered then
        local power = widget.power
        if power and not power.constant then
          GamePowers.requestNonConstantPowerChanges(power)
          return false -- Cancel old tooltip
        end
      end
      return true
    end

    local powerButton = powersList[power.id]
    if not powerButton then
      if not updateNonConstantPower then
        -- Add
        local ret = GamePowers.add(power)
        if not hasAdded then
          hasAdded = ret
        end
      end
    else
      -- Update
      GamePowers.update(power) -- No messages in this case, since is probably minor changes or nothing
    end
  end

  -- For remove
  if not updateNonConstantPower then
    for _ = #powersList, 1, -1 do -- for powerId in pairs(powersList) do
      local powerFound = false

      for _, powerData in ipairs(powers) do
        if powerId == powerData[1] then
          powerFound = true
          break
        end
      end

      if not powerFound then
        -- Remove
        local ret = GamePowers.remove(powerId)
        if not hasRemoved then
          hasRemoved = ret
        end
      end
    end
  end

  if modules.game_textmessage and not ignoreMessage and (hasAdded or hasRemoved) then
    GameTextMessage.displayGameMessage(loc'${GamePowersInfoPowerListUpdated}')
  end

  if not updateNonConstantPower then
    GamePowers.updatePowersList() -- Update once after adding all powers
  end

  if updateNonConstantPower then
    local widget = g_game.getWidgetByPos()
    if g_tooltip and widget and widget:hasTooltip() then
      widget:getTooltipObject():show(widget) -- Automatically show updated power tooltip
    end
  end
end

function GamePowers.getPowerButton(id)
  return id and powersList[id] or nil
end

function GamePowers.getPower(id)
  local ret = GamePowers.getPowerButton(id)
  return ret and ret.power or nil
end

function GamePowers.getPowerInfo(powerId)
  return powerInfo[powerId]
end

function GamePowers.parsePowerList(protocolGame, opcode, msg)
  local totalPowers = msg:getU8()
  for id = 1, totalPowers do
    local id = msg:getU8()
    powerInfo[id] = {
      name  = msg:getString(),
      level = msg:getU16()
    }
  end
  signalcall(GamePowers.onUpdatePowerList)
end
