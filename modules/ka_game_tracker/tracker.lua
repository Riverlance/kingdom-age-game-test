g_locales.loadLocales(resolvepath(''))

_G.GameTracker = { }



TrackingInfo = {
  Id       = 1,
  Name     = 2,
  Position = 3,
  Outfit   = 4,
  Color    = 5,
  Auto     = 250,
  Tracking = 251,
  Paused   = 252,
  Start    = 253,
  Stop     = 254,
  MsgEnd   = 255,
}

trackList = { }



function GameTracker.init()
  GameTracker.m = modules.ka_game_tracker -- Alias

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeTracking, GameTracker.parseTrack)

  connect(g_game, {
    onGameEnd = GameTracker.onGameEnd,
    onClickStartTrackPosition = GameTracker.startTrackPosition
  })

  connect(LocalPlayer, { onPositionChange = GameTracker.onLocalPlayerPositionChange })
end

function GameTracker.terminate()
  GameTracker.onGameEnd()

  disconnect(LocalPlayer, { onPositionChange = GameTracker.onLocalPlayerPositionChange })

  disconnect(g_game, {
    onGameEnd = GameTracker.onGameEnd,
    onClickStartTrackPosition = GameTracker.startTrackPosition
  })

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeTracking)

  _G.GameTracker = nil
end

function GameTracker.getTrackList()
  return trackList
end



--[[ Client Events ]]

function GameTracker.onGameEnd()
  for _, trackNode in pairs(trackList) do
    GameTracker.onTrackEnd(trackNode)
  end
end

function GameTracker.onLocalPlayerPositionChange()
  for _, trackNode in pairs(trackList) do
    if trackNode.id then
      signalcall(g_game.onTrackCreature, trackNode)
    else
      signalcall(g_game.onTrackPosition, trackNode)
    end
  end
end



--[[ Network ]]

function GameTracker.sendTrack(trackNode)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeTracking)
  msg:addU8(trackNode.status)
  if trackNode.id then
    msg:addU8(TrackingInfo.Id)
    msg:addU32(trackNode.id)
  else
    msg:addU8(TrackingInfo.Position)
    msg:addPosition(trackNode.position)
  end

  protocolGame:send(msg)
end

function GameTracker.parseTrack(protocol, msg)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local trackNode = { }
  trackNode.status = msg:getU8()

  while true do
    local flag = msg:getU8()
    if flag == TrackingInfo.Id then
      trackNode.id = msg:getU32()
    elseif flag == TrackingInfo.Name then
      trackNode.name = msg:getString()
    elseif flag == TrackingInfo.Position then
      trackNode.position = msg:getPosition()
    elseif flag == TrackingInfo.Outfit then
      trackNode.outfit = protocolGame:getOutfit(msg)
    elseif flag == TrackingInfo.Color then
      trackNode.color = msg:getColor()
    elseif flag == TrackingInfo.Auto then
      trackNode.auto = true
    elseif flag == TrackingInfo.MsgEnd then
      break
    else
      print_traceback(f('[GameTracker.parseTrack] Error with flag %d', flag))
      break
    end
  end

  GameTracker.onTrack(trackNode)

  return true
end



--[[ Track Events ]]

function GameTracker.onTrack(trackNode)
  local trackIndex
  if trackNode.id then -- creature
    trackIndex = trackNode.id
  else -- position
    trackIndex = postostring(trackNode.position)
  end

  if not trackList[trackIndex] then
    trackList[trackIndex] = { }
  end

  local trackView    = trackList[trackIndex]
  trackView.status   = trackNode.status
  trackView.id       = trackNode.id
  trackView.name     = trackNode.name
  trackView.position = trackNode.position
  trackView.outfit   = trackNode.outfit
  trackView.color    = trackNode.color or trackView.color or '#ffc659'
  trackView.auto     = trackNode.auto

  if trackNode.status == TrackingInfo.Stop then
    GameTracker.onTrackEnd(trackNode)
    return
  end

  if trackView.id then
    signalcall(g_game.onTrackCreature, trackView)
  else
    signalcall(g_game.onTrackPosition, trackView)
  end
end

function GameTracker.onTrackEnd(trackNode)
  if trackNode.id then
    signalcall(g_game.onTrackCreatureEnd, trackList[trackNode.id])
    trackList[trackNode.id] = nil
  else
    signalcall(g_game.onTrackPositionEnd, trackList[postostring(trackNode.position)])
    trackList[postostring(trackNode.position)] = nil
  end
end



--[[ Track Creatures ]]

