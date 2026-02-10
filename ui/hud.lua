local Settings = require("settings")

local HUD = {}

function HUD.drawScore(score, font, y, bonusActive)
    y = y or 32
    love.graphics.setFont(font)
    if bonusActive then
        local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 6)
        love.graphics.setColor(1, 0.843, 0, pulse)
    else
        love.graphics.setColor(Settings.COLORS.WHITE)
    end
    local text = tostring(score)
    local tw = font:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, y)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawHighScore(highScore, font, y)
    y = y or 10
    love.graphics.setFont(font)
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    local text = "High Score: " .. highScore
    local tw = font:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, y)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawTimer(timeRemaining, font)
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

    love.graphics.setFont(font)
    local tw = font:getWidth(text)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, 8)
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
        local label = (p.name or "???") .. " " .. (p.baseScore or 1) .. "x" .. (p.comboLevel or 1)
        love.graphics.print(label, x, y + (i - 1) * lineHeight)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawCombo(combo, font)
    if combo < 2 then return end
    love.graphics.setFont(font)
    local text = "x" .. combo
    local x = 280
    local y = Settings.KILL_FEED_Y

    local Asteroid = require("entities.asteroid")
    local appearance = Asteroid.getAppearance(combo)
    if appearance.type == "solid" then
        love.graphics.setColor(appearance.color[1], appearance.color[2], appearance.color[3], 0.7)
    else
        love.graphics.setColor(appearance.colors[1][1], appearance.colors[1][2], appearance.colors[1][3], 0.7)
    end
    love.graphics.print(text, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawCatProfile(name, trait, catImg, fonts)
    if not name or not catImg then return end
    local imgW, imgH = catImg:getDimensions()
    local profileSize = 60
    local scale = profileSize / imgH
    local imgDrawW = imgW * scale
    local margin = 16
    local rightX = Settings.CANVAS_WIDTH - margin
    local y = 10

    -- Name (yellow)
    local nameFont = fonts.profileName
    love.graphics.setFont(nameFont)
    love.graphics.setColor(1, 0.843, 0, 0.9)
    local nameW = nameFont:getWidth(name)
    love.graphics.print(name, rightX - nameW, y)
    y = y + nameFont:getHeight() + 4

    -- Cat image
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(catImg, rightX - imgDrawW, y, 0, scale, scale)
    y = y + profileSize + 4

    -- Trait (white)
    if trait then
        local traitFont = fonts.profileTrait
        love.graphics.setFont(traitFont)
        love.graphics.setColor(1, 1, 1, 0.8)
        local traitW = traitFont:getWidth(trait)
        love.graphics.print(trait, rightX - traitW, y)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawScoreMultiplier(multiplier, timer, font, y)
    if multiplier <= 1 then return end
    local text = "BONUS x" .. multiplier
    love.graphics.setFont(font)
    local tw = font:getWidth(text)
    local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 6)
    love.graphics.setColor(1, 0.843, 0, pulse)
    love.graphics.print(text, (Settings.CANVAS_WIDTH - tw) / 2, y)
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
