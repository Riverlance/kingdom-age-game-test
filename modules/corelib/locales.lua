--[[
  * Polish signs: https://github.com/otland/otclient/pull/6
  * See also: https://egzot.github.io/otclient-font-create-tool
]]

g_locales = { }



local debugInfo = false



Locale = {
  En = 1,
  Pt = 2,
  Es = 3,
  De = 4,
  Pl = 5,
  Sv = 6,
}
Locale.First = Locale.En
Locale.Last  = Locale.Sv

Locales = {
  [Locale.En] = 'en',
  [Locale.Pt] = 'pt',
  [Locale.Es] = 'es',
  [Locale.De] = 'de',
  [Locale.Pl] = 'pl',
  [Locale.Sv] = 'sv',
}



InstalledLocales = nil

DefaultLocaleId = Locale.En
CurrentLocaleId = DefaultLocaleId



localesWindow = nil



function UIWidget:updateLocale(params)
  local par = type(params) == 'function' and params(self) or params
  if self.loc then self:setText(loc(self.loc, par), false) end
  if self.loct then self:setTooltip(loc(self.loct, par), self:getTooltipType()) end
end

function UIWidget:onLocaleChange(localeId, prevLocaleId)
  self:updateLocale()
  for _, child in ipairs(self:getChildren() or { }) do
    child:onLocaleChange(localeId, prevLocaleId)
  end
end



function g_locales.getInstalledLocales()
  return InstalledLocales
end

function g_locales.installLocale(locale)
  if not locale or not locale.id then
    error('Unable to install locale.')
  end

  local installedLocale = InstalledLocales[locale.id]
  if installedLocale then
    return -- Installed already
  end

  -- Set up
  InstalledLocales[locale.id] = locale
end

function g_locales.installLocales()
  dofiles('/locales')
end

function g_locales.installLocaleFonts() -- See https://github.com/otland/otclient/pull/6
  local locale = g_locales.getLocale()
  if not locale then
    return
  end

  for _, file in pairs(g_resources.listDirectoryFiles(f('/fonts/%s', locale.charset))) do
    if g_resources.isFileType(file, 'otfont') then
      g_fonts.importFont(f('/fonts/%s/%s', locale.charset, file))
    end
  end
end

function g_locales.getLocale()
  return InstalledLocales[CurrentLocaleId]
end

function g_locales.setLocale(id)
  local locale = InstalledLocales[id]

  if not locale then
    error(f('Locale %d does not exist.', id))

  elseif locale == g_locales.getLocale() then
    g_settings.set('locale', id)
    return
  end

  local prevLocaleId = CurrentLocaleId
  CurrentLocaleId    = id
  g_settings.set('locale', id)

  rootWidget:onLocaleChange(id, prevLocaleId)

  g_locales.sendLocale()

  if debugInfo then
    pdebug(f('Using configured locale: %d', id))
  end
end

function g_locales.createWindow()
  localesWindow          = g_ui.displayUI('locales')
  localesWindow.onEscape = g_locales.destroyWindow

  local localesPanel = localesWindow:getChildById('localesPanel')
  local layout       = localesPanel:getLayout()
  local spacing      = layout:getCellSpacing()
  local size         = layout:getCellSize()

  local count = 0
  for id, locale in ipairs(InstalledLocales) do
    local widget = g_ui.createWidget('LocalesButton', localesPanel)

    widget:setImageSource(f('/images/ui/flags/%s', locale.name))
    widget:setText(locale.languageName)

    widget.onClick = function()
      g_locales.destroyWindow()

      -- If chose current locale
      if id == CurrentLocaleId then
        return
      end

      g_locales.setLocale(id)

      restart()
    end

    count = count + 1
  end

  count = math.max(1, math.min(count, 3)) -- Display 3 per line
  localesPanel:setWidth(size.width * count + spacing * (count - 1))

  addEvent(withWeakWidget(localesWindow, function(widget)
    widget:raise()
    widget:focus()
  end))
end

function g_locales.destroyWindow()
  if not localesWindow then
    return
  end

  localesWindow:destroy()
  localesWindow = nil
end

function g_locales.getWindow()
  return localesWindow
end



-- Client to server

function g_locales.sendLocale()
  if not g_locales.getLocale() then
    if debugInfo then
      pdebug(f('Current locale %d is unknown.', CurrentLocaleId))
    end
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeLocale)
  msg:addU8(CurrentLocaleId)
  protocolGame:send(msg)

  return true
end



g_locales.translationList = { }

function g_locales.getTranslation(id)
  local lang = Locales[CurrentLocaleId]
  local tr = g_locales.translationList[id]
  local selected = tr and (tr[lang] or tr['en']) or nil-- default: English
  if type(selected) == 'table' then
    return selected[math.random(#selected)]
  else
    return selected
  end
end

function g_locales.addTranslations(tr, overwrite) -- { id = { [lang] = text, ... }, ...}
  if overwrite == nil then
    overwrite = true
  end

  for id, trList in pairs(tr) do
    if overwrite then
      -- Registered already
      if g_locales.translationList[id] then
        print_traceback(f('Duplicated translation: "%s"', g_locales.translationList[id][Locales[1]]))
      else
        g_locales.translationList[id] = trList
      end

    else
      -- Not registered yet
      if not g_locales.translationList[id] then
        print_traceback(f('No translation found for key: "%s"', id))
      else
        for locale, str in pairs(trList) do
          g_locales.translationList[id][locale] = str
        end
      end
    end
  end
end

function _G.loc(str, params)
  local locale = g_locales.getLocale()
  if not locale then
    return str
  end

  -- Number
  if tonumber(str) and locale.formatNumbers then
    local number        = tostring(str) / '.'
    local reverseNumber = number[1]:reverse()
    local out           = ''

    for i = 1, #reverseNumber do
      out = out .. reverseNumber:sub(i, i)
      if i % 3 == 0 and i ~= #number and i ~= #reverseNumber then
        out = out .. locale.thousandsSeperator
      end
    end

    if number[2] then
      out = number[2] .. locale.decimalSeperator .. out
    end

    return out:reverse()
  end

  -- String
  local ret = tostring(str):eval(function(s) return loc(g_locales.getTranslation(s) or (params and params[s]) or _G.s, params) end)
  if ret == 'nil' and tostring(str) ~= 'nil' then -- Translation failed now and not failed before
    print_traceback(f('No translation found for: "%s"', str))
  end
  return ret
end

do
  local charsetFilenames = { -- In priority order!
    'cp1252', -- en, pt, es, sv, de
    'cp1250', -- pl
  }

  function g_locales.loadLocales(path)
    for _, charsetFilename in ipairs(charsetFilenames) do
      dofile(f('%sloc/%s', path, charsetFilename))
    end
  end
end





function g_locales.init()
  InstalledLocales = { }

  g_locales.installLocales()

  local localeId = tonumber(g_settings.get('locale'))
  g_locales.setLocale(localeId or DefaultLocaleId)

  g_locales.installLocaleFonts() -- See https://github.com/otland/otclient/pull/6

  connect(g_game, {
    onGameStart = g_locales.onGameStart
  })
end

function g_locales.terminate() -- not in use at the moment
  InstalledLocales = nil

  disconnect(g_game, {
    onGameStart = g_locales.onGameStart
  })

  disconnect(g_app, {
    onRun = g_locales.createWindow
  })
end

function g_locales.onGameStart()
  g_locales.sendLocale()
end

g_locales.init()
