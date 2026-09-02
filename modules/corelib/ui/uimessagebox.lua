if not UIWindow then
  dofile 'uiwindow'
end

-- @docclass
UIMessageBox = extends(UIWindow, 'UIMessageBox')

-- messagebox cannot be created from otui files
UIMessageBox.create = nil

function UIMessageBox.display(title, message, buttons, onEnterCallback, onEscapeCallback, buttonWidth)
  local messageBox = UIMessageBox.internalCreate()
  rootWidget:addChild(messageBox)

  messageBox:setStyle('MainWindow')
  messageBox:setText(title)

  local messageLabel = g_ui.createWidget('MessageBoxLabel', messageBox)
  messageLabel:setText(message)

  local buttonHolder
  if buttons then
    local buttonsWidth = 0
    local buttonsHeight = 0

    local anchor = AnchorRight
    if buttons.anchor then
      anchor = buttons.anchor
    end

    buttonHolder = g_ui.createWidget('MessageBoxButtonHolder', messageBox)
    buttonHolder:addAnchor(anchor, 'parent', anchor)

    for i=1,#buttons do
      local button = messageBox:addButton(buttons[i].text, buttons[i].callback)
      if i == 1 then
        button:setMarginLeft(0)
        button:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        button:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        buttonsHeight = button:getHeight()
      else
        button:addAnchor(AnchorBottom, 'prev', AnchorBottom)
        button:addAnchor(AnchorLeft, 'prev', AnchorRight)
      end
      if buttonWidth then
        button:setWidth(buttonWidth)
      end

      buttonsWidth = buttonsWidth + button:getWidth() + button:getMarginLeft()
    end

    buttonHolder:setWidth(buttonsWidth)
    buttonHolder:setHeight(buttonsHeight)

    if onEnterCallback then
      connect(messageBox, {
        onEnter = onEnterCallback
      })
    end

    if onEscapeCallback then
      connect(messageBox, {
        onEscape = onEscapeCallback
      })
    end
  end

  messageBox:setWidth(math.max(messageLabel:getWidth(), messageBox:getTextSize().width, (buttonHolder and buttonHolder:getWidth() or 0)) + messageBox:getPaddingLeft() + messageBox:getPaddingRight())
  messageBox:setHeight(messageLabel:getHeight() + messageBox:getPaddingTop() + messageBox:getPaddingBottom() + (buttonHolder and buttonHolder:getHeight() + buttonHolder:getMarginTop() or 0))

  return messageBox
end

function displaySystemBox(title, message)
  return UIMessageBox.display(title, message)
end

function displayInfoBox(title, message)
  local messageBox
  local defaultCallback = function() messageBox:ok() end
  messageBox = UIMessageBox.display(title, message, {{text = loc'${CorelibInfoOk}', callback = defaultCallback}}, defaultCallback, defaultCallback)
  return messageBox
end

function displayErrorBox(title, message)
  local messageBox
  local defaultCallback = function() messageBox:ok() end
  messageBox = UIMessageBox.display(title, message, {{text = loc'${CorelibInfoOk}', callback = defaultCallback}}, defaultCallback, defaultCallback)
  return messageBox
end

function displayCancelBox(title, message)
  local messageBox
  local defaultCallback = function() messageBox:cancel() end
  messageBox = UIMessageBox.display(title, message, {{text = loc'${CorelibInfoCancel}', callback = defaultCallback}}, defaultCallback, defaultCallback)
  return messageBox
end

function displayOkBox(title, message, okCallback)
  local messageBox

  local _okCallback = function()
    messageBox:ok()
    if okCallback then
      okCallback(messageBox)
    end
  end

  messageBox = UIMessageBox.display(title, message, {{text = loc'${CorelibInfoOk}', callback = _okCallback}}, _okCallback, _okCallback)
  return messageBox
end

function displayOkCancelBox(title, message, okCallback, onCancelCallback)
  local messageBox

  local _okCallback = function()
    messageBox:ok()
    if okCallback then
      okCallback(messageBox)
    end
  end

  local _cancelCallback = function()
    messageBox:cancel()
    if onCancelCallback then
      onCancelCallback(messageBox)
    end
  end

  messageBox = UIMessageBox.display(title, message, {{text = loc'${CorelibInfoOk}', callback = _okCallback}, {text = loc'${CorelibInfoCancel}', callback = _cancelCallback}}, _okCallback, _cancelCallback)
  return messageBox
end

-- Use buttons[i].buttonCallback and onCancelCallback for the button's callbacks
-- buttonIndexOnEnterCallback is the array position of the chosen button for be the one that will be executed also by the onEnterCallback
function displayCustomBox(title, message, buttons, buttonIndexOnEnterCallback, cancelText, onCancelCallback, buttonWidth)
  local messageBox
  for i = 1, #buttons do
    if buttons[i] then
      buttons[i].callback = function()
        messageBox:ok()
        if buttons[i] and buttons[i].buttonCallback then
          buttons[i].buttonCallback(messageBox)
        end
      end
    end
  end

  local _cancelCallback = function()
    messageBox:cancel()
    if onCancelCallback then
      onCancelCallback(messageBox)
    end
  end

  table.insert(buttons, {text = cancelText or loc'${CorelibInfoCancel}', callback = _cancelCallback})
  messageBox = UIMessageBox.display(title, message, buttons, buttons[buttonIndexOnEnterCallback] and buttons[buttonIndexOnEnterCallback].callback or nil, _cancelCallback, buttonWidth or 80)
  return messageBox
end

function displayGeneralBox(title, message, buttons, onEnterCallback, onEscapeCallback, buttonWidth)
  return UIMessageBox.display(title, message, buttons, onEnterCallback, onEscapeCallback, buttonWidth)
end

function UIMessageBox:addButton(text, callback)
  local buttonHolder = self:getChildById('buttonHolder')
  local button = g_ui.createWidget('MessageBoxButton', buttonHolder)
  button:setText(text)
  connect(button, {
    onClick = callback
  })
  return button
end

function UIMessageBox:ok()
  signalcall(self.onOk, self)
  self.onOk = nil
  self:destroy()
end

function UIMessageBox:cancel()
  signalcall(self.onCancel, self)
  self.onCancel = nil
  self:destroy()
end
