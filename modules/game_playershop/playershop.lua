g_locales.loadLocales(resolvepath(''))

_G.GamePlayerShop = { }

initialized = false
cancelNextPopupRelease = nil

playerMoney     = 0
playerBankMoney = 0

tradeItems   = { }
playerItems  = { }
selectedItem = nil

ShopActions = {
  OpenShopWindow  = 0, -- client asks and server responds and open with list if yes or 0 if not
  CloseShopWindow = 1, -- client tells server that closed window or server asks server to close window
  ConfigShop      = 2, -- client opens/closes shop to public
  CheckAddItem    = 3, -- client tries to add item and server responds with item info if yes or 0 if not
  UpdateItem      = 4, -- client tries to change item value, or move item inside list
  RemoveItem      = 5, -- client removes item and server confirms
  BuyItem         = 6, -- client tries to buy item
}

-- See achievements on server

GpsStr     = 'gps'
WeightUnit = loc'${CorelibInfoOz}'

BackpackSize   = 20
BackpackPrice  = 20
BackpackWeight = 18
ItemMaxAmount  = 100
ItemMaxPrice   = 100000000

-- Error

TradeNoError               = 0
TradeUnknownError          = 1
TradeErrorNoEnoughMoney    = 2
TradeErrorNoEnoughCapacity = 3
TradeErrorItemNotFound     = 5
TradeErrorInventoryItem    = 6

TradeErrorStr = {
  [TradeNoError]               = '',
  [TradeUnknownError]          = loc'${GamePlayerShopUnknownError}',
  [TradeErrorNoEnoughMoney]    = loc'${GamePlayerShopErrorNoEnoughMoney}',
  [TradeErrorNoEnoughCapacity] = loc'${GamePlayerShopErrorNoEnoughCapacity}',
  [TradeErrorItemNotFound]     = loc'${GamePlayerShopErrorItemNotFound}',
  [TradeErrorInventoryItem]    = loc'${GamePlayerShopErrorInventoryItem}',
}

-- Widget

shopWindow              = nil
itemsPanelListScrollBar = nil
itemsPanel              = nil

radioItems              = nil
temporaryItemBox        = nil
temporaryItemIndex      = nil

searchText              = nil
setupPanel              = nil
setupTable              = nil
quantityScroll          = nil
nameLabel               = nil
priceLabel              = nil
moneyLabel              = nil
weightLabel             = nil
capacityLabel           = nil
tradeButton             = nil

bankTrade               = nil
buyWithBackpack         = nil
ignoreCapacity          = nil
showAllItems            = nil


function GamePlayerShop.init()
  -- Alias
  GamePlayerShop.m = modules.game_playershop

  shopWindow = g_ui.displayUI('playershop')
  shopWindow:setVisible(false)

  itemsPanelListScrollBar = shopWindow.itemsArea.itemsPanelListScrollBar

  itemsPanel = shopWindow.itemsArea.itemsPanel
  searchText = shopWindow.buyOptions.searchText

  setupPanel    = shopWindow.setupPanel
  tradeButton   = shopWindow.tradeButton

  quantityScroll = setupPanel.quantityScroll
  setupTable = setupPanel.setupTable

  -- Initialize table on demand (after UI/style is fully loaded)
  setupTableInitialized = false

  bankTrade       = shopWindow.buyOptions.buyOptionsContainer.bankTrade
  buyWithBackpack = shopWindow.buyOptions.buyOptionsContainer.buyWithBackpack
  ignoreCapacity  = shopWindow.buyOptions.buyOptionsContainer.ignoreCapacity
  showAllItems    = shopWindow.buyOptions.buyOptionsContainer.showAllItems

  bankTrade:setChecked(true) -- Bank trade as default

  if not radioItems then
    radioItems = UIRadioGroup.create()
  end

  cancelNextPopupRelease = false

  connect(g_game, {
    onGameEnd       = GamePlayerShop.hide,
    onPlayerGoods   = GamePlayerShop.onPlayerGoods
  })

  connect(LocalPlayer, {
    onFreeCapacityChange = GamePlayerShop.refreshPlayerGoods,
    onInventoryChange    = GamePlayerShop.refreshPlayerGoods
  })

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodePlayerShop, GamePlayerShop.parsePlayerShop)
  initialized = true



  itemsPanel.onDrop = function(self, droppedWidget, mousePos)
    if droppedWidget and droppedWidget:getClassName() == "UIItem" and not droppedWidget:isVirtual() then
      local index = GamePlayerShop.getIndexByPos(mousePos)
      -- server expects 0-based index
      GamePlayerShop.sendCheckAddShopItem(droppedWidget.position, math.max(0, (index or 1) - 1))
      -- remember where new item is placed so price window can use it
      if temporaryItemBox then
        temporaryItemBox.index = index
      end
      temporaryItemIndex = index
      GamePlayerShop.setupPriceWindow()
    end
  end

  itemsPanel.onHoverChange = GamePlayerShop.onHoverChange
