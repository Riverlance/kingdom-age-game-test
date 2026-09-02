PowerBoost = {
  None   = 0,
  Low    = 1,
  Medium = 2,
  High   = 3,
}
PowerBoostFirst = PowerBoost.Low
PowerBoostLast  = PowerBoost.High

lastBoost = PowerBoost.None

local PowerCastQueue = { }

local PowerFlags = {
  Charge = 1,
  Cast = 2,
  Cancel = 3,
}

--[[Send to Server]]
function GamePowers.sendPowerCharge(powerId)
  if not g_game.canPerformGameAction() then
    return
  end
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodePowerCast)
  msg:addU8(PowerFlags.Charge)
  msg:addU8(powerId)
  g_game.getProtocolGame():send(msg)
end

function GamePowers.sendPowerCast(position)
  if not g_game.canPerformGameAction() then
    return
  end
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodePowerCast)
  msg:addU8(PowerFlags.Cast)
  msg:addPosition(position)
  g_game.getProtocolGame():send(msg)
end

function GamePowers.sendPowerCancel()
  if not g_game.canPerformGameAction() then
    return
  end
  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodePowerCast)
  msg:addU8(PowerFlags.Cancel)
  g_game.getProtocolGame():send(msg)
end

--[[Receive from Server]]
function GamePowers.parsePower(protocol, msg)
  local flag = msg:getU8()
  if flag == PowerFlags.Charge then
    local powerId = msg:getU8()
    local boost = msg:getU8()
    GamePowers.onChargePower(powerId, boost)
  elseif flag == PowerFlags.Cast then
    local powerId = msg:getU8()
    local exhaustTime = msg:getU32()
    GamePowers.onCastPower(powerId, exhaustTime)
  elseif flag == PowerFlags.Cancel then
    GamePowers.onCancelPower()
  else
    print_traceback(f('[Warning - ServerPowerCast] Unknown flag [id: %d]', flag))
  end
end


--[[Actions]]

function GamePowers.chargePower(powerId)--onKeyDown/onMousePress
  if not PowerCastQueue[powerId] then
    GamePowers.sendPowerCharge(powerId)
  end
end

function GamePowers.castPower(position)--onKeyUp/onMouseRelease
  GamePowers.sendPowerCast(position)
end

function GamePowers.cancelPower()--onEsc
  GamePowers.sendPowerCancel()
  return not table.empty(PowerCastQueue)
end


--[[Events]]

function GamePowers.onChargePower(powerId, boostLevel)
  PowerCastQueue[powerId] = true
  GamePowers.updateBoostEffects(boostLevel)
  signalcall(g_game.onChargePower, powerId, boostLevel, lastBoost)
  lastBoost = boostLevel
end

function GamePowers.onCastPower(powerId, exhaustTime)
  PowerCastQueue = { }
  GamePowers.updateBoostEffects(PowerBoost.None)
  signalcall(g_game.onCastPower, powerId, exhaustTime, lastBoost)
  lastBoost = PowerBoost.None
end

function GamePowers.onCancelPower()
  PowerCastQueue = { }
  GamePowers.updateBoostEffects(PowerBoost.None)
  signalcall(g_game.onCancelPower)
  lastBoost = PowerBoost.None
end
