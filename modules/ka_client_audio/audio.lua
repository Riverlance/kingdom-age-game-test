_G.ClientAudio = { }



local ACTION_CHANNEL_PLAY                 = 0
local ACTION_CHANNEL_STOP                 = 1
local ACTION_CHANNEL_SETCHANNELAUDIOSGAIN = 2
local ACTION_CHANNEL_SETGAIN              = 3
local ACTION_CHANNEL_STOPAUDIOS           = 4
local ACTION_CHANNEL_AUDIOSSETGAIN        = 5

local channels = { }
for channelId = AudioChannels.First, AudioChannels.Last do
  channels[channelId] = { }
  channels[channelId].id      = channelId -- Same as its key
  channels[channelId].volume  = 0
  channels[channelId].channel = g_sounds.getChannel(channelId)
end

local function setChannelVolume(channelId, volume)
  if not channels[channelId] then
    return
  end

  channels[channelId].volume = volume
  channels[channelId].channel:setGain(volume)
end



function ClientAudio.init()
  -- Alias
  ClientAudio.m = modules.ka_client_audio

  local isAudioEnabled = ClientOptions.getOption('enableAudio')

  channels[AudioChannels.Music].volume   = isAudioEnabled and ClientOptions.getOption('enableMusic') and ClientOptions.getOption('musicVolume') or 0
  channels[AudioChannels.Ambient].volume = isAudioEnabled and ClientOptions.getOption('enableSoundAmbient') and ClientOptions.getOption('soundAmbientVolume') or 0
  channels[AudioChannels.Effect].volume  = isAudioEnabled and ClientOptions.getOption('enableSoundEffect') and ClientOptions.getOption('soundEffectVolume') or 0
  channels[AudioChannels.Voice].volume   = isAudioEnabled and ClientOptions.getOption('enableSoundVoice') and ClientOptions.getOption('soundVoiceVolume') or 0
  channels[AudioChannels.Gui].volume     = isAudioEnabled and ClientOptions.getOption('enableSoundGui') and ClientOptions.getOption('soundGuiVolume') or 0

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAudio, ClientAudio.parseAudioRequest)

  connect(LocalPlayer, {
    onPositionChange = ClientAudio.onPositionChange
  })

  connect(g_game, {
    onAddMagicEffect     = ClientAudio.onAddMagicEffect,
    onAddDistanceMissile = ClientAudio.onAddDistanceMissile,
  })
end

function ClientAudio.terminate()
  disconnect(g_game, {
    onAddMagicEffect     = ClientAudio.onAddMagicEffect,
    onAddDistanceMissile = ClientAudio.onAddDistanceMissile,
  })

  disconnect(LocalPlayer, {
    onPositionChange = ClientAudio.onPositionChange
  })

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAudio)

  ClientAudio.clearAudios()

  _G.ClientAudio = nil
end

function ClientAudio.setMusicVolume(volume)
  setChannelVolume(AudioChannels.Music, volume)
end

function ClientAudio.setAmbientVolume(volume)
  setChannelVolume(AudioChannels.Ambient, volume)
end

function ClientAudio.setEffectVolume(volume)
  setChannelVolume(AudioChannels.Effect, volume)
end

function ClientAudio.setVoiceVolume(volume)
  setChannelVolume(AudioChannels.Voice, volume)
end

function ClientAudio.setGuiVolume(volume)
  setChannelVolume(AudioChannels.Gui, volume)
end

function ClientAudio.updateAudios()
  if not g_game.isOnline() then
    return
  end

  local position = g_game.getLocalPlayer():getPosition()
  for _, _channel in ipairs(channels) do
    local channel = _channel.channel
    if channel then
      channel:setThingPosition(position.x, position.y)
    end
  end
end

function ClientAudio.clearAudios()
  g_sounds.stopAll()
  for _, _channel in ipairs(channels) do
    local channel = _channel.channel
    if channel then
      channel:clear()
    end
  end
end