end


function GamePlayerShop.initializeSetupTable()
  if setupTableInitialized or not setupTable or not setupPanel or not setupPanel.setupData then
    return
  end

  setupTable:setTableData(setupPanel.setupData)
  setupTable:clearData()

  local function addRow(labelText, id)
    local row = setupTable:addRow({ {text = labelText, width = 100}, {text = '', width = 100} })
    local cell = row:getChildByIndex(2)
    if cell then
      cell:setId(id)
    end
    return cell
  end

  nameLabel     = addRow(loc'${CorelibInfoName}:', 'name')
  priceLabel    = addRow(loc'${GamePlayerShopPriceDesc}:', 'price')
  weightLabel   = addRow(loc'${GamePlayerShopWeightDesc}:', 'weight')
  moneyLabel    = addRow(loc'${GamePlayerShopMoneyDesc}:', 'money')
  capacityLabel = addRow(loc'${GamePlayerShopCapacityDesc}:', 'capacity')

  setupTableInitialized = true
end



function GamePlayerShop.terminate()
  initialized = false

  --if shop is open
  GamePlayerShop:closeShop()

  shopWindow:destroy()
  shopWindow = nil

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodePlayerShop)

  disconnect(g_game, {
    onGameEnd       = GamePlayerShop.closeShop,
    onPlayerGoods   = GamePlayerShop.onPlayerGoods
  })

  disconnect(LocalPlayer, {
    onFreeCapacityChange = GamePlayerShop.refreshPlayerGoods,
    onInventoryChange    = GamePlayerShop.refreshPlayerGoods,
  })

  itemsPanelListScrollBar = nil
  itemsPanel = nil
  searchText = nil
  setupPanel = nil
  setupTable = nil
  setupTableInitialized = nil
  quantityScroll = nil
  nameLabel = nil
  priceLabel = nil
  moneyLabel = nil
  weightLabel = nil
  capacityLabel = nil
  tradeButton = nil
  buyTab = nil
  sellTab = nil
  bankTrade = nil
  buyWithBackpack = nil
  ignoreCapacity = nil
  showAllItems = nil
  sellAllButton = nil
  selectedItem = nil
  temporaryItemBox = nil

  _G.GamePlayerShop = nil
end


-- General

function GamePlayerShop.setupPriceWindow()
  priceWindow = g_ui.createWidget('PriceWindow', rootWidget)
  priceWindow.itemValue.onTextChange = function(widget, text, oldText)
    if string.match(text, "^%d*$") == nil or tonumber(text) > ItemMaxPrice then
      widget:setText(oldText)
    else
      widget:setText(tonumber(text))
    end
  end

  local okFunc = function()
    local price = tonumber(priceWindow.itemValue:getText()) or 0
    -- use stored index from temporaryItemBox or fallback global
    local idx = (temporaryItemBox and temporaryItemBox.index) or temporaryItemIndex
    if idx then
      -- server expects 0-based index
      GamePlayerShop.sendUpdateShopItem(math.max(0, idx - 1), price)
    end
    priceWindow:destroy()
    priceWindow = nil
  end

  local cancelFunc = function()
    priceWindow:destroy()
    priceWindow = nil
    GamePlayerShop.resetTempContainer()
  end

  priceWindow.onEnter = okFunc
  priceWindow.onEscape = cancelFunc

  local okButton = priceWindow.buttonOk
  okButton.onClick = okFunc

  local cancelButton = priceWindow.buttonCancel
  cancelButton.onClick = cancelFunc
