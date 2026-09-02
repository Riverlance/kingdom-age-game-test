_G.GameUIExpBar = { }



function GameUIExpBar.init()
  -- Alias
  GameUIExpBar.m = modules.ka_game_ui

  connect(g_game, {
    onClientOptionChanged = GameUIExpBar.onClientOptionChanged,
  })

  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameUIExpBar.onGeometryChange,
    onViewModeChange = GameUIExpBar.onViewModeChange,
    onZoomChange     = GameUIExpBar.onZoomChange,
  })

  connect(LocalPlayer, {
    onLevelChange = GameUIExpBar.onLevelChange,
  })

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    GameUIExpBar.onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
  end
end

function GameUIExpBar.terminate()
  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameUIExpBar.onGeometryChange,
    onViewModeChange = GameUIExpBar.onViewModeChange,
    onZoomChange     = GameUIExpBar.onZoomChange,
  })

  disconnect(LocalPlayer, {
    onLevelChange = GameUIExpBar.onLevelChange,
  })

  disconnect(g_game, {
    onClientOptionChanged = GameUIExpBar.onClientOptionChanged,
  })

  _G.GameUIExpBar = nil
end

function GameUIExpBar.updateGameExpBarPercent(percent)
  if not GameInterface.m.gameExpBar:isOn() then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not percent and not localPlayer then
    return
  end

  GameInterface.m.gameExpBar.bar:setPercent(percent or localPlayer:getLevelPercent())
end

function GameUIExpBar.updateExpBar()
  GameUIExpBar.updateGameExpBarPercent()
end

function GameUIExpBar.onGeometryChange()
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onViewModeChange(mapWidget, newMode, oldMode)
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onClientOptionChanged(key, value, force, wasClientSettingUp)
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onLevelChange(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  GameUIExpBar.updateGameExpBarPercent(levelPercent)
  GameInterface.m.gameExpBar:setTooltip(getExperienceTooltipText(localPlayer, level, levelPercent), TooltipType.textBlock)
end

function GameUIExpBar.setExpBar(enable)
  local isOn = GameInterface.m.gameExpBar:isOn()

  -- Enable bar
  if not isOn and enable then
    GameInterface.m.gameExpBar:setOn(true)
    GameUIExpBar.updateExpBar()

  -- Disable bar
  elseif isOn and not enable then
    GameInterface.m.gameExpBar:setOn(false)
    GameUIExpBar.updateExpBar()
  end
end
