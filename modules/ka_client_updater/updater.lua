g_locales.loadLocales(resolvepath(''))

_G.ClientUpdater = { }

local updaterWindow

local startTime = 0

function ClientUpdater.init()
  ClientUpdater.m = modules.ka_client_updater

  connect(g_updater, {
    onUpdated        = ClientUpdater.onUpdated,
    onUpdateStart    = ClientUpdater.onUpdateStart,
    onUpdateProgress = ClientUpdater.onUpdateProgress,
    onUpdateEnd      = ClientUpdater.onUpdateEnd,
    onUpdateError    = ClientUpdater.onUpdateError,
  })

  updaterWindow = g_ui.displayUI('updater')
  updaterWindow:getChildById('topText'):setText('Loading...')
  updaterWindow:show()
end

function ClientUpdater.terminate()
  disconnect(g_updater, {
    onUpdated        = ClientUpdater.onUpdated,
    onUpdateStart    = ClientUpdater.onUpdateStart,
    onUpdateProgress = ClientUpdater.onUpdateProgress,
    onUpdateEnd      = ClientUpdater.onUpdateEnd,
    onUpdateError    = ClientUpdater.onUpdateError,
  })

  updaterWindow:destroy()
  updaterWindow = nil

  _G.ClientUpdater = nil
end

function ClientUpdater.onUpdated()
  updaterWindow:hide()
end

function ClientUpdater.onUpdateStart()
  startTime = g_clock.millis()
  updaterWindow:show()
  updaterWindow:getChildById('topText'):setText(loc'${KaClientUpdaterStarting}')
end

function ClientUpdater.onUpdateProgress(receivedObj, totalObj, receivedBytes)
  local percent = (receivedObj/totalObj) * 100
  local deltaTime = (g_clock.millis() - startTime) / 1000
  local avgSpeed = receivedBytes / 1024 / deltaTime
  local receivedMB = receivedBytes / 1024 / 1024

  updaterWindow:getChildById('topText'):setText(f(loc'${KaClientUpdaterDownloading}', loc(receivedObj), loc(totalObj)))
  updaterWindow:getChildById('bottomText'):setText(f(loc'${KaClientUpdaterReceived}', receivedMB, avgSpeed < 1024 and avgSpeed or avgSpeed / 1024, avgSpeed < 1024 and 'kB' or 'MB'))
  updaterWindow:getChildById('rightText'):setText(f('%.2f%%', percent))
  updaterWindow:getChildById('bar'):setPercent(percent)
end

function ClientUpdater.onUpdateEnd()
  displayOkBox(loc'${KaClientUpdaterEndTitle}', loc'${KaClientUpdaterEndMsg}', function() restart() end)
end

function ClientUpdater.onUpdateError(message)
  updaterWindow:hide()
  displayErrorBox('Updater Error', message)
end