end

function GamePlayerShop.onHoverChange(widget, hovered)
  local item = g_ui.getDraggingWidget()
  local mousePos = g_window.getMousePosition()
  if item and item:getClassName() == "UIItem" and not item:isVirtual() then
    if hovered and not temporaryItemBox then
      local index = GamePlayerShop.getIndexByPos(mousePos)
      temporaryItemBox = GamePlayerShop.createItemBox({clientId = item:getItemId(), subType = item:getItemSubType(), temp = true})
    elseif not hovered and temporaryItemBox then
      GamePlayerShop.resetTempContainer()
    end
  end

  if hovered then
    widget:setColor('#FFFFFF')
  else
    widget:setColor('#AAAAAA')
  end
end

function GamePlayerShop.onDragMove(widget, mousePos, mouseMoved)
  if temporaryItemBox then
    local index = GamePlayerShop.getIndexByPos(mousePos)
    widget:moveChildToIndex(temporaryItemBox, index)
  end
end

function GamePlayerShop.onDrop(widget, droppedWidget, mousePos)
  if widget == itemsPanel and droppedWidget:getClassName() == 'UIItem' then
    print("dropped")
    GamePlayerShop.sendShopAddItem(droppedWidget:getItem())
  end
end

function GamePlayerShop.sendShopAddItem(item)
  if not item or not g_game.isOnline() then
    return
  end

  g_game.addShopItem(item)
end

function GamePlayerShop.show()
  if not g_game.isOnline() then
    return
  end

  itemsPanelListScrollBar:setValue(0)

  shopWindow:show()
  shopWindow:raise()
  shopWindow:focus()
end

function GamePlayerShop.hide()
  shopWindow:hide()
end


function GamePlayerShop.getCurrentMoney(item)
  return bankTrade:isChecked() and playerBankMoney or playerMoney
end

function GamePlayerShop.formattedGoldPieces(amount)
  return f('%s %s', loc(amount), GpsStr)
end

function GamePlayerShop.formattedPrice(item) -- (item) or (price)
  if type(item) == 'table' then
    return f('%s %s', loc(item.price), GpsStr)
  end

  return f('%s %s', item, GpsStr)
end





-- Trade

function GamePlayerShop.canBuyItem(item)
  local localPlayer = g_game.getLocalPlayer()
  local _, _, unitPrice = GamePlayerShop.getBuyAmount(item, 1)
  if unitPrice < 0 then
    return TradeUnknownError
  elseif GamePlayerShop.getCurrentMoney(item) < unitPrice then
    return TradeErrorNoEnoughMoney
  elseif not ignoreCapacity:isChecked() and localPlayer:getFreeCapacity() < item.weight then
    return TradeErrorNoEnoughCapacity
  end
  return TradeNoError
end

function GamePlayerShop.getIndexByPos(mousePos)
  local itemBoxes = radioItems.widgets
  local index = 1
  for i, w in ipairs(itemBoxes) do
    if mousePos.x <= w:getX() + math.floor(w:getWidth() / 2) then
      index = i
      break
    end
    index = i + 1
  end
  return index
end

