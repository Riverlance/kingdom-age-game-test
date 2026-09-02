g_locales.loadLocales(resolvepath(''))

_G.GameAttributes = { }



local GameAttributesActionKey = 'Ctrl+Shift+U'



attributeWindow        = nil
attributeFooter        = nil
attributeTopMenuButton = nil

attackAttributeAddButton       = nil
defenseAttributeAddButton      = nil
magicDefenseAttributeAddButton = nil
vitalityAttributeAddButton     = nil
willPowerAttributeAddButton    = nil
agilityAttributeAddButton      = nil
dodgeAttributeAddButton        = nil
walkingAttributeAddButton      = nil
luckAttributeAddButton         = nil

attackAttributeLabel       = nil
defenseAttributeLabel      = nil
magicDefenseAttributeLabel = nil
vitalityAttributeLabel     = nil
willPowerAttributeLabel    = nil
agilityAttributeLabel      = nil
dodgeAttributeLabel        = nil
walkingAttributeLabel      = nil
luckAttributeLabel         = nil

attackAttributeActLabel       = nil
defenseAttributeActLabel      = nil
magicDefenseAttributeActLabel = nil
vitalityAttributeActLabel     = nil
willPowerAttributeActLabel    = nil
agilityAttributeActLabel      = nil
dodgeAttributeActLabel        = nil
walkingAttributeActLabel      = nil
luckAttributeActLabel         = nil

availablePointsLabel = nil
pointsCostLabel      = nil

ATTRIBUTE_NONE         = 0
ATTRIBUTE_ATTACK       = 1
ATTRIBUTE_DEFENSE      = 2
ATTRIBUTE_MAGICDEFENSE = 3
ATTRIBUTE_VITALITY     = 4
ATTRIBUTE_WILLPOWER    = 5
ATTRIBUTE_AGILITY      = 6 -- Limited to 100 points
ATTRIBUTE_DODGE        = 7 -- Limited to 100 points
ATTRIBUTE_WALKING      = 8 -- Limited to 100 points
ATTRIBUTE_LUCK         = 9 -- Limited to 100 points
ATTRIBUTE_FIRST        = ATTRIBUTE_ATTACK
ATTRIBUTE_LAST         = ATTRIBUTE_LUCK

attributeLabel    = nil
attributeActLabel = nil

local attribute_flag_updateList = -1

local _pointsPerLevel  = 0
local _availablePoints = 0



