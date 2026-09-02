-- uncomment this line to apply an effect on the local player, just for testing purposes.
function onGameStart()
  -- g_game.getLocalPlayer():attachEffect(g_attachedEffects.getById(1))
  -- g_game.getLocalPlayer():attachEffect(g_attachedEffects.getById(2))
  -- g_game.getLocalPlayer():attachEffect(g_attachedEffects.getById(3))
end

function onGameEnd()
  -- g_game.getLocalPlayer():clearAttachedEffects()
end

local function onAttach(effect, owner)
  local category, thingId = AttachedEffectManager.getDataThing(owner)
  local config = AttachedEffectManager.getConfig(effect:getId(), category, thingId)

  if config.isThingConfig then
    AttachedEffectManager.executeThingConfig(effect, category, thingId)
  end

  if config.onAttach then
    config.onAttach(effect, owner, config.__onAttach)
  end
end

local function onDetach(effect, oldOwner)
  local category, thingId = AttachedEffectManager.getDataThing(oldOwner)
  local config = AttachedEffectManager.getConfig(effect:getId(), category, thingId)

  if config.onDetach then
    config.onDetach(effect, oldOwner, config.__onDetach)
  end
end

local function onOutfitChange(creature, outfit, oldOutfit)
  for _i, effect in pairs(creature:getAttachedEffects()) do
    AttachedEffectManager.executeThingConfig(effect, ThingCategoryCreature, outfit.type)
  end
end

function init()
  connect(LocalPlayer, {
    onOutfitChange = onOutfitChange
  })

  connect(Creature, {
    onOutfitChange = onOutfitChange
  })

  connect(AttachedEffect, {
    onAttach = onAttach,
    onDetach = onDetach
  })

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })

  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  if g_game.isOnline() then
    onGameEnd()
  end

  disconnect(LocalPlayer, {
    onOutfitChange = onOutfitChange
  })

  disconnect(Creature, {
    onOutfitChange = onOutfitChange
  })

  disconnect(AttachedEffect, {
    onAttach = onAttach,
    onDetach = onDetach
  })

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })

  g_attachedEffects.clear()
end
