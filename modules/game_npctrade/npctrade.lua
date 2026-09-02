g_locales.loadLocales(resolvepath(''))

_G.GameNpcTrade = { }



-- See achievements on server
HowToTownTrustStr = loc'${GameNpcTradeTrustHowToTown}'

GpsStr     = 'gps'
KapsStr    = 'KAps'
WeightUnit = loc'${CorelibInfoOz}'

BackpackSize   = 20
BackpackPrice  = 20
BackpackWeight = 18
ItemMaxAmount  = 100

ConstSlotFirst = 1 -- Server CONST_SLOT_FIRST
ConstSlotLast  = 11 -- Server CONST_SLOT_LAST

IgnoreInventory = true -- Old checkbox which now we use as a flag constant to ignore inventory when selling items



TradeType = {
  Buy  = 1,
  Sell = 2,
}

-- Error

TradeNoError               = 0
TradeUnknownError          = 1
TradeErrorNoEnoughMoney    = 2
TradeErrorNoEnoughCapacity = 3
TradeErrorNoEnoughTrust    = 4
TradeErrorItemNotFound     = 5
TradeErrorInventoryItem    = 6

TradeErrorStr = {
  [TradeNoError]               = '',
  [TradeUnknownError]          = loc'${GameNpcTradeUnknownError}',
  [TradeErrorNoEnoughMoney]    = loc'${GameNpcTradeErrorNoEnoughMoney}',
  [TradeErrorNoEnoughCapacity] = loc'${GameNpcTradeErrorNoEnoughCapacity}',
  [TradeErrorNoEnoughTrust]    = loc'${GameNpcTradeErrorNoEnoughTrust}',
  [TradeErrorItemNotFound]     = loc'${GameNpcTradeErrorItemNotFound}',
  [TradeErrorInventoryItem]    = loc'${GameNpcTradeErrorInventoryItem}',
}

-- Widget

npcWindow               = nil
itemsPanelListScrollBar = nil
itemsPanel              = nil
radioTabs               = nil
radioItems              = nil
searchText              = nil
setupPanel              = nil
quantityScroll          = nil
nameLabel               = nil
priceLabel              = nil
moneyLabel              = nil
kapsLabel               = nil
weightDesc              = nil
weightLabel             = nil
capacityDesc            = nil
capacityLabel           = nil
trustDesc               = nil
trustLabel              = nil
tradeButton             = nil
buyTab                  = nil
sellTab                 = nil
bankTrade               = nil
buyWithBackpack         = nil
ignoreCapacity          = nil
showAllItems            = nil
sellAllButton           = nil



initialized = false

cancelNextPopupRelease = nil

playerMoney     = 0
playerBankMoney = 0
playerKapsCoins = 0
playerKaps      = 0
vipNpc          = false

tradeItems   = { }
playerItems  = { }
selectedItem = nil

townId                    = 0
trustMaxLevel             = 0
townTrustLevel            = 0
townTrustExperience       = 0
townTrustExpOfActualLevel = 0
townTrustExpToNextLevel   = 0



