if not bit then
  bit = { }
end

function bit.bit(p)
  return 2 ^ p
end

function bit.hasBit(x, p)
  return x % (p + p) >= p
end

function bit.setbit(x, p)
  return bit.hasBit(x, p) and x or x + p
end

function bit.clearbit(x, p)
  return bit.hasBit(x, p) and x - p or x
end
