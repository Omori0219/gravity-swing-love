local Settings = require("settings")

local FloatingScore = {}
FloatingScore.list = {}

function FloatingScore.spawn(text, x, y, color, isBonus, comboLevel)
    local fontSize
    if isBonus then
        local bonusLevel = math.max(0, (comboLevel or 0) - 2)
        fontSize = Settings.BASE_BONUS_FONT_SIZE + bonusLevel * Settings.BONUS_FONT_SIZE_INCREMENT
    else
        fontSize = 32
    end

    table.insert(FloatingScore.list, {
        text = text,
        x = x,
        y = y,
        color = color,
        timer = Settings.FLOATING_SCORE_DURATION,
        duration = Settings.FLOATING_SCORE_DURATION,
        fontSize = fontSize,
        isBonus = isBonus,
    })
end

function FloatingScore.update(dt)
    for i = #FloatingScore.list, 1, -1 do
        local fs = FloatingScore.list[i]
        fs.timer = fs.timer - dt
        fs.y = fs.y - 30 * dt  -- float upward
        if fs.timer <= 0 then
            table.remove(FloatingScore.list, i)
        end
    end
end

function FloatingScore.draw(font)
    local baseFontSize = font:getHeight()
    for _, fs in ipairs(FloatingScore.list) do
        local alpha = math.max(0, fs.timer / fs.duration)
        if type(fs.color) == "table" then
            love.graphics.setColor(fs.color[1], fs.color[2], fs.color[3], alpha)
        else
            love.graphics.setColor(1, 1, 1, alpha)
        end
        love.graphics.setFont(font)
        local scale = fs.fontSize / baseFontSize
        love.graphics.push()
        love.graphics.translate(fs.x, fs.y)
        love.graphics.scale(scale, scale)
        love.graphics.print(fs.text, -10, -10)
        love.graphics.pop()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function FloatingScore.clear()
    FloatingScore.list = {}
end

return FloatingScore