function GameNpcTrade.init()
  -- Alias
  GameNpcTrade.m = modules.game_npctrade

  npcWindow = g_ui.displayUI('npctrade')
  npcWindow:setVisible(false)

  itemsPanelListScrollBar = npcWindow.itemsArea.itemsPanelListScrollBar

  itemsPanel = npcWindow.itemsArea.itemsPanel
  searchText = npcWindow.buyOptions.searchText

  setupPanel    = npcWindow.setupPanel
  tradeButton   = npcWindow.tradeButton
  sellAllButton = npcWindow.sellAllButton

  quantityScroll = setupPanel.quantityScroll
  nameLabel      = setupPanel.name
  priceLabel     = setupPanel.price
  moneyLabel     = setupPanel.money
  kapsLabel      = setupPanel.kaps
  weightDesc     = setupPanel.weightDesc
  weightLabel    = setupPanel.weight
  capacityDesc   = setupPanel.capacityDesc
  capacityLabel  = setupPanel.capacity
  trustDesc      = setupPanel.trustDesc
  trustLabel     = setupPanel.trust

  bankTrade       = npcWindow.buyOptions.bankTrade
  buyWithBackpack = npcWindow.buyOptions.buyWithBackpack
  ignoreCapacity  = npcWindow.buyOptions.ignoreCapacity
  showAllItems    = npcWindow.buyOptions.showAllItems

  buyTab  = npcWindow.buyTab
  sellTab = npcWindow.sellTab

  radioTabs = UIRadioGroup.create()
  radioTabs:addWidget(buyTab)
  radioTabs:addWidget(sellTab)
  radioTabs:selectWidget(buyTab)
  radioTabs.onSelectionChange = GameNpcTrade.onTradeTypeChange

  bankTrade:setChecked(true) -- Bank trade as default

  cancelNextPopupRelease = false

  connect(g_game, {
    onGameEnd       = GameNpcTrade.hide,
    onOpenNpcTrade  = GameNpcTrade.onOpenNpcTrade,
    onCloseNpcTrade = GameNpcTrade.onCloseNpcTrade,
    onPlayerGoods   = GameNpcTrade.onPlayerGoods
  })

  connect(LocalPlayer, {
    onFreeCapacityChange = GameNpcTrade.onFreeCapacityChange,
    onInventoryChange    = GameNpcTrade.onInventoryChange
  })

  initialized = true
end

function GameNpcTrade.terminate()
  initialized = false

  disconnect(g_game, {
    onGameEnd       = GameNpcTrade.hide,
    onOpenNpcTrade  = GameNpcTrade.onOpenNpcTrade,
    onCloseNpcTrade = GameNpcTrade.onCloseNpcTrade,
    onPlayerGoods   = GameNpcTrade.onPlayerGoods
  })

  disconnect(LocalPlayer, {
    onFreeCapacityChange = GameNpcTrade.onFreeCapacityChange,
    onInventoryChange    = GameNpcTrade.onInventoryChange
  })

  if radioItems then
    radioItems:destroy()
    radioItems = nil
  end

  if radioTabs then
    radioTabs:destroy()
    radioTabs = nil
  end

  npcWindow:destroy()
  npcWindow = nil

  itemsPanelListScrollBar = nil
  itemsPanel              = nil
  searchText              = nil
  setupPanel              = nil
  quantityScroll          = nil
  nameLabel               = nil
  priceLabel              = nil
  moneyLabel              = nil
  kapsLabel               = nil
  weightDesc              = nil
  weightLabel             = nil
  capacityDesc            = nil
  capacityLabel           = nil
  trustDesc               = nil
  trustLabel              = nil
  tradeButton             = nil
  buyTab                  = nil
  sellTab                 = nil
  bankTrade               = nil
  buyWithBackpack         = nil
  ignoreCapacity          = nil
  showAllItems            = nil
  sellAllButton           = nil
  selectedItem            = nil

  _G.GameNpcTrade = nil
end



-- General

function GameNpcTrade.show()
  if not g_game.isOnline() then
    return
  end

  if #tradeItems[TradeType.Buy] > 0 then
    radioTabs:selectWidget(buyTab)
  else
    radioTabs:selectWidget(sellTab)
  end

  itemsPanelListScrollBar:setValue(0)

  npcWindow:show()
  npcWindow:raise()
  npcWindow:focus()
end

function GameNpcTrade.hide()
  npcWindow:hide()
end

function GameNpcTrade.getCurrentTradeType()
  if tradeButton:getText() == loc'${GameNpcTradeTabSell}' then
    return TradeType.Sell
  end

  return TradeType.Buy
end

function GameNpcTrade.getCurrentMoney(item)
  if item.isPriceKaps then
    return bankTrade:isChecked() and playerKaps or playerKapsCoins
  end
  return bankTrade:isChecked() and playerBankMoney or playerMoney
end

function GameNpcTrade.formattedGoldPieces(amount)
  return f('%s %s', loc(amount), GpsStr)
end

function GameNpcTrade.formattedKAps(amount)
  return f('%s %s', loc(amount), KapsStr)
end

function GameNpcTrade.formattedPrice(item, isPriceKaps) -- (item) or (price, isPriceKaps)
  if type(item) == 'table' then
    return f('%s %s', loc(item.price), item.isPriceKaps and KapsStr or GpsStr)
  end

  return f('%s %s', item, isPriceKaps and KapsStr or GpsStr)