function GameAttributes.init()
  -- Alias
  GameAttributes.m = modules.ka_game_attributes

  g_keyboard.bindKeyDown('Ctrl+Shift+U', GameAttributes.toggle)

  attributeWindow        = g_ui.loadUI('attributes')
  attributeFooter        = attributeWindow:getChildById('miniWindowFooter')
  attributeTopMenuButton = ClientTopMenu.addRightGameToggleButton('attributeTopMenuButton', { loct = '${GameAttributesWindowTitle} (${GameAttributesActionKey})', locpar = { GameAttributesActionKey = GameAttributesActionKey } }, '/images/ui/top_menu/attributes', GameAttributes.toggle)

  attributeWindow.topMenuButton = attributeTopMenuButton
  attributeWindow:disableResize()

  local contentsPanel = attributeWindow:getChildById('contentsPanel')

  attackAttributeAddButton       = contentsPanel:getChildById('attackAttributeAddButton')
  defenseAttributeAddButton      = contentsPanel:getChildById('defenseAttributeAddButton')
  magicDefenseAttributeAddButton = contentsPanel:getChildById('magicDefenseAttributeAddButton')
  vitalityAttributeAddButton     = contentsPanel:getChildById('vitalityAttributeAddButton')
  willPowerAttributeAddButton    = contentsPanel:getChildById('willPowerAttributeAddButton')
  agilityAttributeAddButton      = contentsPanel:getChildById('agilityAttributeAddButton')
  dodgeAttributeAddButton        = contentsPanel:getChildById('dodgeAttributeAddButton')
  walkingAttributeAddButton      = contentsPanel:getChildById('walkingAttributeAddButton')
  luckAttributeAddButton         = contentsPanel:getChildById('luckAttributeAddButton')

  attackAttributeLabel       = contentsPanel:getChildById('attackAttributeLabel')
  defenseAttributeLabel      = contentsPanel:getChildById('defenseAttributeLabel')
  magicDefenseAttributeLabel = contentsPanel:getChildById('magicDefenseAttributeLabel')
  vitalityAttributeLabel     = contentsPanel:getChildById('vitalityAttributeLabel')
  willPowerAttributeLabel    = contentsPanel:getChildById('willPowerAttributeLabel')
  agilityAttributeLabel      = contentsPanel:getChildById('agilityAttributeLabel')
  dodgeAttributeLabel        = contentsPanel:getChildById('dodgeAttributeLabel')
  walkingAttributeLabel      = contentsPanel:getChildById('walkingAttributeLabel')
  luckAttributeLabel         = contentsPanel:getChildById('luckAttributeLabel')

  attackAttributeActLabel       = contentsPanel:getChildById('attackAttributeActLabel')
  defenseAttributeActLabel      = contentsPanel:getChildById('defenseAttributeActLabel')
  magicDefenseAttributeActLabel = contentsPanel:getChildById('magicDefenseAttributeActLabel')
  vitalityAttributeActLabel     = contentsPanel:getChildById('vitalityAttributeActLabel')
  willPowerAttributeActLabel    = contentsPanel:getChildById('willPowerAttributeActLabel')
  agilityAttributeActLabel      = contentsPanel:getChildById('agilityAttributeActLabel')
  dodgeAttributeActLabel        = contentsPanel:getChildById('dodgeAttributeActLabel')
  walkingAttributeActLabel      = contentsPanel:getChildById('walkingAttributeActLabel')
  luckAttributeActLabel         = contentsPanel:getChildById('luckAttributeActLabel')

  availablePointsLabel = attributeFooter:getChildById('availablePointsLabel')
  pointsCostLabel      = attributeFooter:getChildById('pointsCostLabel')

  attributeLabel = {
    [ATTRIBUTE_ATTACK]       = attackAttributeLabel,
    [ATTRIBUTE_DEFENSE]      = defenseAttributeLabel,
    [ATTRIBUTE_MAGICDEFENSE] = magicDefenseAttributeLabel,
    [ATTRIBUTE_VITALITY]     = vitalityAttributeLabel,
    [ATTRIBUTE_WILLPOWER]    = willPowerAttributeLabel,
    [ATTRIBUTE_AGILITY]      = agilityAttributeLabel,
    [ATTRIBUTE_DODGE]        = dodgeAttributeLabel,
    [ATTRIBUTE_WALKING]      = walkingAttributeLabel,
    [ATTRIBUTE_LUCK]         = luckAttributeLabel,
  }

  attributeActLabel = {
    [ATTRIBUTE_ATTACK]       = attackAttributeActLabel,
    [ATTRIBUTE_DEFENSE]      = defenseAttributeActLabel,
    [ATTRIBUTE_MAGICDEFENSE] = magicDefenseAttributeActLabel,
    [ATTRIBUTE_VITALITY]     = vitalityAttributeActLabel,
    [ATTRIBUTE_WILLPOWER]    = willPowerAttributeActLabel,
    [ATTRIBUTE_AGILITY]      = agilityAttributeActLabel,
    [ATTRIBUTE_DODGE]        = dodgeAttributeActLabel,
    [ATTRIBUTE_WALKING]      = walkingAttributeActLabel,
    [ATTRIBUTE_LUCK]         = luckAttributeActLabel,
  }

  attackAttributeAddButton.attributeId       = ATTRIBUTE_ATTACK
  defenseAttributeAddButton.attributeId      = ATTRIBUTE_DEFENSE
  magicDefenseAttributeAddButton.attributeId = ATTRIBUTE_MAGICDEFENSE
  vitalityAttributeAddButton.attributeId     = ATTRIBUTE_VITALITY
  willPowerAttributeAddButton.attributeId    = ATTRIBUTE_WILLPOWER
  agilityAttributeAddButton.attributeId      = ATTRIBUTE_AGILITY
  dodgeAttributeAddButton.attributeId        = ATTRIBUTE_DODGE
  walkingAttributeAddButton.attributeId      = ATTRIBUTE_WALKING
  luckAttributeAddButton.attributeId         = ATTRIBUTE_LUCK

  attackAttributeAddButton.onClick       = GameAttributes.onClickAddButton
  defenseAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  magicDefenseAttributeAddButton.onClick = GameAttributes.onClickAddButton
  vitalityAttributeAddButton.onClick     = GameAttributes.onClickAddButton
  willPowerAttributeAddButton.onClick    = GameAttributes.onClickAddButton
  agilityAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  dodgeAttributeAddButton.onClick        = GameAttributes.onClickAddButton
  walkingAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  luckAttributeAddButton.onClick         = GameAttributes.onClickAddButton

  connect(g_game, {
    onGameStart        = GameAttributes.online,
    onGameEnd          = GameAttributes.offline,
  })

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeAttributesList, GameAttributes.parseAttribute)

  if g_game.isOnline() then
    GameAttributes.online()
  end
