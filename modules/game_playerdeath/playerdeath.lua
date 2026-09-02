g_locales.loadLocales(resolvepath(''))

_G.GamePlayerDeath = { }



deathWindow = nil

local deathTexts = {
  regular = { text = loc'${GamePlayerDeathMsgRegular}' },
  unfair = { text = loc'${GamePlayerDeathMsgUnfair}' },
  blessed = { text = loc'${GamePlayerDeathMsgBlessed}' }
}



function GamePlayerDeath.init()
  -- Alias
  GamePlayerDeath.m = modules.game_npctrade

  g_ui.importStyle('deathwindow')

  connect(g_game, {
    onDeath   = GamePlayerDeath.display,
    onGameEnd = GamePlayerDeath.reset
  })
end

function GamePlayerDeath.terminate()
  disconnect(g_game, {
    onDeath   = GamePlayerDeath.display,
    onGameEnd = GamePlayerDeath.reset
  })

  GamePlayerDeath.reset()

  _G.GamePlayerDeath = nil
end

function GamePlayerDeath.reset()
  if deathWindow then
    deathWindow:destroy()
    deathWindow = nil
  end
end

function GamePlayerDeath.display(deathType, penalty)
  GamePlayerDeath.displayDeadMessage()
  GamePlayerDeath.openWindow(deathType, penalty)
end

function GamePlayerDeath.displayDeadMessage()
  local advanceLabel = GameInterface.getRootPanel():recursiveGetChildById('middleCenterLabel')
  if advanceLabel:isVisible() then
    return
  end

  if modules.game_textmessage then
    GameTextMessage.displayGameMessage(loc'${GamePlayerDeathMsgYouAreDead}.')
  end
end

function GamePlayerDeath.openWindow(deathType, penalty)
  if deathWindow then
    deathWindow:destroy()
    return
  end

  deathWindow = g_ui.createWidget('DeathWindow', rootWidget)

  if deathType == DeathType.Regular then
    if penalty == 100 then
      deathWindow:setTooltip(deathTexts.regular.text, TooltipType.textBlock)
    else
      deathWindow:setTooltip(f(deathTexts.unfair.text, 100 - penalty), TooltipType.textBlock)
    end
  elseif deathType == DeathType.Blessed then
    deathWindow:setTooltip(deathTexts.blessed.text, TooltipType.textBlock)
  end

  local okButton = deathWindow:getChildById('buttonOk')
  local cancelButton = deathWindow:getChildById('buttonCancel')

  local okFunc = function()
    ClientCharacterList.doLogin()
    okButton:getParent():destroy()
    deathWindow = nil
  end
  local cancelFunc = function()
    g_game.safeLogout()
    cancelButton:getParent():destroy()
    deathWindow = nil
  end

  deathWindow.onEnter = okFunc
  deathWindow.onEscape = cancelFunc

  okButton.onClick = okFunc
  cancelButton.onClick = cancelFunc
end