function Creature:getTrackInfo()
  return trackList[self:getId()]
end

function GameTracker.isTracked(creature)
  return trackList[creature:getId()] and true or false
end

function GameTracker.startTrackCreature(creature)
  GameTracker.sendTrack({ status = TrackingInfo.Start, id = creature:getId() })
end

function GameTracker.stopTrackCreature(creature)
  GameTracker.sendTrack({ status = TrackingInfo.Stop, id = creature:getId() })
end

function GameTracker.toggleTracking(creature)
  if not GameTracker.isTracked(creature) then
    GameTracker.startTrackCreature(creature)
  else
    GameTracker.stopTrackCreature(creature)
  end
end



--[[ Track Position ]]

function GameTracker.getTrackedPosition(position)
  return trackList[postostring(position)]
end

function GameTracker.startTrackPosition(position)
  local trackNode = GameTracker.getTrackedPosition(position)
  if trackNode then
    trackNode.auto = false
    GameTracker.sendTrack(trackNode)
  else
    GameTracker.sendTrack({ status = TrackingInfo.Start, position = position })
  end
end

function GameTracker.stopTrackPosition(position)
  local trackNode = GameTracker.getTrackedPosition(position)
  if trackNode then
    if trackNode.auto then
      trackNode.status = TrackingInfo.Stop
      GameTracker.sendTrack(trackNode)
    else
      GameTracker.onTrackEnd(trackNode)
    end
  end
end



--[[ Track Window ]]

function GameTracker.createEditTrackWindow(trackNode)
  local trackerWindow = g_ui.displayUI('tracker')

  local red = trackerWindow:getChildById('red')
  local green = trackerWindow:getChildById('green')
  local blue = trackerWindow:getChildById('blue')

  local activeColor = tocolor(trackNode.color)
  red:setValue(activeColor.r)
  green:setValue(activeColor.g)
  blue:setValue(activeColor.b)

  local updateColor = function()
    local display = trackerWindow:getChildById('colorDisplay')
    display:setBackgroundColor({r = red:getValue(), g = green:getValue(), b = blue:getValue(), a = 255})
  end

  updateColor()

  local changeFunc = function()
    trackNode.color = colortostring({r = red:getValue(), g = green:getValue(), b = blue:getValue(), a = 255})
    signalcall(g_game.onUpdateTrackColor, trackNode)
    trackerWindow:destroy()
  end

  local cancelFunc = function()
    trackerWindow:destroy()
  end

  trackerWindow.onEnter = changeFunc
  trackerWindow.onEscape = cancelFunc

  local okButton = trackerWindow:getChildById('okButton')
  local cancelButton = trackerWindow:getChildById('cancelButton')

  okButton.onClick = changeFunc
  cancelButton.onClick = cancelFunc

  red.onValueChange = updateColor
  green.onValueChange = updateColor
  blue.onValueChange = updateColor
end

function GameTracker.createTrackByPosWindow(mapPos)
  local trackerWindow = g_ui.displayUI('trackerbypos')

  local xTextEdit = trackerWindow.posX
  local yTextEdit = trackerWindow.posY
  local zTextEdit = trackerWindow.posZ

  local function onPositionTextChange(self)
    local text   = self:getText()
    local number = tonumber(text) or 0
    if text:match('[^0-9]+') or number > 65535 or text:match('^[0]+[1-9]*') then -- Pattern: Cannot have non numbers (Correct: '7', '777' | Wrong: 'A7', '-7')
      return self:setText(0)
    end
  end

  local function trackCallback()
    local x = tonumber(xTextEdit:getText()) or 0
    local y = tonumber(yTextEdit:getText()) or 0
    local z = tonumber(zTextEdit:getText()) or 0
    if x ~= 0 and y ~= 0 then
      local toPos = { x = x, y = y, z = z }
      signalcall(g_game.onClickStartTrackPosition, toPos)
      trackerWindow:destroy()
    end
  end

  local function cancelCallback()
    trackerWindow:destroy()
  end

  xTextEdit:setText(tostring(mapPos.x))
  xTextEdit.onTextChange = onPositionTextChange

  yTextEdit:setText(tostring(mapPos.y))
  yTextEdit.onTextChange = onPositionTextChange

  zTextEdit:setText(tostring(mapPos.z))
  zTextEdit.onTextChange = onPositionTextChange

  trackerWindow.onEnter  = trackCallback
  trackerWindow.onEscape = cancelCallback

  trackerWindow.okButton.onClick = trackCallback
  trackerWindow.cancelButton.onClick = cancelCallback
end
