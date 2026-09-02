g_locales.loadLocales(resolvepath(''))

_G.ClientTopMenu = { }



local topMenu
local leftButtonsPanel
local rightButtonsPanel
local leftGameButtonsPanel
local rightGameButtonsPanel

local lastSyncValue = -1
local fpsEvent = nil
local fpsMin = -1;
local fpsMax = -1;



local function addButton(id, description, icon, callback, panel, toggle, front)
  local class
  if toggle then
    class = 'TopToggleButton'
  else
    class = 'TopButton'
  end

  local button = panel:getChildById(id)

  if not button then
    button = g_ui.createWidget(class)
    if front then
      panel:insertChild(1, button)
    else
      panel:addChild(button)
    end
  end

  button:setId(id)
  if type(description) == 'table' then --workaround
    button.loct = description.loct
    button.locpar = description.locpar
    button:updateLocale(button.locpar)
  else
    button:setTooltip(description)
  end
  button:setIcon(resolvepath(icon, 3))

  function button:onMouseRelease(pos, button)
    if self:containsPoint(pos) and button ~= MouseMidButton then
      callback()
      g_sounds.getChannel(AudioChannels.Gui):play(f('%s/button_2.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
      return true
    end
  end

  return button
end



function ClientTopMenu.init()
  -- Alias
  ClientTopMenu.m = modules.client_topmenu

  connect(g_game, {
    onGameStart = ClientTopMenu.online,
    onGameEnd   = ClientTopMenu.offline,
    onPingBack  = ClientTopMenu.updatePing
  })
  connect(g_app, {
    onFps = ClientTopMenu.updateFps
  })

  topMenu = g_ui.displayUI('topmenu')

  leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
  rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
  leftGameButtonsPanel = topMenu:getChildById('leftGameButtonsPanel')
  rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')
  pingLabel = topMenu:getChildById('pingLabel')
  fpsLabel = topMenu:getChildById('fpsLabel')

  if g_game.isOnline() then
    ClientTopMenu.online()
  end
end

function ClientTopMenu.terminate()
  disconnect(g_app, {
    onFps = ClientTopMenu.updateFps
  })
  disconnect(g_game, {
    onGameStart = ClientTopMenu.online,
    onGameEnd   = ClientTopMenu.offline,
    onPingBack  = ClientTopMenu.updatePing
  })

  topMenu:destroy()
  topMenu = nil
  leftButtonsPanel = nil
  rightButtonsPanel = nil
  leftGameButtonsPanel = nil
  rightGameButtonsPanel = nil
  pingLabel = nil
  fpsLabel = nil

  _G.ClientTopMenu = nil
end



function ClientTopMenu.online()
  ClientTopMenu.showGameButtons()

  addEvent(withWeakWidget(pingLabel, function(widget)
    if ClientOptions.getOption('showPing') and g_game.getFeature(GameClientPing) then
      widget:show()
    else
      widget:hide()
    end
  end))
end

function ClientTopMenu.offline()
  ClientTopMenu.hideGameButtons()
  pingLabel:hide()
  fpsMin = -1
end

function ClientTopMenu.updateFps(fps)
  if not fpsLabel:isVisible() then
    return
  end

  text = f(loc'${ClientTopMenuFps}: %s', fps)

  if g_game.isOnline() then
    local vsync = ClientOptions.getOption('vsync')
    if fpsEvent == nil and lastSyncValue ~= vsync then
      fpsEvent = scheduleEvent(function()
        fpsMin = -1
        lastSyncValue = vsync
        fpsEvent = nil
      end, 2000)
    end

    if fpsMin == -1 then
      fpsMin = fps
      fpsMax = fps
    end

    if fps > fpsMax then
      fpsMax = fps
    end

    if fps < fpsMin then
      fpsMin = fps
    end

    local midFps = math.floor((fpsMin + fpsMax) / 2)
    fpsLabel:setTooltip(f(loc'${ClientTopMenuFpsTooltip}', fpsMin, midFps, fpsMax))
  else
    fpsLabel:removeTooltip()
  end

  fpsLabel:setText(text)
end

function ClientTopMenu.updatePing(ping) -- See UICreatureButton:updatePing
  if not pingLabel:isVisible() then
    return
  end

  local text
  local color

  -- Unknown
  if ping < 0 then
    text  = loc'${ClientTopMenuFpsInfoPing}: ?'
    color = 'yellow'

  -- Known
  else
    text = f(loc'${ClientTopMenuFpsInfoPing}: %d ${CorelibInfoMs}', ping)

    if ping >= 500 then
      color = 'red'

    elseif ping >= 250 then
      color = 'yellow'

    else
      color = 'green'
    end
  end

  pingLabel:setText(text)
  pingLabel:setColor(color)
end

function ClientTopMenu.setPingVisible(enable)
  pingLabel:setVisible(enable)
end

function ClientTopMenu.setFpsVisible(enable)
  fpsLabel:setVisible(enable)
end

function ClientTopMenu.addLeftButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, false, front)
end

function ClientTopMenu.addLeftToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, true, front)
end

function ClientTopMenu.addRightButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, false, front)
end

function ClientTopMenu.addRightToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, true, front)
end

function ClientTopMenu.addLeftGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, false, front)
end

function ClientTopMenu.addLeftGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, true, front)
end

function ClientTopMenu.addRightGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, false, front)
end

function ClientTopMenu.addRightGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, true, front)
end

function ClientTopMenu.showGameButtons()
  leftGameButtonsPanel:show()
  rightGameButtonsPanel:show()
end

function ClientTopMenu.hideGameButtons()
  leftGameButtonsPanel:hide()
  rightGameButtonsPanel:hide()
end

function ClientTopMenu.getButton(id)
  return topMenu:recursiveGetChildById(id)
end

function ClientTopMenu.getTopMenu()
  return topMenu
end
