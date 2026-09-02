function Player:setPremiumDays(premiumDays)
	self.premiumDays = tonumber(premiumDays)
end

function Player:getPremiumDays()
	return self.premiumDays
end

function Player:getCurrentWeight()
	return self:getTotalCapacity() + self:getOverweight() - self:getFreeCapacity()
end

function Player:getWeightColor()
	local currentWeight = self:getCurrentWeight()
	local totalCapacity = self:getTotalCapacity()

	if currentWeight > totalCapacity then -- overweight
		return 'red'
	elseif currentWeight > 0.95 * totalCapacity then
		return 'darkRed'
	elseif currentWeight > 0.9 * totalCapacity then
		return 'darkOrange'
	elseif currentWeight > 0.8 * totalCapacity then
		return 'darkYellow'
	elseif currentWeight > 0.7 * totalCapacity then
		return 'darkTeal'
	end
	return '#4facffff'
end
