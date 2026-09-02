g_locales.loadLocales(resolvepath(''))

_G.GameCharacter = { }



CharacterWindowActionKey = 'Ctrl+I'



outfitCreatureBox = nil



local loginTime = 0

healthBarPrevious = nil
healthBar = nil
manaBar = nil
vigorBar = nil
capacityBar = nil
experienceBar = nil
healthBarValueLabel = nil
manaBarValueLabel = nil
vigorBarValueLabel = nil
capacityBarValueLabel = nil
experienceBarValueLabel = nil



local defaultValues = {
  statsWindow     = true,
  inventoryWindow = true,
}

InventorySlotStyles = {
  [InventorySlotHead] = 'HeadSlot',
  [InventorySlotNeck] = 'NeckSlot',
  [InventorySlotBack] = 'BackSlot',
  [InventorySlotBody] = 'BodySlot',
  [InventorySlotRight] = 'RightSlot',
  [InventorySlotLeft] = 'LeftSlot',
  [InventorySlotLeg] = 'LegSlot',
  [InventorySlotFeet] = 'FeetSlot',
  [InventorySlotFinger] = 'FingerSlot',
  [InventorySlotAmmo] = 'AmmoSlot',
  [InventorySlotInbox] = 'InboxSlot'
}

inventoryTopMenuButton = nil
inventoryWindow = nil
inventoryHeader = nil



-- Combat controls
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
safeFightButton = nil
mountButton = nil



function GameCharacter.init()
  -- Alias
  GameCharacter.m = modules.game_character

  connect(LocalPlayer, {
    onNicknameChange = GameCharacter.onNicknameChange,

    onOutfitChange = GameCharacter.onOutfitChange,

    -- Health info
    onHealthChange       = GameCharacter.onHealthChange,
    onManaChange         = GameCharacter.onManaChange,
    onVigorChange        = GameCharacter.onVigorChange,
    onFreeCapacityChange = GameCharacter.onCapacityChange,
    onOverweightChange   = GameCharacter.onCapacityChange,
    onLevelChange        = GameCharacter.onLevelChange,

    -- Inventory
    onInventoryChange = GameCharacter.onInventoryChange,
    onBlessingsChange = GameCharacter.onBlessingsChange,
  })

  connect(g_game, {
    -- Inventory / Combat controls
    onGameStart = GameCharacter.online,

    -- Health info / Combat controls
    onGameEnd = GameCharacter.offline,

    -- Combat controls
    onChaseModeChange = GameCharacter.updateCombatControls,
    onSafeFightChange = GameCharacter.updateCombatControls,
    onWalk            = GameCharacter.check,
    onAutoWalk        = GameCharacter.check
  })

  g_keyboard.bindKeyDown(CharacterWindowActionKey, GameCharacter.toggle)

  inventoryWindow            = g_ui.loadUI('character')
  inventoryWindow.onMinimize = GameCharacter.onMinimize
  inventoryWindow.onMaximize = GameCharacter.onMaximize
  inventoryHeader            = inventoryWindow:getChildById('miniWindowHeader')
  inventoryTopMenuButton     = ClientTopMenu.addRightGameToggleButton('inventoryTopMenuButton', { loct = "${CharacterWindowTitle} (${CharacterWindowActionKey})", locpar = { CharacterWindowActionKey = CharacterWindowActionKey } }, '/images/ui/top_menu/healthinfo', GameCharacter.toggle)

  inventoryWindow.topMenuButton = inventoryTopMenuButton
  inventoryWindow:disableResize()

  local contentsPanel = inventoryWindow:getChildById('contentsPanel')

  outfitCreatureBox = contentsPanel:getChildById('outfitCreatureBox')

  -- Health info
  healthBarPrevious       = inventoryHeader:getChildById('healthBarPrevious')
  healthBar               = inventoryHeader:getChildById('healthBar')
  manaBar                 = inventoryHeader:getChildById('manaBar')
  vigorBar                = inventoryHeader:getChildById('vigorBar')
  capacityBar             = inventoryHeader:getChildById('capacityBar')
  experienceBar           = inventoryHeader:getChildById('experienceBar')
  healthBarValueLabel     = inventoryHeader:getChildById('healthBarValueLabel')
  manaBarValueLabel       = inventoryHeader:getChildById('manaBarValueLabel')
  vigorBarValueLabel      = inventoryHeader:getChildById('vigorBarValueLabel')
  capacityBarValueLabel   = inventoryHeader:getChildById('capacityBarValueLabel')
  experienceBarValueLabel = inventoryHeader:getChildById('experienceBarValueLabel')

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    GameCharacter.onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
    GameCharacter.onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
    GameCharacter.onVigorChange(localPlayer, localPlayer:getVigor(), localPlayer:getMaxVigor())
    GameCharacter.onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
    GameCharacter.onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
  end

  local combatControls = contentsPanel:getChildById('combatControls')

  -- Combat controls
  chaseModeButton = combatControls:getChildById('chaseModeBox')
  safeFightButton = combatControls:getChildById('safeFightBox')
  mountButton = combatControls:getChildById('mountButton')
  mountButton.onClick = GameCharacter.onMountButtonClick

  -- Combat controls
  connect(chaseModeButton, {
    onCheckChange = GameCharacter.onSetChaseMode
  })
  connect(safeFightButton, {
    onCheckChange = GameCharacter.onSetSafeFight
  })

  addEvent(function()
    if not isWidgetAlive(contentsPanel) then
      return
    end

    -- Skills button
    local skillsButton = contentsPanel.skillsButton
    if skillsButton then
      skillsButton.onClick = GameSkills.toggle
    end

    -- Conditions button
    local conditionsButton = contentsPanel.conditionsButton
    if conditionsButton then
      conditionsButton.onClick = GameConditions.toggle
    end
  end)

  if g_game.isOnline() then
    GameCharacter.online()
  end
