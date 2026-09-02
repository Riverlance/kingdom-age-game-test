local opcodeCallbacks         = { }
local extendedOpcodeCallbacks = { }



function ProtocolGame:onOpcode(opcode, msg) -- Priority is C++ (ProtocolGame::parseMessage), then Lua (ProtocolGame:onOpcode)
  local callback = opcodeCallbacks[opcode]
  if not callback then
    print_traceback(f('ProtocolGame:onOpcode - Sent an unknown packet to client: %d.', opcode))
    return false
  end

  callback(self, msg)
  return true
end

function ProtocolGame:onExtendedOpcode(opcode, msg) -- Priority is C++ (ProtocolGame::parseExtendedOpcode), then Lua (ProtocolGame:onExtendedOpcode)
  local callback = extendedOpcodeCallbacks[opcode]
  if not callback then
    print_traceback(f('ProtocolGame.onExtendedOpcode - Sent an unknown packet to client: %d.', opcode))
    return
  end

  callback(self, opcode, msg)
end

function ProtocolGame.registerOpcode(opcode, callback)
  if not callback or type(callback) ~= 'function' then
    print_traceback(f('ProtocolGame.registerOpcode - opcode %d: Invalid callback.', opcode))
    return
  elseif opcode < 0 or opcode > 255 then
    print_traceback(f('ProtocolGame.registerOpcode - opcode %d: Invalid opcode. Opcodes range is from 0 to 255.', opcode))
    return
  elseif opcodeCallbacks[opcode] then
    print_traceback(f('ProtocolGame.registerOpcode - opcode %d: Opcode is already registered.', opcode))
    return
  end

  opcodeCallbacks[opcode] = callback
end

function ProtocolGame.unregisterOpcode(opcode)
  if opcode < 0 or opcode > 255 then
    print_traceback(f('ProtocolGame.unregisterOpcode - opcode %d: Invalid opcode. Opcodes range is from 0 to 255.', opcode))
    return
  elseif not opcodeCallbacks[opcode] then
    print_traceback(f('ProtocolGame.unregisterOpcode - opcode %d: Attempt to unregister unknown opcode.', opcode))
    return
  end

  opcodeCallbacks[opcode] = nil
end

function ProtocolGame.registerExtendedOpcode(opcode, callback)
  if not callback or type(callback) ~= 'function' then
    print_traceback(f('ProtocolGame.registerExtendedOpcode - opcode %d: Invalid callback.', opcode))
    return
  elseif opcode < 0 or opcode > 65535 then
    print_traceback(f('ProtocolGame.registerExtendedOpcode - opcode %d: Invalid opcode. Opcodes range is from 0 to 65535.', opcode))
    return
  elseif extendedOpcodeCallbacks[opcode] then
    print_traceback(f('ProtocolGame.registerExtendedOpcode - opcode %d: Opcode is already registered.', opcode))
    return
  end

  extendedOpcodeCallbacks[opcode] = callback
end

function ProtocolGame.unregisterExtendedOpcode(opcode)
  if opcode < 0 or opcode > 65535 then
    print_traceback(f('ProtocolGame.unregisterExtendedOpcode - opcode %d: Invalid opcode. Opcodes range is from 0 to 65535.', opcode))
  elseif not extendedOpcodeCallbacks[opcode] then
    print_traceback(f('ProtocolGame.unregisterExtendedOpcode - opcode %d: Attempt to unregister unknown opcode.', opcode))
  end

  extendedOpcodeCallbacks[opcode] = nil
end
