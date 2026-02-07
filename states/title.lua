local Settings = require("settings")
local Stars = require("systems.stars")
local Button = require("ui.button")

local Title = {}

local startBtn, timedBtn, optionsBtn
local fonts

function Title.enter(f)
    fonts = f
    local bw, bh = 240, 44
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    startBtn = Button.new("Start", cx, 330, bw, bh, Settings.COLORS.GREEN, fonts.medium)
    timedBtn = Button.new("60s Mode", cx, 390, bw, bh, {0.9, 0.55, 0.1}, fonts.medium)
    optionsBtn = Button.new("Options", cx, 460, bw, 36, Settings.COLORS.BLUE, fonts.small)
end

function Title.update(dt)
    local mx, my = love.mouse.getPosition()
    startBtn:updateHover(mx, my)
    timedBtn:updateHover(mx, my)
    optionsBtn:updateHover(mx, my)
end

function Title.draw(highScore)
    -- Background
    love.graphics.setColor(Settings.COLORS.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)
    Stars.draw()

    -- Logo / Title
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.title)
    local titleText = "Gravity Swing"
    local tw = fonts.title:getWidth(titleText)
    love.graphics.print(titleText, (Settings.CANVAS_WIDTH - tw) / 2, 140)

    -- Version
    love.graphics.setFont(fonts.tiny)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    local verText = "Ver.0.1 LOVE2D"
    local vw = fonts.tiny:getWidth(verText)
    love.graphics.print(verText, (Settings.CANVAS_WIDTH - vw) / 2, 190)

    -- High Score
    love.graphics.setColor(Settings.COLORS.GOLD)
    love.graphics.setFont(fonts.small)
    local hsText = "High Score: " .. highScore
    local hw = fonts.small:getWidth(hsText)
    love.graphics.print(hsText, (Settings.CANVAS_WIDTH - hw) / 2, 280)

    -- Buttons
    startBtn:draw()
    timedBtn:draw()
    optionsBtn:draw()

    -- Copyright
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.setFont(fonts.tiny)
    local cpText = "2025 CAEN Inc."
    local cw = fonts.tiny:getWidth(cpText)
    love.graphics.print(cpText, (Settings.CANVAS_WIDTH - cw) / 2, Settings.CANVAS_HEIGHT - 30)

    love.graphics.setColor(1, 1, 1, 1)
end

function Title.mousepressed(x, y, button)
    if button == 1 then
        if startBtn:isClicked(x, y) then
            return "play"
        end
        if timedBtn:isClicked(x, y) then
            return "play_timed"
        end
        if optionsBtn:isClicked(x, y) then
            return "options"
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