function GamePlayerShop.refreshPlayerGoods()
  if not initialized or not shopWindow:isVisible() then
    return
  end

  local localPlayer       = g_game.getLocalPlayer()
  local searchFilter      = searchText:getText():lower()
  local isBankTrade       = bankTrade:isChecked()
  local foundSelectedItem = false

  -- Refresh player goods base values
  moneyLabel:setText(f('%s (%s)', GamePlayerShop.formattedGoldPieces(isBankTrade and playerBankMoney or playerMoney), isBankTrade and loc'${GamePlayerShopGoodsFromBank}' or loc'${GamePlayerShopGoodsHoldingMoney}'))
  capacityLabel:setText(f('%s %s', loc(localPlayer:getFreeCapacity()), WeightUnit))

  -- Update tooltip

  GamePlayerShop.updateTradeButtonTooltip()

  -- Refresh store items according to player goods

  -- For each item box
  for i = 1, itemsPanel:getChildCount() do
    local shopItemBox  = itemsPanel:getChildByIndex(i)
    local itemBox     = shopItemBox.itemBox -- Clickable item checkbox
    local boxOutfit   = itemBox.outfit
    local tradeItem   = itemBox.tradeItem
    local canTradeRet = GamePlayerShop.canTradeItem(tradeItem)
    local canTrade    = canTradeRet == TradeNoError

    -- Enable item box according to canTrade
    itemBox:setOn(canTrade)
    itemBox:setEnabled(canTrade)
    boxOutfit:setOn(canTrade)

    -- Set item box visibility according to search condition and show all items condition
    local searchCondition       = searchFilter == '' or tradeItem.name:lower():find(searchFilter)
    local showAllItemsCondition = not showAllItems:isChecked() and canTrade
    shopItemBox:setVisible(searchCondition and showAllItemsCondition)

    if not foundSelectedItem and selectedItem == tradeItem and shopItemBox:isVisible() and itemBox:isEnabled() then
      foundSelectedItem = true
    end
  end

  -- If selected item is not found in the search condition, clear its selection
  if not foundSelectedItem then
    GamePlayerShop.clearSelectedItem()
  end

  -- If there is still a selected item, refresh it
  if selectedItem then
    GamePlayerShop.refreshSelectedItem(selectedItem)
  end
end

function GamePlayerShop.createItemBox(item)
  -- ensure item has a valid ptr for price/capacity calculations
  if item and not item.ptr and Item and type(Item.create) == 'function' then
    item.ptr = Item.create(item.clientId)
  end

  local shopItemBox = g_ui.createWidget('ShopItemBox', itemsPanel)
  local itemBox    = shopItemBox.itemBox -- Clickable item checkbox
  local boxItem    = itemBox.item

  -- Update item
  boxItem:setItemId(item.clientId)
  boxItem:setItemSubType(item.subType or 0)
  boxItem:updateBackground()

  if item.temp then
    shopItemBox:setOpacity(0.5)
  else
    shopItemBox:setOpacity(1.0)
    itemBox.tradeItem = item
    itemBox:setText(f('%s\n%s\n%.2f %s', item.name, GamePlayerShop.formattedPrice(item), item.weight, WeightUnit))

    shopItemBox.removeItemButton:show()
  end

  -- preserve index if provided
  if item.index then
    shopItemBox.index = item.index
    itemBox.index = item.index
  end

  -- Add item box to items list
  radioItems:addWidget(itemBox)
  return itemBox
end

function GamePlayerShop.resetTempContainer()
  if temporaryItemBox and temporaryItemBox:getParent() then
    radioItems:removeWidget(temporaryItemBox)
    temporaryItemBox:getParent():destroy()
    temporaryItemBox = nil
  end
  temporaryItemIndex = nil
end

function GamePlayerShop.refreshTradeItems()
  print("refresh trade items")
  local layout                = itemsPanel:getLayout()
  local localPlayer           = g_game.getLocalPlayer()

  -- Disable layout updates
  layout:disableUpdates()

  -- Clear selected item
  GamePlayerShop.clearSelectedItem()

  -- Clear items of panel
  itemsPanel:destroyChildren()
  radioItems:destroy()

  -- Clear other stuff
  searchText:clearText()
  setupPanel:disable()

  -- For each available item
  for _, tradeItem in pairs(tradeItems) do
    -- Create item box
    GamePlayerShop.createItemBox(tradeItem)
  end

  -- Enable layout updates
  layout:enableUpdates()

  -- Force layout update
  layout:update()
end

function GamePlayerShop.closeShop()
  -- Hide window
  GamePlayerShop.hide()
  GamePlayerShop.resetTempContainer()
  if g_game.isOnline() then
    GamePlayerShop:sendCloseShopWindow()
  end
end

function GamePlayerShop.closeShopServer()
  -- Server requested close; do not resend close command.
  GamePlayerShop.hide()
  GamePlayerShop.resetTempContainer()
end

function GamePlayerShop.checkShopItemResult(protocol, msg)
  local canAdd = msg:getU8() ~= 0
  local index = msg:getU8()
  local clientId = msg:getU16()
  local subType = msg:getU8()

  if canAdd then
    -- Optionally highlight or update the slot so the user can place the item.
    -- For now, we just debug log.
    print(('GamePlayerShop: shop item %d can be added (clientId=%d subType=%d)'):format(index, clientId, subType))
  else
    print(('GamePlayerShop: shop item %d cannot be added (clientId=%d subType=%d)'):format(index, clientId, subType))
  end
