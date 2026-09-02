_G.GameBlinkHit = { }

local blinkTime = 200

function GameBlinkHit.init()
  -- Alias
  GameBlinkHit.m = modules.ka_game_blinkhit

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeBlinkHit, GameBlinkHit.onBlinkHit)
end

function GameBlinkHit.terminate()
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeBlinkHit)
end

local function setBlink(creatureId, active)
  local creature = g_map.getCreatureById(creatureId)
  if not creature then
    return
  end

  if active then
    creature:setShader('Outfit - Negative')
  else
    creature:setShader('Outfit - None')
  end
end

function GameBlinkHit.onBlinkHit(protocolGame, opcode, msg)
  local buffer = msg:getString()

  local id = tonumber(buffer)
  if not id then
    return
  end

  setBlink(id, true)
  scheduleEvent(function() setBlink(id, false) end, blinkTime)
end
