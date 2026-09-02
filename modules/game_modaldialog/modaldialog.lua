g_locales.loadLocales(resolvepath(''))

_G.GameModalDialog = { }



local debugging = false

local minWidth = 200
local maxWidth = 800

local choiceHeight      = 14
local minVisibleChoices = 1
local maxVisibleChoices = 10

local checkBoxHeight       = 14
local minVisibleCheckBoxes = 1
local maxVisibleCheckBoxes = 10

local fieldHeight      = 22
local minVisibleFields = 1
local maxVisibleFields = 5

local buttonSpacing = 2



-- Class

do
  -- ModalDialog

  do
    ModalDialog = createClass{
      id = 0,

      spectatorUid = 0,

      title   = '',
      message = '',

      width  = 0, -- Optional
      height = 0, -- Optional

      priority = false,

      choices    = { }, -- { [id] = { name = '', tooltip = '', info = '', infoColor = '', selected = false } }
      checkBoxes = { }, -- { [id] = { name = '', tooltip = '', value = false } }
      fields     = { }, -- { [id] = { name = '', tooltip = '', regex = '', minChars = 0, maxChars = 0, hidden = false, value = '' } }
      buttons    = { }, -- { [id] = { name = '', tooltip = '', close = true } }

      enterButton  = true,
      escapeButton = true,



      -- Virtual
      widget     = nil,
      playerData = { },



      -- List with all dialogs
      __listById = { },
    }



    -- Base

    do
      function ModalDialog:__onCall(value)
        -- Get object by id
        if type(value) == 'number' then
          return ModalDialog.__listById[value]
        end
      end

      function ModalDialog:__onNew(obj)
        if self.__listById[obj.id] then
          return
        end

        -- Attach to list - List by id
        self.__listById[obj.id] = obj

        -- Show dialog
        obj:show()
      end

      function ModalDialog:destroy() -- modalDialog:destroy() or ModalDialog.destroy()
        if not self then
          ModalDialog.forEach(function(dialog)
            dialog:destroy()
          end)

          ModalDialog.__listById = { }

          return
        end

        -- Hide dialog
        self:hide()

        -- Detach from list - List by id
        ModalDialog.__listById[self.id] = nil
      end

      function ModalDialog.forEach(callback)
        for _, dialog in pairs(ModalDialog.__listById) do
          if callback(dialog) then
            return dialog
          end
        end
      end

      function ModalDialog:getEnterButton()
        if self.enterButton == true then
          return #self.buttons > 0 and #self.buttons or 0
        end
        return self.enterButton
      end

      function ModalDialog:getEscapeButton()
        if self.escapeButton == true then
          return #self.buttons > 0 and 1 or 0
        end
        return self.escapeButton
      end
    end



    -- Get attributes

    do
      function ModalDialog:getFocusedChoice()
        local choiceList = self.widget.choiceList

        local focusedChoice = choiceList:getFocusedChild()
        if not focusedChoice then
          return nil
        end

        return focusedChoice
      end

      function ModalDialog:getCheckBoxValues()
        local values       = { }
        local checkBoxList = self.widget.checkBoxList

        for k, checkBox in ipairs(checkBoxList:getChildren()) do
          values[k] = checkBox:isChecked()
        end

        return values
      end

      function ModalDialog:getFieldsText()
        local texts     = { }
        local fieldList = self.widget.fieldList

        for k, field in ipairs(fieldList:getChildren()) do
          texts[k] = field:getText()
        end

        return texts
      end

      function ModalDialog:getButtonText(buttonId)
        local text = ''

        local buttonList = self.widget.buttonsPanel

        for _, button in ipairs(buttonList:getChildren()) do
          if (button.buttonId or 0) == buttonId then
            text = button.buttonText
            break
          end
        end

        return text
      end

      function ModalDialog:getGoalWidth()
        if self.width > 0 then
          return math.min(math.max(minWidth, self.width), maxWidth)
        end

        local widget            = self.widget
        local choiceList        = widget.choiceList
        local choiceScrollBar   = widget.choiceScrollBar
        local checkBoxList      = widget.checkBoxList
        local checkBoxScrollBar = widget.checkBoxScrollBar
        local buttonsPanel      = widget.buttonsPanel

        local choicesWidth = 0
        for _, choice in ipairs(choiceList:getChildren()) do
          local valueWidth      = choice:getTextSize().width + choice:getTextOffset().x * 2
          local infoButtonWidth = choice.infoButton:isVisible() and choice.infoButton:getWidth() or 0
          local infoLabelWidth  = choice.infoLabel:isVisible() and choice.infoLabel:getTextSize().width + choice.infoLabel:getTextOffset().x * 2 or 0
          choicesWidth = math.max(valueWidth + infoButtonWidth + infoLabelWidth, choicesWidth)
        end

        local checkBoxesWidth = 0
        for _, checkBox in ipairs(checkBoxList:getChildren()) do
          local valueWidth      = checkBox:getTextSize().width + checkBox:getTextOffset().x
          local infoButtonWidth = checkBox.infoButton:isVisible() and checkBox.infoButton:getWidth() or 0
          checkBoxesWidth = math.max(valueWidth + infoButtonWidth, checkBoxesWidth)
        end

        return math.min(math.max(minWidth, math.max(widget:getTextSize().width, choiceList:getPaddingLeft() + choicesWidth + choiceList:getPaddingRight() + choiceScrollBar:getWidth(), checkBoxList:getPaddingLeft() + checkBoxesWidth + checkBoxList:getPaddingRight() + checkBoxScrollBar:getWidth(), buttonsPanel:getWidth()) + 20), maxWidth)
      end

      function ModalDialog:getGoalHeight()
        if self.height > 0 then
          return self.height
        end

        local widget = self.widget

        return widget:getPaddingTop() +
               widget.messageLabel:getHeight() +
               widget.guideLine1:getMarginTop() +
               widget.choiceScrollBar:getHeight() +
               widget.guideLine2:getMarginTop() +
               widget.checkBoxScrollBar:getHeight() +
               widget.guideLine3:getMarginTop() +
               widget.fieldScrollBar:getHeight() +
               10 + widget.bottomSeparator:getHeight() + widget.bottomSeparator:getMarginBottom() +
               widget.buttonsPanel:getHeight() +
               widget:getPaddingBottom()
      end
    end



    -- Set attributes

    do
      function ModalDialog:setMessageLabel(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local messageLabel = self.widget.messageLabel

        messageLabel:setText(self.message)
        messageLabel:setTextWrap(true)
        messageLabel:resizeToText()
        messageLabel:setVisible(string.exists(messageLabel:getText()))

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setChoices(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local widget          = self.widget
        local choices         = self.choices
        local choiceList      = widget.choiceList
        local choiceScrollBar = widget.choiceScrollBar

        for choiceId = 1, #choices do
          local label           = g_ui.createWidget('ModalChoice', choiceList)
          label.choiceId        = choiceId
          label.choiceText      = choices[choiceId].name and choices[choiceId].name or ''
          label.choiceTooltip   = choices[choiceId].tooltip and choices[choiceId].tooltip or ''
          label.choiceInfo      = choices[choiceId].info or ''
          label.choiceInfoColor = choices[choiceId].infoColor or ''

          label:setText(label.choiceText)
          label:setPhantom(false)

          -- Tooltip
          if string.exists(label.choiceTooltip) then
            local text = f("%s%s\n%s", label.choiceText, string.exists(label.choiceInfo) and f(" - %s", label.choiceInfo) or '', label.choiceTooltip)
            label.infoButton:setTooltip(text, TooltipType.textBlock)
            label.infoButton:show()
          else
            label.infoButton:removeTooltip()
            label.infoButton:hide()
          end

          -- Info label
          if string.exists(label.choiceInfo) then
            label.infoLabel:setText(label.choiceInfo)
            label.infoLabel:resizeToText()

            if string.exists(label.choiceInfoColor) then
              label.infoLabel:setColor(label.choiceInfoColor)
            end
          end

          -- Initial value
          if choices[choiceId].selected then
            addEvent(function()
              if self.widget and self.widget.choiceList then
                self.widget.choiceList:focusChild(label)
              end
            end)
          end
        end

        -- Visible
        if #choices > 0 then
          choiceList:setVisible(true)
          choiceList:setFocusable(true)

          local choicesSizeAmount = math.min(math.max(minVisibleChoices, #choices), maxVisibleChoices)
          choiceScrollBar:setHeight(choicesSizeAmount * choiceHeight + choiceList:getPaddingTop() + choiceList:getPaddingBottom())
          choiceScrollBar:setVisible(#choices > maxVisibleChoices)

        -- Hidden
        else
          choiceList:setVisible(false)
          choiceScrollBar:setVisible(false)
          choiceScrollBar:setHeight(0)
        end

        -- Keys
        g_keyboard.bindKeyPress('Up', function(widget)
          if widget.choiceList then
            widget.choiceList:focusPreviousChild(KeyboardFocusReason)
          end
        end, widget)
        g_keyboard.bindKeyPress('Down', function(widget)
          if widget.choiceList then
            widget.choiceList:focusNextChild(KeyboardFocusReason)
          end
        end, widget)

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setCheckBoxes(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local widget            = self.widget
        local checkBoxes        = self.checkBoxes
        local checkBoxList      = widget.checkBoxList
        local checkBoxScrollBar = widget.checkBoxScrollBar

        for checkBoxId = 1, #checkBoxes do
          local checkBox           = g_ui.createWidget('ModalCheckBox', checkBoxList)
          checkBox.checkBoxText    = checkBoxes[checkBoxId].name and checkBoxes[checkBoxId].name or ''
          checkBox.checkBoxTooltip = checkBoxes[checkBoxId].tooltip and checkBoxes[checkBoxId].tooltip or ''

          checkBox:setText(checkBox.checkBoxText)

          -- Tooltip
          if string.exists(checkBox.checkBoxTooltip) then
            local text = f("%s\n%s", checkBox.checkBoxText, checkBox.checkBoxTooltip)
            checkBox.infoButton:setTooltip(text, TooltipType.textBlock)
            checkBox.infoButton:show()
          else
            checkBox.infoButton:removeTooltip()
            checkBox.infoButton:hide()
          end

          -- Initial value
          if checkBoxes[checkBoxId].value then
            addEvent(function() checkBox:setChecked(true) end)
          end
        end

        -- Visible
        if #checkBoxes > 0 then
          checkBoxList:setVisible(true)

          local checkBoxesSizeAmount = math.min(math.max(minVisibleCheckBoxes, #checkBoxes), maxVisibleCheckBoxes)
          checkBoxScrollBar:setHeight(checkBoxesSizeAmount * checkBoxHeight + checkBoxList:getPaddingTop() + checkBoxList:getPaddingBottom())
          checkBoxScrollBar:setVisible(#checkBoxes > maxVisibleCheckBoxes)

        -- Hidden
        else
          checkBoxList:setVisible(false)
          checkBoxScrollBar:setVisible(false)
          checkBoxScrollBar:setHeight(0)
        end

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setFields(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local widget         = self.widget
        local fields         = self.fields
        local fieldList      = widget.fieldList
        local fieldScrollBar = widget.fieldScrollBar

        for fieldId = 1, #fields do
          local field         = g_ui.createWidget('ModalField', fieldList)
          field.fieldId       = fieldId
          field.fieldName     = fields[fieldId].name and fields[fieldId].name or ''
          field.fieldTooltip  = fields[fieldId].tooltip and fields[fieldId].tooltip or ''
          field.fieldRegex    = fields[fieldId].regex or ''
          field.fieldMinChars = fields[fieldId].minChars or 0
          field.fieldMaxChars = fields[fieldId].maxChars or 0
          field.fieldHidden   = fields[fieldId].hidden or false

          field.maxChars = field.fieldMaxChars -- TextField typing
          field.regex    = field.fieldRegex
          field:setTextHidden(field.fieldHidden)
          field:setPlaceholderText(field.fieldName)
          field:setPhantom(true)

          -- Tooltip
          if string.exists(field.fieldTooltip) then
            local min            = field.fieldMinChars
            local max            = field.fieldMaxChars
            local hasMinMaxLimit = min > 0 and max > 0
            local higherAmount   = max > 0 and max or min > 0 and min or 0
            local charsLimitText = (min > 0 or max > 0) and f(loc'\n${GameModalDialogLimitChars}', min > 0 and f("%d%s", min, not hasMinMaxLimit and loc' (${GameModalDialogMin})' or '') or '', hasMinMaxLimit and ' ~ ' or '', max > 0 and f("%d%s", max, not hasMinMaxLimit and loc' (${GameModalDialogMax})' or '') or '') or ''
            local text           = f("%s%s\n%s", field.fieldName, charsLimitText, field.fieldTooltip)
            field.infoButton:setTooltip(text, TooltipType.textBlock)
            field.infoButton:show()
          else
            field.infoButton:removeTooltip()
            field.infoButton:hide()
          end

          -- Initial value
          if string.exists(fields[fieldId].value) then
            local fieldValue = fields[fieldId].value
            addEvent(function() field:setText(fieldValue) end)
          end
        end

        -- Visible
        if #fields > 0 then
          fieldList:setVisible(true)
          fieldList:setFocusable(true)

          local fieldsSizeAmount = math.min(math.max(minVisibleFields, #fields), maxVisibleFields)
          fieldScrollBar:setHeight(fieldsSizeAmount * fieldHeight + fieldList:getPaddingTop() + fieldList:getPaddingBottom())
          fieldScrollBar:setVisible(#fields > maxVisibleFields)

        -- Hidden
        else
          fieldList:setVisible(false)
          fieldScrollBar:setVisible(false)
          fieldScrollBar:setHeight(0)
        end

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end

      function ModalDialog:setButtons(updateLayout) -- (updateLayout = true)
        if updateLayout == nil then
          updateLayout = true
        end

        local dialog       = self
        local widget       = self.widget
        local buttons      = self.buttons
        local buttonsPanel = widget.buttonsPanel

        local buttonsWidth = 0
        for buttonId = 1, #buttons do
          local button         = g_ui.createWidget('ModalButton', buttonsPanel)
          button.buttonId      = buttonId
          button.buttonText    = buttons[buttonId].name and buttons[buttonId].name or ''
          button.buttonTooltip = buttons[buttonId].tooltip and buttons[buttonId].tooltip or ''

          button:setText(button.buttonText)
          button:setMarginLeft(buttonSpacing)

          -- Tooltip
          if string.exists(button.buttonTooltip) then
            button:setTooltip(button.buttonTooltip, TooltipType.textBlock)
          else
            button:removeTooltip()
          end

          buttonsWidth = buttonsWidth + button:getWidth()

          function button:onClick()
            dialog:answer(buttonId)
          end
        end

        -- Visible
        if #buttons > 0 then
          buttonsWidth = buttonsWidth + (#buttons - 1) * buttonSpacing

          buttonsPanel:setWidth(buttonsWidth)
          buttonsPanel:setVisible(true)
          buttonsPanel:setFocusable(false)

        -- Hidden
        else
          buttonsPanel:setVisible(false)
        end

        -- Update layout
        if updateLayout then
          self:updateLayout()
        end
      end
    end



    -- Main

    do
      function ModalDialog:updateLayout()
        local widget       = self.widget
        local messageLabel = widget.messageLabel
        local choiceList   = widget.choiceList
        local checkBoxList = widget.checkBoxList
        local fieldList    = widget.fieldList

        -- Guide lines
        do
          local message    = messageLabel:isVisible()
          local choices    = choiceList:isVisible()
          local checkBoxes = checkBoxList:isVisible()
          local fields     = fieldList:isVisible()

          widget.guideLine1:setVisible(message and choices)
          widget.guideLine2:setVisible((message or choices) and checkBoxes)
          widget.guideLine3:setVisible((message or choices or checkBoxes) and fields)
        end

        -- Update width
        widget:setWidth(self:getGoalWidth())

        -- Fix message size according to window width
        messageLabel:setTextWrap(true)
        messageLabel:resizeToText()

        -- Update height
        widget:setHeight(self:getGoalHeight())

        -- Update focus
        if choiceList:hasChildren() then
          choiceList:focusChild(choiceList:getFirstChild())
        elseif fieldList:hasChildren() then
          local field = fieldList:getFirstChild()
          fieldList:focusChild(field)
          addEvent(function() field:selectAll() end)
        end
      end

      function ModalDialog:answer(buttonId)
        local button = self.buttons[buttonId]
        if button and button.close == false or not g_game.canPerformGameAction() then
          return
        end

        local widget = self.widget

        local choice     = self:getFocusedChoice()
        local choiceId   = choice and choice.choiceId or 0xFF
        local choiceText = choice and choice.choiceText or ''

        -- Is not a cancel button
        if buttonId ~= self:getEscapeButton() then
          local fieldList = widget.fieldList

          for _, field in ipairs(fieldList:getChildren()) do
            local text = field:getText()

            -- Min characters
            if field.fieldMinChars > 0 and #text < field.fieldMinChars then
              displayErrorBox(loc'${CorelibInfoError}', f(loc'${GameModalDialogCharsMinErrorMsg}', field.fieldName, field.fieldMinChars))
              return

            -- Max characters
            elseif field.fieldMaxChars > 0 and #text > field.fieldMaxChars then
              displayErrorBox(loc'${CorelibInfoError}', f(loc'${GameModalDialogCharsMaxErrorMsg}', field.fieldName, field.fieldMaxChars))
              return
            end
          end
        end

        -- Send answer to server
        GameModalDialog.sendAnswer(self.id, self.spectatorUid, buttonId, self:getButtonText(buttonId), choiceId, choiceText, self:getCheckBoxValues(), self:getFieldsText(), self.playerData)

        -- Destroy window
        self:destroy()
      end

      function ModalDialog:show()
        if self.priority then
          local anotherPriorityDialog = ModalDialog.forEach(function(dialog)
            if dialog ~= self and dialog.priority then
              return true
            end
          end)
          if anotherPriorityDialog then
            return false -- Can have only one priority modal dialog opened
          end
        end

        local dialog = self

        -- Create widget
        self.widget  = self.widget or g_ui.createWidget('ModalDialog', rootWidget)
        local widget = self.widget

        -- Lock
        if self.priority then
          widget:lock()
        end

        local choiceList = widget.choiceList

        -- Update content
        widget:setText(self.title)
        self:setMessageLabel(false)
        self:setChoices(false)
        self:setCheckBoxes(false)
        self:setFields(false)
        self:setButtons(false)

        -- Update layout
        self:updateLayout()

        -- Event

        local function confirm()
          dialog:answer(dialog:getEnterButton())
        end

        -- On double click
        function choiceList:onDoubleClick()
          confirm()
        end

        -- On press enter
        function widget:onEnter()
          confirm()
        end

        -- On press escape
        function widget:onEscape()
          dialog:answer(dialog:getEscapeButton())
        end

        return true
      end

      function ModalDialog:hide()
        if not self.widget then
          return false
        end

        -- Unlock
        self.widget:unlock()

        -- Destroy widget
        self.widget:destroy()
        self.widget = nil

        return true
      end
    end
  end
end



-- Module

do
  function GameModalDialog.init()
    -- Alias
    GameModalDialog.m = modules.game_modaldialog

    g_ui.importStyle('modaldialog')

    connect(LocalPlayer, {
      onPositionChange = GameModalDialog.onPositionChange
    })

    connect(g_game, {
      onGameStart = GameModalDialog.onGameStart,
      onGameEnd   = GameModalDialog.onGameEnd,
    })

    ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeModalDialog, GameModalDialog.parse)
  end

  function GameModalDialog.terminate()
    ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeModalDialog)

    disconnect(g_game, {
      onGameStart = GameModalDialog.onGameStart,
      onGameEnd   = GameModalDialog.onGameEnd,
    })

    disconnect(LocalPlayer, {
      onPositionChange = GameModalDialog.onPositionChange
    })

    ModalDialog.destroy() -- Destroy all dialogs

    _G.GameModalDialog = nil
  end
end



-- Event

do
  function GameModalDialog.parse(protocol, msg)
    local action = msg:getU8()

    if action == 1 then
      local id = msg:getU32()

      local dialog = ModalDialog(id)
      if dialog then
        dialog:destroy()
      end

      return

    elseif action ~= 0 then
      return
    end

    local id           = msg:getU32()
    local spectatorUid = msg:getU32()
    local title        = msg:getString()
    local message      = msg:getString()
    local width        = msg:getU16()
    local height       = msg:getU16()
    local priority     = msg:getU8() == 1

    -- Choice
    local choices           = { }
    local choicesSizeAmount = msg:getU8()
    for id = 1, choicesSizeAmount do
      choices[id]           = { }
      choices[id].id        = id
      choices[id].name      = msg:getString()
      choices[id].tooltip   = msg:getString()
      choices[id].info      = msg:getString()
      choices[id].infoColor = msg:getString()
      choices[id].selected  = msg:getU8() == 1
    end

    -- CheckBox
    local checkBoxes           = { }
    local checkBoxesSizeAmount = msg:getU8()
    for id = 1, checkBoxesSizeAmount do
      checkBoxes[id]         = { }
      checkBoxes[id].id      = id
      checkBoxes[id].name    = msg:getString()
      checkBoxes[id].tooltip = msg:getString()
      checkBoxes[id].value   = msg:getU8() == 1
    end

    -- Field
    local fields           = { }
    local fieldsSizeAmount = msg:getU8()
    for id = 1, fieldsSizeAmount do
      fields[id]          = { }
      fields[id].id       = id
      fields[id].name     = msg:getString()
      fields[id].tooltip  = msg:getString()
      fields[id].regex    = msg:getString()
      fields[id].minChars = msg:getU16()
      fields[id].maxChars = msg:getU16()
      fields[id].hidden   = msg:getU8() == 1
      fields[id].value    = msg:getString()
    end

    -- Button
    local buttons           = { }
    local buttonsSizeAmount = msg:getU8()
    for id = 1, buttonsSizeAmount do
      buttons[id]         = { }
      buttons[id].id      = id
      buttons[id].name    = msg:getString()
      buttons[id].tooltip = msg:getString()
      buttons[id].close   = msg:getU8() == 1
    end

    local enterButton  = msg:getU8()
    local escapeButton = msg:getU8()

    local playerData = table.unserialize(msg:getString())

    ModalDialog:new{
      id           = id,
      spectatorUid = spectatorUid,

      title   = title,
      message = message,

      width  = width,
      height = height,

      priority = priority,

      choices    = choices,
      checkBoxes = checkBoxes,
      fields     = fields,
      buttons    = buttons,

      enterButton  = enterButton,
      escapeButton = escapeButton,

      playerData = playerData,
    }
  end

  function GameModalDialog.sendAnswer(id, spectatorUid, buttonId, buttonText, choiceId, choiceText, checkBoxes, fields, playerData)
    local msg = OutputMessage.create()
    msg:addU8(ClientOpcodes.ClientOpcodeAnswerModalDialog)

    msg:addU32(id)
    msg:addU32(spectatorUid)

    -- Button
    msg:addU8(buttonId)
    msg:addString(buttonText)

    -- Choice
    msg:addU8(choiceId)
    msg:addString(choiceText)

    -- CheckBoxes
    msg:addU8(#checkBoxes)
    for id = 1, #checkBoxes do
      msg:addU8(checkBoxes[id] and 1 or 0)
    end

    -- Fields
    msg:addU8(#fields)
    for id = 1, #fields do
      msg:addString(fields[id])
    end

    msg:addString(table.serialize(playerData))

    g_game.getProtocolGame():send(msg)
  end

  function GameModalDialog.onPositionChange(creature, pos, oldPos)
    ModalDialog.destroy() -- Destroy all dialogs
  end

  function GameModalDialog.onGameStart()
    if debugging then
      addEvent(function()
        ModalDialog.destroy() -- Destroy all dialogs
        ModalDialog:new{
          id           = 0,
          spectatorUid = 0,

          title   = 'Lorem ipsum dolor',
          message = 'Lorem ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet ipsum dolor sit amet.',

          width  = 0,
          height = 0,

          priority = false,

          choices = {
            { name = "Choice 1", tooltip = "Tooltip of 'Choice 1'." },
            { name = "Choice 2", info = "Extra info.", selected = true },
            { name = "Choice 3", info = "Additional information.", infoColor = '#e6db74', tooltip = "Tooltip of 'Choice 3'." },
          },

          checkBoxes = {
            { name = "CheckBox 1", tooltip = "Tooltip of 'CheckBox 1'.", value = true },
            { name = "CheckBox 2" },
            { name = "CheckBox 3", value = true },
          },

          fields = {
            { name = "Name", tooltip = "Letters and spaces only.", regex = "^[%a ]+$", minChars = 4, maxChars = 10, value = "Lorem" },
            { name = "Text" },
            { name = "Password", tooltip = "Numbers only.", regex = "^[0-9]+$", maxChars = 20, hidden = true },
          },

          buttons = {
            { name = "Cancel" },
            { name = "Do nothing", close = false },
            { name = "Ok", tooltip = "Tooltip of 'Ok' button." },
          },
        }
      end)
    end
  end

  function GameModalDialog.onGameEnd()
    ModalDialog.destroy() -- Destroy all dialogs
  end
end
