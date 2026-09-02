function getDistanceTo(fromPos, toPos, ignoreFloorDif)
  local xDif, yDif = math.abs(fromPos.x - toPos.x), math.abs(fromPos.y - toPos.y)
  local dif = math.max(xDif, yDif)
  return (ignoreFloorDif or fromPos.z == toPos.z) and dif or dif + 15
end

function expForLevel(level)
  return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function expToAdvance(currentLevel, currentExp)
  return expForLevel(currentLevel + 1) - currentExp
end

function getExperienceTooltipText(localPlayer, value, percent)
  local ret = f(loc'${KalibInfoRemainingXpToAdvance}', 100 - percent, loc(expToAdvance(localPlayer:getLevel(), localPlayer:getExperience())), loc(value + 1))

  if type(localPlayer.expSpeed) == 'number' then
    local xpPerHour = math.floor(localPlayer.expSpeed * 3600)
    if xpPerHour > 0 then
      local xpNextLevel = expForLevel(localPlayer:getLevel() + 1)
      local hoursLeft   = (xpNextLevel - localPlayer:getExperience()) / xpPerHour
      local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft)) * 60)
      ret = f('%s\n%s\n%s', ret, f(loc'${KalibInfoXpPerHour}', loc(xpPerHour)), f(loc'${KalibInfoRemainingTimeToAdvance}', math.floor(hoursLeft), minutesLeft))
    end
  end

  return ret
end
