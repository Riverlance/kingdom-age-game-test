g_locales.loadLocales(resolvepath(''))

_G.GameStatsCircle = { }



local baseSize       = 354
local baseDistFactor = 1.5



Stats = {
  None       = 0,
  Health     = 1,
  Mana       = 2,
  Vigor      = 3,
  Boost      = 4,
  Capacity   = 5,
  Experience = 6,
  Any        = 9,
}

statsCircle = nil

leftArc   = nil
rightArc  = nil
topArc    = nil
bottomArc = nil

arcSettings = nil
optionPanel = nil

arcSizeRatio        = g_settings.getNumber('stats_circle_size', 1.)
gameScreenBased     = g_settings.getBoolean('stats_circle_gamescreenbased', false)
distFromCenterRatio = g_settings.getNumber('stats_circle_distfromcenter', 0.)
opacityCircleFill   = g_settings.getNumber('stats_circle_fillopacity', 1.)
opacityCircleBg     = g_settings.getNumber('stats_circle_bgopacity', 0.7)



function GameStatsCircle.init()
  -- Alias
  GameStatsCircle.m = modules.game_statscircle

  local mapPanel = GameInterface.getMapPanel()

  statsCircle = g_ui.loadUI('game_statscircle', mapPanel)

  leftArc   = statsCircle.leftArc
  rightArc  = statsCircle.rightArc
  topArc    = statsCircle.topArc
  bottomArc = statsCircle.bottomArc

  -- load defaults
  leftArc.statsType   = Stats.Health
  rightArc.statsType  = Stats.Mana
  topArc.statsType    = Stats.None
  bottomArc.statsType = Stats.None

  arcs = { leftArc, rightArc, topArc, bottomArc }

  baseImageSizeThin  = leftArc:getWidth()
  baseImageSizeBroad = leftArc:getHeight()
  imageSizeThin      = baseImageSizeThin * 1.
  imageSizeBroad     = baseImageSizeBroad * 1.
  imageMargin        = 0

  connect(g_game, {
    onGameStart = GameStatsCircle.onGameStart,
    onGameEnd   = GameStatsCircle.onGameEnd,
  })

  connect(mapPanel, {
    onGeometryChange = GameStatsCircle.onGeometryChange,
    onViewModeChange = GameStatsCircle.onViewModeChange,
    onZoomChange     = GameStatsCircle.onZoomChange,
  })

  connect(LocalPlayer, {
    onHealthChange       = GameStatsCircle.onHealthChange,
    onManaChange         = GameStatsCircle.onManaChange,
    onVigorChange        = GameStatsCircle.onVigorChange,
    onFreeCapacityChange = GameStatsCircle.onFreeCapacityChange,
    onOverweightChange   = GameStatsCircle.onFreeCapacityChange,
    onExperienceChange   = GameStatsCircle.onExperienceChange,
    onVocationChange     = GameStatsCircle.onVocationChange,
  })
end

function GameStatsCircle.terminate()
  statsCircle:destroy()

  statsCircle = nil

  leftArc   = nil
  rightArc  = nil
  topArc    = nil
  bottomArc = nil

  optionPanel = nil

  disconnect(LocalPlayer, {
    onHealthChange       = GameStatsCircle.onHealthChange,
    onManaChange         = GameStatsCircle.onManaChange,
    onVigorChange        = GameStatsCircle.onVigorChange,
    onFreeCapacityChange = GameStatsCircle.onFreeCapacityChange,
    onOverweightChange   = GameStatsCircle.onFreeCapacityChange,
    onExperienceChange   = GameStatsCircle.onExperienceChange,
    onVocationChange     = GameStatsCircle.onVocationChange,
  })

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameStatsCircle.onGeometryChange,
    onViewModeChange = GameStatsCircle.onViewModeChange,
    onZoomChange     = GameStatsCircle.onZoomChange,
  })

  disconnect(g_game, {
    onGameStart = GameStatsCircle.onGameStart,
    onGameEnd   = GameStatsCircle.onGameEnd,
  })

  GameStatsCircle = { }
