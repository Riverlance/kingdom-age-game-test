_G.GameThings = { }



function GameThings.init()
  -- Alias
  GameThings.m = modules.game_things

  connect(g_game, {
    onGameStart = GameThings.online,
    onGameEnd   = GameThings.offline
  })
end

function GameThings.terminate()
  disconnect(g_game, {
    onGameStart = GameThings.online,
    onGameEnd   = GameThings.offline
  })

  _G.GameThings = nil
end

function GameThings.setFileName(name)
  filename = name
end

function GameThings.online()
  -- Ensure player settings file existence
  Client.getPlayerSettings()
end

function GameThings.offline()
  -- On last save of playerSettingsFile when player get offline
  scheduleEvent(function()
    local file = Client.getPlayerSettings()
    -- Keep player settings after terminate
    file:save()
  end)
end
