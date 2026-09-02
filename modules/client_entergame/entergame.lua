g_locales.loadLocales(resolvepath(''))

_G.ClientEnterGame = { }



ClientEnterGame.localIp = '127.0.0.1'
ClientEnterGame.clientIp = 'kingdomageonline.com'
ClientEnterGame.clientPort = '7171'
ClientEnterGame.clientProtocolVersion = 1099

EnterGameActionKey = 'Ctrl+G'

local loadBox
local enterGame
local enterGameButton
local motdWindow
local motdButton
local clientBox
local protocolLogin
local motdEnabled = false



local function onError(protocol, message, errorCode)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end

  if not errorCode then
    ClientEnterGame.clearAccountFields()
  end

  local errorBox = displayErrorBox(loc'${EnterGameLoginErrorTitle}', message)
  connect(errorBox, {
    onOk = ClientEnterGame.show
  })
end

local function onMotd(protocol, motd)
  G.motdNumber = tonumber(motd:sub(0, motd:find('\n')))
  G.motdMessage = motd:sub(motd:find('\n') + 1, #motd)
  if motdEnabled then
    motdButton:show()
  end
end

local function onSessionKey(protocol, sessionKey)
  G.sessionKey = sessionKey
end

local function onCharacterList(protocol, characters, account, otui)
  -- Try add server to the server list
  ClientServerList.add(G.host, G.port, g_game.getClientVersion())

  -- Save 'Stay logged in' setting
  --g_settings.set('staylogged', enterGame:getChildById('stayLoggedBox'):isChecked())
  g_settings.set('staylogged', G.stayLogged)

  if enterGame:getChildById('rememberPasswordBox'):isChecked() then
    local account = g_crypt.encrypt(G.account)
    local password = g_crypt.encrypt(G.password)

    g_settings.set('account', account)
    g_settings.set('password', password)

    ClientServerList.setServerAccount(G.host, account)
    ClientServerList.setServerPassword(G.host, password)

    g_settings.set('autologin', enterGame:getChildById('autoLoginBox'):isChecked())
  else
    -- reset server list account/password
    ClientServerList.setServerAccount(G.host, '')
    ClientServerList.setServerPassword(G.host, '')

    ClientEnterGame.clearAccountFields()
  end

  loadBox:destroy()
  loadBox = nil

  for _, characterInfo in pairs(characters) do
    if characterInfo.previewState and characterInfo.previewState ~= PreviewState.Default then
      characterInfo.worldName = f('%s, %s', characterInfo.worldName, loc'${EnterGamePreviewState}')
    end
  end

  ClientCharacterList.create(characters, account, otui)
  ClientCharacterList.show()

  if motdEnabled then
    local lastMotdNumber = g_settings.getNumber('motd')
    if G.motdNumber and G.motdNumber ~= lastMotdNumber then
      g_settings.set('motd', G.motdNumber)
      motdWindow = displayInfoBox(loc'${EnterGameMotdTitle}', G.motdMessage)
      motdButton:setOn(true)
      connect(motdWindow, {
        onOk = function()
          ClientCharacterList.show()
          motdButton:setOn(false)
          motdWindow = nil
        end
      })
      ClientCharacterList.hide()
    end
  end
end

local function onUpdateNeeded(protocol, signature)
  loadBox:destroy()
  loadBox = nil

  if ClientEnterGame.updateFunc then
    local continueFunc = ClientEnterGame.show
    local cancelFunc = ClientEnterGame.show
    ClientEnterGame.updateFunc(signature, continueFunc, cancelFunc)
  else
    local errorBox = displayErrorBox(loc'${EnterGameUpdateNeededTitle}', loc'${EnterGameUpdateNeededMessage}')
    connect(errorBox, {
      onOk = ClientEnterGame.show
    })
  end
end



function ClientEnterGame.init()
  -- Alias
  ClientEnterGame.m = modules.client_entergame

  enterGame = g_ui.displayUI('entergame')
  motdButton = ClientTopMenu.addLeftButton('motdButton', loc'${EnterGameMotdTitle}', '/images/ui/top_menu/motd', ClientEnterGame.toggleMotd)
  motdButton:setOn(false)
  motdButton:hide()
  g_keyboard.bindKeyDown(EnterGameActionKey, ClientEnterGame.openWindow)

  if motdEnabled and G.motdNumber then
    motdButton:show()
  end

  local account = g_settings.get('account')
  local password = g_settings.get('password')
  local autologin = g_settings.getBoolean('autologin')

  ClientEnterGame.setAccountName(account)
  ClientEnterGame.setPassword(password)

  enterGame:getChildById('autoLoginBox'):setChecked(autologin)

  enterGame:hide()

  if g_app.isRunning() and not g_game.isOnline() then
    enterGame:show()
  end
end

function ClientEnterGame.firstShow()
  ClientEnterGame.show()

  local account = g_crypt.decrypt(g_settings.get('account'))
  local password = g_crypt.decrypt(g_settings.get('password'))
  local host = g_settings.get('host')
  if host == '' then
    host = ClientEnterGame.clientIp
  end
  local autologin = g_settings.getBoolean('autologin')
  if #host > 0 and #password > 0 and #account > 0 and autologin then
    addEvent(function()
      if not g_settings.getBoolean('autologin') then
        return
      end

      ClientEnterGame.doLogin()
    end)
  end
end

function ClientEnterGame.terminate()
  g_keyboard.unbindKeyDown(EnterGameActionKey)
  enterGame:destroy()
  enterGame = nil

  clientBox = nil

  if enterGameButton then
    enterGameButton:destroy()
    enterGameButton = nil
  end

  if motdWindow then
    motdWindow:destroy()
    motdWindow = nil
  end

  if motdButton then
    motdButton:destroy()
    motdButton = nil
  end

  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end

  if protocolLogin then
    protocolLogin:cancelLogin()
    protocolLogin = nil
  end

  _G.ClientEnterGame = nil
end

function ClientEnterGame.createEnterGameButton()
  enterGameButton = ClientTopMenu.addLeftButton('enterGameButton', { loct = '${CharacterListTitle} (${EnterGameActionKey})', locpar = { EnterGameActionKey = EnterGameActionKey } }, '/images/ui/top_menu/login', ClientEnterGame.openWindow, true)
end

function ClientEnterGame.toggleLoginButton(on)
  if not enterGameButton then
    return
  end
  enterGameButton:setOn(on)
end

function ClientEnterGame.show()
  if loadBox then
    return
  end

  if not Client.isLoaded() then
    displayOkCancelBox(loc'${EnterGameClientModifiedTitle}', loc'${EnterGameClientModifiedMessage}', function() restart() end)
    return
  end

  enterGame:show()
  enterGame:raise()
  enterGame:focus()

  local localesWindow = g_locales.getWindow()
  if localesWindow then
    localesWindow:raise()
    localesWindow:focus()
  end
end

function ClientEnterGame.hide()
  enterGame:hide()
end

function ClientEnterGame.openWindow()
  if g_game.isOnline() then
    if not ClientCharacterList.isVisible() then
      ClientEnterGame.hide()
      ClientCharacterList.show()
      if enterGameButton then
        enterGameButton:setOn(true)
      end
    else
      ClientEnterGame.hide()
      ClientCharacterList.hide(false)
      if enterGameButton then
        enterGameButton:setOn(false)
      end
    end
  else
    if not g_game.isLogging() then
      ClientEnterGame.show()
      ClientCharacterList.hide()
      if enterGameButton then
        enterGameButton:setOn(false)
      end
    end
  end
end

function ClientEnterGame.setAccountName(account)
  local account = g_crypt.decrypt(account)
  enterGame:getChildById('accountNameTextEdit'):setText(account)
  enterGame:getChildById('accountNameTextEdit'):setCursorPos(-1)
  enterGame:getChildById('rememberPasswordBox'):setChecked(#account > 0)
end

function ClientEnterGame.setPassword(password)
  local password = g_crypt.decrypt(password)
  enterGame:getChildById('accountPasswordTextEdit'):setText(password)
end

function ClientEnterGame.clearAccountFields()
  enterGame:getChildById('accountNameTextEdit'):clearText()
  enterGame:getChildById('accountPasswordTextEdit'):clearText()
  enterGame:getChildById('accountNameTextEdit'):focus()
  g_settings.remove('account')
  g_settings.remove('password')
end

function ClientEnterGame.doLogin()
  G.account = enterGame:getChildById('accountNameTextEdit'):getText()
  G.password = enterGame:getChildById('accountPasswordTextEdit'):getText()
  G.authenticatorToken = ''
  G.stayLogged = false
  G.host = g_settings.get('host')
  G.port = g_settings.getInteger('port')
  local clientVersion = g_settings.getInteger('client-version')
  if G.host == '' then
    G.host = ClientEnterGame.clientIp
  end
  if G.port == 0 then
    G.port = ClientEnterGame.clientPort
  end
  if clientVersion == 0 then
    clientVersion = ClientEnterGame.clientProtocolVersion
  end
  ClientEnterGame.hide()

  if g_game.isOnline() then
    local errorBox = displayErrorBox(loc'${EnterGameLoggedAlreadyTitle}', loc'${EnterGameLoggedAlreadyMessage}')
    connect(errorBox, {
      onOk = ClientEnterGame.show
    })
    return
  end

  g_settings.set('host', G.host)
  g_settings.set('port', G.port)
  g_settings.set('client-version', clientVersion)

  protocolLogin = ProtocolLogin.create()
  protocolLogin.onLoginError = onError
  protocolLogin.onMotd = onMotd
  protocolLogin.onSessionKey = onSessionKey
  protocolLogin.onCharacterList = onCharacterList
  protocolLogin.onUpdateNeeded = onUpdateNeeded

  loadBox = displayCancelBox(loc'${CorelibInfoLoading}', loc'${EnterGameConnectingToLoginServerMessage}')
  connect(loadBox, {
    onCancel = function(msgbox)
      loadBox = nil
      protocolLogin:cancelLogin()
      ClientEnterGame.show()
    end
  })

  g_game.setClientVersion(clientVersion)
  g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
  g_game.chooseRsa(G.host)

  if Client.isLoaded() then
    protocolLogin:login(G.host, G.port, G.account, G.password, G.authenticatorToken, G.stayLogged)
  else
    loadBox:destroy()
    loadBox = nil
    ClientEnterGame.show()
  end
end

function ClientEnterGame.displayMotd()
  if not motdEnabled or motdWindow then
    return
  end

  motdWindow      = displayInfoBox(loc'${EnterGameMotdTitle}', G.motdMessage)
  motdWindow.onOk = function() motdButton:setOn(false) motdWindow = nil end
  motdButton:setOn(true)
end

function ClientEnterGame.toggleMotd()
  if motdWindow then
    motdButton:setOn(false)
    motdWindow:destroy()
    motdWindow = nil
  else
    ClientEnterGame.displayMotd()
  end
end

function ClientEnterGame.setDefaultServer(host, port, protocol)
  local accountTextEdit = enterGame:getChildById('accountNameTextEdit')
  local passwordTextEdit = enterGame:getChildById('accountPasswordTextEdit')

  accountTextEdit:setText('')
  passwordTextEdit:setText('')
end

--function ClientEnterGame.setUniqueServer(host, port, protocol, windowWidth, windowHeight)
function ClientEnterGame.setUniqueServer(host, port, protocol)
  g_settings.set('host', host)
  g_settings.set('port', port)
  g_settings.set('client-version', protocol)
end
