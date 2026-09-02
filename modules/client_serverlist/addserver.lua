_G.ClientAddServer = { }



local addServerWindow = nil



function ClientAddServer.init()
  -- Alias
  ClientAddServer.m = modules.client_serverlist

  addServerWindow = g_ui.displayUI('addserver')
end

function ClientAddServer.terminate()
  addServerWindow:destroy()
  addServerWindow = nil

  _G.ClientAddServer = nil
end



function ClientAddServer.add()
  local host = addServerWindow:getChildById('host'):getText()
  local port = addServerWindow:getChildById('port'):getText()
  local protocol = addServerWindow:getChildById('protocol'):getCurrentOption().text

  local added, error = ClientServerList.add(host, port, protocol)
  if not added then
    displayErrorBox(loc'${CorelibInfoError}', error)
  else
    ClientAddServer.hide()
  end
end

function ClientAddServer.show()
  addServerWindow:show()
  addServerWindow:raise()
  addServerWindow:focus()
  addServerWindow:lock()
end

function ClientAddServer.hide()
  addServerWindow:hide()
  addServerWindow:unlock()
end
