_G.GameLevelUp = { }



levelUpWidget = nil



local queue = { }
local config = {
  -- maxItems = 10,
  showingTime = 5000,
  shrinkTime = 1800,
  shrinkInterval = 50,
  ensurePositionInterval = 50,
  baseMargin = 4 -- Old: 8
}

local emblems = {
  { path = '/images/game/level_up/1', levelMin =   1, levelMax =  15 },
  { path = '/images/game/level_up/2', levelMin =  16, levelMax =  25 },
  { path = '/images/game/level_up/3', levelMin =  26, levelMax =  50 },
  { path = '/images/game/level_up/4', levelMin =  51, levelMax =  75 },
  { path = '/images/game/level_up/5', levelMin =  76, levelMax = 100 },
  { path = '/images/game/level_up/6', levelMin = 101, levelMax = true } -- levelMax as true is infinite
}



function GameLevelUp.init()
  -- Alias
  GameLevelUp.m = modules.ka_game_ui

  g_ui.importStyle('levelup')

  connect(LocalPlayer, {
    onLevelChange = GameLevelUp.onLevelChange
  })
  connect(g_game, {
    onClientOptionChanged = GameLevelUp.onClientOptionChanged,
  })
  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameLevelUp.onGeometryChange,
    onViewModeChange = GameLevelUp.onViewModeChange,
    onZoomChange     = GameLevelUp.onZoomChange,
  })

  if not levelUpWidget then
    levelUpWidget = g_ui.createWidget('LevelUpPanel', GameInterface.getRootPanel())
    levelUpWidget:setVisible(false)
    GameLevelUp.updatePosition()
  end
end

function GameLevelUp.terminate()
  if levelUpWidget then
    removeEvent(levelUpWidget.shrinkInEvent)
    removeEvent(levelUpWidget.shrinkOutEvent)
    removeEvent(levelUpWidget.ensurePositionEvent)
    levelUpWidget.shrinkInEvent       = nil
    levelUpWidget.shrinkOutEvent      = nil
    levelUpWidget.ensurePositionEvent = nil
    levelUpWidget:destroy()
    levelUpWidget = nil
  end

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameLevelUp.onGeometryChange,
    onViewModeChange = GameLevelUp.onViewModeChange,
    onZoomChange     = GameLevelUp.onZoomChange,
  })
  disconnect(g_game, {
    onClientOptionChanged = GameLevelUp.onClientOptionChanged,
  })
  disconnect(LocalPlayer, {
    onLevelChange = GameLevelUp.onLevelChange
  })

  _G.GameLevelUp = nil
end

function GameLevelUp.updatePosition()
  if not levelUpWidget then
    return
  end

  local margin = GameInterface.m.topMenuButton:getHeight() + config.baseMargin

  -- Hotkey bar
  local topHotkeyBar = modules.ka_game_hotkeybars and GameHotkeyBars.getHotkeyBars()[AnchorTop] or nil
  if topHotkeyBar and topHotkeyBar:isVisible() then
    margin = margin + topHotkeyBar:getHeight()
  end

  -- Loot bar
  local tmpLootbar = modules.ka_game_lootbar and GameLootbar.m.lootWidget or nil
  if tmpLootbar and tmpLootbar:isVisible() then
    margin = margin + tmpLootbar:getHeight() + GameLootbar.getBaseMargin()
  end

  addEvent(withWeakWidget(levelUpWidget, function(widget) widget:setMarginTop(margin) end))
end

function GameLevelUp.onGeometryChange(self)
  GameLevelUp.updatePosition()
end

function GameLevelUp.onViewModeChange(mapWidget, newMode, oldMode)
  GameLevelUp.updatePosition()
end

function GameLevelUp.onClientOptionChanged(key, value, force, wasClientSettingUp)
  GameLevelUp.updatePosition()
end

function GameLevelUp.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end

  GameLevelUp.updatePosition()
end

function GameLevelUp.removeWidget()
  removeEvent(levelUpWidget.shrinkInEvent)
  removeEvent(levelUpWidget.shrinkOutEvent)
  removeEvent(levelUpWidget.ensurePositionEvent)
  levelUpWidget.shrinkInEvent       = nil
  levelUpWidget.shrinkOutEvent      = nil
  levelUpWidget.ensurePositionEvent = nil

  levelUpWidget:setVisible(false)
end

function GameLevelUp.shrinkOut(time)
  local opacity = time / config.shrinkTime
  if opacity <= 0 then
    GameLevelUp.removeWidget()
    return
  end

  levelUpWidget:setOpacity(opacity)
  GameLevelUp.updatePosition()

  levelUpWidget.shrinkOutEvent = scheduleEvent(withWeakWidget(levelUpWidget, function(widget)
    if widget == levelUpWidget then
      GameLevelUp.shrinkOut(time - config.shrinkInterval)
    end
  end), config.shrinkInterval)
end

function GameLevelUp.ensurePosition()
  GameLevelUp.updatePosition()
  levelUpWidget.ensurePositionEvent = scheduleEvent(withWeakWidget(levelUpWidget, function(widget)
    if widget == levelUpWidget then
      GameLevelUp.ensurePosition()
    end
  end), config.ensurePositionInterval)
end

function GameLevelUp.addWidget(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  GameLevelUp.removeWidget()

  local path = nil
  for _, emblem in ipairs(emblems) do
    if level >= emblem.levelMin and (emblem.levelMax == true or level <= emblem.levelMax) then
      path = emblem.path
      break
    end
  end
  if not path then
    return
  end
  levelUpWidget:setImageSource(path)

  levelUpWidget:setVisible(true)
  levelUpWidget:setOpacity(1)
  GameLevelUp.ensurePosition()

  levelUpWidget.shrinkInEvent = scheduleEvent(withWeakWidget(levelUpWidget, function(widget)
    if widget == levelUpWidget then
      GameLevelUp.shrinkOut(config.shrinkTime)
    end
  end), config.showingTime)
end

function GameLevelUp.onLevelChange(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  if oldLevel == 0 or oldLevel >= level then
    return
  end

  GameLevelUp.addWidget(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
end

function GameLevelUp.getBaseMargin()
  return config.baseMargin
end
