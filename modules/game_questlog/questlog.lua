g_locales.loadLocales(resolvepath(''))

_G.GameQuestLog = { }



local GameQuestLogActionKey = 'Ctrl+Q'

questLogButton = nil
questLineWindow = nil

local questLogTeleportLock = false

QUEST_CATEGORY_MAIN      = 1
QUEST_CATEGORY_SIDEQUEST = 2
QUEST_CATEGORY_DAILY     = 3
QUEST_CATEGORY_WEEKLY    = 4
QUEST_CATEGORY_MONTHLY   = 5
QUEST_CATEGORY_GUILD     = 6

QUESTS_CATEGORIESNAMES = {
  [QUEST_CATEGORY_MAIN]      = loc'${GameQuestLogMain}',
  [QUEST_CATEGORY_SIDEQUEST] = loc'${GameQuestLogSide}',
  [QUEST_CATEGORY_DAILY]     = loc'${GameQuestLogDaily}',
  [QUEST_CATEGORY_WEEKLY]    = loc'${GameQuestLogWeekly}',
  [QUEST_CATEGORY_MONTHLY]   = loc'${GameQuestLogMonthly}',
  [QUEST_CATEGORY_GUILD]     = loc'${GameQuestLogGuild}',
}



function GameQuestLog.init()
  -- Alias
  GameQuestLog.m = modules.game_questlog

  g_ui.importStyle('questlogwindow')
  g_ui.importStyle('questlinewindow')

  questLogButton = ClientTopMenu.addRightGameButton('questLogButton', { loct = '${GameQuestLogWindowTitle} (${GameQuestLogActionKey})', locpar = { GameQuestLogActionKey = GameQuestLogActionKey } }, '/images/ui/top_menu/questlog', GameQuestLog.toggle)

  connect(g_game, {
    onGameEnd = GameQuestLog.destroyWindows
  })
  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeQuestLog, GameQuestLog.parseQuestLog)
  g_keyboard.bindKeyDown(GameQuestLogActionKey, GameQuestLog.toggle)
end

function GameQuestLog.terminate()
  g_keyboard.unbindKeyDown(GameQuestLogActionKey)
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeQuestLog)
  disconnect(g_game, {
    onGameEnd = GameQuestLog.destroyWindows
  })

  GameQuestLog.destroyWindows()
  questLogButton:destroy()

  _G.GameQuestLog = nil
end

-- For avoid multiple teleport confirm windows
function GameQuestLog.getTeleportLock()
  return questLogTeleportLock
end
function GameQuestLog.setTeleportLock(lock)
  questLogTeleportLock = lock
end

function GameQuestLog.destroyWindows()
  if questLogWindow then
    questLogWindow:destroy()
  end

  if questLineWindow then
    questLineWindow:destroy()
  end
end

function GameQuestLog.show()
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  GameQuestLog.sendLogWindowRequest()

  questLogButton:setOn(true)
end

function GameQuestLog.hide()
  GameQuestLog.destroyWindows()
  questLogButton:setOn(false)
end

function GameQuestLog.toggle()
  if not questLogWindow or not questLogWindow:isVisible() then
    GameQuestLog.show()
  else
    GameQuestLog.hide()
  end
end

function GameQuestLog.sendTeleportRequest(questId, missionId)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeAction)

  msg:addU16(ClientActions.QuestTeleports)
  msg:addU16(questId)
  msg:addU16(missionId)

  protocolGame:send(msg)

  return true
end

function GameQuestLog.sendShowItemsRequest(questId, missionId)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeAction)

  msg:addU16(ClientActions.QuestItems)
  msg:addU16(questId)
  msg:addU16(missionId)

  protocolGame:send(msg)

  return true
end

function GameQuestLog.sendLogWindowRequest(questId)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeQuestLog)

  -- Quest log
  if not questId then
    msg:addU8(1)

  -- Mission log
  else
    msg:addU8(2)

    msg:addU16(questId) -- Quest id
  end

  protocolGame:send(msg)

  return true
end

function GameQuestLog.onRowUpdate(child)
  if child then
    if not child.isComplete and not child.canDo then
      child:setBackgroundColor('#ff000020')
    end
    child.mainDataLabel:setColor(child:isFocused() and '#ffffff' or '#e6db74')
  end
end