end

function GameCharacter.terminate()
  if g_game.isOnline() then
    GameCharacter.offline()
  end

  -- Combat controls
  disconnect(chaseModeButton, {
    onCheckChange = GameCharacter.onSetChaseMode
  })
  disconnect(safeFightButton, {
    onCheckChange = GameCharacter.onSetSafeFight
  })

  disconnect(LocalPlayer, {
    onNicknameChange = GameCharacter.onNicknameChange,

    onOutfitChange = GameCharacter.onOutfitChange,

    -- Health info
    onHealthChange       = GameCharacter.onHealthChange,
    onManaChange         = GameCharacter.onManaChange,
    onVigorChange        = GameCharacter.onVigorChange,
    onFreeCapacityChange = GameCharacter.onCapacityChange,
    onOverweightChange   = GameCharacter.onCapacityChange,
    onLevelChange        = GameCharacter.onLevelChange,

    -- Inventory
    onInventoryChange = GameCharacter.onInventoryChange,
    onBlessingsChange = GameCharacter.onBlessingsChange,
  })

  disconnect(g_game, {
    -- Inventory / Combat controls
    onGameStart = GameCharacter.online,

    -- Health info / Combat controls
    onGameEnd = GameCharacter.offline,

    -- Combat controls
    onChaseModeChange = GameCharacter.updateCombatControls,
    onSafeFightChange = GameCharacter.updateCombatControls,
    onWalk            = GameCharacter.check,
    onAutoWalk        = GameCharacter.check
  })

  g_keyboard.unbindKeyDown(CharacterWindowActionKey)

  -- Combat controls
  chaseModeButton:destroy()
  safeFightButton:destroy()
  mountButton:destroy()
  chaseModeButton = nil
  safeFightButton = nil
  mountButton = nil

  outfitCreatureBox:destroy()
  outfitCreatureBox = nil

  -- Health info
  healthBarPrevious:destroy()
  healthBar:destroy()
  manaBar:destroy()
  vigorBar:destroy()
  capacityBar:destroy()
  experienceBar:destroy()
  healthBarValueLabel:destroy()
  manaBarValueLabel:destroy()
  vigorBarValueLabel:destroy()
  capacityBarValueLabel:destroy()
  experienceBarValueLabel:destroy()
  healthBarPrevious = nil
  healthBar = nil
  manaBar = nil
  vigorBar = nil
  capacityBar = nil
  experienceBar = nil
  healthBarValueLabel = nil
  manaBarValueLabel = nil
  vigorBarValueLabel = nil
  capacityBarValueLabel = nil
  experienceBarValueLabel = nil

  inventoryTopMenuButton:destroy()
  inventoryTopMenuButton = nil
  inventoryWindow:destroy()
  inventoryWindow = nil

  _G.GameCharacter = nil
