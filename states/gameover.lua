local Settings = require("settings")
local Button = require("ui.button")
local HUD = require("ui.hud")

local GameOver = {}

local playAgainBtn
local titleBtn
local fonts
local scoreData = {}

-- Name input state
local phase          -- "input" or "result"
local inputName      -- current name string
local MAX_NAME_LEN = 5
local MIN_NAME_LEN = 3
local cursorBlink    -- timer for cursor blink
local qualified      -- whether score qualified for ranking

function GameOver.enter(f, data)
    fonts = f
    scoreData = data or {}
    qualified = data.qualified or false
    inputName = ""
    cursorBlink = 0

    if qualified then
        phase = "input"
    else
        phase = "result"
    end

    local bw, bh = 240, 44
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    playAgainBtn = Button.new("Play Again", cx, 410, bw, bh, Settings.COLORS.GREEN, fonts.medium)
    titleBtn = Button.new("Title", cx, 465, bw, bh, Settings.COLORS.GRAY, fonts.medium)
end

function GameOver.update(dt)
    if phase == "input" then
        cursorBlink = cursorBlink + dt
    else
        local mx, my = love.mouse.getPosition()
        playAgainBtn:updateHover(mx, my)
        titleBtn:updateHover(mx, my)
    end
end

function GameOver.draw()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, Settings.GAMEOVER_OVERLAY_ALPHA)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    -- Header (GAME OVER! or TIME UP!)
    local header = scoreData.header or "GAME OVER!"
    local isTimeUp = (header == "TIME UP!")
    if isTimeUp then
        love.graphics.setColor(Settings.COLORS.GOLD)
    else
        love.graphics.setColor(1, 0.2, 0.2, 1)
    end
    love.graphics.setFont(fonts.large)
    local gw = fonts.large:getWidth(header)
    love.graphics.print(header, (Settings.CANVAS_WIDTH - gw) / 2, 140)

    -- Reason
    love.graphics.setFont(fonts.small)
    if isTimeUp then
        love.graphics.setColor(0.9, 0.8, 0.4, 1)
    else
        love.graphics.setColor(1, 0.3, 0.3, 1)
    end
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

    if phase == "input" then
        drawNameInput()
    else
        drawResult()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function drawNameInput()
    local cx = Settings.CANVAS_WIDTH / 2

    -- "Enter your name" prompt
    love.graphics.setColor(Settings.COLORS.GOLD)
    love.graphics.setFont(fonts.small)
    local prompt = "Ranking In! Enter your name:"
    local pw = fonts.small:getWidth(prompt)
    love.graphics.print(prompt, (Settings.CANVAS_WIDTH - pw) / 2, 310)

    -- Name display with placeholders
    love.graphics.setFont(fonts.medium)
    local display = {}
    for i = 1, MAX_NAME_LEN do
        local ch = inputName:sub(i, i)
        if ch ~= "" then
            table.insert(display, ch)
        else
            table.insert(display, "_")
        end
    end
    local nameStr = table.concat(display, " ")
    local nw = fonts.medium:getWidth(nameStr)
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.print(nameStr, (Settings.CANVAS_WIDTH - nw) / 2, 340)

    -- Cursor blink on current position
    if #inputName < MAX_NAME_LEN then
        local blinkOn = math.floor(cursorBlink * 2) % 2 == 0
        if blinkOn then
            -- Calculate cursor position
            local before = {}
            for i = 1, MAX_NAME_LEN do
                if i <= #inputName then
                    table.insert(before, inputName:sub(i, i))
                else
                    table.insert(before, "_")
                end
            end
            local fullStr = table.concat(before, " ")
            local startX = (Settings.CANVAS_WIDTH - nw) / 2

            -- Measure up to the cursor character
            local cursorIdx = #inputName + 1
            local prefix = {}
            for i = 1, cursorIdx - 1 do
                table.insert(prefix, before[i])
            end
            local prefixStr = ""
            if #prefix > 0 then
                prefixStr = table.concat(prefix, " ") .. " "
            end
            local prefixW = fonts.medium:getWidth(prefixStr)
            local charW = fonts.medium:getWidth("_")

            love.graphics.setColor(Settings.COLORS.GOLD)
            love.graphics.rectangle("fill", startX + prefixW, 360, charW, 3)
        end
    end

    -- Hint
    love.graphics.setFont(fonts.tiny)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    local hint = "A-Z only / ENTER to confirm"
    local hw = fonts.tiny:getWidth(hint)
    love.graphics.print(hint, (Settings.CANVAS_WIDTH - hw) / 2, 380)

    -- Show validity
    if #inputName >= MIN_NAME_LEN then
        love.graphics.setColor(Settings.COLORS.GREEN)
        local ok = "Press ENTER"
        local ow = fonts.tiny:getWidth(ok)
        love.graphics.print(ok, (Settings.CANVAS_WIDTH - ow) / 2, 395)
    end
