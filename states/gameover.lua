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
    love.graphics.setColor(0, 0, 0, 0.55)
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

    -- Buttons
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
