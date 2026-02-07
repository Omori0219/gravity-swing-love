local Settings = require("settings")

local Paused = {}
local fonts

function Paused.enter(f)
    fonts = f
end

function Paused.update(dt)
    -- Nothing updates while paused
end

function Paused.draw()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    -- PAUSED text
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.large)
    local text = "PAUSED"
    local tw = fonts.large:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, Settings.CANVAS_HEIGHT / 2 - 40)

    -- Instructions
    love.graphics.setFont(fonts.small)
    local subText = "Space / ESC : Resume"
    local sw = fonts.small:getWidth(subText)
    love.graphics.print(subText, (Settings.CANVAS_WIDTH - sw) / 2, Settings.CANVAS_HEIGHT / 2 + 20)

    love.graphics.setColor(Settings.COLORS.GRAY)
    local quitText = "Q : Back to Title"
    local qw = fonts.small:getWidth(quitText)
    love.graphics.print(quitText, (Settings.CANVAS_WIDTH - qw) / 2, Settings.CANVAS_HEIGHT / 2 + 50)

    love.graphics.setColor(1, 1, 1, 1)
end

function Paused.keypressed(key)
    if key == "space" or key == "escape" then
        return "resume"
    end
    if key == "q" then
        return "quit"
    end
    return nil
end

return Paused