end

function GameNpcTrade.formattedTown()
  return townId > 0 and TownStr[townId] and f(' (%s)', TownStr[townId]) or ''
end

function GameNpcTrade.formattedTrust(item, includeCity)
  includeCity = includeCity == nil and true or includeCity

  if GameNpcTrade.getCurrentTradeType() == TradeType.Buy and item.tradeTrustLevel > 0 then
    return f(loc'${GameNpcTradeTrustLevel}', item.tradeTrustLevel)
  elseif GameNpcTrade.getCurrentTradeType() == TradeType.Sell and item.addTrustOnSell then
    return f(loc'${CorelibInfoYes}%s', includeCity and GameNpcTrade.formattedTown() or '')
  end
  return ''
end



-- Trade

function GameNpcTrade.getTradeItemData(id, tradeType)
  if table.empty(tradeItems[tradeType]) then
    return nil
  end

  -- Find in chosen TradeType
  if tradeType then
    for _, item in pairs(tradeItems[tradeType]) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
    return nil
  end

  -- Find in all trade types
  for _, items in pairs(tradeItems) do
    for _, item in pairs(items) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
  end

  return nil
end

function GameNpcTrade.canTradeItem(item)
  local localPlayer = g_game.getLocalPlayer()
  local tradeType   = GameNpcTrade.getCurrentTradeType()

  if tradeType == TradeType.Buy then
    if townTrustLevel < item.tradeTrustLevel then
      return TradeErrorNoEnoughTrust
    end

    local _, _, unitPrice = GameNpcTrade.getBuyAmount(item, 1)

    if unitPrice < 0 then
      return TradeUnknownError
    elseif GameNpcTrade.getCurrentMoney(item) < unitPrice then
      return TradeErrorNoEnoughMoney
    elseif not ignoreCapacity:isChecked() and localPlayer:getFreeCapacity() < item.weight then
      return TradeErrorNoEnoughCapacity
    end

  elseif tradeType == TradeType.Sell then
    local itemsAmount, unitPrice = GameNpcTrade.getSellAmount(item)

    if unitPrice < 0 then
      return TradeUnknownError
    elseif itemsAmount < 1 then
      if IgnoreInventory then
        local inventorySellQuantity = GameNpcTrade.getInventorySellQuantity(item.ptr)
        if inventorySellQuantity > 0 then
          return TradeErrorInventoryItem
        end
      end
      return TradeErrorItemNotFound
    end
  end

  return TradeNoError
end

