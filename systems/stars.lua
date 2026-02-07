local Settings = require("settings")

local Stars = {}
local bgImage = nil

function Stars.generate()
    local ok, img = pcall(love.graphics.newImage, "assets/images/space.jpg")
    if ok then
        bgImage = img
        bgImage:setFilter("linear", "linear")
    end
end

function Stars.draw()
    if bgImage then
        local w, h = Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT
        local imgW, imgH = bgImage:getDimensions()
        local scale = math.max(w / imgW, h / imgH)
        local ox = (w - imgW * scale) / 2
        local oy = (h - imgH * scale) / 2
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.draw(bgImage, ox, oy, 0, scale, scale)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Stars
