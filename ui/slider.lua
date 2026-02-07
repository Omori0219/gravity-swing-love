local Slider = {}
Slider.__index = Slider

function Slider.new(label, x, y, w, h, value, font)
    local self = setmetatable({}, Slider)
    self.label = label
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.value = value or 0.5   -- 0.0 ~ 1.0
    self.font = font
    self.dragging = false
    self.hovered = false
    self.knobRadius = h * 0.8
    return self
end

function Slider:getKnobX()
    return self.x + self.value * self.w
end

function Slider:updateHover(mx, my)
    local kx = self:getKnobX()
    local ky = self.y + self.h / 2
    local dx = mx - kx
    local dy = my - ky
    self.hovered = (dx * dx + dy * dy) <= (self.knobRadius + 4) * (self.knobRadius + 4)
end

function Slider:mousepressed(mx, my, button)
    if button ~= 1 then return end
    -- Click anywhere on the track
    if mx >= self.x - 4 and mx <= self.x + self.w + 4
       and my >= self.y - self.knobRadius and my <= self.y + self.h + self.knobRadius then
        self.dragging = true
        self.value = math.max(0, math.min(1, (mx - self.x) / self.w))
    end
end

function Slider:mousemoved(mx, my)
    if self.dragging then
        self.value = math.max(0, math.min(1, (mx - self.x) / self.w))
    end
end

function Slider:mousereleased()
    self.dragging = false
end

function Slider:draw()
    local cy = self.y + self.h / 2

    -- Label
    love.graphics.setColor(1, 1, 1, 1)
    if self.font then
        love.graphics.setFont(self.font)
    end
    love.graphics.print(self.label, self.x, self.y - 24)

    -- Track background
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", self.x, cy - 3, self.w, 6, 3, 3)

    -- Filled portion
    love.graphics.setColor(0.275, 0.510, 0.706, 1)
    love.graphics.rectangle("fill", self.x, cy - 3, self.w * self.value, 6, 3, 3)

    -- Knob
    local kx = self:getKnobX()
    if self.dragging then
        love.graphics.setColor(1, 1, 1, 1)
    elseif self.hovered then
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
    end
    love.graphics.circle("fill", kx, cy, self.knobRadius)

    -- Percentage text
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    local pct = tostring(math.floor(self.value * 100)) .. "%"
    if self.font then
        local pw = self.font:getWidth(pct)
        love.graphics.print(pct, self.x + self.w + 16, self.y - 24)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Slider