function GameNpcTrade.refreshPlayerGoods()
  if not initialized then
    return
  end

  local localPlayer       = g_game.getLocalPlayer()
  local currentTradeType  = GameNpcTrade.getCurrentTradeType()
  local searchFilter      = searchText:getText():lower()
  local isBankTrade       = bankTrade:isChecked()
  local trustLabelMessage = ''
  local foundSelectedItem = false

  -- Refresh player goods base values
  moneyLabel:setText(f('%s (%s)', GameNpcTrade.formattedGoldPieces(isBankTrade and playerBankMoney or playerMoney), isBankTrade and loc'${GameNpcTradeGoodsFromBank}' or loc'${GameNpcTradeGoodsHoldingMoney}'))
  kapsLabel:setText(f('%s (%s)', GameNpcTrade.formattedKAps(isBankTrade and playerKaps or playerKapsCoins), isBankTrade and loc'${GameNpcTradeGoodsFromVipBank}' or loc'${GameNpcTradeGoodsHoldingMoney}'))
  capacityLabel:setText(f('%s %s', loc(localPlayer:getFreeCapacity()), WeightUnit))
  trustLabel:setText(f(loc'${GameNpcTradeGoodsTrustLevel}', townTrustLevel, loc(townTrustExperience)))

  -- Update tooltip

  GameNpcTrade.updateTradeButtonTooltip()
  GameNpcTrade.updateSellAllButtonTooltip()

  kapsLabel:setTooltip(loc'${GameNpcTradeKapsWarning}', TooltipType.textBlock)

  if townTrustLevel < trustMaxLevel then
    local trustExpDiff      = townTrustExpToNextLevel - townTrustExpOfActualLevel
    local trustExpToAdvance = townTrustExpToNextLevel - townTrustExperience
    local trustExpPercent   = (trustExpToAdvance / trustExpDiff) * 100
    trustLabelMessage       = f(loc'${GameNpcTradeTrustRemainingXp}', trustExpPercent, loc(trustExpToAdvance), townTrustLevel + 1, GameNpcTrade.formattedTown())
  else
    trustLabelMessage = f(loc'${GameNpcTradeTrustRemainingXpMax}', GameNpcTrade.formattedTown())
  end
  trustLabel:setTooltip(trustLabelMessage .. '\n\n' .. HowToTownTrustStr, TooltipType.textBlock)

  -- Refresh store items according to player goods

  -- For each item box
  for i = 1, itemsPanel:getChildCount() do
    local npcItemBox  = itemsPanel:getChildByIndex(i)
    local itemBox     = npcItemBox.itemBox -- Clickable item checkbox
    local boxOutfit   = itemBox.outfit
    local tradeItem   = itemBox.tradeItem
    local canTradeRet = GameNpcTrade.canTradeItem(tradeItem)
    local canTrade    = canTradeRet == TradeNoError

    -- Enable item box according to canTrade
    itemBox:setOn(canTrade)
    itemBox:setEnabled(canTrade)
    boxOutfit:setOn(canTrade)

    -- Set item box visibility according to search condition and show all items condition
    local searchCondition       = searchFilter == '' or tradeItem.name:lower():find(searchFilter)
    local showAllItemsCondition = currentTradeType == TradeType.Buy or showAllItems:isChecked() or currentTradeType == TradeType.Sell and not showAllItems:isChecked() and canTrade
    npcItemBox:setVisible(searchCondition and showAllItemsCondition)

    if not foundSelectedItem and selectedItem == tradeItem and npcItemBox:isVisible() and itemBox:isEnabled() then
      foundSelectedItem = true
    end
  end

  -- If selected item is not found in the search condition, clear its selection
  if not foundSelectedItem then
    GameNpcTrade.clearSelectedItem()
  end

  -- If there is still a selected item, refresh it
  if selectedItem then
    GameNpcTrade.refreshSelectedItem(selectedItem)
  end
end

do
  function GameNpcTrade.refreshTradeItems()
    local layout                = itemsPanel:getLayout()
    local localPlayer           = g_game.getLocalPlayer()
    local localPlayerOutfit     = localPlayer:getOutfit()
    local localPlayerOutfitType = localPlayerOutfit.type
    local tradeType             = GameNpcTrade.getCurrentTradeType()

    -- Disable layout updates
    layout:disableUpdates()

    -- Clear selected item
    GameNpcTrade.clearSelectedItem()

    -- Clear items of panel
    itemsPanel:destroyChildren()
    if radioItems then
      radioItems:destroy()
    end
    radioItems = UIRadioGroup.create()

    -- Clear other stuff
    searchText:clearText()
    setupPanel:disable()

    -- For each available item
    for _, tradeItem in pairs(tradeItems[tradeType]) do
      local npcItemBox = g_ui.createWidget('NPCItemBox', itemsPanel)
      local itemBox    = npcItemBox.itemBox -- Clickable item checkbox
      local boxOutfit  = itemBox.outfit
      local boxItem    = itemBox.item

      -- Attach trade item
      itemBox.tradeItem = tradeItem

      -- Update item box text
      local trustStr = GameNpcTrade.formattedTrust(tradeItem, false)
      trustStr       = string.exists(trustStr) and (tradeType == TradeType.Buy and f('\n%s %s', (loc'${GameNpcTradeTrust}'):lower(), trustStr:lower()) or tradeType == TradeType.Sell and loc'\n+ ${GameNpcTradeTrustXp}') or ''
      itemBox:setText(f('%s\n%s%s\n%.2f %s', tradeItem.name, GameNpcTrade.formattedPrice(tradeItem), trustStr, tradeItem.weight, WeightUnit))

      -- Item
      if tradeItem.maskOutfitType == 0 and tradeItem.maskOutfitMount == 0 then
        -- Hide outfit
        boxOutfit:hide()

        -- Update item
        boxItem:setItem(tradeItem.maskptr or tradeItem.ptr)
        boxItem.hoverLookAllowVirtual = true
        boxItem.hoverLookNpcTrade = true

      -- Outfit
      else
        -- Hide item
        boxItem:hide()

        -- Update outfit
        if tradeItem.maskOutfitType ~= 0 then
          localPlayerOutfit.type  = tradeItem.maskOutfitType
          localPlayerOutfit.mount = 0
        elseif tradeItem.maskOutfitMount ~= 0 then
          localPlayerOutfit.type  = localPlayerOutfitType
          localPlayerOutfit.mount = tradeItem.maskOutfitMount
        end
        localPlayerOutfit.auxType = 0
        boxOutfit:setOutfit(localPlayerOutfit)
      end

      -- Add item box to items list
      radioItems:addWidget(itemBox)
    end

    -- Enable layout updates
    layout:enableUpdates()

    -- Force layout update
    layout:update()
  end