end





-- Combat controls

function GameCharacter.updateCombatControls()
  local chaseMode = g_game.getChaseMode()
  chaseModeButton:setChecked(chaseMode == ChaseOpponent)

  local safeFight = g_game.isSafeFight()
  safeFightButton:setChecked(not safeFight)
end

function GameCharacter.check()
  if ClientOptions.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(false, DontChase)
    end
  end
end

function GameCharacter.onSetChaseMode(self, checked)
  if not g_app.isOnInputEvent() then --just check the option
    return
  end
  local chaseMode
  if checked then
    chaseMode = ChaseOpponent
  else
    chaseMode = DontChase
  end
  g_game.setChaseMode(false, chaseMode)
end

function GameCharacter.onMountButtonClick(self, mousePos)
  if not g_app.isOnInputEvent() then --just check the option
    return
  end
  local player = g_game.getLocalPlayer()
  if player then
    player:toggleMount()
  end
end

function GameCharacter.onSetSafeFight(self, checked)
  if not g_app.isOnInputEvent() then --just check the option
    return
  end
  g_game.setSafeFight(false, not checked)
end





-- Inventory

function GameCharacter.toggleAdventurerStyle(hasBlessing)
  for slot = InventorySlotFirst, InventorySlotLast do
    local itemWidget = inventoryWindow:getChildById('contentsPanel'):getChildById('slot' .. slot)
    if itemWidget then
      itemWidget:setOn(hasBlessing)
    end
  end
end

function GameCharacter.toggle()
  GameInterface.toggleMiniWindow(inventoryWindow)
end

function GameCharacter.onInventoryChange(localPlayer, slot, item, oldItem)
  if slot > InventorySlotInbox then
    return
  end

  local itemWidget = inventoryWindow:getChildById('contentsPanel'):getChildById('slot' .. slot)
  if item then
    itemWidget:setStyle('InventoryItem')
    itemWidget:setItem(item)
  else
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
  end
  itemWidget:updateBackground()
end

function GameCharacter.onBlessingsChange(player, blessings, oldBlessings)
  local hasAdventurerBlessing = bit.hasBit(blessings, Blessings.Adventurer)
  if hasAdventurerBlessing ~= bit.hasBit(oldBlessings, Blessings.Adventurer) then
    GameCharacter.toggleAdventurerStyle(hasAdventurerBlessing)
  end
end





function GameCharacter.onNicknameChange(creature, nickname)
  local player = g_game.getLocalPlayer()
  if not player or creature ~= player then
    return
  end

  inventoryWindow:setText(nickname ~= '' and nickname or player:getName())
end

function GameCharacter.updateOutfitCreatureBox(outfit)
  outfitCreatureBox:setOutfit(outfit)
end

function GameCharacter.onOutfitChange(localPlayer, outfit, oldOutfit)
  GameCharacter.updateOutfitCreatureBox(outfit)

  if outfit.mount ~= oldOutfit.mount then
    mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
  end
end



local function isLogin()
  return loginTime <= 0 or loginTime > g_clock.millis()
end

function GameCharacter.onHealthChange(localPlayer, health, maxHealth)
  local isLogin = isLogin()

  if isLogin then
    healthBarPrevious:setValue(health, 0, maxHealth)
  else
    healthBarPrevious:setValueDelayed(health, 0, maxHealth, 1000, 25, 1000, false, true)
  end

  healthBar:setValue(health, 0, maxHealth)

  healthBarValueLabel:setText(f('%s / %s HP', loc(health), loc(maxHealth)))
  healthBarValueLabel:setTooltip(f(loc'${BarHealthTooltip}', loc(health), loc(maxHealth)), TooltipType.textBlock)
end

function GameCharacter.onManaChange(localPlayer, mana, maxMana)
  if isLogin() then
    manaBar:setValue(mana, 0, maxMana)
  else
    manaBar:setValueDelayed(mana, 0, maxMana, 200, 25, 0, true, false)
  end

  manaBarValueLabel:setText(f('%s / %s MP', loc(mana), loc(maxMana)))
  manaBarValueLabel:setTooltip(f(loc'${BarManaTooltip}', loc(mana), loc(maxMana)), TooltipType.textBlock)
