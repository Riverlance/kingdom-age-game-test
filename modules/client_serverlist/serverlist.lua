g_locales.loadLocales(resolvepath(''))

_G.ClientServerList = { }



local serverListWindow = nil
local serverTextList = nil
local removeWindow = nil
local servers = { }



function ClientServerList.init()
  -- Alias
  ClientServerList.m = modules.client_serverlist

  serverListWindow = g_ui.displayUI('serverlist')
  serverTextList = serverListWindow:getChildById('serverList')

  servers = g_settings.getNode('ServerList') or { }
  if servers then
    ClientServerList.load()
  end
end

function ClientServerList.terminate()
  ClientServerList.destroy()
  serverListWindow = nil
  serverTextList = nil

  g_settings.setNode('ServerList', servers)

  _G.ClientServerList = nil
end



function ClientServerList.load()
  for host, server in pairs(servers) do
    ClientServerList.add(host, server.port, server.protocol, true)
  end
end

function ClientServerList.select()
  local selected = serverTextList:getFocusedChild()
  if selected then
    local server = servers[selected:getId()]
    if server then
      ClientEnterGame.setDefaultServer(selected:getId(), server.port, server.protocol)
      ClientEnterGame.setAccountName(server.account)
      ClientEnterGame.setPassword(server.password)
      ClientServerList.hide()
    end
  end
end

function ClientServerList.add(host, port, protocol, load)
  if not host or not port or not protocol then
    return false, loc'${ClientServerListErrorFailedLoadSettings}'
  elseif not load and servers[host] then
    return false, loc'${ClientServerListErrorExistsAlready}'
  elseif host == '' or port == '' then
    return false, loc'${ClientServerListErrorFieldsMissing}'
  end
  local widget = g_ui.createWidget('ServerWidget', serverTextList)
  widget:setId(host)

  if not load then
    servers[host] = {
      port = port,
      protocol = protocol,
      account = '',
      password = ''
    }
  end

  local details = widget:getChildById('details')
  details:setText(host..':'..port)

  local proto = widget:getChildById('protocol')
  proto:setText(protocol)

  connect(widget, {
    onDoubleClick = function()
      ClientServerList.select()
      return true
    end
  })
  return true
end

function ClientServerList.remove(widget)
  local host = widget:getId()

  if removeWindow then
    return
  end

  local yesCallback = function()
    widget:destroy()
    servers[host] = nil
    removeWindow:destroy()
    removeWindow = nil
  end
  local noCallback = function()
    removeWindow:destroy()
    removeWindow = nil
  end

  removeWindow = displayGeneralBox(loc'${CorelibInfoRemove}', f(loc'${ClientServerListRemoveHostMsg}', host), {
    { text = loc'${CorelibInfoYes}', callback = yesCallback },
    { text = loc'${CorelibInfoNo}', callback = noCallback },
    anchor = AnchorHorizontalCenter
  }, yesCallback, noCallback)
end

function ClientServerList.destroy()
  if serverListWindow then
    serverTextList = nil
    serverListWindow:destroy()
    serverListWindow = nil
  end
end

function ClientServerList.show()
  if g_game.isOnline() then
    return
  end

  serverListWindow:show()
  serverListWindow:raise()
  serverListWindow:focus()
end

function ClientServerList.hide()
  serverListWindow:hide()
end

function ClientServerList.setServerAccount(host, account)
  if servers[host] then
    servers[host].account = account
  end
end

function ClientServerList.setServerPassword(host, password)
  if servers[host] then
    servers[host].password = password
  end
end