end

function GameNpcTrade.closeNpcTrade()
  -- Request to close trade on server side
  g_game.closeNpcTrade()

  -- Hide window
  GameNpcTrade.hide()
end



-- Buy

function GameNpcTrade.getBuyAmount(item, amount) -- (item[, amount])
  local localPlayer      = g_game.getLocalPlayer()
  local buyWithBackpacks = buyWithBackpack:isChecked()
  local backpackPrice    = buyWithBackpacks and not item.isPriceKaps and BackpackPrice or 0
  local itemsAmount      = 0

  if not amount then
    local money = GameNpcTrade.getCurrentMoney(item)

    -- Item is stackable or 'buy with backpacks' checkbox is disabled
    if item.ptr:isStackable() or not buyWithBackpacks then
      itemsAmount = math.floor(math.max(0, money - backpackPrice) / item.price)

    -- Item is non-stackable and 'buy with backpacks' checkbox is enabled
    else
      -- Check item amount according to player money, up to ItemMaxAmount
      local minimumCost = item.price + backpackPrice
      while money >= minimumCost and itemsAmount < ItemMaxAmount do
        -- Buying each backpack of items until 100 items (it will loop until 5 times, since 5 * BackpackSize = ItemMaxAmount)
        local amount = math.min(math.floor(money / item.price), BackpackSize)
        local price  = amount * item.price + BackpackPrice

        if money < price then
          break
        end

        money       = money - price
        itemsAmount = itemsAmount + amount
      end
    end
  end

  -- Fit itemsAmount according to capItemAmount and ItemMaxAmount
  local capItemAmount = not ignoreCapacity:isChecked() and math.floor(localPlayer:getFreeCapacity() / item.weight) or ItemMaxAmount
  itemsAmount         = math.max(0, math.min(amount or itemsAmount, capItemAmount, ItemMaxAmount))

  local backpacks = buyWithBackpacks and (not item.ptr:isStackable() and math.ceil(itemsAmount / BackpackSize) or itemsAmount >= 1 and 1 or 0) or 0
  local price     = itemsAmount * item.price + backpacks * backpackPrice

  if amount and amount > itemsAmount then
    return 0, 0, 0
  end

  return itemsAmount, backpacks, price
end



-- Sell

function GameNpcTrade.getInventorySellQuantity(item)
  if not item or not playerItems[item:getId()] then
    return 0
  end

  local amount      = 0
  local localPlayer = g_game.getLocalPlayer()

  for slot = ConstSlotFirst, ConstSlotLast do
    local inventoryItem = localPlayer:getInventoryItem(slot)

    if inventoryItem and inventoryItem:getId() == item:getId() then
      amount = amount + inventoryItem:getCount()
    end
  end

  return amount
end

function GameNpcTrade.getSellQuantity(item)
  if not item or not playerItems[item:getId()] then
    return 0
  end

  return playerItems[item:getId()] - (IgnoreInventory and GameNpcTrade.getInventorySellQuantity(item) or 0)
end