end

function GamePlayerShop.parsePlayerShop(protocol, msg)
  local action = msg:getU8()
  if action == ShopActions.OpenShopWindow then
    GamePlayerShop.openShop(protocol, msg)
  elseif action == ShopActions.CheckAddItem then
    GamePlayerShop.checkShopItemResult(protocol, msg)
  elseif action == ShopActions.CloseShopWindow then
    GamePlayerShop.closeShopServer()
  else
    print(('GamePlayerShop: unknown ServerShopAction %d'):format(action))
  end
end


-- Buy

function GamePlayerShop.getBuyAmount(item, amount) -- (item[, amount])
  local localPlayer      = g_game.getLocalPlayer()
  local buyWithBackpacks = buyWithBackpack:isChecked()
  local backpackPrice    = buyWithBackpacks and BackpackPrice or 0
  local itemsAmount      = 0

  if not amount then
    local money = GamePlayerShop.getCurrentMoney(item)

    -- Item is stackable or 'buy with backpacks' checkbox is disabled
    if (item.ptr and item.ptr:isStackable()) or not buyWithBackpacks then
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

  local backpacks = 0
  if buyWithBackpacks then
    if item.ptr and not item.ptr:isStackable() then
      backpacks = math.ceil(itemsAmount / BackpackSize)
    elseif itemsAmount >= 1 then
      backpacks = 1
    end
  end
  local price     = itemsAmount * item.price + backpacks * backpackPrice

  if amount and amount > itemsAmount then
    return 0, 0, 0
  end

  return itemsAmount, backpacks, price
end






-- Selected item

function GamePlayerShop.clearSelectedItem()
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

function GamePlayerShop.refreshSelectedItem()
  if not selectedItem then
    return
  end


  local quantity         = quantityScroll:getValue()

  local itemsAmount, totalPrice, _

    itemsAmount              = GamePlayerShop.getBuyAmount(selectedItem)
    _, totalPrice = GamePlayerShop.getBuyAmount(selectedItem, quantity)

  nameLabel:setText(selectedItem.name)

  priceLabel:setText(f('%s', GamePlayerShop.formattedPrice(totalPrice)))

  weightLabel:setText(f('%.2f %s', selectedItem.weight * quantity, WeightUnit) or '')
  quantityScroll:setMinimum(itemsAmount > 0 and 1 or 0)
  quantityScroll:setMaximum(itemsAmount)

  setupPanel:enable()

  GamePlayerShop.updateTradeButtonTooltip()
end



-- Tooltip

function GamePlayerShop.updateTradeButtonTooltip()
  if not selectedItem then
    tradeButton:removeTooltip()
    return
  end

  local quantity  = quantityScroll:getValue()

  local _, backpacks, totalPrice
  _, backpacks, totalPrice = GamePlayerShop.getBuyAmount(selectedItem, quantity)


  -- Name
  local text = f(loc'${CorelibInfoName}: %s', selectedItem.name)

  -- Price
  text = f(loc'%s\n\n${GamePlayerShopInfoPrice}: %s', text, GamePlayerShop.formattedPrice(selectedItem))

  -- Weight
  text = f(loc'%s\n${GamePlayerShopInfoWeight}: %.2f %s', text, selectedItem.weight, WeightUnit)

  -- Count
  text = f(loc'%s\n\n${GamePlayerShopInfoCount}: %d', text, quantity)

  -- Total price
  text = f(loc'%s\n${GamePlayerShopInfoTotalPrice}: %s', text, GamePlayerShop.formattedPrice(totalPrice))


  -- Total weight
  local buyWithBackpacks = buyWithBackpack:isChecked()
  local backpackWeight   = buyWithBackpacks and BackpackWeight or 0
  text = f(loc'%s\n${GamePlayerShopInfoTotalWeight}: %.2f %s', text, selectedItem.weight * quantity + backpackWeight * backpacks, WeightUnit)

  -- Backpack note
  text = f('%s%s', text, buyWithBackpack:isChecked() and f(loc'\n${GamePlayerShopInfoBpIncluded}', backpacks) or '')

  tradeButton:setTooltip(text, TooltipType.textBlock)