end



function GameStatsCircle.onGameStart()
  arcSettings = { }

  GameStatsCircle.loadPlayerSettings()
  GameStatsCircle.enableOptionsPanel()

  GameStatsCircle.setSize(arcSizeRatio)
  GameStatsCircle.setDistanceFromCenter(distFromCenterRatio)
  GameStatsCircle.setCircleFillOpacity(opacityCircleFill)
  GameStatsCircle.setCircleBackgroundOpacity(opacityCircleBg)

  GameStatsCircle.update()
end

function GameStatsCircle.onGameEnd()
  GameStatsCircle.savePlayerSettings()
  GameStatsCircle.disableOptionsPanel()

  arcSettings = { }
end



function GameStatsCircle.loadPlayerSettings()
  local settings = Client.getPlayerSettings():getNode('StatsCircle') or { }
  for arcNode, _ in pairs(settings) do
    local arc = GameStatsCircle.m[arcNode]
    arc.statsType = settings[arcNode].statsType or arc.statsType
    arcSettings[arcNode] = arc.statsType
  end
end

function GameStatsCircle.savePlayerSettings()
  local arcSettings = { }
  for _, arc in ipairs(arcs) do
    arcSettings[arc:getId()] = { statsType = arc.statsType }
  end

  local settings = Client.getPlayerSettings()
  settings:setNode('StatsCircle', arcSettings)
  settings:save()
end

function GameStatsCircle.currentViewMode()
  return GameInterface.m.currentViewMode
end



function GameStatsCircle.onHealthChange()
  GameStatsCircle.updateCircle(Stats.Health)
end

function GameStatsCircle.onManaChange()
  GameStatsCircle.updateCircle(Stats.Mana)
end

function GameStatsCircle.onVigorChange()
  GameStatsCircle.updateCircle(Stats.Vigor)
end

function GameStatsCircle.onFreeCapacityChange()
  GameStatsCircle.updateCircle(Stats.Capacity)
end

function GameStatsCircle.onExperienceChange()
  GameStatsCircle.updateCircle(Stats.Experience)
end

function GameStatsCircle.onVocationChange(creature, vocation, oldVocation)
  local localPlayer = g_game.getLocalPlayer()
  if creature ~= localPlayer then
    return
  end

  GameStatsCircle.updateArcsComboBox()
end

function GameStatsCircle.onGeometryChange(self)
  GameStatsCircle.update()
end

function GameStatsCircle.onViewModeChange(mapWidget, newMode, oldMode)
  GameStatsCircle.update()
end

function GameStatsCircle.onZoomChange(self, oldZoom, newZoom)
  GameStatsCircle.update()
end



function GameStatsCircle.update()
  if not g_game.isOnline() then
    return
  end

  addEvent(function()
    GameStatsCircle.setSize(sizeScrollbar:getValue() / 100)
  end)
end

function GameStatsCircle.updateCircle(statsType, percent)
  addEvent(function()
    for _, arc in pairs(arcs) do
      if statsType == Stats.Any or arc.statsType == statsType then
        GameStatsCircle.updateArc(arc, percent)
      end
    end
  end)
end

function GameStatsCircle.setArcStatsType(arc, statsType)
  arc.statsType = statsType
  GameStatsCircle.updateArc(arc)
end

