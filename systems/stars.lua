local Settings = require("settings")

local Stars = {}
Stars.list = {}

function Stars.generate()
    Stars.list = {}
    for i = 1, Settings.STARS_COUNT do
        table.insert(Stars.list, {
            x = math.random() * Settings.CANVAS_WIDTH,
            y = math.random() * Settings.CANVAS_HEIGHT,
            radius = math.random() * 1.5,
            alpha = math.random() * 0.5 + 0.5,
        })
    end
end

function Stars.draw()
    for _, star in ipairs(Stars.list) do
        love.graphics.setColor(1, 1, 1, star.alpha)
        love.graphics.circle("fill", star.x, star.y, star.radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Stars
