Position = { }

function Position.equals(pos1, pos2)
  return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

function Position.greaterThan(pos1, pos2, orEqualTo)
  if orEqualTo then
    return pos1.x >= pos2.x or pos1.y >= pos2.y or pos1.z >= pos2.z
  else
    return pos1.x > pos2.x or pos1.y > pos2.y or pos1.z > pos2.z
  end
end

function Position.lessThan(pos1, pos2, orEqualTo)
  if orEqualTo then
    return pos1.x <= pos2.x or pos1.y <= pos2.y or pos1.z <= pos2.z
  else
    return pos1.x < pos2.x or pos1.y < pos2.y or pos1.z < pos2.z
  end
end

function Position.isInRange(pos1, pos2, xRange, yRange)
  return math.abs(pos1.x-pos2.x) <= xRange and math.abs(pos1.y-pos2.y) <= yRange and pos1.z == pos2.z;
end

function Position.isValid(pos)
  return not (pos.x == 65535 and pos.y == 65535 and pos.z == 255)
end

function Position.distance(pos1, pos2)
  return math.sqrt(math.pow((pos2.x - pos1.x), 2) + math.pow((pos2.y - pos1.y), 2))
end

function Position.manhattanDistance(pos1, pos2)
  return math.abs(pos2.x - pos1.x) + math.abs(pos2.y - pos1.y)
end

function Position.translatedToDirection(pos, direction)
  local newPos = {x = pos.x, y= pos.y, z = pos.z}
  if direction == Directions.North then
    newPos.y = newPos.y - 1
  elseif direction == Directions.East then
    newPos.x = newPos.x + 1
  elseif direction == Directions.South then
    newPos.y = newPos.y + 1
  elseif direction == Directions.West then
    newPos.x = newPos.x - 1
  elseif direction == Directions.NorthEast then
    newPos.x = newPos.x + 1
    newPos.y = newPos.y - 1
  elseif direction == Directions.SouthEast then
    newPos.x = newPos.x + 1
    newPos.y = newPos.y + 1
  elseif direction == Directions.SouthWest then
    newPos.x = newPos.x - 1
    newPos.y = newPos.y + 1
  elseif direction == Directions.NorthWest then
    newPos.x = newPos.x - 1
    newPos.y = newPos.y - 1
  end

  return newPos
end

function Position.parse(pos)
  if not pos then return nil end
  return {x = pos.x, y = pos.y, z = pos.z}
end

function Position.directionToVector(direction)
  if direction == Directions.North then return 0, -1 end
  if direction == Directions.East then return 1, 0 end
  if direction == Directions.South then return 0, 1 end
  if direction == Directions.West then return -1, 0 end
  if direction == Directions.NorthEast then return 1, -1 end
  if direction == Directions.SouthEast then return 1, 1 end
  if direction == Directions.SouthWest then return -1, 1 end
  if direction == Directions.NorthWest then return -1, -1 end
  return nil, nil
end

function Position.vectorToDirection(dx, dy)
  if dx == 0 and dy == -1 then return Directions.North end
  if dx == 1 and dy == 0 then return Directions.East end
  if dx == 0 and dy == 1 then return Directions.South end
  if dx == -1 and dy == 0 then return Directions.West end
  if dx == 1 and dy == -1 then return Directions.NorthEast end
  if dx == 1 and dy == 1 then return Directions.SouthEast end
  if dx == -1 and dy == 1 then return Directions.SouthWest end
  if dx == -1 and dy == -1 then return Directions.NorthWest end
  return nil
end

function Position.transposeDirection(direction)
  local dx, dy = Position.directionToVector(direction)
  if not dx or not dy then
    return direction
  end

  local mappedDirection = Position.vectorToDirection(dy, dx)
  return mappedDirection or direction
end
