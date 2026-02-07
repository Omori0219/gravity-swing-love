local Settings = require("settings")
local Stars = require("systems.stars")
local Button = require("ui.button")
local Audio = require("systems.audio")

local Title = {}

local playBtn, soundBtn
local fonts

function Title.enter(f)
    fonts = f
    local bw, bh = 240, 44
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    playBtn = Button.new("Play", cx, 340, bw, bh, Settings.COLORS.GREEN, fonts.medium)
    soundBtn = Button.new(
        Audio.isMuted and "Sound OFF" or "Sound ON",
        cx, 400, bw, 36,
        Audio.isMuted and Settings.COLORS.GRAY or Settings.COLORS.BLUE,
        fonts.small
    )
end

function Title.update(dt)
    local mx, my = love.mouse.getPosition()
    playBtn:updateHover(mx, my)
    soundBtn:updateHover(mx, my)
end

function Title.draw(highScore)
    -- Dark background
    love.graphics.setColor(Settings.COLORS.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    Stars.draw()

    -- Title
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.title)
    local titleText = "Gravity Swing"
    local tw = fonts.title:getWidth(titleText)
    love.graphics.print(titleText, (Settings.CANVAS_WIDTH - tw) / 2, 120)

    -- Version
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    local verText = "Ver.0.1 LOVE2D"
    local vw = fonts.small:getWidth(verText)
    love.graphics.print(verText, (Settings.CANVAS_WIDTH - vw) / 2, 170)

    -- Instructions
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.setFont(fonts.small)
    local instructions = {
        "Your mouse is the Earth",
        "Guide the bullet",
        "Break asteroids",
        "Don't destroy the Earth",
    }
    for i, line in ipairs(instructions) do
        local lw = fonts.small:getWidth(line)
        love.graphics.print(line, (Settings.CANVAS_WIDTH - lw) / 2, 210 + (i - 1) * 22)
    end

    -- High Score
    love.graphics.setColor(Settings.COLORS.GOLD)
    love.graphics.setFont(fonts.medium)
    local hsText = "High Score: " .. highScore
    local hw = fonts.medium:getWidth(hsText)
    love.graphics.print(hsText, (Settings.CANVAS_WIDTH - hw) / 2, 305)

    -- Buttons
    playBtn:draw()
    soundBtn:draw()

    -- Copyright
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    love.graphics.setFont(fonts.tiny)
    local cpText = "2025 CAEN Inc."
    local cw = fonts.tiny:getWidth(cpText)
    love.graphics.print(cpText, (Settings.CANVAS_WIDTH - cw) / 2, Settings.CANVAS_HEIGHT - 30)

    love.graphics.setColor(1, 1, 1, 1)
end

function Title.mousepressed(x, y, button, switchState)
    if button == 1 then
        if playBtn:isClicked(x, y) then
            return "play"
        end
        if soundBtn:isClicked(x, y) then
            Audio.toggleMute()
            soundBtn.text = Audio.isMuted and "Sound OFF" or "Sound ON"
            soundBtn.color = Audio.isMuted and Settings.COLORS.GRAY or Settings.COLORS.BLUE
            return nil
        end
    end
    return nil
end

function Title.keypressed(key)
    if key == "space" or key == "return" then
        return "play"
    end
    return nil
end

return Title