end


-- Trigger

function GamePlayerShop.onTradeClick()
  if not selectedItem or not selectedItem.ptr then
    return
  end

  g_game.buyItem(selectedItem.ptr, selectedItem.maskptr, selectedItem.maskOutfitType, selectedItem.maskOutfitMount, quantityScroll:getValue(), bankTrade:isChecked(), ignoreCapacity:isChecked(), buyWithBackpack:isChecked())
end

function GamePlayerShop.onItemBoxChecked(widget)
  if not widget:isChecked() then
    return
  end

  selectedItem = widget.tradeItem

  GamePlayerShop.refreshSelectedItem()
  tradeButton:enable()

  quantityScroll:setValue(quantityScroll:getMinimum())
end



-- Callback

function GamePlayerShop.onClose()
  GamePlayerShop.hide()
end

function GamePlayerShop.onPlayerGoods(money, bankMoney, items)
  playerItems = { }

  playerMoney     = money
  playerBankMoney = bankMoney

  for _, item in ipairs(items) do
    local id        = item[1]:getId()
    playerItems[id] = (playerItems[id] or 0) + item[2]
  end

  GamePlayerShop.refreshPlayerGoods()
end


local config = {
  tradeItems = {},
  isOwner    = false,
  shopName   = "",
}

-- Protocol Receive
function GamePlayerShop.openShop(protocol, msg)
  GamePlayerShop.resetTempContainer()
  config.tradeItems = {}
  config.shopId = msg:getU16()
  config.isOwner = msg:getU8() ~= 0
  config.shopName = msg:getString()

  -- Clear current UI before repopulating to reflect latest server state
  if itemsPanel then itemsPanel:destroyChildren() end
  if radioItems then radioItems:destroy() end

  local itemCount = msg:getU16()
  for i = 1, itemCount do
    config.tradeItems[i] = {
      clientId = msg:getU16(),
      subType = msg:getU8(),
      name = msg:getString(),
      description = msg:getString(),
      weight = msg:getU32() / 100,
      class = msg:getU8(),
      tier = msg:getU8(),
      durability = msg:getU32(),
      price = msg:getU32(),
    }
    -- create a client-side Item pointer for usage in buy logic
    if Item and type(Item.create) == 'function' then
      config.tradeItems[i].ptr = Item.create(config.tradeItems[i].clientId)
    end
    GamePlayerShop.createItemBox(config.tradeItems[i])
  end
  print_r(config)

  -- keep tradeItems in sync (used by refreshTradeItems)
  tradeItems = config.tradeItems

  GamePlayerShop.initializeSetupTable()
  GamePlayerShop.show()
  if config.isOwner then
    connect(shopWindow, { onDrop = GamePlayerShop.onDrop })
  end
end

-- Protocol Send

local function sendShopAction(action, writePayload)
  local protocol = g_game.getProtocolGame()
  if not protocol then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodePlayerShop)
  msg:addU8(action)
  if writePayload then
    writePayload(msg)
  end
  protocol:send(msg)
end

-- Shop Window

function GamePlayerShop.sendOpenShopWindow(playerId)
  sendShopAction(ShopActions.OpenShopWindow, function(msg)
    msg:addU8(playerId)
  end)
end

function GamePlayerShop.sendCloseShopWindow()
  sendShopAction(ShopActions.CloseShopWindow)
end

-- Shop

function GamePlayerShop.sendConfigShop(playerId)
    sendShopAction(ShopActions.ConfigShop, function(msg)
    msg:addU8(playerId)
  end)
end

-- Shop Item

function GamePlayerShop.sendCheckAddShopItem(pos, index)
  sendShopAction(ShopActions.CheckAddItem, function(msg)
    msg:addPosition(pos)
    msg:addU8(index)
  end)
end

function GamePlayerShop.sendUpdateShopItem(index, price)
  sendShopAction(ShopActions.UpdateItem, function(msg)
    msg:addU32(price)
  end)
end

function GamePlayerShop.sendRemoveShopItem(index)
  sendShopAction(ShopActions.RemoveItem, function(msg)
    msg:addU8(index)
  end)
end
