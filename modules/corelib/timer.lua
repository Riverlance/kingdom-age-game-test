local day = 24 * 60 * 60

Timer = {
    spentTime = 0,
    updateTicks = 1,
    onUpdate = nil,
    forward = false,
}

function Timer:new(duration, format)
    local timer = { }
    timer.startTime = os.time()
    timer.duration = math.floor(duration / 1000)
    timer.endTime = timer.startTime + timer.duration
    timer.format = format or '!%X'
    return setmetatable(timer, { __index = Timer })
end

function Timer:getString(format)
    if self.forward then
        local time = os.difftime(os.time(), self.startTime)
        return f('%s%s', time < day and '' or f('%dd ', time / day), os.date(format or self.format, time))
    end

    local time = os.difftime(self.endTime, os.time())
    return f('%s%s', time < day and '' or f('%dd ', time / day), os.date(format or self.format, time))
end

function Timer:getDurationString(format)
    local time = os.difftime(self.endTime, self.startTime)
    return f('%s%s', time < day and '' or f('%dd ', time / day), os.date(format or self.format, time))
end

function Timer:getPercent()
    if self.forward then
        return 100 * self.spentTime / self.duration
    end
    return 100 - 100 * self.spentTime / self.duration
end

function Timer:getRemainingTime()
    return self.duration - self.spentTime
end

function Timer:start()
    self.event = cycleEvent(function() self:update() end, self.updateTicks * 1000)
end

function Timer:stop()
    if self.event then
        removeEvent(self.event)
        self.event = nil
    end
end

function Timer:destroy()
    self:stop()
    self.onUpdate = nil
end

function Timer:update()
    self.spentTime = self.spentTime + self.updateTicks

--countdown
    if self.spentTime > self.duration then
        self:stop()
        return
    end

    if self.onUpdate then
        self:onUpdate()
    end
end
