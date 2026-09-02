g_locales.loadLocales(resolvepath(''))

_G.GameDailyReward = { }



local DailyReward = {
  Playing   = 1,
  Unclaimed = 2,
  Claimed   = 3,

  Window = 1,
  Update = 2,
}

dailyRewardInfo = nil

dailyRewardWindow = nil
rewardsBar  = nil
bonusBar    = nil
claimButton = nil
cycleTimer  = nil

function GameDailyReward.init()
  -- Alias
  GameDailyReward.m = modules.ka_game_dailyreward

  g_ui.importStyle('dailyrewardwindow')

  dailyRewardWindow = g_ui.createWidget('DailyRewardWindow', rootWidget)
  dailyRewardWindow:hide()

  rewardsBar  = dailyRewardWindow.claimRewardsBar
  bonusBar    = dailyRewardWindow.bonusBar
  claimButton = dailyRewardWindow.claimButton
  claimButton.onClick = function(self, mousePos)
    GameDailyReward.sendClaimRequest()
  end

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeDailyReward, GameDailyReward.parse)

  connect(g_game, {
    onGameEnd = GameDailyReward.hide,
  })

  connect(LocalPlayer, {
    onPositionChange = GameDailyReward.hide
  })
end

function GameDailyReward.terminate()
  disconnect(LocalPlayer, {
    onPositionChange = GameDailyReward.hide
  })

  disconnect(g_game, {
    onGameEnd = GameDailyReward.hide,
  })

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeDailyReward)

  if dailyRewardWindow then
    dailyRewardWindow:destroy()
    dailyRewardWindow = nil
  end

  if cycleTimer then
    cycleTimer:destroy()
    cycleTimer = nil
  end

  rewardsBar  = nil
  bonusBar    = nil
  claimButton = nil

  _G.GameDailyReward = nil
end

function GameDailyReward.updateCycleTimer()
  dailyRewardWindow.timeLabel:setText(cycleTimer:getString())

  if dailyRewardInfo.status == DailyReward.Playing then
    local dailyPercent = 100 - cycleTimer:getPercent()
    GameDailyReward.setRewardProgress(dailyPercent)
    GameDailyReward.setBonusProgress(dailyPercent)
  end
end

function GameDailyReward.onUpdateWindow(flag) -- only when change status
  if cycleTimer then
    cycleTimer:destroy()
    cycleTimer = nil
  end

  cycleTimer = Timer.new({ }, dailyRewardInfo.statusEnd * 1000, '!%M:%S')
  cycleTimer.updateTicks = 1
  cycleTimer.onUpdate = function() GameDailyReward.updateCycleTimer() end
  cycleTimer:start()

  dailyRewardWindow.timeLabel:setText(cycleTimer:getString())
  if dailyRewardInfo.status == DailyReward.Playing then
    local dailyPercent = 100 - cycleTimer:getPercent()
    GameDailyReward.setRewardProgress(dailyPercent)
    GameDailyReward.setBonusProgress(dailyPercent)
  end

  local bonusWeek   = dailyRewardInfo.dailyStreak >= 7 -- More than 1 week, week last day accomplished and taken, week first day after 7 accomplished

  for prize = 1, 7 do
    local phaseMiddleMargin = GameDailyReward.getPhaseMiddleMargin(rewardsBar, prize)

    -- Reward item
    local rewardItemWidget = dailyRewardWindow['rewardItem' .. prize]
    rewardItemWidget:setMarginLeft(rewardsBar.bgBorderLeft + phaseMiddleMargin - math.floor(rewardItemWidget:getWidth() / 2))
    rewardItemWidget:setEnabled(dailyRewardInfo.currentPrize == prize and dailyRewardInfo.status ~= DailyReward.Claimed)

    local prizeArrow = rewardItemWidget.arrow
    prizeArrow:setVisible(prize == dailyRewardInfo.currentPrize)

    local lock = (dailyRewardInfo.currentPrize - prize - 1) % 7 < dailyRewardInfo.dailyStreak -- claimed
    rewardItemWidget.icon:setVisible(dailyRewardInfo.currentPrize ~= prize or dailyRewardInfo.status == DailyReward.Claimed)
    rewardItemWidget.icon:setOn(lock)

    local prizeItem = dailyRewardInfo.prizes[prize]
    rewardItemWidget.item:setOn(bonusWeek)
    rewardItemWidget.item:setItemId(prizeItem.id)
    rewardItemWidget.item:setItemCount(prizeItem.count)
    rewardItemWidget.blueLabel:setText(prize)

    local desc = prizeItem.description and ('\n' .. prizeItem.description) or ''
    rewardItemWidget.blueLabel:setTooltip(f('%s%s', prizeItem.title, desc))
  end

  -- Reward Bar
  if dailyRewardInfo.status == DailyReward.Playing then
    claimButton:setEnabled(false)
    claimButton:setText(loc'${GameDailyRewardButtonClaimPlayEnough}')
    rewardsBar:setTooltip(loc'${GameDailyRewardButtonClaimPlayEnoughTooltip}', TooltipType.textBlock)
  elseif dailyRewardInfo.status == DailyReward.Unclaimed then
    claimButton:setEnabled(true)
    claimButton:setText(loc'${GameDailyRewardButtonClaimClaimNow}')
    rewardsBar:setTooltip(loc'${GameDailyRewardButtonClaimClaimNowTooltip}', TooltipType.textBlock)
  elseif dailyRewardInfo.status == DailyReward.Claimed then
    claimButton:setEnabled(false)
    claimButton:setText(loc'${GameDailyRewardButtonClaimClaimed}')
    rewardsBar:setTooltip(loc'${GameDailyRewardButtonClaimClaimedTooltip}', TooltipType.textBlock)
  end

  -- Bonus Bar
  local bonusTooltipText
  if bonusWeek then
    bonusTooltipText = loc'${GameDailyRewardBonusBarTooltipEnabled}'
  else
    bonusTooltipText = f(loc'${GameDailyRewardBonusBarTooltipDisabled}\n* ${GameDailyRewardBonusBarTooltipDaysToEnable}: %d', math.max(0, 7 - dailyRewardInfo.dailyStreak))
  end
  bonusBar:setTooltip(bonusTooltipText, TooltipType.textBlock)

  -- Streak Days
  dailyRewardWindow.streakDays:setText(f(loc'${GameDailyRewardInfoStreak}: %s', dailyRewardInfo.dailyStreak))

  if flag == DailyReward.Window then
    GameDailyReward.show()
  end
