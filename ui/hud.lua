local Settings = require("settings")

local HUD = {}

function HUD.drawScore(score, font)
    love.graphics.setFont(font)
    love.graphics.setColor(Settings.COLORS.WHITE)
    local text = "Score: " .. score
    local tw = font:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, 32)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawHighScore(highScore, font)
    love.graphics.setFont(font)
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    local text = "High Score: " .. highScore
    local tw = font:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawTimer(timeRemaining, fonts)
    local seconds = math.ceil(timeRemaining)
    local text = tostring(seconds)

    -- Color: white normally, red when < 10s, pulsing red when < 5s
    if timeRemaining <= 5 then
        local pulse = math.abs(math.sin(love.timer.getTime() * 6))
        love.graphics.setColor(1, pulse * 0.3, pulse * 0.3, 1)
    elseif timeRemaining <= 10 then
        love.graphics.setColor(1, 0.3, 0.2, 1)
    else
        love.graphics.setColor(1, 1, 1, 0.9)
    end

    love.graphics.setFont(fonts.timer)
    local tw = fonts.timer:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, 50)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawKillFeed(destroyedPlanets, font)
    local maxVisible = Settings.KILL_FEED_MAX_VISIBLE
    local lineHeight = Settings.KILL_FEED_LINE_HEIGHT
    local x = Settings.KILL_FEED_X
    local y = Settings.KILL_FEED_Y
    local total = #destroyedPlanets

    love.graphics.setFont(font)
    for i = 1, math.min(total, maxVisible) do
        local p = destroyedPlanets[total - i + 1]  -- newest first
        local alpha = 1 - (i - 1) / maxVisible
        love.graphics.setColor(0.8, 0.8, 0.8, alpha)
        love.graphics.print(p.name or "???", x, y + (i - 1) * lineHeight)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawMuteIndicator(font)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 0.4)
    local text = "MUTE"
    local tw = font:getWidth(text)
    love.graphics.print(text, Settings.CANVAS_WIDTH - tw - 10, Settings.CANVAS_HEIGHT - 20)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.formatPlayTime(elapsedSeconds)
    local cs = math.floor((elapsedSeconds * 100) % 100)
    local totalSec = math.floor(elapsedSeconds)
    local sec = totalSec % 60
    local totalMin = math.floor(totalSec / 60)
    local min = totalMin % 60
    local hr = math.floor(totalMin / 60)
    return string.format("%02d:%02d:%02d:%02d", hr, min, sec, cs)
end

return HUD