function ClientAudio.parseAudioRequest(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = string.split(buffer, ':')

  local action = tonumber(params[1])
  if not action then
    return
  end

  if action == ACTION_CHANNEL_PLAY then
    local channelId = tonumber(params[2])
    local path = params[3]
    local gain = tonumber(params[4])
    local repetitions = tonumber(params[5])
    local fadeInTime = tonumber(params[6])
    local x = tonumber(params[7])
    local y = tonumber(params[8])
    if not channelId or path == '' or not gain or not repetitions or not fadeInTime or not x or not y then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = f('%s%s', AudioChannelRootPath, path)
    local audio = channel:play(path, gain, repetitions, fadeInTime)
    if audio and x ~= 0 and y ~= 0 then
      audio:setPosition(x, y)
    end

  elseif action == ACTION_CHANNEL_STOP then
    local channelId = tonumber(params[2])
    local fadeOutTime = tonumber(params[3])
    if not channelId or not fadeOutTime then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:stop(fadeOutTime)

  elseif action == ACTION_CHANNEL_SETCHANNELAUDIOSGAIN then
    local channelId = tonumber(params[2])
    local gain = tonumber(params[3])
    if not channelId or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:setAudioGroupGain(gain)

  elseif action == ACTION_CHANNEL_SETGAIN then
    local channelId = tonumber(params[2])
    local gain = tonumber(params[3])
    if not channelId or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:setGain(gain)

  elseif action == ACTION_CHANNEL_STOPAUDIOS then
    local channelId = tonumber(params[2])
    local path = params[3]
    local fadeOutTime = tonumber(params[4])
    if not channelId or path == '' or not fadeOutTime then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = f('%s%s', AudioChannelRootPath, path)
    channel:stopAudioGroup(path, fadeOutTime)

 elseif action == ACTION_CHANNEL_AUDIOSSETGAIN then
    local channelId = tonumber(params[2])
    local path = params[3]
    local gain = tonumber(params[4])
    if not channelId or path == '' or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = f('%s%s', AudioChannelRootPath, path)
    channel:setAudioGroupGain(path, gain)
  end
end





function ClientAudio.onPositionChange(creature, newPos, oldPos)
  ClientAudio.updateAudios()
end



-- Effect Audio

do
  local function canReleaseAudioEffect(pos)
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then
      return
    end
    local playerPos = localPlayer:getPosition()

    -- Diff floor, then we need to check if has ground between
    if pos.z ~= playerPos.z then
      -- Effect is above
      if pos.z < playerPos.z then
        -- From effect floor to player floor
        for z = pos.z, playerPos.z do
          local tile = g_map.getTile{ x = pos.x, y = pos.y, z = z }
          if tile and (not tile:isLookPossible() or tile:isFullGround()) then
            return false
          end
        end

      -- Effect is below
      else
        -- From above effect floor to player floor
        for z = pos.z - 1, playerPos.z, -1 do
          local tile = g_map.getTile{ x = pos.x, y = pos.y, z = z }
          if tile and (not tile:isLookPossible() or tile:isFullGround()) then
            return false
          end
        end
      end
    end

    return true
  end



  -- Effect

  do
    local datFxPath = f('%s/dat/fx', getAudioChannelPath(AudioChannels.Effect))

    local effects = {
      [1] = { id = 1 },
      [2] = { id = 2 },
      [3] = { id = 3 },
      [4] = { id = 4 },
      [5] = { id = 5 },
      [6] = { id = 6 },
      [7] = { id = 7 },
      [8] = { id = 8 },
      [9] = { id = 9 },
      [10] = { id = 10 },
      [11] = { id = 11 },
      [12] = { id = 12 },
      [13] = { id = 13 },
      [14] = { id = 14, path = f('%s/13', datFxPath) },
      [15] = { id = 15, path = f('%s/13', datFxPath) },
      [16] = { id = 16 },
      [17] = { id = 17, path = f('%s/1', datFxPath) },
      [18] = { id = 18 },
      [19] = { id = 19 },
      [20] = { id = 20, path = f('%s/19', datFxPath) },
      [21] = { id = 21, path = f('%s/3', datFxPath) },
      [22] = { id = 22, path = f('%s/19', datFxPath) },
      [23] = { id = 23, path = f('%s/19', datFxPath) },
      [24] = { id = 24, path = f('%s/19', datFxPath) },
      [25] = { id = 25, path = f('%s/19', datFxPath) },
      [26] = { id = 26 },
      [27] = { id = 27 },
      [28] = { id = 28 },
      [29] = { id = 29 },
      [30] = { id = 30, path = f('%s/29', datFxPath) },
      [31] = { id = 31, path = f('%s/29', datFxPath) },
      [32] = { id = 32 },
      [33] = { id = 33 },
      [34] = { id = 34 },
      [35] = { id = 35 },
      [36] = { id = 36 },
      [37] = { id = 37 },
      [38] = { id = 38 },
      [39] = { id = 39 },
      [40] = { id = 40 },
      [41] = { id = 41 },
      [42] = { id = 42 },
      [43] = { id = 43 },
      [44] = { id = 44 },
      [45] = { id = 45 },
      [46] = { id = 46 },
      [47] = { id = 47 },
      [48] = { id = 48, path = f('%s/12', datFxPath) },
      [49] = { id = 49, path = f('%s/12', datFxPath) },
      [50] = { id = 50 },
      [51] = { id = 51 },
      [52] = { id = 52 },
      [53] = { id = 53 },
      [54] = { id = 54 },
      [55] = { id = 55 },
      [56] = { id = 56 },
      [57] = { id = 57 },
      [58] = { id = 58 },
      [59] = { id = 59, path = f('%s/58', datFxPath) },
      [60] = { id = 60 },
      [61] = { id = 61, path = f('%s/60', datFxPath) },
      -- 62
      [63] = { id = 63 },
      [64] = { id = 64 },
      [65] = { id = 65, path = f('%s/63', datFxPath) },
      [66] = { id = 66 },
      [67] = { id = 67 },
      [68] = { id = 68 },
      [69] = { id = 69 },
      -- 70
      -- 71
      -- 72
      [73] = { id = 73 },
      -- 74
      [75] = { id = 75, path = f('%s/28', datFxPath) },
      [76] = { id = 76, path = f('%s/28', datFxPath) },
      [77] = { id = 77, path = f('%s/41', datFxPath) },

      [158] = { id = 158 },

      [167] = { id = 167, path = f('%s/158', datFxPath) },
      [168] = { id = 168, path = f('%s/158', datFxPath) },
      [169] = { id = 169, path = f('%s/158', datFxPath) },
      [170] = { id = 170, path = f('%s/158', datFxPath) },

      -- 172
      [173] = { id = 173 },

      [175] = { id = 175 },

      [177] = { id = 177 },
      [178] = { id = 178, path = f('%s/177', datFxPath) },
      [179] = { id = 179, path = f('%s/177', datFxPath) },
      [180] = { id = 180, path = f('%s/177', datFxPath) },
      [181] = { id = 181 },
      [182] = { id = 182, path = f('%s/181', datFxPath) },
      [183] = { id = 183, path = f('%s/181', datFxPath) },
      [184] = { id = 184, path = f('%s/181', datFxPath) },
      [185] = { id = 185 },
      [186] = { id = 186, path = f('%s/185', datFxPath) },
      [187] = { id = 187, path = f('%s/185', datFxPath) },
      [188] = { id = 188, path = f('%s/185', datFxPath) },
      [189] = { id = 189 },
      [190] = { id = 190, path = f('%s/189', datFxPath) },
      [191] = { id = 191, path = f('%s/189', datFxPath) },
      [192] = { id = 192, path = f('%s/189', datFxPath) },
      [193] = { id = 193 },
      [194] = { id = 194, path = f('%s/193', datFxPath) },
      [195] = { id = 195, path = f('%s/193', datFxPath) },
      [196] = { id = 196, path = f('%s/193', datFxPath) },
      [197] = { id = 197 },
      [198] = { id = 198, path = f('%s/197', datFxPath) },
      [199] = { id = 199 },
      [200] = { id = 200, path = f('%s/199', datFxPath) },
      [201] = { id = 201, path = f('%s/199', datFxPath) },
      [202] = { id = 202, path = f('%s/199', datFxPath) },
      [203] = { id = 203, path = f('%s/199', datFxPath) },
      [204] = { id = 204, path = f('%s/199', datFxPath) },
      [205] = { id = 205, path = f('%s/199', datFxPath) },
      [206] = { id = 206, path = f('%s/199', datFxPath) },
      [207] = { id = 207, path = f('%s/199', datFxPath) },
      [208] = { id = 208, path = f('%s/199', datFxPath) },
      [209] = { id = 209, path = f('%s/199', datFxPath) },
      [210] = { id = 210, path = f('%s/199', datFxPath) },
      [211] = { id = 211 },
      [212] = { id = 212, path = f('%s/211', datFxPath) },
      [213] = { id = 213, path = f('%s/211', datFxPath) },
      [214] = { id = 214, path = f('%s/211', datFxPath) },
      [215] = { id = 215 },
      [216] = { id = 216 },
      [217] = { id = 217 },
      [218] = { id = 218 },
      [219] = { id = 219 },
      [220] = { id = 220 },
      [221] = { id = 221 },
      [222] = { id = 222 },
      [223] = { id = 223, path = f('%s/222', datFxPath) },
      [224] = { id = 224, path = f('%s/222', datFxPath) },
      [225] = { id = 225, path = f('%s/222', datFxPath) },
      [226] = { id = 226, path = f('%s/222', datFxPath) },
      [227] = { id = 227 },
      [228] = { id = 228, path = f('%s/227', datFxPath) },
      [229] = { id = 229, path = f('%s/227', datFxPath) },
      [230] = { id = 230, path = f('%s/227', datFxPath) },
      [231] = { id = 231, path = f('%s/227', datFxPath) },
      [232] = { id = 232 },
      [233] = { id = 233 },
      [234] = { id = 234 },
      [235] = { id = 235 },
      [236] = { id = 236 },
      [237] = { id = 237 },
      [238] = { id = 238 },
      [239] = { id = 239 },
      [240] = { id = 240 },
      [241] = { id = 241 },
      [242] = { id = 242 },
      [243] = { id = 243 },
      [244] = { id = 244 },
      [245] = { id = 245, path = f('%s/43', datFxPath) },
      [246] = { id = 246, path = f('%s/43', datFxPath) },
      [247] = { id = 247 },
      [248] = { id = 248 },
      [249] = { id = 249, path = f('%s/248', datFxPath) },
      [250] = { id = 250, path = f('%s/248', datFxPath) },
      [251] = { id = 251, path = f('%s/248', datFxPath) },
      [252] = { id = 252, path = f('%s/248', datFxPath) },
      [253] = { id = 253 },
      [254] = { id = 254 },
      [255] = { id = 255 },
      [256] = { id = 256 },
      [257] = { id = 257 },
      [258] = { id = 258, path = f('%s/257', datFxPath) },
      [259] = { id = 259 },
      [260] = { id = 260 },
      [261] = { id = 261, path = f('%s/237', datFxPath) },
      [262] = { id = 262 },
      [263] = { id = 263 },
      [264] = { id = 264 },
      [265] = { id = 265 },
      [266] = { id = 266 },
      [267] = { id = 267 },
      [268] = { id = 268 },
      [269] = { id = 269 },
      [270] = { id = 270, path = f('%s/269', datFxPath) },
      [271] = { id = 271, path = f('%s/269', datFxPath) },
      [272] = { id = 272, path = f('%s/269', datFxPath) },
      [273] = { id = 273, path = f('%s/269', datFxPath) },
      [274] = { id = 274, path = f('%s/269', datFxPath) },
      [275] = { id = 275, path = f('%s/269', datFxPath) },
      [276] = { id = 276, path = f('%s/269', datFxPath) },
      [277] = { id = 277, path = f('%s/269', datFxPath) },
      [279] = { id = 279, path = f('%s/269', datFxPath) },
      [280] = { id = 280, path = f('%s/269', datFxPath) },
      [281] = { id = 281, path = f('%s/269', datFxPath) },
      [282] = { id = 282, path = f('%s/269', datFxPath) },
      [283] = { id = 283, path = f('%s/269', datFxPath) },
      [284] = { id = 284, path = f('%s/269', datFxPath) },
      [285] = { id = 285, path = f('%s/269', datFxPath) },
      [286] = { id = 286, path = f('%s/269', datFxPath) },
      [287] = { id = 287, path = f('%s/269', datFxPath) },
      [288] = { id = 288, path = f('%s/269', datFxPath) },
      [289] = { id = 289, path = f('%s/269', datFxPath) },
      [290] = { id = 290, path = f('%s/269', datFxPath) },
      [291] = { id = 291, path = f('%s/269', datFxPath) },
      [292] = { id = 292, path = f('%s/269', datFxPath) },
      [293] = { id = 293, path = f('%s/269', datFxPath) },
      [294] = { id = 294, path = f('%s/269', datFxPath) },
      [295] = { id = 295, path = f('%s/269', datFxPath) },
      [296] = { id = 296, path = f('%s/269', datFxPath) },
      [297] = { id = 297, path = f('%s/269', datFxPath) },
      [298] = { id = 298, path = f('%s/269', datFxPath) },
      [299] = { id = 299, path = f('%s/269', datFxPath) },
      [300] = { id = 300, path = f('%s/269', datFxPath) },
      [301] = { id = 301, path = f('%s/269', datFxPath) },
      [302] = { id = 302, path = f('%s/269', datFxPath) },
      [303] = { id = 303, path = f('%s/269', datFxPath) },
      [304] = { id = 304, path = f('%s/269', datFxPath) },
      [305] = { id = 305, path = f('%s/269', datFxPath) },
      [306] = { id = 306, path = f('%s/269', datFxPath) },
      [307] = { id = 307, path = f('%s/269', datFxPath) },
      [308] = { id = 308, path = f('%s/269', datFxPath) },
      [309] = { id = 309 },
      [310] = { id = 310, path = f('%s/309', datFxPath) },
      [311] = { id = 311 },
      [312] = { id = 312 },
      [313] = { id = 313 },
      [314] = { id = 314 },
      [315] = { id = 315 },
      [316] = { id = 316 },
      [317] = { id = 317 },
      [318] = { id = 318 },
      [319] = { id = 319 },
      [320] = { id = 320 },
      [321] = { id = 321, path = f('%s/320', datFxPath) },
      [322] = { id = 322, path = f('%s/320', datFxPath) },
      [323] = { id = 323, path = f('%s/320', datFxPath) },
      [324] = { id = 324 },
      [325] = { id = 325 },
      [326] = { id = 326 },
      [327] = { id = 327 },
      [328] = { id = 328, path = f('%s/3', datFxPath) },
      [329] = { id = 329, path = f('%s/3', datFxPath) },
      [330] = { id = 330, path = f('%s/3', datFxPath) },
      [331] = { id = 331, path = f('%s/3', datFxPath) },
      [332] = { id = 332, path = f('%s/3', datFxPath) },
      [333] = { id = 333 },
      [335] = { id = 335 },
      [336] = { id = 336, path = f('%s/335', datFxPath) },
      [337] = { id = 337, path = f('%s/335', datFxPath) },
      [338] = { id = 338, path = f('%s/335', datFxPath) },
      [339] = { id = 339, path = f('%s/335', datFxPath) },
      [340] = { id = 340, path = f('%s/335', datFxPath) },
      [341] = { id = 341, path = f('%s/13', datFxPath) },
      [342] = { id = 342 },
      [343] = { id = 343 },
      [344] = { id = 344 },
      [345] = { id = 345, path = f('%s/66', datFxPath) },
      [346] = { id = 346 },
      [347] = { id = 347 },
      [348] = { id = 348 },
      [349] = { id = 349, path = f('%s/29', datFxPath) },
      [350] = { id = 350, path = f('%s/29', datFxPath) },
      [351] = { id = 351, path = f('%s/29', datFxPath) },
      [352] = { id = 352, path = f('%s/29', datFxPath) },
      [353] = { id = 353 },
      [354] = { id = 354, path = f('%s/1', datFxPath) },
      [355] = { id = 355, path = f('%s/13', datFxPath) },
      [356] = { id = 356 },
      [357] = { id = 357, path = f('%s/56', datFxPath) },
      [358] = { id = 358, path = f('%s/57', datFxPath) },
      [359] = { id = 359 },
      [360] = { id = 360 },
      [361] = { id = 361 },
      [362] = { id = 362 },
      [363] = { id = 363, path = f('%s/199', datFxPath) },
      [364] = { id = 364 },
      [365] = { id = 365 },
      [366] = { id = 366, path = f('%s/365', datFxPath) },
      [367] = { id = 367 },
      [368] = { id = 368, path = f('%s/11', datFxPath) },
      [369] = { id = 369, path = f('%s/11', datFxPath) },
      [370] = { id = 370, path = f('%s/11', datFxPath) },
      [371] = { id = 371, path = f('%s/11', datFxPath) },
      [372] = { id = 372, path = f('%s/11', datFxPath) },
      [373] = { id = 373 },
      [374] = { id = 374 },
      [375] = { id = 375 },
      [376] = { id = 376 },
      [377] = { id = 377 },
      [378] = { id = 378 },
      [379] = { id = 379 },
      [380] = { id = 380 },
      [381] = { id = 381 },
      [382] = { id = 382 },
      [383] = { id = 383 },
      [384] = { id = 384, path = f('%s/383', datFxPath) },
      [385] = { id = 385 },
      [386] = { id = 386 },
      [387] = { id = 387 },
      [388] = { id = 388 },
      [389] = { id = 389 },
      [390] = { id = 390, path = f('%s/389', datFxPath) },
      [391] = { id = 391 },

      -- [777] = { id = 777, path = f('%s/77', datPath) --[[, gain = 1, repetitions = 0, fadeInTime = 0]] },
    }

    local fxExhaustions = {
      -- [f('%s/77', datPath)]  = { singlePerTime = .1 }, -- example of custom singlePerTime
    }

    function ClientAudio.onAddMagicEffect(id, pos)
      local effect = effects[id]
      if not effect then
        return
      end
      local effectPath = effect.path or f('%s/%d', datFxPath, effect.id)
      effect.onPos     = effect.onPos == nil and true or effect.onPos

      if not fxExhaustions[effectPath] then
        fxExhaustions[effectPath] = { singlePerTime = .1 }
      end
      local exhaustion = fxExhaustions[effectPath]
      if exhaustion.singlePerTime and os.clock() - (exhaustion.lastExecution or 0) < exhaustion.singlePerTime or not canReleaseAudioEffect(pos) then
        return
      end

      local audio = g_sounds.getChannel(AudioChannels.Effect):play(f('%s.ogg', effectPath), effect.gain or 1, effect.repetitions or 0, effect.fadeInTime or 0)
      if audio and effect.onPos then
        audio:setPosition(pos.x, pos.y)
      end

      if exhaustion then
        exhaustion.lastExecution = os.clock()
      end
    end
  end



  -- Distance Effect

  do
    local datFxPath = f('%s/dat/fxdist', getAudioChannelPath(AudioChannels.Effect))

    local effects = {
      [1] = { id = 1 },
      [2] = { id = 2 },
      [3] = { id = 3 },
      [4] = { id = 4 },
      [5] = { id = 5 },
      [6] = { id = 6, path = f('%s/3', datFxPath) },
      [7] = { id = 7, path = f('%s/3', datFxPath) },
      [8] = { id = 8 },
      [9] = { id = 9 },
      [10] = { id = 10 },
      [11] = { id = 11 },
      [12] = { id = 12 },
      [13] = { id = 13, path = f('%s/10', datFxPath) },
      [14] = { id = 14, path = f('%s/2', datFxPath) },
      [15] = { id = 15 },
      [16] = { id = 16, path = f('%s/2', datFxPath) },
      [17] = { id = 17, path = f('%s/1', datFxPath) },
      [18] = { id = 18, path = f('%s/1', datFxPath) },
      [19] = { id = 19, path = f('%s/8', datFxPath) },
      [20] = { id = 20, path = f('%s/8', datFxPath) },
      [21] = { id = 21, path = f('%s/1', datFxPath) },
      [22] = { id = 22, path = f('%s/3', datFxPath) },
      [23] = { id = 23, path = f('%s/3', datFxPath) },
      [24] = { id = 24, path = f('%s/2', datFxPath) },
      [25] = { id = 25, path = f('%s/9', datFxPath) },
      [26] = { id = 26, path = f('%s/9', datFxPath) },
      [27] = { id = 27, path = f('%s/12', datFxPath) },
      [28] = { id = 28, path = f('%s/1', datFxPath) },
      [29] = { id = 29 },
      [30] = { id = 30, path = f('%s/12', datFxPath) },
      [31] = { id = 31 },
      [32] = { id = 32 },
      [33] = { id = 33, path = f('%s/3', datFxPath) },
      [34] = { id = 34, path = f('%s/3', datFxPath) },
      [35] = { id = 35, path = f('%s/3', datFxPath) },
      [36] = { id = 36, path = f('%s/4', datFxPath) },
      [37] = { id = 37 },
      [38] = { id = 38 },
      [39] = { id = 39, path = f('%s/10', datFxPath) },
      [40] = { id = 40, path = f('%s/3', datFxPath) },
      [41] = { id = 41 },
      [42] = { id = 42, path = f('%s/12', datFxPath) },

      [44] = { id = 44, path = f('%s/3', datFxPath) },
      [45] = { id = 45, path = f('%s/2', datFxPath) },

      [48] = { id = 48, path = f('%s/2', datFxPath) },
      [49] = { id = 49, path = f('%s/3', datFxPath) },
      [50] = { id = 50, path = f('%s/2', datFxPath) },
      [51] = { id = 51, path = f('%s/3', datFxPath) },

      [53] = { id = 53, path = f('%s/1', datFxPath) },
      [54] = { id = 54, path = f('%s/3', datFxPath) },
      [55] = { id = 55 },
      [56] = { id = 56 },
      [57] = { id = 57 },
      [58] = { id = 58 },
      [59] = { id = 59, path = f('%s/4', datFxPath) },
      [60] = { id = 60 },
      [61] = { id = 61, path = f('%s/12', datFxPath) },
      [62] = { id = 62, path = f('%s/10', datFxPath) },
      [63] = { id = 63 },
      [64] = { id = 64, path = f('%s/56', datFxPath) },
      [65] = { id = 65, path = f('%s/12', datFxPath) },
      [66] = { id = 66, path = f('%s/4', datFxPath) },
      [67] = { id = 67, path = f('%s/4', datFxPath) },
      [68] = { id = 68, path = f('%s/4', datFxPath) },
      [69] = { id = 69, path = f('%s/4', datFxPath) },
      [70] = { id = 70, path = f('%s/4', datFxPath) },
      [71] = { id = 71, path = f('%s/4', datFxPath) },
      [72] = { id = 72, path = f('%s/4', datFxPath) },
      [73] = { id = 73 },
      [74] = { id = 74 },
      [75] = { id = 75, path = f('%s/55', datFxPath) },
      [76] = { id = 76, path = f('%s/9', datFxPath) },
      [77] = { id = 77, path = f('%s/8', datFxPath) },
      [78] = { id = 78, path = f('%s/3', datFxPath) },
      [79] = { id = 79, path = f('%s/3', datFxPath) },
      [80] = { id = 80, path = f('%s/8', datFxPath) },
      [81] = { id = 81, path = f('%s/8', datFxPath) },
      [82] = { id = 82, path = f('%s/8', datFxPath) },
      [83] = { id = 83, path = f('%s/8', datFxPath) },
      [84] = { id = 84, path = f('%s/8', datFxPath) },
      [85] = { id = 85, path = f('%s/8', datFxPath) },
      [86] = { id = 86, path = f('%s/8', datFxPath) },
      [87] = { id = 87, path = f('%s/8', datFxPath) },
      [88] = { id = 88, path = f('%s/8', datFxPath) },
      [89] = { id = 89, path = f('%s/8', datFxPath) },
      [90] = { id = 90, path = f('%s/8', datFxPath) },

      -- [777] = { id = 777, path = f('%s/77', datPath) --[[, gain = 1, repetitions = 0, fadeInTime = 0]] },
    }

    local fxExhaustions = {
      -- [f('%s/77', datPath)]  = { singlePerTime = .1 }, -- example of custom singlePerTime
    }

    function ClientAudio.onAddDistanceMissile(id, fromPos, toPos)
      local effect = effects[id]
      if not effect then
        return
      end
      local effectPath = effect.path or f('%s/%d', datFxPath, effect.id)
      effect.onPos     = effect.onPos == nil and true or effect.onPos

      if not fxExhaustions[effectPath] then
        fxExhaustions[effectPath] = { singlePerTime = .1 }
      end
      local exhaustion = fxExhaustions[effectPath]
      if exhaustion.singlePerTime and os.clock() - (exhaustion.lastExecution or 0) < exhaustion.singlePerTime or not canReleaseAudioEffect(fromPos) then
        return
      end

      local audio = g_sounds.getChannel(AudioChannels.Effect):play(f('%s.ogg', effectPath), effect.gain or 1, effect.repetitions or 0, effect.fadeInTime or 0)
      if audio and effect.onPos then
        audio:setPosition(fromPos.x, fromPos.y)
      end

      if exhaustion then
        exhaustion.lastExecution = os.clock()
      end
    end
  end
end