end

function GameCharacter.onVigorChange(localPlayer, vigor, maxVigor)
  if isLogin() then
    vigorBar:setValue(vigor, 0, maxVigor)
  else
    vigorBar:setValueDelayed(vigor, 0, maxVigor, 200, 25, 0, true, false)
  end

  vigorBarValueLabel:setText(f('%s / %s VP', loc(vigor), loc(maxVigor)))
  vigorBarValueLabel:setTooltip(f(loc'${BarVigorTooltip}', loc(vigor), loc(maxVigor)), TooltipType.textBlock)
end

function GameCharacter.onCapacityChange(localPlayer)
  local currentWeight = localPlayer:getCurrentWeight()
  local totalCapacity = localPlayer:getTotalCapacity()
  local ratio         = currentWeight / totalCapacity

  capacityBar.bgColor = localPlayer:getWeightColor()
  capacityBar:updateBackground()

  if isLogin() then
    capacityBar:setValue(currentWeight, 0, totalCapacity)
  else
    capacityBar:setValueDelayed(currentWeight, 0, totalCapacity, 200, 25, 0, true, false)
  end

  capacityBarValueLabel:setText(f('%s / %s (%d%%) CAP', loc(currentWeight), loc(totalCapacity), ratio * 100))
  capacityBarValueLabel:setTooltip(f(loc'${BarCapacityTooltip}', loc(currentWeight), loc(totalCapacity), ratio > 1 and loc' (${BarCapacityTooltipOverweight})' or ''), TooltipType.textBlock)
end