end

function drawResult()
    local cx = Settings.CANVAS_WIDTH / 2
    local y = 310

    -- Max Combo & Play Time (same line)
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    local comboText = "Max Combo: " .. (scoreData.maxCombo or 0)
    local timeText = "Time: " .. (scoreData.playTime or "00:00:00:00")
    local statsText = comboText .. "   " .. timeText
    local stw = fonts.small:getWidth(statsText)
    love.graphics.print(statsText, (Settings.CANVAS_WIDTH - stw) / 2, y)
    y = y + 25

    -- High Score
    love.graphics.setColor(Settings.COLORS.GOLD)
    local hsText = "High Score: " .. (scoreData.highScore or 0)
    local hw = fonts.small:getWidth(hsText)
    love.graphics.print(hsText, (Settings.CANVAS_WIDTH - hw) / 2, y)
    y = y + 35

    -- Destroyed planets parade
    local destroyed = scoreData.destroyedPlanets or {}
    if #destroyed > 0 then
        love.graphics.setFont(fonts.tiny)
        love.graphics.setColor(0.667, 0.667, 0.667, 1)
        local titleText = "Destroyed:"
        local ttw = fonts.tiny:getWidth(titleText)
        love.graphics.print(titleText, (Settings.CANVAS_WIDTH - ttw) / 2, y)
        y = y + 18

        -- Planet icons in order
        local iconSize = 60
        local iconGap = 6
        local maxPerRow = math.floor((Settings.CANVAS_WIDTH - 100) / (iconSize + iconGap))
        local totalIcons = #destroyed
        local rows = math.ceil(totalIcons / maxPerRow)
        local maxRows = 4
        if rows > maxRows then rows = maxRows end

        for row = 1, rows do
            local startIdx = (row - 1) * maxPerRow + 1
            local endIdx = math.min(row * maxPerRow, totalIcons)
            local count = endIdx - startIdx + 1
            local rowWidth = count * (iconSize + iconGap) - iconGap
            local startX = (Settings.CANVAS_WIDTH - rowWidth) / 2

            for i = startIdx, endIdx do
                local p = destroyed[i]
                local px = startX + (i - startIdx) * (iconSize + iconGap)
                if p.image then
                    local iw, ih = p.image:getDimensions()
                    local sx = iconSize / iw
                    local sy = iconSize / ih
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(p.image, px, y, 0, sx, sy)
                end
            end
            y = y + iconSize + 3
        end

        if totalIcons > maxRows * maxPerRow then
            love.graphics.setFont(fonts.tiny)
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            local moreText = "+" .. (totalIcons - maxRows * maxPerRow) .. " more..."
            local mw = fonts.tiny:getWidth(moreText)
            love.graphics.print(moreText, (Settings.CANVAS_WIDTH - mw) / 2, y)
            y = y + 16
        end

        y = y + 6

        -- Summary: Planet x count
        local counts = {}
        local order = {}
        for _, p in ipairs(destroyed) do
            local name = p.name or "???"
            if not counts[name] then
                counts[name] = 0
                table.insert(order, name)
            end
            counts[name] = counts[name] + 1
        end

        love.graphics.setFont(fonts.tiny)
        local summaryParts = {}
        for _, name in ipairs(order) do
            table.insert(summaryParts, name .. " x" .. counts[name])
        end
        local summaryText = table.concat(summaryParts, "  ")
        local sumW = fonts.tiny:getWidth(summaryText)

        if sumW > Settings.CANVAS_WIDTH - 60 then
            -- Wrap into two lines
            local half = math.ceil(#summaryParts / 2)
            local line1 = table.concat(summaryParts, "  ", 1, half)
            local line2 = table.concat(summaryParts, "  ", half + 1)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            local l1w = fonts.tiny:getWidth(line1)
            love.graphics.print(line1, (Settings.CANVAS_WIDTH - l1w) / 2, y)
            y = y + 14
            local l2w = fonts.tiny:getWidth(line2)
            love.graphics.print(line2, (Settings.CANVAS_WIDTH - l2w) / 2, y)
            y = y + 14
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.print(summaryText, (Settings.CANVAS_WIDTH - sumW) / 2, y)
            y = y + 14
        end
    end

    y = y + 15

    -- Buttons (dynamic position)
    local bw, bh = 240, 44
    local bx = cx - bw / 2
    playAgainBtn.x, playAgainBtn.y = bx, y
    titleBtn.x, titleBtn.y = bx, y + 55

    playAgainBtn:draw()
    titleBtn:draw()

    -- Enter key hint next to Play Again
    local kx = playAgainBtn.x + playAgainBtn.w + 12
    local ky = playAgainBtn.y + (playAgainBtn.h - 20) / 2
    local kw, kh = 56, 20
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    love.graphics.rectangle("line", kx, ky, kw, kh, 4, 4)
    love.graphics.setFont(fonts.tiny)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local label = "Enter"
    local lw = fonts.tiny:getWidth(label)
    love.graphics.print(label, kx + (kw - lw) / 2, ky + (kh - fonts.tiny:getHeight()) / 2)

    -- Esc key hint next to Title
    local ex = titleBtn.x + titleBtn.w + 12
    local ey = titleBtn.y + (titleBtn.h - 20) / 2
    local ew = 40
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    love.graphics.rectangle("line", ex, ey, ew, kh, 4, 4)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local escLabel = "Esc"
    local elw = fonts.tiny:getWidth(escLabel)
    love.graphics.print(escLabel, ex + (ew - elw) / 2, ey + (kh - fonts.tiny:getHeight()) / 2)
end

function GameOver.textinput(text)
    if phase ~= "input" then return end

    -- Only allow A-Z
    local ch = text:upper()
    if ch:match("^[A-Z]$") and #inputName < MAX_NAME_LEN then
        inputName = inputName .. ch
    end
end

function GameOver.keypressed(key)
    if phase == "input" then
        if key == "backspace" then
            if #inputName > 0 then
                inputName = inputName:sub(1, -2)
            end
            return nil
        elseif key == "return" or key == "kpenter" then
            if #inputName >= MIN_NAME_LEN then
                -- Confirm name - return special action with name
                phase = "result"
                return "name_confirmed", inputName
            end
            return nil
        end
        -- Block other actions during input
        return nil
    end

    -- Result phase
    if key == "space" or key == "return" then
        return "play"
    end
    return nil
end

function GameOver.mousepressed(x, y, button)
    if phase == "input" then return nil end

    if button == 1 then
        if playAgainBtn:isClicked(x, y) then
            return "play"
        elseif titleBtn:isClicked(x, y) then
            return "title"
        end
    end
    return nil
end

function GameOver.getPhase()
    return phase
end

return GameOver
