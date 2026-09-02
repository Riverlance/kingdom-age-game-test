_G.GameLootbar = { }



lootWidget = nil

local queue = { }
local config = {
  maxItems = 10,
  showingTime = 5000,
  shrinkTime = 1800,
  shrinkInterval = 50,
  baseMargin = 4 -- Old: 8
}



function GameLootbar.init()
  -- Alias
  GameLootbar.m = modules.ka_game_lootbar

  g_ui.importStyle('lootbar')

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeLootWindow, GameLootbar.onLoot)
  connect(g_game, {
    onClientOptionChanged = GameLootbar.onClientOptionChanged,
  })
  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameLootbar.onGeometryChange,
    onViewModeChange = GameLootbar.onViewModeChange,
    onZoomChange     = GameLootbar.onZoomChange,
  })

  if not lootWidget then
    lootWidget = g_ui.createWidget('LootPanel', GameInterface.getRootPanel())
    g_ui.createWidget('ItemBoxLeft', lootWidget)
    g_ui.createWidget('ItemBoxRight', lootWidget)
    lootWidget:setVisible(false)
    lootWidget:setWidth(48)
    GameLootbar.updatePosition()
  end
end

function GameLootbar.terminate()
  if lootWidget then
    lootWidget:destroy()
  end

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameLootbar.onGeometryChange,
    onViewModeChange = GameLootbar.onViewModeChange,
    onZoomChange     = GameLootbar.onZoomChange,
  })
  disconnect(g_game, {
    onClientOptionChanged = GameLootbar.onClientOptionChanged,
  })
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeLootWindow)

  _G.GameLootbar = nil
end

function GameLootbar.updatePosition()
  if not lootWidget then
    return
  end

  local margin = GameInterface.m.topMenuButton:getHeight() + config.baseMargin

  -- Hotkey bar
  local topHotkeyBar = modules.ka_game_hotkeybars and GameHotkeyBars.getHotkeyBars()[AnchorTop] or nil
  if topHotkeyBar and topHotkeyBar:isVisible() then
    margin = margin + topHotkeyBar:getHeight()
  end

  addEvent(withWeakWidget(lootWidget, function(widget) widget:setMarginTop(margin) end))
end

function GameLootbar.onGeometryChange(self)
  GameLootbar.updatePosition()
end

function GameLootbar.onViewModeChange(mapWidget, newMode, oldMode)
  GameLootbar.updatePosition()
end

function GameLootbar.onClientOptionChanged(key, value, force, wasClientSettingUp)
  GameLootbar.updatePosition()
end

function GameLootbar.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end

  GameLootbar.updatePosition()
end

function GameLootbar.updateLootWidget()
  local width = 0
  for i = 1, lootWidget:getChildCount() do
    local child = lootWidget:getChildByIndex(i)
    width = width + child:getWidth()
  end

  lootWidget:setWidth(width)
end

function GameLootbar.removeWidget(widget)
  if lootWidget:hasChild(widget) then
    removeEvent(widget.shrinkInEvent)
    removeEvent(widget.shrinkOutEvent)
    widget.shrinkInEvent  = nil
    widget.shrinkOutEvent = nil

    lootWidget:removeChild(widget)

    widget:destroy()

    if #queue > 0 then
      local item = queue[1]
      table.remove(queue, 1)
      GameLootbar.addItem(item.item, item.count, item.name, item.pos)
    end

    if lootWidget:getChildCount() <= 2 then
      lootWidget:setVisible(false)
    end
  end
end

function GameLootbar.clearLoot()
  queue = { }

  for i = lootWidget:getChildCount(), 1, -1 do
    local child = lootWidget:getChildByIndex(i)
    if child:getStyleName() == 'ItemBoxContainer' then
      GameLootbar.removeWidget(child)
    end
  end
end

function GameLootbar.shrinkOut(widget, time)
  local opacity = time / config.shrinkTime
  local width   = math.floor(widget.realWidth * math.min((time / config.shrinkTime) * 1.5, 1))
  if opacity <= 0 or width <= 0 then
    GameLootbar.removeWidget(widget)
    return
  end

  local item = widget:getChildById('item')
  if item then
    item:setOpacity(opacity)
  end

  widget:setWidth(width)
  GameLootbar.updatePosition()

  widget.shrinkOutEvent = scheduleEvent(function()
    if isWidgetAlive(widget) then
      GameLootbar.shrinkOut(widget, time - config.shrinkInterval)
    end
  end, config.shrinkInterval)

  GameLootbar.updateLootWidget()
end

function GameLootbar.onHoverChange(widget, hovered)
  if hovered and os.time() > widget.lastHover then
    g_game.sendMagicEffect(widget.pos, 32)    -- stun / stars
    g_game.sendMagicEffect(widget.pos, 57)    -- orange square
    g_game.sendDistanceEffect(widget.pos, 41) -- red thing
    widget.lastHover = os.time()
  end
end

function GameLootbar.addItem(id, count, name, pos)
  count = count or 1
  if lootWidget:getChildCount() - 2 >= config.maxItems then
    table.insert(queue, { item = id, count = count, name = name, pos = pos })
    return
  end

  local widget = g_ui.createWidget('ItemBoxContainer', lootWidget)
  widget:setTooltip((count > 1 and count .. 'x ' or '') .. name)
  widget.realWidth = widget:getWidth()
  widget.pos = pos
  widget.lastHover = 0
  connect(widget, {
    onHoverChange = GameLootbar.onHoverChange
  })

  lootWidget:moveChildToIndex(widget, lootWidget:getChildCount() - 1)
  lootWidget:setVisible(true)
  GameLootbar.updatePosition()

  local item = widget:getChildById('item')
  item:setItemId(id)
  item:setItemCount(count)

  widget.shrinkInEvent = scheduleEvent(function()
    if isWidgetAlive(widget) then
      GameLootbar.shrinkOut(widget, config.shrinkTime)
    end
  end, config.showingTime)

  GameLootbar.updateLootWidget()
end

function GameLootbar.onLoot(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = buffer / ':'

  if ClientOptions.getOption('clearLootbarItemsOnEachDrop') then
    GameLootbar.clearLoot()
  end

  local pos = { x = tonumber(params[1]), y = tonumber(params[2]), z = tonumber(params[3]) }
  if not pos.x or not pos.y or not pos.z then
    pos = g_game.getLocalPlayer():getPosition()
  end

  for i = 4, #params do
    -- Item params
    local itemParams = params[i] / ';'
    for j = 1, 3 do
      -- Params 1 to 2 are numeric
      if j >= 1 and j <= 2 then
        itemParams[j] = tonumber(itemParams[j])
      end
      -- Check if item params are valid
      if not itemParams[j] then
        return
      end
    end

    GameLootbar.addItem(itemParams[1], itemParams[2], itemParams[3], pos)
  end
end

function GameLootbar.getBaseMargin()
  return config.baseMargin
end