function GameNpcTrade.getSellAmount(item, amount) -- (item[, amount])
  local itemsAmount = math.max(0, math.min(amount or GameNpcTrade.getSellQuantity(item.ptr), ItemMaxAmount))

  if amount and amount > itemsAmount then
    return 0, 0
  end

  return itemsAmount, itemsAmount * item.price
end

function GameNpcTrade.sellAll()
  -- For all player items
  for itemId in pairs(playerItems) do
    -- Get item data
    local item = GameNpcTrade.getTradeItemData(itemId, TradeType.Sell)
    if item then
      -- Get sell quantity
      local quantity = GameNpcTrade.getSellQuantity(item.ptr)
      if quantity > 0 then

        -- Sell item in specified quantity
        g_game.sellItem(item.ptr, item.maskptr, item.maskOutfitType, item.maskOutfitMount, quantity, bankTrade:isChecked(), IgnoreInventory)
      end
    end
  end

  if g_tooltip then
    Tooltip.hide()
  end
end



-- Selected item

function GameNpcTrade.clearSelectedItem()
  nameLabel:clearText()
  priceLabel:clearText()
  weightLabel:clearText()
  tradeButton:disable()
  quantityScroll:setMinimum(0)
  quantityScroll:setMaximum(0)

  if selectedItem then
    radioItems:selectWidget(nil)
    selectedItem = nil
  end
end

function GameNpcTrade.refreshSelectedItem(item)
  local tradeType        = GameNpcTrade.getCurrentTradeType()
  local quantity         = quantityScroll:getValue()
  local buyWithBackpacks = buyWithBackpack:isChecked()
  local backpackWeight   = buyWithBackpacks and not item.isPriceKaps and BackpackWeight or 0

  local itemsAmount, backpacks, totalPrice, _
  if tradeType == TradeType.Buy then
    itemsAmount              = GameNpcTrade.getBuyAmount(item)
    _, backpacks, totalPrice = GameNpcTrade.getBuyAmount(item, quantity)
  else
    itemsAmount   = GameNpcTrade.getSellAmount(item)
    _, totalPrice = GameNpcTrade.getSellAmount(item, quantity)
  end

  nameLabel:setText(item.name)

  local trustStr = GameNpcTrade.formattedTrust(item)
  trustStr       = string.exists(trustStr) and (tradeType == TradeType.Buy and f(' (%s %s)', (loc'${GameNpcTradeTrust}'):lower(), trustStr:lower()) or tradeType == TradeType.Sell and loc' + ${GameNpcTradeTrustXp}') or ''
  priceLabel:setText(f('%s%s', GameNpcTrade.formattedPrice(totalPrice, item.isPriceKaps), trustStr))

  weightLabel:setText(tradeType == TradeType.Buy and f('%.2f %s', item.weight * quantity + backpackWeight * backpacks, WeightUnit) or '')
  quantityScroll:setMinimum(itemsAmount > 0 and 1 or 0)
  quantityScroll:setMaximum(itemsAmount)

  setupPanel:enable()

  GameNpcTrade.updateTradeButtonTooltip()
end



-- Tooltip

