function pcolored(text, color)
  color = color or 'white'
  ClientTerminal.addLine(tostring(text), color)
end

function draw_debug_boxes()
  g_ui.setDebugBoxesDrawing(not g_ui.isDrawingDebugBoxes())
end

function hide_map()
  if not modules.game_interface then
    return
  end
  GameInterface.getMapPanel():hide()
end

function show_map()
  if not modules.game_interface then
    return
  end
  GameInterface.getMapPanel():show()
end

function live_textures_reload()
  g_textures.liveReload()
end

do
  local pinging = false

  local function pingBack(ping)
    pcolored(f(loc'%s => %d ${CorelibInfoMs}', g_game.getWorldName(), ping), ping < 300 and 'green' or ping < 600 and 'yellow' or 'red')
  end

  function ping()
    if pinging then
      pcolored(loc'${ClientTerminalPingStopped}')
      g_game.setPingDelay(1000)
      disconnect(g_game, {
        onPingBack = pingBack
      })
    else
      if not g_game.isOnline() then
        pcolored(loc'${ClientTerminalErrorNotOnline}', 'red')
        return
      elseif not g_game.getFeature(GameClientPing) then
        pcolored(loc'${ClientTerminalErrorPingNotSupported}', 'red')
        return
      end

      pcolored(loc'${ClientTerminalPingStarting}')
      g_game.setPingDelay(0)
      connect(g_game, {
        onPingBack = pingBack
      })
    end
    pinging = not pinging
  end
end

function clear()
  ClientTerminal.clear()
end

function ls(path)
  path = path or '/'
  local files = g_resources.listDirectoryFiles(path)
  for _, v in pairs(files) do
    if g_resources.directoryExists(path .. v) then
      pcolored(path .. v, 'blue')
    else
      pcolored(path .. v)
    end
  end
end

function about_version()
  pcolored(f("%s %s", g_app.getName(), g_app.getVersion()))
  pcolored(f(loc'${ClientTerminalAboutVersionRevision}', g_app.getBuildRevision(), g_app.getBuildCommit()))
  pcolored(f(loc'${ClientTerminalAboutVersionBuilt}', g_app.getBuildDate()))
end

function about_graphics()
  pcolored(f(loc'${ClientTerminalAboutGraphicsVendor}', g_graphics.getVendor()))
  pcolored(f(loc'${ClientTerminalAboutGraphicsRenderer}', g_graphics.getRenderer()))
  pcolored(f(loc'${ClientTerminalAboutGraphicsVersion}', g_graphics.getVersion()))
end

function about_modules()
  for _, m in pairs(g_modules.getModules()) do
    local loadedtext
    if m:isLoaded() then
      pcolored(f(loc'%s => ${ClientTerminalAboutModulesLoaded}', m:getName()), 'green')
    else
      pcolored(f(loc'%s => ${ClientTerminalAboutModulesNotLoaded}', m:getName()), 'red')
    end
  end
end
