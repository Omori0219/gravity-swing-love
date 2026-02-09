local Settings = require("settings")
local Button = require("ui.button")

local Paused = {}
local fonts
local resumeBtn, quitBtn

function Paused.enter(f)
    fonts = f
    local bw = 260
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    local cy = Settings.CANVAS_HEIGHT / 2

    resumeBtn = Button.new("Resume", cx, cy + 10, bw, 40, Settings.COLORS.GREEN, fonts.small)
    quitBtn = Button.new("Back to Title", cx, cy + 64, bw, 40, Settings.COLORS.GRAY, fonts.small)
end

function Paused.update(dt)
    local mx, my = love.mouse.getPosition()
    resumeBtn:updateHover(mx, my)
    quitBtn:updateHover(mx, my)
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
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, Settings.CANVAS_HEIGHT / 2 - 50)

    -- Buttons
    resumeBtn:draw()
    quitBtn:draw()

    -- Key hints
    love.graphics.setFont(fonts.tiny)
    local kh = 20

    -- Space/Esc hint next to Resume
    local rkx = resumeBtn.x + resumeBtn.w + 12
    local rky = resumeBtn.y + (resumeBtn.h - kh) / 2
    local rkw = 80
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    love.graphics.rectangle("line", rkx, rky, rkw, kh, 4, 4)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local rkLabel = "Spc/Esc"
    local rkLw = fonts.tiny:getWidth(rkLabel)
    love.graphics.print(rkLabel, rkx + (rkw - rkLw) / 2, rky + (kh - fonts.tiny:getHeight()) / 2)

    -- Q hint next to Quit
    local qkx = quitBtn.x + quitBtn.w + 12
    local qky = quitBtn.y + (quitBtn.h - kh) / 2
    local qkw = 24
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    love.graphics.rectangle("line", qkx, qky, qkw, kh, 4, 4)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local qkLabel = "Q"
    local qkLw = fonts.tiny:getWidth(qkLabel)
    love.graphics.print(qkLabel, qkx + (qkw - qkLw) / 2, qky + (kh - fonts.tiny:getHeight()) / 2)

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

function Paused.mousepressed(x, y, button)
    if button == 1 and resumeBtn:isClicked(x, y) then
        return "resume"
    end
    if button == 1 and quitBtn:isClicked(x, y) then
        return "quit"
    end
    return nil
end

return Paused
