_G.GamePlayerMount = { }



function GamePlayerMount.init()
  -- Alias
  GamePlayerMount.m = modules.game_playermount

  connect(g_game, {
    onGameStart = GamePlayerMount.online,
    onGameEnd   = GamePlayerMount.offline
  })

  if g_game.isOnline() then
    GamePlayerMount.online()
  end
end

function GamePlayerMount.terminate()
  disconnect(g_game, {
    onGameStart = GamePlayerMount.online,
    onGameEnd   = GamePlayerMount.offline
  })

  GamePlayerMount.offline()

  _G.GamePlayerMount = nil
end

function GamePlayerMount.online()
  if g_game.getFeature(GamePlayerMounts) then
    g_keyboard.bindKeyDown('Ctrl+R', GamePlayerMount.toggleMount)
  end
end

function GamePlayerMount.offline()
  if g_game.getFeature(GamePlayerMounts) then
    g_keyboard.unbindKeyDown('Ctrl+R')
  end
end

function GamePlayerMount.toggleMount()
  local player = g_game.getLocalPlayer()
  if player then
    player:toggleMount()
  end
end

function GamePlayerMount.mount()
  local player = g_game.getLocalPlayer()
  if player then
    player:mount()
  end
end

function GamePlayerMount.dismount()
  local player = g_game.getLocalPlayer()
  if player then
    player:dismount()
  end
end
