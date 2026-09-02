--[[Config]]

local powerBoostScreenImage = {
  fadeIn                = 200,
  fadeOut               = 100,
  sizeX                 = 0.5,
  sizeY                 = 0.5,
  sizeByFactor          = true,
  sizeBasedOnGameScreen = true,
  position              = ScreenImagePos.Center,
  scale                 = ScreenImageScale.Inside,
}

local powerNormalBoostScreenImage = { }
local powerExtraBoostScreenImage  = { }

for i = PowerBoostFirst, PowerBoostLast do
  powerNormalBoostScreenImage[i]      = table.copy(powerBoostScreenImage)
  powerNormalBoostScreenImage[i].path = f('system/power_boost/normal_%d.png', i)

  powerExtraBoostScreenImage[i]      = table.copy(powerBoostScreenImage)
  powerExtraBoostScreenImage[i].path = f('system/power_boost/extra_%d.png', i)
end

PowerBoostColorSpeed = 200

PowerBoostColor = {
  [PowerBoost.None]   = '#ffffffff',
  [PowerBoost.Low]    = '#ffff96ff',
  [PowerBoost.Medium] = '#ff9696ff',
  [PowerBoost.High]   = '#9696ffff'
}
PowerBoostColorDefault = PowerBoostColor[PowerBoost.None]



--[[Effects]]

function GamePowers.setBoostColor(boostLevel)
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    localPlayer:setColor(PowerBoostColor[boostLevel])
  end
end

function GamePowers.removeBoostColor()
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    localPlayer:setColor(PowerBoostColorDefault)
  end
end

function GamePowers.setBoostImage(boostLevel)
  if modules.ka_game_screenimage then
    GameScreenImage.addImage(powerNormalBoostScreenImage[boostLevel])
    GameScreenImage.addImage(powerExtraBoostScreenImage[boostLevel])
  end
end

function GamePowers.removeBoostImage(boostLevel)
  if modules.ka_game_screenimage then
    local normalBoost = powerNormalBoostScreenImage[boostLevel]
    local extraBoost  = powerExtraBoostScreenImage[boostLevel]
    GameScreenImage.removeImage(normalBoost.path, normalBoost.fadeOut, normalBoost.removeMode)
    GameScreenImage.removeImage(extraBoost.path, extraBoost.fadeOut, extraBoost.removeMode)
  end
end

function GamePowers.updateBoostEffects(boostLevel)
  -- remove current effects
  if lastBoost >= PowerBoostFirst and lastBoost <= PowerBoostLast then
    GamePowers.removeBoostImage(lastBoost)
    GamePowers.removeBoostColor(lastBoost)
  end
  -- add next effects
  if boostLevel and boostLevel >= PowerBoostFirst and boostLevel <= PowerBoostLast then
    GamePowers.setBoostImage(boostLevel)
    GamePowers.setBoostColor(boostLevel)
  end
end