end

function GameAttributes.terminate()
  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeAttributesList)

  disconnect(g_game, {
    onGameStart        = GameAttributes.online,
    onGameEnd          = GameAttributes.offline,
  })

  attributeTopMenuButton:destroy()
  attributeWindow:destroy()

  attributeTopMenuButton = nil
  attributeWindow        = nil
  attributeFooter        = nil

  attackAttributeAddButton       = nil
  defenseAttributeAddButton      = nil
  magicDefenseAttributeAddButton = nil
  vitalityAttributeAddButton     = nil
  willPowerAttributeAddButton    = nil
  agilityAttributeAddButton      = nil
  dodgeAttributeAddButton        = nil
  walkingAttributeAddButton      = nil
  luckAttributeAddButton         = nil

  attackAttributeLabel       = nil
  defenseAttributeLabel      = nil
  magicDefenseAttributeLabel = nil
  vitalityAttributeLabel     = nil
  willPowerAttributeLabel    = nil
  agilityAttributeLabel      = nil
  dodgeAttributeLabel        = nil
  walkingAttributeLabel      = nil
  luckAttributeLabel         = nil

  attackAttributeActLabel       = nil
  defenseAttributeActLabel      = nil
  magicDefenseAttributeActLabel = nil
  vitalityAttributeActLabel     = nil
  willPowerAttributeActLabel    = nil
  agilityAttributeActLabel      = nil
  dodgeAttributeActLabel        = nil
  walkingAttributeActLabel      = nil
  luckAttributeActLabel         = nil

  availablePointsLabel = nil
  pointsCostLabel      = nil

  g_keyboard.unbindKeyDown('Ctrl+Shift+U')

  _G.GameAttributes = nil
end

function GameAttributes.toggle()
  GameInterface.toggleMiniWindow(attributeWindow)
end

function GameAttributes.online()
  local localPlayer = g_game.getLocalPlayer()

  connect(localPlayer, {
    onVocationChange = GameAttributes.onVocationChange,
  })

  attributeWindow:setup(attributeTopMenuButton)

  GameAttributes.clearWindow()

  g_game.sendAttributeBuffer(f('%d', attribute_flag_updateList))
end

function GameAttributes.offline()
  local localPlayer = g_game.getLocalPlayer()

  disconnect(localPlayer, {
    onVocationChange = GameAttributes.onVocationChange,
  })
end