function GameQuestLog.updateLayout(window, questId, missionId, row)
  if not window then
    return
  end
  local teleportButton             = window:getChildById('teleportButton')
  local rewardsLabel               = window:getChildById('rewardsLabel')
  local rewardExperienceLabel      = window:getChildById('rewardExperienceLabel')
  local rewardExperienceValueLabel = window:getChildById('rewardExperienceValueLabel')
  local rewardMoneyLabel           = window:getChildById('rewardMoneyLabel')
  local rewardMoneyValueLabel      = window:getChildById('rewardMoneyValueLabel')
  local itemsButton                = window:getChildById('itemsButton')
  local otherRewards               = window:getChildById('otherRewards')
  local otherRewardsScrollBar      = window:getChildById('otherRewardsScrollBar')
  local rowsList                   = row.parent

  if row.hasTeleport then
    teleportButton:setVisible(true)

    teleportButton.onClick = function()
      if not GameQuestLog.getTeleportLock() then
        local buttonCallback = function()
          GameQuestLog.sendTeleportRequest(questId, missionId)
          if modules.game_questlog then
            GameQuestLog.setTeleportLock(false)
          end
        end

        local onCancelCallback = function()
          if modules.game_questlog then
            GameQuestLog.setTeleportLock(false)
          end
        end

        displayCustomBox(loc'${GameQuestLogDialogTeleportTitle}', loc'${GameQuestLogDialogTeleportMsg}', {{ text = loc'${CorelibInfoYes}', buttonCallback = buttonCallback }}, 1, loc'${CorelibInfoNo}', onCancelCallback, nil)
        GameQuestLog.setTeleportLock(true)
      end
    end
  else
    teleportButton:setVisible(false)
  end

  if row.experience >= 1 then
    rewardExperienceLabel:setVisible(true)
    rewardExperienceValueLabel:setVisible(true)
    rewardExperienceValueLabel:setText(f('%s XP', loc(row.experience)))
  else
    rewardExperienceLabel:setVisible(false)
    rewardExperienceValueLabel:setVisible(false)
  end

  if row.money >= 1 then
    rewardMoneyLabel:setVisible(true)
    rewardMoneyValueLabel:setVisible(true)
    rewardMoneyValueLabel:setText(f('%s GPs', loc(row.money)))
  else
    rewardMoneyLabel:setVisible(false)
    rewardMoneyValueLabel:setVisible(false)
  end

  if row.showItems then
    itemsButton:setVisible(true)
    itemsButton.onClick = function()
      GameQuestLog.sendShowItemsRequest(questId, missionId)
    end
  else
    itemsButton:setVisible(false)
  end

  if row.otherRewards and row.otherRewards ~= '' then
    otherRewards:setVisible(true)
    otherRewards:setText(row.otherRewards)
    otherRewardsScrollBar:setVisible(true)
  else
    otherRewards:setVisible(false)
    otherRewardsScrollBar:setVisible(false)
  end

  rewardsLabel:setVisible(rewardExperienceValueLabel:isVisible() or rewardMoneyValueLabel:isVisible() or itemsButton:isVisible() or otherRewards:isVisible())

  if rowsList and rowsList:hasChildren() then
    local children = rowsList:getChildren()
    if #children >= 1 then
      for i = 1, #children do
        GameQuestLog.onRowUpdate(children[i])
      end
    end
  end
end

function GameQuestLog.parseQuestLog(protocolGame, opcode, msg)
  local windowId = msg:getU8()

  -- Quest log window
  if windowId == 1 then
    local quests = { }

    local questListSize = msg:getU16()
    for i = 1, questListSize do
      local quest = { }

      quest.id           = msg:getU16()
      quest.isComplete   = msg:getU8() == 1
      quest.canDo        = msg:getU8() == 1
      quest.logName      = msg:getString()
      quest.categoryName = QUESTS_CATEGORIESNAMES[msg:getU8()] or ''
      quest.minLevel     = msg:getU32()
      quest.hasTeleport  = msg:getU8() == 1

      local hasRewards   = msg:getU8() == 1
      quest.experience   = hasRewards and msg:getU64() or 0
      quest.money        = hasRewards and msg:getU64() or 0
      quest.showItems    = hasRewards and msg:getU8() == 1 or false
      quest.otherRewards = hasRewards and msg:getString() or ''

      table.insert(quests, quest)
    end

    GameQuestLog.onGameQuestLog(quests)

  -- Mission log window
  elseif windowId == 2 then
    local missions = { }

    local questId = msg:getU16()

    local missionListSize = msg:getU16()
    for i = 1, missionListSize do
      local mission = { }

      mission.id           = msg:getU16()
      mission.isComplete   = msg:getU8() == 1
      mission.canDo        = msg:getU8() == 1
      mission.logName      = msg:getString()
      mission.minLevel     = msg:getU32()
      mission.description  = msg:getString()
      mission.hasTeleport  = msg:getU8() == 1

      local hasRewards     = msg:getU8() == 1
      mission.experience   = hasRewards and msg:getU64() or 0
      mission.money        = hasRewards and msg:getU64() or 0
      mission.showItems    = hasRewards and msg:getU8() == 1 or false
      mission.otherRewards = hasRewards and msg:getString() or ''

      table.insert(missions, mission)
    end

    GameQuestLog.onGameQuestLine(questId, missions)
  end
