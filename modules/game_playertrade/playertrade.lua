g_locales.loadLocales(resolvepath(''))

_G.GamePlayerTrade = { }



tradeWindow = nil

function GamePlayerTrade.init()
  -- Alias
  GamePlayerTrade.m = modules.game_playertrade

  g_ui.importStyle('tradewindow')

  connect(g_game, {
    onOwnTrade     = GamePlayerTrade.onGameOwnTrade,
    onCounterTrade = GamePlayerTrade.onGameCounterTrade,
    onCloseTrade   = GamePlayerTrade.onGameCloseTrade,
    onGameEnd      = GamePlayerTrade.onGameCloseTrade
  })
end

function GamePlayerTrade.terminate()
  disconnect(g_game, {
    onOwnTrade     = GamePlayerTrade.onGameOwnTrade,
    onCounterTrade = GamePlayerTrade.onGameCounterTrade,
    onCloseTrade   = GamePlayerTrade.onGameCloseTrade,
    onGameEnd      = GamePlayerTrade.onGameCloseTrade
  })

  if tradeWindow then
    tradeWindow:destroy()
  end

  _G.GamePlayerTrade = nil
end

function GamePlayerTrade.createTrade()
  tradeWindow = g_ui.createWidget('TradeWindow')

  if not GameInterface.addToPanels(tradeWindow) then
    tradeWindow = nil
    return
  end

  tradeWindow.onClose = function()
    g_game.rejectTrade()
    tradeWindow:hide()
  end
  tradeWindow:setContentMinimumHeight(80)
  tradeWindow:setup()
  tradeWindow:setContentHeight(80)
end

function GamePlayerTrade.fillTrade(name, items, counter)
  if not tradeWindow then
    GamePlayerTrade.createTrade()
  end

  local tradeItemWidget = tradeWindow:getChildById('tradeItem')
  tradeItemWidget:setItemId(items[1]:getId())

  local tradeContainer
  local label
  if counter then
    tradeContainer = tradeWindow:recursiveGetChildById('counterTradeContainer')
    label = tradeWindow:recursiveGetChildById('counterTradeLabel')

    tradeWindow:recursiveGetChildById('acceptButton'):enable()
  else
    tradeContainer = tradeWindow:recursiveGetChildById('ownTradeContainer')
    label = tradeWindow:recursiveGetChildById('ownTradeLabel')
  end
  label:setText(name)

  for index,item in ipairs(items) do
    local itemWidget = g_ui.createWidget('Item', tradeContainer)
    itemWidget:setItem(item)
    itemWidget:setVirtual(true)
    itemWidget:setMargin(0)
    itemWidget.onClick = function()
      g_game.inspectTrade(counter, index-1)
    end
  end
end

function GamePlayerTrade.onGameOwnTrade(name, items)
  GamePlayerTrade.fillTrade(name, items, false)
end

function GamePlayerTrade.onGameCounterTrade(name, items)
  GamePlayerTrade.fillTrade(name, items, true)
end

function GamePlayerTrade.onGameCloseTrade()
  if tradeWindow then
    tradeWindow:destroy()
    tradeWindow = nil
  end
end