function GameStatsCircle.updateArc(arc, percent)
  arc:setVisible(arc.statsType > Stats.None)

  local hasVisibleArc = false
  for _, arc in pairs(arcs) do
    if arc.statsType > Stats.None then
      hasVisibleArc = true
      break
    end
  end
  statsCircle:setVisible(hasVisibleArc)

  if arc.statsType == Stats.None then
    return
  end

  local player = g_game.getLocalPlayer()

  if arc.statsType == Stats.Health then
    percent = percent or player:getHealthPercent()
    color = '#FF4444'
  elseif arc.statsType == Stats.Mana then
    percent = percent or 100 * player:getMana() / player:getMaxMana()
    color = '#AA44FF'
  elseif arc.statsType == Stats.Vigor then
    percent = percent or 100 * player:getVigor() / player:getMaxVigor()
    color = '#FFA14F'
  elseif arc.statsType == Stats.Capacity then
    percent = percent or 100 * player:getCurrentWeight() / player:getTotalCapacity()
    color = player:getWeightColor()
  elseif arc.statsType == Stats.Experience then
    percent = percent or player:getLevelPercent()
    color = '#8BE866'
  end
  percent = percent / 100

  local circleSize   = baseSize + math.floor(distFromCenterRatio * 100 * baseDistFactor)
  local stretchRatio = gameScreenBased and GameInterface.getMapPanel():getStretchRatio() or 1

  imageSizeThin  = baseImageSizeThin * arcSizeRatio * stretchRatio
  imageSizeBroad = baseImageSizeBroad * arcSizeRatio * stretchRatio
  imageMargin    = gameScreenBased and 0 or math.ceil((1 - arcSizeRatio) * (baseSize / 2))

  -- Circle
  statsCircle:setSize{ width = circleSize * stretchRatio * (gameScreenBased and arcSizeRatio or 1), height = circleSize * stretchRatio * (gameScreenBased and arcSizeRatio or 1) }

  -- Arcs

  -- Vertical
  if arc.isVertical then
    arc:setSize{ width = imageSizeThin, height = imageSizeBroad }
    arc.bg:setSize{ width = imageSizeThin, height = imageSizeBroad }
    arc.fill:setImageClip{
      x      = 0,
      y      = (1 - percent) * baseImageSizeBroad,
      width  = baseImageSizeThin,
      height = baseImageSizeBroad * percent,
    }
    arc.fill:setWidth(imageSizeThin)
    arc.fill:setHeight(percent * imageSizeBroad)

  -- Horizontal
  elseif arc.isHorizontal then
    arc:setSize{ width = imageSizeBroad, height = imageSizeThin }
    arc.bg:setSize{ width = imageSizeBroad, height = imageSizeThin }
    arc.fill:setImageClip{
      x      = 0,
      y      = 0,
      width  = percent * baseImageSizeBroad,
      height = baseImageSizeThin,
    }
    arc.fill:setWidth(percent * imageSizeBroad)
    arc.fill:setHeight(imageSizeThin)
  end

  -- Margin
  if arc == topArc then
    arc:setMarginTop(imageMargin)
  elseif arc == bottomArc then
    arc:setMarginBottom(imageMargin)
  elseif arc == leftArc then
    arc:setMarginLeft(imageMargin)
  elseif arc == rightArc then
    arc:setMarginRight(imageMargin)
  end

  -- Color
  arc.fill:setImageColor(color)
end

function GameStatsCircle.setSize(value)
  arcSizeRatio = value
  g_settings.set('stats_circle_size', value)

  GameStatsCircle.updateCircle(Stats.Any)
end

function GameStatsCircle.setGameScreenBased(checked)
  gameScreenBased = checked
  g_settings.set('stats_circle_gamescreenbased', checked)

  GameStatsCircle.update()
end

function GameStatsCircle.setDistanceFromCenter(value)
  distFromCenterRatio = value
  g_settings.set('stats_circle_distfromcenter', value)

  GameStatsCircle.update()
end

function GameStatsCircle.setCircleFillOpacity(value)
  opacityCircleFill = value
  g_settings.set('stats_circle_fillopacity', value)

  leftArc.fill:setOpacity(value)
  rightArc.fill:setOpacity(value)
  topArc.fill:setOpacity(value)
  bottomArc.fill:setOpacity(value)
end

function GameStatsCircle.setCircleBackgroundOpacity(value)
  opacityCircleBg = value
  g_settings.set('stats_circle_bgopacity', value)

  leftArc.bg:setOpacity(value)
  rightArc.bg:setOpacity(value)
  topArc.bg:setOpacity(value)
  bottomArc.bg:setOpacity(value)