function GameAttributes.clearWindow()
  attackAttributeActLabel:setText(f('%.2f', 0))
  defenseAttributeActLabel:setText(f('%.2f', 0))
  magicDefenseAttributeActLabel:setText(f('%.2f', 0))
  vitalityAttributeActLabel:setText(f('%.2f', 0))
  willPowerAttributeActLabel:setText(f('%.2f', 0))
  agilityAttributeActLabel:setText(f('%.2f', 0))
  dodgeAttributeActLabel:setText(f('%.2f', 0))
  walkingAttributeActLabel:setText(f('%.2f', 0))
  luckAttributeActLabel:setText(f('%.2f', 0))

  availablePointsLabel:setText(f(loc'${GameAttributesInfoPoints}: %d', 0))
  pointsCostLabel:setText(f(loc'${GameAttributesInfoCost}: %d', 0))

  attackAttributeActLabel:removeTooltip()
  defenseAttributeActLabel:removeTooltip()
  magicDefenseAttributeActLabel:removeTooltip()
  vitalityAttributeActLabel:removeTooltip()
  willPowerAttributeActLabel:removeTooltip()
  agilityAttributeActLabel:removeTooltip()
  dodgeAttributeActLabel:removeTooltip()
  walkingAttributeActLabel:removeTooltip()
  luckAttributeActLabel:removeTooltip()

  availablePointsLabel:setTooltip(f(loc'${GameAttributesInfoUsedWithCost}: %d\n${GameAttributesInfoUsedWithoutCost}: %d', 0, 0))
  pointsCostLabel:setTooltip(f(loc'${GameAttributesInfoPointsToIncreaseCost}: %d', 0))

  attackAttributeActLabel:setColor('#dfdfdf')
  defenseAttributeActLabel:setColor('#dfdfdf')
  magicDefenseAttributeActLabel:setColor('#dfdfdf')
  vitalityAttributeActLabel:setColor('#dfdfdf')
  willPowerAttributeActLabel:setColor('#dfdfdf')
  agilityAttributeActLabel:setColor('#dfdfdf')
  dodgeAttributeActLabel:setColor('#dfdfdf')
  walkingAttributeActLabel:setColor('#dfdfdf')
  luckAttributeActLabel:setColor('#dfdfdf')
end

function GameAttributes.parseAttribute(protocol, msg)
  local attributes = { }

  local first = msg:getU8()
  local last  = msg:getU8()

  local singleAttr   = first == 0
  local singleAttrId = last

  for attrId = singleAttr and singleAttrId or first, singleAttr and singleAttrId or last do
    local distributionPoints      = msg:getU32()
    local alignmentPoints         = msg:getDouble()
    local alignmentMaxPoints      = msg:getDouble()
    local questPoints             = msg:getDouble()
    local questMaxPoints          = msg:getDouble()
    local buffPoints              = msg:getDouble()
    local total                   = msg:getDouble()

    local alignmentPointsPerLevel = 0
    local tooltip
    if not singleAttr then
      alignmentPointsPerLevel = msg:getU8() / 100
      tooltip                 = msg:getString()
    end

    attributes[singleAttr and 1 or attrId] = {
      attrId                  = attrId,
      distributionPoints      = distributionPoints,
      alignmentPoints         = alignmentPoints,
      alignmentMaxPoints      = alignmentMaxPoints,
      alignmentPointsPerLevel = alignmentPointsPerLevel,
      questPoints             = questPoints,
      questMaxPoints          = questMaxPoints,
      buffPoints              = buffPoints,
      total                   = total,
      tooltip                 = tooltip, -- Optional
    }
  end

  if not singleAttr then
    _pointsPerLevel = msg:getU8()
  end

  _availablePoints           = msg:getU32()
  local usedPoints           = msg:getU32()
  local distributionPoints   = msg:getU32()
  local pointsCost           = msg:getU16()
  local pointsToCostIncrease = msg:getU32()

  if not attributeLabel or not attributeActLabel then
    return
  end

  for _, attribute in ipairs(attributes) do
    local id = attribute.attrId

    if attributeActLabel[id] then
      attributeActLabel[id].distributionPoints      = attribute.distributionPoints
      attributeActLabel[id].alignmentPoints         = attribute.alignmentPoints
      attributeActLabel[id].alignmentMaxPoints      = attribute.alignmentMaxPoints
      attributeActLabel[id].alignmentPointsPerLevel = attribute.alignmentPointsPerLevel
      attributeActLabel[id].questPoints             = attribute.questPoints
      attributeActLabel[id].questMaxPoints          = attribute.questMaxPoints
      attributeActLabel[id].buffPoints              = attribute.buffPoints
      attributeActLabel[id].total                   = attribute.total

      attributeActLabel[id]:setText(f('%.2f', attributeActLabel[id].total))
      GameAttributes.updateActLabelTooltip(id)
      attributeActLabel[id]:setColor(attributeActLabel[id].buffPoints > 0 and 'green' or attributeActLabel[id].buffPoints < 0 and 'red' or '#dfdfdf')
    end

    if attribute.tooltip and attributeLabel[id] then
      attributeLabel[id]:setTooltip(attribute.tooltip, TooltipType.textBlock)
    end
  end

  availablePointsLabel:setText(f(loc'${GameAttributesInfoPoints}: %d', _availablePoints))
  availablePointsLabel:setTooltip(f(loc'${GameAttributesInfoUsedWithCost}: %d\n${GameAttributesInfoUsedWithoutCost}: %d\n${GameAttributesInfoPointsEarnedPerLevel}: %d', usedPoints, distributionPoints, _pointsPerLevel))
  pointsCostLabel:setText(f(loc'${GameAttributesInfoCost}: %d', pointsCost))
  pointsCostLabel:setTooltip(f(loc'${GameAttributesInfoPointsToIncreaseCost}: %d', pointsToCostIncrease))
