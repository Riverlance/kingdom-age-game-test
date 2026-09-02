local regionLabels = {
  { pos = { x = 3400, y = 2670, z = 7 }, text = loc'${GamelibInfoRegionRookieIsland}' },
  { pos = { x = 2743, y = 2721, z = 7 }, text = loc'${GamelibInfoRegionCityErembor}' },
  { pos = { x = 3017, y = 2619, z = 7 }, text = loc'${GamelibInfoRegionCityElensar}' },
  { pos = { x = 3224, y = 2687, z = 7 }, text = loc'${GamelibInfoRegionCityNova}' },
  { pos = { x = 2983, y = 2543, z = 7 }, text = loc'${GamelibInfoRegionCityNalta}' },
  { pos = { x = 3292, y = 2997, z = 7 }, text = loc'${GamelibInfoRegionCityDronMa}' },
  { pos = { x = 2655, y = 2597, z = 7 }, text = loc'${GamelibInfoRegionAmazoniaHideout}' },
  { pos = { x = 2710, y = 2580, z = 7 }, text = loc'${GamelibInfoRegionVengeanceVillage}' },
  { pos = { x = 2885, y = 2635, z = 7 }, text = loc'${GamelibInfoRegionMountFarber}' },
  { pos = { x = 2855, y = 2700, z = 7 }, text = loc'${GamelibInfoRegionEraninWoods}' },
  { pos = { x = 2740, y = 2795, z = 7 }, text = loc'${GamelibInfoRegionTrollShaws}' },
  { pos = { x = 2625, y = 2805, z = 7 }, text = loc'${GamelibInfoRegionDeathClawMountain}' },
  { pos = { x = 3155, y = 2595, z = 7 }, text = loc'${GamelibInfoRegionKrogHar}' },
  { pos = { x = 3133, y = 2713, z = 7 }, text = loc'${GamelibInfoRegionSandHills}' },
  { pos = { x = 2965, y = 2790, z = 7 }, text = loc'${GamelibInfoRegionMountChrist}' },
  { pos = { x = 3165, y = 2790, z = 7 }, text = loc'${GamelibInfoRegionMavigicValley}' },
  { pos = { x = 3140, y = 2855, z = 7 }, text = loc'${GamelibInfoRegionMavigicForest}' },
  { pos = { x = 3232, y = 2853, z = 7 }, text = loc'${GamelibInfoRegionMavigicCitadel}' },
  { pos = { x = 2992, y = 2867, z = 7 }, text = loc'${GamelibInfoRegionAnvhiansMines}' },
  { pos = { x = 2830, y = 2865, z = 7 }, text = loc'${GamelibInfoRegionHolkaganDesert}' },
  { pos = { x = 3077, y = 2920, z = 7 }, text = loc'${GamelibInfoRegionCyclopsTunnel}' },
  { pos = { x = 3100, y = 2990, z = 7 }, text = loc'${GamelibInfoRegionElvenCamp}' },
  { pos = { x = 3280, y = 2882, z = 7 }, text = loc'${GamelibInfoRegionLollaardCave}' },
  { pos = { x = 3000, y = 3052, z = 7 }, text = loc'${GamelibInfoRegionTempleAcegordsPlains}' },
  { pos = { x = 3000, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionAcegordsPlains}' },
  { pos = { x = 3105, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionDragonLair}' },
  { pos = { x = 3180, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionVampireMansion}' },
  { pos = { x = 2875, y = 2975, z = 7 }, text = loc'${GamelibInfoRegionRakkarHills}' },
  { pos = { x = 2733, y = 3028, z = 7 }, text = loc'${GamelibInfoRegionGreenest}' },
  { pos = { x = 2690, y = 3080, z = 7 }, text = loc'${GamelibInfoRegionLusorSwamp}' },
  { pos = { x = 2495, y = 3120, z = 7 }, text = loc'${GamelibInfoRegionThartov}' },
  { pos = { x = 2865, y = 3135, z = 7 }, text = loc'${GamelibInfoRegionOutlawVillage}' },
  { pos = { x = 2790, y = 3240, z = 7 }, text = loc'${GamelibInfoRegionWealthIsland}' },
  { pos = { x = 2945, y = 3430, z = 7 }, text = loc'${GamelibInfoRegionRoshamuul}' },
}

local function bindCopyPositionOption(menu, pos)
  menu:addOption(loc'${GamelibInfoOptionCopyPosition}', function() g_window.setClipboardText(f(loc'${GamelibInfoPosition}', pos.x, pos.y, pos.z)) end)
end

function UIMinimap:onCreate()
  self.autowalk = true
end

function UIMinimap:onSetup()
  self.addFlagWindow = nil
  self.editFlagWindow = nil
  self.floorUpWidget = self:getChildById('floorUp')
  self.floorDownWidget = self:getChildById('floorDown')
  self.zoomInWidget = self:getChildById('zoomIn')
  self.zoomOutWidget = self:getChildById('zoomOut')
  self.flags = { }
  self.fullMapView = false
  self.zoomMinimap = 0
  self.zoomFullmap = 0
  self.alternatives = { }
  self.alternativesVisible = true
  self.onAddAutomapFlag = function(pos, icon, description, force, temporary)
    self:addFlag(pos, icon, description, force, temporary)
  end
  self.onRemoveAutomapFlag = function(pos)
    self:removeFlag(pos)
  end
  self.onGameEnd = function()
    for k = #self.flags, 1, -1 do
      local flag = self.flags[k]
      if flag.temporary then
        flag:destroy() -- Removed from list with onDestroy
      end
    end

    for _, widget in pairs(self.alternatives) do
      if widget.temporary then
        widget:destroy() -- Removed from list with onDestroy
      end
    end
  end

  connect(g_game, {
    onAddAutomapFlag    = self.onAddAutomapFlag,
    onRemoveAutomapFlag = self.onRemoveAutomapFlag,
    onGameEnd           = self.onGameEnd,
  })

  -- Add title labels
  for _, regionLabel in ipairs(regionLabels) do
    local regionLabelWidget         = g_ui.createWidget('MinimapRegionLabel')
    regionLabelWidget.alternativeId = #self.alternatives + 1 -- ignoring creature minimap widgets
    regionLabelWidget.pos           = regionLabel.pos
    regionLabelWidget:setText(regionLabel.text)

    self:addAlternativeWidget(regionLabelWidget)
    self:centerInPosition(regionLabelWidget, regionLabelWidget.pos)
  end
end

function UIMinimap:onDestroy()
  for _, widget in pairs(self.alternatives) do
    widget:destroy()
  end

  self.alternatives = { }

  disconnect(g_game, {
    onAddAutomapFlag    = self.onAddAutomapFlag,
    onRemoveAutomapFlag = self.onRemoveAutomapFlag,
    onGameEnd           = self.onGameEnd,
  })

  self:destroyAddFlagWindow()
  self:destroyEditFlagWindow()
  self.flags = { }
end

function UIMinimap:save()
  local settings = { flags = { } }

  for _, flag in pairs(self.flags) do
    if not flag.temporary then
      table.insert(settings.flags, {
        position = flag.pos,
        icon = flag.icon,
        description = flag.description,
      })
    end
  end

  settings.zoom     = self.zoomMinimap
  settings.zoomFull = self.zoomFullmap

  g_settings.setNode('Minimap', settings)
end

function UIMinimap:load()
  local settings = g_settings.getNode('Minimap')
  if settings then
    if settings.flags then
      for _, flag in pairs(settings.flags) do
        self:addFlag(flag.position, flag.icon, flag.description)
      end
    end

    self.zoomMinimap = settings.zoom
    self.zoomFullmap = settings.zoomFull or settings.zoom

    self:setZoom(self.zoomMinimap)
  end
end

function UIMinimap:move(x, y)
  if self.isTransposedView and self:isTransposedView() then
    x, y = y, x
  end

  local cameraPos = self:getCameraPosition()
  local scale     = self:getScale()
  if scale > 1 then
    scale = 1
  end

  local dx = x / scale
  local dy = y / scale
  local pos = { x = cameraPos.x - dx, y = cameraPos.y - dy, z = cameraPos.z }
  self:setCameraPosition(pos)
end

function UIMinimap:refreshAlternativesPosition()
  for _, widget in pairs(self.alternatives) do
    if widget.pos then
      self:centerInPosition(widget, widget.pos)
    end
  end
end

function UIMinimap:reset()
  local player = g_game.getLocalPlayer()
  if player then
    self:setCameraPosition(player:getPosition())
  end
end

function UIMinimap:hideFloor()
  self.floorUpWidget:hide()
  self.floorDownWidget:hide()
end

function UIMinimap:hideZoom()
  self.zoomInWidget:hide()
  self.zoomOutWidget:hide()
end

function UIMinimap:setCrossPosition(pos)
  local cross = self.cross
  if not self.cross then
    cross = g_ui.createWidget('MinimapCross', self)
    cross:setIcon('/images/ui/minimap/cross')
    self.cross = cross
  end

  pos.z = self:getCameraPosition().z
  cross.pos = pos
  if pos then
    self:centerInPosition(cross, pos)
  else
    cross:breakAnchors()
  end
end

function UIMinimap:disableAutoWalk()
  self.autowalk = false
end



function UIMinimap:getFlag(mapPos)
  for _, flag in pairs(self.flags) do
    if flag.pos.x == mapPos.x and flag.pos.y == mapPos.y and flag.pos.z == mapPos.z then
      return flag
    end
  end
  return nil
end

function UIMinimap:addFlag(mapPos, icon, description, force, temporary)
  if not mapPos or not icon then
    return
  end

  local flag = self:getFlag(mapPos)
  if force then
    if flag then
      self:removeFlag(mapPos)
    end
  else
    if flag then
      return
    end
  end

  temporary = temporary or false

  flag = g_ui.createWidget('MinimapFlag')
  self:insertChild(1, flag)
  flag.pos = mapPos
  flag.description = description
  flag.icon = icon
  flag.temporary = temporary
  if type(tonumber(icon)) == 'number' then
    flag:setIcon('/images/ui/minimap/flag' .. icon)
  else
    flag:setIcon(resolvepath(icon, 1))
  end
  flag:setIconClip({ width = 11, height = 11 })
  flag:setTooltip(description)

  flag.onMouseRelease = function(widget, _pos, button)
    if button == MouseLeftButton then
      local player = g_game.getLocalPlayer()
      if player then
        if Position.distance(player:getPosition(), widget.pos) > 250 then
          GameTextMessage.displayStatusMessage(loc'${GamelibInfoDestinationOutRange}')
          return false
        end

        if widget:getParent().autowalk then
          player:autoWalk(widget.pos)
        end
        return true
      end

    elseif button == MouseRightButton then
      local menu = g_ui.createWidget('PopupMenu')
      menu:setGameMenu(true)
      menu:addOption(loc'${GamelibInfoOptionEditMark}', function() self:createEditFlagWindow(mapPos) end)
      menu:addOption(loc'${GamelibInfoOptionRemoveMark}', function() widget:destroy() end)
      menu:addSeparator()
      bindCopyPositionOption(menu, mapPos)
      menu:display(_pos)

      return true
    end

    return false
  end

  flag.onDestroy = function()
    table.removevalue(self.flags, flag)
  end

  table.insert(self.flags, flag)
  self:centerInPosition(flag, mapPos)
end

function UIMinimap:removeFlag(mapPos)
  local flag = self:getFlag(mapPos)
  if flag then
    flag:destroy()
  end
end



-- Attach data in widget before use this function: pos, alternativeId, temporary, description, minZoom, maxZoom
function UIMinimap:addAlternativeWidget(widget)
  local hasAlternativeWidget = table.contains(self.alternatives, widget)
  local hasChild             = self:hasChild(widget)

  if hasAlternativeWidget and hasChild then
    return

  else
    -- Ensure it is removed from both lists
    if hasAlternativeWidget then
      table.removevalue(self.alternatives, widget)
    end
    if hasChild then
      self:removeChild(widget)
    end
  end

  if self.alternativesVisible then
    self:insertChild(1, widget)
  end

  if widget.description then
    if widget:getStyleName() ~= 'CreatureButtonMinimapWidget' then -- CreatureButtonMinimapWidget updates its tooltip within UICreatureButton
      widget:setTooltip(widget.description)
    end
  end

  connect(widget, {
    onDestroy = function() table.removevalue(self.alternatives, widget, nil, true) end
  })

  self.alternatives[widget.alternativeId or tostring(widget:getId())] = widget
  self:centerInPosition(widget, widget.pos)
end

function UIMinimap:setAlternativeWidgetsVisible(show)
  local layout = self:getLayout()
  layout:disableUpdates()

  self.alternativesVisible = show

  for _, widget in pairs(self.alternatives) do
    if show then
      if not self:hasChild(widget) then
        self:insertChild(1, widget)
        self:centerInPosition(widget, widget.pos)
      end

    else
      if self:hasChild(widget) then
        self:removeChild(widget)
      end
    end
  end

  layout:enableUpdates()
  layout:update()
end



function UIMinimap:createAddFlagWindow(mapPos)
  if self.addFlagWindow or not mapPos then
    return
  end

  self.addFlagWindow = g_ui.createWidget('MinimapAddFlagWindow', rootWidget)

  local positionLabel = self.addFlagWindow:getChildById('position')
  local description   = self.addFlagWindow:getChildById('description')
  local okButton      = self.addFlagWindow:getChildById('okButton')
  local cancelButton  = self.addFlagWindow:getChildById('cancelButton')

  local flagRadioGroup = UIRadioGroup.create()

  for i = 0, 19 do
    local checkbox = self.addFlagWindow:getChildById('flag' .. i)
    checkbox.icon = i
    flagRadioGroup:addWidget(checkbox)
  end

  positionLabel:setText(f('%i, %i, %i', mapPos.x, mapPos.y, mapPos.z))
  flagRadioGroup:selectWidget(flagRadioGroup:getFirstWidget())

  local successFunc = function()
    self:addFlag(mapPos, flagRadioGroup:getSelectedWidget().icon, description:getText())
    self:destroyAddFlagWindow()
  end

  local cancelFunc = function()
    self:destroyAddFlagWindow()
  end

  okButton.onClick     = successFunc
  cancelButton.onClick = cancelFunc

  self.addFlagWindow.onEnter   = successFunc
  self.addFlagWindow.onEscape  = cancelFunc
  self.addFlagWindow.onDestroy = function() flagRadioGroup:destroy() end
end

function UIMinimap:destroyAddFlagWindow()
  if self.addFlagWindow then
    self.addFlagWindow:destroy()
    self.addFlagWindow = nil
  end
end

function UIMinimap:createEditFlagWindow(mapPos)
  if self.editFlagWindow or not mapPos then
    return
  end

  local flag = self:getFlag(mapPos)
  if not flag then
    return
  end

  self.editFlagWindow = g_ui.createWidget('MinimapEditFlagWindow', rootWidget)

  local positionLabel = self.editFlagWindow:getChildById('position')
  local description   = self.editFlagWindow:getChildById('description')
  local okButton      = self.editFlagWindow:getChildById('okButton')
  local cancelButton  = self.editFlagWindow:getChildById('cancelButton')

  local flagRadioGroup = UIRadioGroup.create()

  for i = 0, 19 do
    local checkbox = self.editFlagWindow:getChildById('flag' .. i)
    checkbox.icon = i
    flagRadioGroup:addWidget(checkbox)
  end

  positionLabel:setText(f('%i, %i, %i', mapPos.x, mapPos.y, mapPos.z))
  description:setText(flag.description)
  flagRadioGroup:selectWidget(flagRadioGroup.widgets[flag.icon + 1])

  local successFunc = function()
    self:addFlag(mapPos, flagRadioGroup:getSelectedWidget().icon, description:getText(), true)
    self:destroyEditFlagWindow()
  end

  local cancelFunc = function()
    self:destroyEditFlagWindow()
  end

  okButton.onClick     = successFunc
  cancelButton.onClick = cancelFunc

  self.editFlagWindow.onEnter   = successFunc
  self.editFlagWindow.onEscape  = cancelFunc
  self.editFlagWindow.onDestroy = function() flagRadioGroup:destroy() end
end

function UIMinimap:destroyEditFlagWindow()
  if self.editFlagWindow then
    self.editFlagWindow:destroy()
    self.editFlagWindow = nil
  end
end



function UIMinimap:onVisibilityChange()
  if not self:isVisible() then
    self:destroyAddFlagWindow()
    self:destroyEditFlagWindow()
  end
end

function UIMinimap:onCameraPositionChange(cameraPos)
  if self.cross then
    self:setCrossPosition(self.cross.pos)
  end

  self:refreshAlternativesPosition()
end

function UIMinimap:onZoomChange(zoom) -- zoom is from maxZoom -5 (far) to minZoom 5 (near)
  if self.fullMapView then
    self.zoomFullmap = zoom
  else
    self.zoomMinimap = zoom
  end

  for _,widget in pairs(self.alternatives) do
    if (not widget.minZoom or widget.minZoom >= zoom) and (widget.maxZoom or 0) <= zoom then
      widget:show()
    else
      widget:hide()
    end
  end

  self:refreshAlternativesPosition()
end

function UIMinimap:onMouseWheel(mousePos, direction)
  local keyboardModifiers = g_keyboard.getModifiers()
  if direction == MouseWheelUp and keyboardModifiers == KeyboardNoModifier then
    self:zoomIn()
  elseif direction == MouseWheelDown and keyboardModifiers == KeyboardNoModifier then
    self:zoomOut()
  elseif direction == MouseWheelDown and keyboardModifiers == KeyboardCtrlModifier then
    self:floorUp(1)
  elseif direction == MouseWheelUp and keyboardModifiers == KeyboardCtrlModifier then
    self:floorDown(1)
  end
end

function UIMinimap:onMousePress(pos, button)
  if not self:isDragging() then
    self.allowNextRelease = true
  end
end

function UIMinimap:onMouseRelease(pos, button)
  if not self.allowNextRelease then
    return true
  end

  self.allowNextRelease = false

  local mapPos = self:getTilePosition(pos)
  if not mapPos then
    return false
  end

  if button == MouseLeftButton then
    local player = g_game.getLocalPlayer()
    if Position.distance(player:getPosition(), mapPos) > 250 then
    	GameTextMessage.displayStatusMessage(loc'${GamelibInfoDestinationOutRange}')
    	return false
    end

    if self.autowalk then
      player:autoWalk(mapPos)
    end
    return true
  elseif button == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(loc'${GamelibInfoOptionAddNewMark}', function() self:createAddFlagWindow(mapPos) end)
    if GameTracker then
      menu:addOption(loc'${GamelibInfoOptionTrackPos}', function() signalcall(g_game.onClickStartTrackPosition, mapPos) end)
      menu:addOption(loc'${GamelibInfoOptionTrackCustomPos}', function() GameTracker.createTrackByPosWindow(mapPos) end)
    end
    menu:addSeparator()
    bindCopyPositionOption(menu, mapPos)
    menu:display(pos)
    return true
  end
  return false
end

function UIMinimap:onDragEnter(pos)
  self.dragReference = pos
  self.dragCameraReference = self:getCameraPosition()
  return true
end

function UIMinimap:onDragMove(pos, moved)
  local scale = self:getScale()
  local dx = (self.dragReference.x - pos.x) / scale
  local dy = (self.dragReference.y - pos.y) / scale

  if self.isTransposedView and self:isTransposedView() then
    dx, dy = dy, dx
  end

  local pos = { x = self.dragCameraReference.x + dx, y = self.dragCameraReference.y + dy, z = self.dragCameraReference.z }
  self:setCameraPosition(pos)
  return true
end

function UIMinimap:onDragLeave(widget, pos)
  return true
end

function UIMinimap:onStyleApply(styleName, styleNode)
  for name, value in pairs(styleNode) do
    if name == 'autowalk' then
      self.autowalk = value
    end
  end
end
