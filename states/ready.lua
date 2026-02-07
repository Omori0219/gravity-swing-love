local Settings = require("settings")
local Stars = require("systems.stars")

local Ready = {}
local fonts
local gameMode

function Ready.enter(f, mode)
    fonts = f
    gameMode = mode
end

function Ready.update(dt)
end

function Ready.draw()
    -- Game background (stars)
    love.graphics.setColor(Settings.COLORS.BLACK)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)
    Stars.draw()

    -- Dim overlay
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    -- Instruction panel
    local panelW, panelH = 480, 210
    local panelX = (Settings.CANVAS_WIDTH - panelW) / 2
    local panelY = (Settings.CANVAS_HEIGHT - panelH) / 2

    -- Panel background with border
    love.graphics.setColor(0.08, 0.08, 0.16, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 4, 4)
    love.graphics.setColor(0.35, 0.35, 0.55, 1)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 4, 4)

    -- "HOW TO PLAY" header
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.medium)
    local title = "HOW TO PLAY"
    local tw = fonts.medium:getWidth(title)
    love.graphics.print(title, (Settings.CANVAS_WIDTH - tw) / 2, panelY + 20)

    -- Instructions
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(Settings.COLORS.WHITE)
    local lines = {
        "Move the Earth with your mouse.",
        "Bend asteroids into enemies!",
        "",
        "Don't let them hit the Earth!",
    }

    local lineY = panelY + 60
    for _, line in ipairs(lines) do
        if line ~= "" then
            local lw = fonts.small:getWidth(line)
            love.graphics.print(line, (Settings.CANVAS_WIDTH - lw) / 2, lineY)
        end
        lineY = lineY + 26
    end

    -- "Click to Start" with pulse
    local pulse = math.abs(math.sin(love.timer.getTime() * 3))
    love.graphics.setColor(1, 0.92, 0.23, 0.5 + pulse * 0.5)
    love.graphics.setFont(fonts.small)
    local startText = "Click to Start"
    local sw = fonts.small:getWidth(startText)
    love.graphics.print(startText, (Settings.CANVAS_WIDTH - sw) / 2, panelY + panelH - 42)

    love.graphics.setColor(1, 1, 1, 1)
end

function Ready.mousepressed(x, y, button)
    if button == 1 then
        return "start"
    end
    return nil
end

function Ready.keypressed(key)
    if key == "space" or key == "return" then
        return "start"
    end
    return nil
end

return Ready