function GameCharacter.onLevelChange(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  experienceBar:setPercent(levelPercent)
  experienceBarValueLabel:setText(levelPercent .. '% XP')
  experienceBarValueLabel:setTooltip(f(loc'${BarExperienceTooltip}', getExperienceTooltipText(localPlayer, level, levelPercent)), TooltipType.textBlock)
end





function GameCharacter.online()
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  loginTime = g_clock.millis() + 50

  inventoryWindow:setup(inventoryTopMenuButton)
  GameCharacter.updateMiniWindowSize()

  connect(player, {
    onVocationChange = GameCharacter.onVocationChange,
  })

  inventoryWindow:setText(player:getName())

  addEvent(function()
    local _player = g_game.getLocalPlayer()
    if _player and isWidgetAlive(outfitCreatureBox) then
      GameCharacter.updateOutfitCreatureBox(_player:getOutfit())
    end
  end)

  -- Inventory

  for i = InventorySlotFirst, InventorySlotInbox do
    if g_game.isOnline() then
      GameCharacter.onInventoryChange(player, i, player:getInventoryItem(i))
    else
      GameCharacter.onInventoryChange(player, i, nil)
    end
  end
  GameCharacter.toggleAdventurerStyle(player and bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)

  -- Combat controls

  local settings = Client.getPlayerSettings()
  local lastCombatControls = settings:getNode('lastCombatControls') or { }

  g_game.setChaseMode(true, lastCombatControls.chaseMode)
  g_game.setSafeFight(true, lastCombatControls.safeFight)

  if lastCombatControls.pvpMode then
    g_game.setPVPMode(true, lastCombatControls.pvpMode)
  end

  if g_game.getFeature(GamePlayerMounts) then
    mountButton:setVisible(true)
    mountButton:setChecked(player:isMounted())
  else
    mountButton:setVisible(false)
  end

  GameCharacter.updateCombatControls()
end

function GameCharacter.offline()
  loginTime = 0

  local player = g_game.getLocalPlayer()

  disconnect(player, {
    onVocationChange = GameCharacter.onVocationChange,
  })

  -- Combat controls

  local settings = Client.getPlayerSettings()
  local lastCombatControls = settings:getNode('lastCombatControls') or { }

  lastCombatControls = {
    chaseMode = g_game.getChaseMode(),
    safeFight = g_game.isSafeFight(),
  }

  -- KA - Removed GamePVPMode
  -- if g_game.getFeature(GamePVPMode) then
  --   lastCombatControls.pvpMode = g_game.getPVPMode()
  -- end

  -- Save last combat control settings
  settings:setNode('lastCombatControls', lastCombatControls)
  settings:save()
end

function GameCharacter.onVocationChange(creature, vocation, oldVocation)
  local localPlayer = g_game.getLocalPlayer()
  if creature ~= localPlayer then
    return
  end

  GameCharacter.updateMiniWindowSize()
end

function GameCharacter.onMiniWindowBallButton()
  if inventoryWindow:getSettings('minimized') then
    return
  end

  -- If all hidden, show them all
  local function onHide()
    local isStatsEnabled     = GameCharacter.isStatsEnabled()
    local isInventoryEnabled = GameCharacter.isInventoryEnabled()
    if isStatsEnabled or isInventoryEnabled then -- Any visible
      return
    end

    -- Show all
    GameCharacter.setStatsEnabled(true)
    GameCharacter.setInventoryEnabled(true)
  end

  local menu = g_ui.createWidget('PopupMenu')

  local isStatsEnabled = GameCharacter.isStatsEnabled()
  if isStatsEnabled then
    menu:addOption(loc'${CharacterStatsWindowHide}', function()
      GameCharacter.setStatsEnabled(false)
      onHide()
    end)
  else
    menu:addOption(loc'${CharacterStatsWindowShow}', function() GameCharacter.setStatsEnabled(true) end)
  end

  local isInventoryEnabled = GameCharacter.isInventoryEnabled()
  if isInventoryEnabled then
    menu:addOption(loc'${CharacterInventoryWindowHide}', function()
      GameCharacter.setInventoryEnabled(false)
      onHide()
    end)
  else
    menu:addOption(loc'${CharacterInventoryWindowShow}', function() GameCharacter.setInventoryEnabled(true) end)
  end

  menu:display()
end

function GameCharacter.isStatsEnabled()
  return g_settings.getValue('Character', 'statsWindow', defaultValues.statsWindow)
end

function GameCharacter.setStatsEnabled(on)
  g_settings.setValue('Character', 'statsWindow', on)
  if on then
    inventoryHeader:setHeight(GameCharacter.getHeaderHeight())
    inventoryHeader:setOn(true)
  else
    inventoryHeader:setOn(false)
  end
  inventoryWindow:setHeight(GameCharacter.getMiniWindowHeight(), true)
end

function GameCharacter.isInventoryEnabled()
  return g_settings.getValue('Character', 'inventoryWindow', defaultValues.inventoryWindow)
end

function GameCharacter.setInventoryEnabled(on)
  local contentsPanel = inventoryWindow:getChildById('contentsPanel')
  g_settings.setValue('Character', 'inventoryWindow', on)
  if on then
    contentsPanel:setHeight(GameCharacter.getInventoryHeight())
    contentsPanel:setOn(true)
  else
    contentsPanel:setOn(false)
  end
  inventoryWindow:setHeight(GameCharacter.getMiniWindowHeight(), true)
end

function GameCharacter.getHeaderHeight()
  if not GameCharacter.isStatsEnabled() then
    return 0
  end

  local barHeight   = 17 -- height + padding between
  local localPlayer = g_game.getLocalPlayer()
  return 5 * barHeight - (localPlayer and localPlayer:isWarrior() and barHeight or 0) - 1 --[[ remove padding on bottom ]] + 2 --[[ border ]]
end

function GameCharacter.getInventoryHeight()
  if not GameCharacter.isInventoryEnabled() then
    return 0
  end

  return 185
end

function GameCharacter.getWindow()
  return inventoryWindow
end

function GameCharacter.getMiniWindowHeight()
  return inventoryWindow.miniwindowTopBar:getHeight() + GameCharacter.getHeaderHeight() + GameCharacter.getInventoryHeight() + 2
end

function GameCharacter.updateMiniWindowSize()
  if inventoryWindow:getSettings('minimized') then
    return
  end

  local player    = g_game.getLocalPlayer()
  local isWarrior = player and player:isWarrior()

  manaBar:setOn(not isWarrior)
  inventoryHeader:setHeight(GameCharacter.getHeaderHeight())

  GameCharacter.setStatsEnabled(GameCharacter.isStatsEnabled())
  GameCharacter.setInventoryEnabled(GameCharacter.isInventoryEnabled())
end

function GameCharacter.onMinimize(window)
  inventoryHeader:setOn(false)
end

function GameCharacter.onMaximize(window)
  GameCharacter.updateMiniWindowSize()
end