function GameNpcTrade.updateTradeButtonTooltip()
  if not selectedItem then
    tradeButton:removeTooltip()
    return
  end

  local tradeType = GameNpcTrade.getCurrentTradeType()
  local quantity  = quantityScroll:getValue()
  local trustStr  = GameNpcTrade.formattedTrust(selectedItem)
  trustStr        = string.exists(trustStr) and (tradeType == TradeType.Buy and f(' (%s %s)', (loc'${GameNpcTradeTrust}'):lower(), trustStr:lower()) or tradeType == TradeType.Sell and loc' + ${GameNpcTradeTrustXp}') or ''

  local _, backpacks, totalPrice
  if tradeType == TradeType.Buy then
    _, backpacks, totalPrice = GameNpcTrade.getBuyAmount(selectedItem, quantity)
  else
    _, totalPrice = GameNpcTrade.getSellAmount(selectedItem, quantity)
  end

  -- Name
  local text = f(loc'${CorelibInfoName}: %s', selectedItem.name)

  -- Price and trust
  text = f(loc'%s\n\n${GameNpcTradeInfoPrice}: %s%s', text, GameNpcTrade.formattedPrice(selectedItem), trustStr)

  -- Weight
  if tradeType == TradeType.Buy then
    text = f(loc'%s\n${GameNpcTradeInfoWeight}: %.2f %s', text, selectedItem.weight, WeightUnit)
  end


  -- Count
  text = f(loc'%s\n\n${GameNpcTradeInfoCount}: %d', text, quantity)

  -- Total price
  text = f(loc'%s\n${GameNpcTradeInfoTotalPrice}: %s%s', text, GameNpcTrade.formattedPrice(totalPrice, selectedItem.isPriceKaps), trustStr)

  if tradeType == TradeType.Buy then
    -- Total weight
    local buyWithBackpacks = buyWithBackpack:isChecked()
    local backpackWeight   = buyWithBackpacks and not selectedItem.isPriceKaps and BackpackWeight or 0
    text = f(loc'%s\n${GameNpcTradeInfoTotalWeight}: %.2f %s', text, selectedItem.weight * quantity + backpackWeight * backpacks, WeightUnit)

    -- Backpack note
    text = f('%s%s', text, buyWithBackpack:isChecked() and f(loc'\n${GameNpcTradeInfoBpIncluded}', backpacks) or '')
  end

  tradeButton:setTooltip(text, TooltipType.textBlock)
end

function GameNpcTrade.updateSellAllButtonTooltip()
  local text           = ''
  local first          = true
  local finalPriceKaps = 0
  local finalPriceGps  = 0
  local hasTrust       = false

  -- For all player items
  for itemId in pairs(playerItems) do
    -- Get item data
    local item = GameNpcTrade.getTradeItemData(itemId, TradeType.Sell)
    if item then
      -- Get sell amount and price
      local itemsAmount = GameNpcTrade.getSellAmount(item)
      if itemsAmount > 0 then
        local _, totalPrice = GameNpcTrade.getSellAmount(item, itemsAmount)
        local trustStr      = GameNpcTrade.formattedTrust(item)
        if string.exists(trustStr) then
          hasTrust = true
        end

        -- Add item amount and price to text
        text  = f('%s%s* %dx %s: %s %s%s', text, (first and '' or '\n'), itemsAmount, item.name, loc(totalPrice), item.isPriceKaps and KapsStr or GpsStr, hasTrust and loc' + ${GameNpcTradeTrustXp}' or '')
        first = false

        if item.isPriceKaps then
          finalPriceKaps = finalPriceKaps + totalPrice
        else
          finalPriceGps = finalPriceGps + totalPrice
        end
      end
    end
  end

  -- Has content
  if text ~= '' then
    sellAllButton:setEnabled(true)

    do
      local finalPrices = { }
      if finalPriceKaps > 0 then
        finalPrices[#finalPrices + 1] = f('%s %s', finalPriceKaps, KapsStr)
      end
      if finalPriceGps > 0 then
        finalPrices[#finalPrices + 1] = f('%s %s', finalPriceGps, GpsStr)
      end
      text = f(loc'%s\n\n${GameNpcTradeInfoTotalPrice}: %s%s', text, table.list(finalPrices), hasTrust and loc' + ${GameNpcTradeTrustXp}' or '')
    end

    sellAllButton:setTooltip(text, TooltipType.textBlock)

  -- Has no content
  else
    sellAllButton:setEnabled(false)
    sellAllButton:removeTooltip()
  end
end



-- Trigger

function GameNpcTrade.onTradeTypeChange(radioTabs, selected, deselected)
  -- Update trade type tab
  tradeButton:setText(selected:getText())
  selected:setOn(true)
  deselected:setOn(false)

  -- Get updated trade type
  local currentTradeType = GameNpcTrade.getCurrentTradeType()

  buyWithBackpack:setVisible(currentTradeType == TradeType.Buy)
  ignoreCapacity:setVisible(currentTradeType == TradeType.Buy)
  showAllItems:setVisible(currentTradeType == TradeType.Sell)
  sellAllButton:setVisible(currentTradeType == TradeType.Sell)

  GameNpcTrade.refreshTradeItems()
  GameNpcTrade.refreshPlayerGoods()

  itemsPanelListScrollBar:setValue(0)
end

function GameNpcTrade.onTradeClick()
  if not selectedItem then
    return
  end

  local currentTradeType = GameNpcTrade.getCurrentTradeType()

  if currentTradeType == TradeType.Buy then
    g_game.buyItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), bankTrade:isChecked(), ignoreCapacity:isChecked(), buyWithBackpack:isChecked())
  elseif currentTradeType == TradeType.Sell then
    g_game.sellItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), bankTrade:isChecked(), IgnoreInventory)
  end
