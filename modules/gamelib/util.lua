function postostring(pos)
  return f('%d %d %d', pos.x, pos.y, pos.z)
end

function dirtostring(dir)
  for k, v in pairs(Directions) do
    if v == dir then
      return k
    end
  end
end
