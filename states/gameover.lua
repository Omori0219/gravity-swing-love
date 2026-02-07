local Settings = require("settings")
local Button = require("ui.button")
local HUD = require("ui.hud")

local GameOver = {}

local playAgainBtn
local fonts
local scoreData = {}

function GameOver.enter(f, data)
    fonts = f
    scoreData = data or {}

    local bw, bh = 240, 44
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    playAgainBtn = Button.new("Play Again", cx, 420, bw, bh, Settings.COLORS.GREEN, fonts.medium)
end

function GameOver.update(dt)
    local mx, my = love.mouse.getPosition()
    playAgainBtn:updateHover(mx, my)
end

function GameOver.draw()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    -- GAME OVER
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.setFont(fonts.large)
    local goText = "GAME OVER!"
    local gw = fonts.large:getWidth(goText)
    love.graphics.print(goText, (Settings.CANVAS_WIDTH - gw) / 2, 140)

    -- Reason
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(1, 0.3, 0.3, 1)
    local reason = scoreData.reason or "The earth destroyed."
    local rw = fonts.small:getWidth(reason)
    love.graphics.print(reason, (Settings.CANVAS_WIDTH - rw) / 2, 180)

    -- New High Score
    if scoreData.isNewHighScore then
        love.graphics.setColor(Settings.COLORS.GOLD)
        love.graphics.setFont(fonts.medium)
        local nhsText = "New High Score!"
        local nw = fonts.medium:getWidth(nhsText)
        love.graphics.print(nhsText, (Settings.CANVAS_WIDTH - nw) / 2, 220)
    end

    -- Score
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.large)
    local scoreText = "Score: " .. (scoreData.score or 0)
    local sw = fonts.large:getWidth(scoreText)
    love.graphics.print(scoreText, (Settings.CANVAS_WIDTH - sw) / 2, 260)

    -- Max Combo
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    local comboText = "Max Combo: " .. (scoreData.maxCombo or 0)
    local cw = fonts.small:getWidth(comboText)
    love.graphics.print(comboText, (Settings.CANVAS_WIDTH - cw) / 2, 310)

    -- Play Time
    local timeText = "Time: " .. (scoreData.playTime or "00:00:00:00")
    local tw = fonts.small:getWidth(timeText)
    love.graphics.print(timeText, (Settings.CANVAS_WIDTH - tw) / 2, 340)

    -- High Score
    love.graphics.setColor(Settings.COLORS.GOLD)
    local hsText = "High Score: " .. (scoreData.highScore or 0)
    local hw = fonts.small:getWidth(hsText)
    love.graphics.print(hsText, (Settings.CANVAS_WIDTH - hw) / 2, 375)

    -- Play Again button
    playAgainBtn:draw()

    love.graphics.setColor(1, 1, 1, 1)
end

function GameOver.mousepressed(x, y, button)
    if button == 1 and playAgainBtn:isClicked(x, y) then
        return "play"
    end
    return nil
end

function GameOver.keypressed(key)
    if key == "space" or key == "return" then
        return "play"
    end
    return nil
end

return GameOver