end

function GameDailyReward.show()
  dailyRewardWindow:show()
  dailyRewardWindow:focus()
end

function GameDailyReward.hide()
  dailyRewardWindow:hide()
end

function GameDailyReward.toggle()
  if dailyRewardWindow:isVisible() then
    GameDailyReward.hide()
  else
    GameDailyReward.show()
  end
end

function GameDailyReward.getPhaseMargin(rewardsBar, phaseId)
  local rewardSliceWidth = (rewardsBar:getWidth() - (rewardsBar.bgBorderLeft + rewardsBar.bgBorderRight)) / 7

  return rewardSliceWidth * phaseId
end

function GameDailyReward.getPhaseMiddleMargin(barWidget, phaseId)
  local rewardSliceWidth     = (rewardsBar:getWidth() - (rewardsBar.bgBorderLeft + rewardsBar.bgBorderRight)) / 7
  local halfRewardSliceWidth = rewardSliceWidth / 2

  return rewardSliceWidth * phaseId - halfRewardSliceWidth
end


function GameDailyReward.setRewardProgress(dayPercent)
  local progress = 100
  local currentPrize = dailyRewardInfo.currentPrize
  if currentPrize <= 7 then
    progress = math.max(0, currentPrize - 1) * (100 / 7) + (dayPercent / 7)
  end
  rewardsBar:setPercent(progress)
end

function GameDailyReward.setBonusProgress(dayPercent)
  local progress = 100
  local dailyStreak = dailyRewardInfo.dailyStreak
  if dailyStreak < 7 then
    progress = dailyStreak * (100 / 7) + (dayPercent / 7)
  end
  bonusBar:setPercent(progress)
end

-- Server to client

function GameDailyReward.parse(protocolGame, opcode, msg)
  local flag = msg:getU8()
  local dailyRewardWindowInfo = {
    status       = msg:getU8(),
    currentPrize = msg:getU8(),
    dailyStreak  = msg:getU16(),
    statusEnd    = msg:getU32(),
  }

  local items = { }
  for day = 1, 7 do
    items[day] = {
      id          = msg:getU16(),
      count       = msg:getU16(),
      title       = msg:getString(),
      description = msg:getString(),
    }
  end
  dailyRewardWindowInfo.prizes = items
  dailyRewardInfo = dailyRewardWindowInfo
  GameDailyReward.onUpdateWindow(flag)
end

-- Client to server

function GameDailyReward.sendClaimRequest()
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeDailyReward)
  protocolGame:send(msg)
end
