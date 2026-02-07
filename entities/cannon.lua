local Settings = require("settings")

local Cannon = {}

function Cannon.new()
    return {
        x = Settings.CANNON_X,
        y = Settings.CANVAS_HEIGHT / 2,
        width = Settings.CANNON_WIDTH,
        height = Settings.CANNON_HEIGHT,
    }
end

function Cannon.draw(cannon)
    love.graphics.setColor(Settings.COLORS.CANNON)
    -- Body
    love.graphics.rectangle("fill",
        cannon.x - cannon.width / 2,
        cannon.y - cannon.height / 2,
        cannon.width,
        cannon.height
    )
    -- Barrel
    love.graphics.setLineWidth(Settings.CANNON_BARREL_WIDTH)
    love.graphics.line(
        cannon.x + cannon.width / 2, cannon.y,
        cannon.x + cannon.width / 2 + Settings.CANNON_BARREL_LENGTH, cannon.y
    )
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

return Cannon
