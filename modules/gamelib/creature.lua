-- @docclass Creature

function getCreatureTypeImagePath(typeId)
  local path = ''
  if typeId == CreatureTypeSummonOwn then
    path = '/images/game/creature/type/summon_own'
  elseif typeId == CreatureTypeSummonOther then
    path = '/images/game/creature/type/summon_other'
  end
  return path
end

function getNextSkullId(skullId)
  if skullId == SkullRed or skullId == SkullBlack then
    return SkullBlack
  end
  return SkullRed
end

function getSkullImagePath(skullId)
  local path = ''
  if skullId == SkullYellow then
    path = '/images/game/creature/skull/yellow'
  elseif skullId == SkullGreen then
    path = '/images/game/creature/skull/green'
  elseif skullId == SkullWhite then
    path = '/images/game/creature/skull/white'
  elseif skullId == SkullRed then
    path = '/images/game/creature/skull/red'
  elseif skullId == SkullBlack then
    path = '/images/game/creature/skull/black'
  elseif skullId == SkullOrange then
    path = '/images/game/creature/skull/orange'
  elseif skullId == SkullProtected then
    path = '/images/game/creature/skull/protected'
  end
  return path
end

function getShieldImagePathAndBlink(shieldId)
  local path, blink = '', false
  if shieldId == ShieldWhiteYellow then
    path, blink = '/images/game/creature/shield/yellow_white', false
  elseif shieldId == ShieldWhiteBlue then
    path, blink = '/images/game/creature/shield/blue_white', false
  elseif shieldId == ShieldBlue then
    path, blink = '/images/game/creature/shield/blue', false
  elseif shieldId == ShieldYellow then
    path, blink = '/images/game/creature/shield/yellow', false
  elseif shieldId == ShieldBlueSharedExp then
    path, blink = '/images/game/creature/shield/blue_shared', false
  elseif shieldId == ShieldYellowSharedExp then
    path, blink = '/images/game/creature/shield/yellow_shared', false
  elseif shieldId == ShieldBlueNoSharedExpBlink then
    path, blink = '/images/game/creature/shield/blue_not_shared', true
  elseif shieldId == ShieldYellowNoSharedExpBlink then
    path, blink = '/images/game/creature/shield/yellow_not_shared', true
  elseif shieldId == ShieldBlueNoSharedExp then
    path, blink = '/images/game/creature/shield/blue_not_shared', false
  elseif shieldId == ShieldYellowNoSharedExp then
    path, blink = '/images/game/creature/shield/yellow_not_shared', false
  elseif shieldId == ShieldGray then
    path, blink = '/images/game/creature/shield/gray', false
  end
  return path, blink
end

function getEmblemImagePath(emblemId)
  local path = ''
  if emblemId == EmblemGreen then
    path = '/images/game/creature/emblem/green'
  elseif emblemId == EmblemRed then
    path = '/images/game/creature/emblem/red'
  elseif emblemId == EmblemBlue then
    path = '/images/game/creature/emblem/blue'
  elseif emblemId == EmblemMember then
    path = '/images/game/creature/emblem/member'
  elseif emblemId == EmblemOther then
    path = '/images/game/creature/emblem/other'
  end
  return path
end

function getSpecialIconPath(iconId)
  local path = ''
  if iconId == SpecialIconWanted then
    path = '/images/game/creature/special_icon/wanted'
  end
  return path
end

function getSpeechBubbleImagePath(speechBubbleId)
  local path = ''
  if speechBubbleId == SpeechBubbleChat then
    path = '/images/game/creature/speech_bubble/chat'
  elseif speechBubbleId == SpeechBubbleTrader then
    path = '/images/game/creature/speech_bubble/trader'
  elseif speechBubbleId == SpeechBubbleQuest then
    path = '/images/game/creature/speech_bubble/quest'
  elseif speechBubbleId == SpeechBubbleHouse then
    path = '/images/game/creature/speech_bubble/house'
  elseif speechBubbleId == SpeechBubbleTraderQuest then
    path = '/images/game/creature/speech_bubble/trader_quest'
  elseif speechBubbleId == SpeechBubbleTraderHouse then
    path = '/images/game/creature/speech_bubble/trader_house'
  end
  return path
end

function Creature:onTypeChange(typeId)
  local imagePath = getCreatureTypeImagePath(typeId)
  if imagePath ~= '' then
    self:setTypeTexture(imagePath)
  end
end

function Creature:onSkullChange(skullId, oldSkull)
  local imagePath = getSkullImagePath(skullId)
  if imagePath ~= '' then
    self:setSkullTexture(imagePath)
  end
end

function Creature:onShieldChange(shieldId)
  local imagePath, blink = getShieldImagePathAndBlink(shieldId)
  if imagePath ~= '' then
    self:setShieldTexture(imagePath, blink)
  end
end

function Creature:onEmblemChange(emblemId)
  local imagePath = getEmblemImagePath(emblemId)
  if imagePath ~= '' then
    self:setEmblemTexture(imagePath)
  end
end

function Creature:onSpeechBubbleChange(iconId)
  local imagePath = getSpeechBubbleImagePath(iconId)
  if imagePath ~= '' then
    self:setSpeechBubbleTexture(imagePath)
  end
end

function Creature:onSpecialIconChange(iconId)
  local imagePath = getSpecialIconPath(iconId)
  if imagePath ~= '' then
    self:setSpecialIconTexture(imagePath)
  end
end