end

function GameAttributes.sendAdd(attributeId)
  g_game.sendAttributeBuffer(f('%d', attributeId))
end

function GameAttributes.onClickAddButton(widget)
  if not widget.attributeId then
    return
  end

  GameAttributes.sendAdd(widget.attributeId)
end

function GameAttributes.updateActLabelTooltip(attrId)
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local isWarrior                   = localPlayer and localPlayer:isWarrior()
  local widget                      = attributeActLabel[attrId]
  local distributionPointsText      = widget.distributionPoints ~= 0 and f(loc'${GameAttributesInfoDistribution}: %d\n', widget.distributionPoints) or ''
  local alignmentLimit              = attrId == ATTRIBUTE_VITALITY and not isWarrior
  local alignmentMaxPointsText      = alignmentLimit and '' or f(loc' ${GameAttributesInfoOfMax} %s', widget.alignmentMaxPoints)
  local alignmentPointsPerLevelText = widget.alignmentPointsPerLevel ~= 0 and f(loc'\n(${GameAttributesInfoPointsPerLevel}%s)', widget.alignmentPointsPerLevel, alignmentLimit and f(loc'; ${GameAttributesInfoUntilLevel}', 100) or '') or ''
  local alignmentPointsText         = widget.alignmentPoints ~= 0 and f(loc'${GameAttributesInfoAlignment}: %s%s%s\n', widget.alignmentPoints, alignmentMaxPointsText, alignmentPointsPerLevelText) or ''
  local questPointsText             = widget.questMaxPoints ~= 0 and f(loc'${GameAttributesInfoQuest}: %s ${GameAttributesInfoOfMax} %s\n', widget.questPoints, widget.questMaxPoints) or ''
  local buffPointsText              = widget.buffPoints ~= 0 and f(loc'${GameAttributesInfoBuffDebuff}: %s%s\n', widget.buffPoints > 0 and '+' or '', widget.buffPoints) or ''
  local moreThanMaximum             = (widget.distributionPoints + widget.alignmentPoints + widget.buffPoints) > widget.total
  local totalPointsText             = widget.total ~= 0 and f(loc'${GameAttributesInfoTotal}: %s%s', widget.total, moreThanMaximum and loc'\n(${GameAttributesInfoExceededMax})' or '') or ''

  widget:setTooltip(f('%s%s%s%s%s', distributionPointsText, alignmentPointsText, questPointsText, buffPointsText, totalPointsText))
end

function GameAttributes.onVocationChange(creature, vocation, oldVocation)
  local localPlayer = g_game.getLocalPlayer()
  if creature ~= localPlayer then
    return
  end

  for attrId = ATTRIBUTE_FIRST, ATTRIBUTE_LAST do
    -- Update act label tooltip
    GameAttributes.updateActLabelTooltip(attrId)
  end
end