end



-- Option Settings

optionPanel             = nil
leftArcComboBox         = nil
rightArcComboBox        = nil
topArcComboBox          = nil
bottomArcComboBox       = nil
sizeScrollbar           = nil
gameScreenBasedCheckBox = nil
distFromCenScrollbar    = nil
fillOpacityScrollbar    = nil
bgOpacityScrollbar      = nil

function GameStatsCircle.updateArcsComboBox()
  local localPlayer   = g_game.getLocalPlayer()
  local isManaEnabled = not localPlayer or not localPlayer:isWarrior()

  for arcPos, comboBox in ipairs(arcsComboBox or { }) do
    comboBox:clearOptions()

    comboBox:addOption(loc'${CorelibInfoNone}', Stats.None)
    comboBox:addOption(loc'${GameStatsCircleStatHealth}', Stats.Health)
    if isManaEnabled then
      comboBox:addOption(loc'${GameStatsCircleStatMana}', Stats.Mana)
    end
    comboBox:addOption(loc'${GameStatsCircleStatVigor}', Stats.Vigor)
    comboBox:addOption(loc'${GameStatsCircleStatCapacity}', Stats.Capacity)
    comboBox:addOption(loc'${GameStatsCircleStatExperience}', Stats.Experience)
    comboBox:setCurrentOptionByData(arcSettings[comboBox.arc:getId()])
  end
end

function GameStatsCircle.enableOptionsPanel()
  -- Add to options module
  optionPanel = g_ui.loadUI('option_statscircle')
  ClientOptions.addTab(loc'${GameStatsCircleTitle}', optionPanel, '/images/ui/options/stats_circle')

  -- UI values
  leftArcComboBox   = optionPanel:recursiveGetChildById('leftArcComboBox')
  rightArcComboBox  = optionPanel:recursiveGetChildById('rightArcComboBox')
  topArcComboBox    = optionPanel:recursiveGetChildById('topArcComboBox')
  bottomArcComboBox = optionPanel:recursiveGetChildById('bottomArcComboBox')

  leftArcComboBox.arc   = leftArc
  rightArcComboBox.arc  = rightArc
  topArcComboBox.arc    = topArc
  bottomArcComboBox.arc = bottomArc

  arcsComboBox = { leftArcComboBox, rightArcComboBox, topArcComboBox, bottomArcComboBox }

  sizeScrollbar           = optionPanel:recursiveGetChildById('sizeScrollbar')
  gameScreenBasedCheckBox = optionPanel:recursiveGetChildById('gameScreenBasedCheckBox')
  distFromCenScrollbar    = optionPanel:recursiveGetChildById('distFromCenScrollbar')
  fillOpacityScrollbar    = optionPanel:recursiveGetChildById('fillOpacityScrollbar')
  bgOpacityScrollbar      = optionPanel:recursiveGetChildById('bgOpacityScrollbar')

  GameStatsCircle.updateArcsComboBox()

  sizeScrollbar:setValue(arcSizeRatio * 100)
  gameScreenBasedCheckBox:setChecked(gameScreenBased)
  distFromCenScrollbar:setValue(distFromCenterRatio * 100)
  fillOpacityScrollbar:setValue(opacityCircleFill * 100)
  bgOpacityScrollbar:setValue(opacityCircleBg * 100)
end

function GameStatsCircle.disableOptionsPanel()
  leftArcComboBox         = nil
  rightArcComboBox        = nil
  topArcComboBox          = nil
  bottomArcComboBox       = nil
  arcsComboBox            = nil
  sizeScrollbar           = nil
  gameScreenBasedCheckBox = nil
  distFromCenScrollbar    = nil
  fillOpacityScrollbar    = nil
  bgOpacityScrollbar      = nil

  ClientOptions.removeTab(loc'${GameStatsCircleTitle}')
  optionPanel = nil
end
