local Button = {}
Button.__index = Button

function Button.new(text, x, y, w, h, color, font)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.color = color or {0.298, 0.686, 0.314}
    self.font = font
    self.hovered = false
    return self
end

function Button:updateHover(mx, my)
    self.hovered = mx >= self.x and mx <= self.x + self.w
                and my >= self.y and my <= self.y + self.h
end

function Button:isClicked(mx, my)
    return mx >= self.x and mx <= self.x + self.w
       and my >= self.y and my <= self.y + self.h
end

function Button:draw()
    -- Shadow
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", self.x, self.y + 4, self.w, self.h, 8, 8)

    -- Button body
    local r, g, b = self.color[1], self.color[2], self.color[3]
    if self.hovered then
        love.graphics.setColor(r * 0.85, g * 0.85, b * 0.85, 1)
    else
        love.graphics.setColor(r, g, b, 1)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 8, 8)

    -- Text
    love.graphics.setColor(1, 1, 1, 1)
    if self.font then
        love.graphics.setFont(self.font)
    end
    local tw = self.font and self.font:getWidth(self.text) or love.graphics.getFont():getWidth(self.text)
    local th = self.font and self.font:getHeight() or love.graphics.getFont():getHeight()
    love.graphics.print(self.text, self.x + (self.w - tw) / 2, self.y + (self.h - th) / 2)
end

return Button
