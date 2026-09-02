-- @docclass
UIPowerButton = extends(UIWidget, 'UIPowerButton')

-- See uicreaturebutton.lua

local extraLabelColors = { }
extraLabelColors[0]    = '#888888' -- No boost
extraLabelColors[1]    = '#9E9A32'
extraLabelColors[2]    = '#B770FF'
extraLabelColors[3]    = '#70B8FF'

POWER_CLASS_ALL       = 0
POWER_CLASS_OFFENSIVE = 1
POWER_CLASS_DEFENSIVE = 2
POWER_CLASS_SUPPORT   = 3
POWER_CLASS_SPECIAL   = 4

UIPowerButton.powerClass = {
  [POWER_CLASS_ALL]       = loc'${CorelibInfoAll}',
  [POWER_CLASS_OFFENSIVE] = loc'${GamelibInfoPowerClassOffensive}',
  [POWER_CLASS_DEFENSIVE] = loc'${GamelibInfoPowerClassDefensive}',
  [POWER_CLASS_SUPPORT]   = loc'${GamelibInfoPowerClassSupport}',
  [POWER_CLASS_SPECIAL]   = loc'${GamelibInfoPowerClassSpecial}',
}

--[[
  Power Object:
  - (number)  id
  - (string)  name
  - (string)  class
  - (array)   mana
  - (array)   vocations
  - (number)  level
  - (boolean) constant
  - (boolean) aggressive
  - (boolean) premium
  - (string)  description
  - (string)  descriptionBoostNone
  - (string)  descriptionBoostLow
  - (string)  descriptionBoostHigh
]]
function UIPowerButton.create()
  local button = UIPowerButton.internalCreate()
  button:setFocusable(false)
  button.power = nil
  return button
end

function UIPowerButton:setup(power)
  self:setId(f('PowerButton_id%d', power.id))
  self:updateData(power)
end

function UIPowerButton:onDragEnter(mousePos)
  g_mouse.pushCursor('target')
  g_mouseicon.display(f('/images/ui/power/%d_off', self.power.id))

  g_sounds.getChannel(AudioChannels.Gui):play(f('%s/power_drag.ogg', getAudioChannelPath(AudioChannels.Gui)), 1.)
  return true
end

function UIPowerButton:onDragLeave(droppedWidget, mousePos)
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  return true
end

function UIPowerButton:updateData(power)
  if power then
    self.power = power
  end

  self:setIcon()
  self:setLabel()
  self:setTooltipText()
  self:updateOffensiveIcon()
end

function UIPowerButton:setIcon(id)
  if id then
    local powerWidget = self:getChildById('power')
    powerWidget:setIcon(f('/images/ui/power/%d_off', id))
    powerWidget:setIconSize({ width = 32, height = 32 })
    return
  end

  local power = self.power
  self:setIcon(power.id)
end

function UIPowerButton:setLabel(text)
  local labelWidget = self:getChildById('label')
  if text then
    labelWidget:setText(text)
    return
  end

  local power = self.power
  if power.name then
    labelWidget:setText(power.name)
  end
end

function UIPowerButton:setTooltipText(text)
  if text then
    self:setTooltip(text)
    return
  end

  self.onTooltipHoverChange = self.power.onTooltipHoverChange
  self:setTooltip(true, TooltipType.powerButton)
end

function UIPowerButton:updateOffensiveIcon()
  local offensiveWidget = self:getChildById('offensive')
  local labelWidget     = self:getChildById('label')

  local power = self.power
  offensiveWidget:setImageSource(power.aggressive and '/images/game/creature/power/type_aggressive' or '/images/game/creature/power/type_non_aggressive')
end



function UIPowerButton:getMana()
  local power = self.power
  if not power.mana or power.mana[1] == 0 or power.mana[2] == 0 or power.mana[3] == 0 then
    return loc'${GamelibInfoManaVariable}'
  end

  return table.concat(power.mana, ' / ')
end

function UIPowerButton:getVocations()
  local power = self.power
  if not power.vocations then
    return loc'${GamelibInfoVocationUnknown}'
  end

  if #power.vocations == table.size(VocationStr) then
    return loc'${CorelibInfoAll}'
  end

  local vocations = { }
  for _, vocationId in ipairs(power.vocations) do
    if VocationStr[vocationId] then
      table.insert(vocations, VocationStr[vocationId])
    end
  end
  return table.concat(vocations, ', ')
end