end

function GameQuestLog.onGameQuestLog(quests)
  GameQuestLog.destroyWindows()

  questLogWindow = g_ui.createWidget('QuestLogWindow', rootWidget)
  local questList = questLogWindow:getChildById('questList')

  connect(questList, {
    onChildFocusChange = function(self, focusedChild)
      if focusedChild == nil then
        return
      end

      GameQuestLog.updateLayout(questLogWindow, focusedChild.questId, 0, focusedChild)
    end
  })

  for _, quest in ipairs(quests) do
    local questLabel = g_ui.createWidget('QuestLabel', questList)
    questLabel.parent = questList
    questLabel.questId = quest.id
    questLabel.isComplete = quest.isComplete
    questLabel:setOn(quest.isComplete)
    questLabel.canDo = quest.canDo
    questLabel.logName = quest.logName
    questLabel.categoryName = quest.categoryName
    questLabel.minLevel = quest.minLevel
    questLabel:setText(quest.logName)
    questLabel.hasTeleport = quest.hasTeleport
    questLabel.experience = quest.experience
    questLabel.money = quest.money
    questLabel.showItems = quest.showItems
    questLabel.otherRewards = quest.otherRewards

    local questMainDataLabel = g_ui.createWidget('QuestDataLabel', questLabel)
    questMainDataLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    questMainDataLabel:setText(f('[%s]%s', quest.categoryName, quest.minLevel > 1 and f(loc' [${GameQuestLogInfoLevel}]', quest.minLevel) or ''))
    questLabel.mainDataLabel = questMainDataLabel

    GameQuestLog.onRowUpdate(questLabel)
    questLabel.onDoubleClick =
    function()
      if not g_game.canPerformGameAction() then
        return
      end

      local protocolGame = g_game.getProtocolGame()
      if not protocolGame then
        return
      end

      questLogWindow:hide()

      GameQuestLog.sendLogWindowRequest(quest.id)
    end

  end

  questLogWindow.onDestroy = function()
    questLogWindow = nil
  end

  --questList:focusChild(questList:getFirstChild())
end

function GameQuestLog.onGameQuestLine(questId, missions)
  if questLogWindow then
    questLogWindow:hide()
  end

  if questLineWindow then
    questLineWindow:destroy()
  end

  questLineWindow = g_ui.createWidget('QuestLineWindow', rootWidget)
  local missionList = questLineWindow:getChildById('missionList')
  local missionDescription = questLineWindow:getChildById('missionDescription')

  connect(missionList, {
    onChildFocusChange = function(self, focusedChild)
      if focusedChild == nil then
        return
      end

      missionDescription:setText(focusedChild.description)
      GameQuestLog.updateLayout(questLineWindow, questId, focusedChild.missionId, focusedChild)
    end
  })

  for _, mission in pairs(missions) do
    local missionLabel = g_ui.createWidget('MissionLabel')
    missionLabel.parent = missionList
    missionLabel.missionId = mission.id
    missionLabel.isComplete = mission.isComplete
    missionLabel:setOn(mission.isComplete)
    missionLabel.canDo = mission.canDo
    missionLabel.logName = mission.logName
    missionLabel.minLevel = mission.minLevel
    missionLabel:setText(mission.logName)
    missionLabel.description = mission.description
    missionLabel.hasTeleport = mission.hasTeleport
    missionLabel.experience = mission.experience
    missionLabel.money = mission.money
    missionLabel.showItems = mission.showItems
    missionLabel.otherRewards = mission.otherRewards

    local missionMainDataLabel = g_ui.createWidget('MissionDataLabel', missionLabel)
    missionMainDataLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    missionMainDataLabel:setText(mission.minLevel > 1 and f(loc' [${GameQuestLogInfoLevel}]', mission.minLevel) or '')
    missionLabel.mainDataLabel = missionMainDataLabel

    GameQuestLog.onRowUpdate(missionLabel)
    missionList:addChild(missionLabel)
  end

  questLineWindow.onDestroy = function()
    if questLogWindow then
      questLogWindow:show()
    end

    questLineWindow = nil
  end

  --missionList:focusChild(missionList:getFirstChild())
end

function GameQuestLog.questLogWindowFocus()
  if questLogWindow then
    questLogWindow:focus()
  end
end