end

function GameNpcTrade.onItemBoxChecked(widget)
  if not widget:isChecked() then
    return
  end

  selectedItem = widget.tradeItem

  GameNpcTrade.refreshSelectedItem(selectedItem)
  tradeButton:enable()

  quantityScroll:setValue(quantityScroll:getMinimum())
end

function GameNpcTrade.onQuantityValueChange(quantity)
  if selectedItem then
    GameNpcTrade.refreshSelectedItem(selectedItem)
  end
end

function GameNpcTrade.onBankTradeChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onBuyWithBackpackChange()
  if selectedItem then
    GameNpcTrade.refreshSelectedItem(selectedItem)
  end
end

function GameNpcTrade.onSearchTextChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onIgnoreCapacityChange()
  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onShowAllItemsChange()
  GameNpcTrade.refreshPlayerGoods()
end



-- Callback

function GameNpcTrade.onOpenNpcTrade(items, _townId, _trustMaxLevel, isVip)
  tradeItems[TradeType.Buy]  = { }
  tradeItems[TradeType.Sell] = { }

  for _, item in pairs(items) do
    -- Buy
    if item[10] > 0 then
      table.insert(tradeItems[TradeType.Buy], {
        ptr             = item[1],
        maskptr         = item[2],
        maskOutfitType  = item[3],
        maskOutfitMount = item[4],
        description     = item[5],
        name            = item[6],
        weight          = item[7] / 100,
        addTrustOnSell  = item[8],
        tradeTrustLevel = item[9],

        price       = item[10],
        isPriceKaps = item[12],
      })
    end

    -- Sell
    if item[11] > 0 then
      table.insert(tradeItems[TradeType.Sell], {
        ptr             = item[1],
        maskptr         = item[2],
        maskOutfitType  = item[3],
        maskOutfitMount = item[4],
        description     = item[5],
        name            = item[6],
        weight          = item[7] / 100,
        addTrustOnSell  = item[8],
        tradeTrustLevel = item[9],

        price       = item[11],
        isPriceKaps = item[12],
      })
    end
  end

  townId        = _townId
  trustMaxLevel = _trustMaxLevel
  vipNpc        = isVip

  GameNpcTrade.refreshTradeItems()
  addEvent(GameNpcTrade.show)
end

function GameNpcTrade.onCloseNpcTrade()
  GameNpcTrade.hide()
end

function GameNpcTrade.onPlayerGoods(money, bankMoney, kapsCoins, kaps, _townTrustLevel, _townTrustExperience, _townTrustExpOfActualLevel, _townTrustExpToNextLevel, items)
  playerItems = { }

  playerMoney     = money
  playerBankMoney = bankMoney
  playerKapsCoins = kapsCoins
  playerKaps      = kaps

  for _, item in ipairs(items) do
    local id        = item[1]:getId()
    playerItems[id] = (playerItems[id] or 0) + item[2]
  end

  townTrustLevel            = _townTrustLevel
  townTrustExperience       = _townTrustExperience
  townTrustExpOfActualLevel = _townTrustExpOfActualLevel
  townTrustExpToNextLevel   = _townTrustExpToNextLevel

  GameNpcTrade.refreshPlayerGoods()
end

function GameNpcTrade.onFreeCapacityChange(localPlayer, freeCapacity, oldFreeCapacity)
  if npcWindow:isVisible() then
    GameNpcTrade.refreshPlayerGoods()
  end
end

function GameNpcTrade.onInventoryChange(localPlayer, slot, item, oldItem)
  if npcWindow:isVisible() then
    GameNpcTrade.refreshPlayerGoods()
  end
end
