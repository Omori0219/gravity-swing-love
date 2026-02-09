local Settings = require("settings")
local Stars = require("systems.stars")
local Button = require("ui.button")
local KeyMap = require("ui.keymap")

local Title = {}

local startBtn, optionsBtn
local fonts
local rankingList = {}
local buttons = {}
local selectedIndex = 1

function Title.enter(f, ranking)
    fonts = f
    rankingList = ranking or {}
    local bw, bh = 240, 44
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    startBtn = Button.new("Start", cx, 380, bw, bh, Settings.COLORS.GREEN, fonts.medium)
    optionsBtn = Button.new("Options", cx, 435, bw, 36, Settings.COLORS.BLUE, fonts.small)
    buttons = { startBtn, optionsBtn }
    selectedIndex = 1
    Title._updateSelection()
end

function Title._updateSelection()
    for i, btn in ipairs(buttons) do
        btn.selected = (i == selectedIndex)
    end
end

function Title.update(dt)
    local mx, my = love.mouse.getPosition()
    startBtn:updateHover(mx, my)
    optionsBtn:updateHover(mx, my)
end

function Title.draw()
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

    -- Ranking
    drawRanking()

    -- Buttons
    startBtn:draw()
    optionsBtn:draw()

    -- Enter key hint next to selected button
    love.graphics.setFont(fonts.tiny)
    local kh = 20
    local selBtn = buttons[selectedIndex]
    local kx = selBtn.x + selBtn.w + 12
    local ky = selBtn.y + (selBtn.h - kh) / 2
    local kw = 56
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    love.graphics.rectangle("line", kx, ky, kw, kh, 4, 4)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local enterLabel = "Enter"
    local elw = fonts.tiny:getWidth(enterLabel)
    love.graphics.print(enterLabel, kx + (kw - elw) / 2, ky + (kh - fonts.tiny:getHeight()) / 2)

    -- Copyright
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.setFont(fonts.tiny)
    local cpText = "2025 CAEN Inc."
    local cw = fonts.tiny:getWidth(cpText)
    love.graphics.print(cpText, (Settings.CANVAS_WIDTH - cw) / 2, Settings.CANVAS_HEIGHT - 30)

    love.graphics.setColor(1, 1, 1, 1)
end

function drawRanking()
    local cx = Settings.CANVAS_WIDTH / 2

    -- Header
    love.graphics.setColor(Settings.COLORS.GOLD)
    love.graphics.setFont(fonts.small)
    local header = "RANKING"
    local hw = fonts.small:getWidth(header)
    love.graphics.print(header, (Settings.CANVAS_WIDTH - hw) / 2, 220)

    -- Entries
    love.graphics.setFont(fonts.tiny)
    local startY = 240
    local lineH = 13

    for i = 1, 10 do
        local y = startY + (i - 1) * lineH
        local entry = rankingList[i]

        if entry then
            -- Rank number
            if i == 1 then
                love.graphics.setColor(Settings.COLORS.GOLD)
            elseif i == 2 then
                love.graphics.setColor(0.75, 0.75, 0.75, 1)
            elseif i == 3 then
                love.graphics.setColor(0.80, 0.50, 0.20, 1)
            else
                love.graphics.setColor(0.6, 0.6, 0.6, 1)
            end

            local rank = string.format("%02d", i)
            local name = entry.name
            local score = tostring(entry.score)

            -- Format: "01. AAA     1234"
            local line = rank .. ". " .. name .. string.rep(" ", 5 - #name) .. "  " .. score
            local lw = fonts.tiny:getWidth(line)
            love.graphics.print(line, (Settings.CANVAS_WIDTH - lw) / 2, y)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            local line = string.format("%02d. ---      0", i)
            local lw = fonts.tiny:getWidth(line)
            love.graphics.print(line, (Settings.CANVAS_WIDTH - lw) / 2, y)
        end
    end
end

function Title.mousepressed(x, y, button)
    if button == 1 then
        if startBtn:isClicked(x, y) then
            return "play"
        end
        if optionsBtn:isClicked(x, y) then
            return "options"
        end
    end
    return nil
end

function Title.keypressed(key)
    if KeyMap.isUp(key) then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = #buttons end
        Title._updateSelection()
        return nil
    elseif KeyMap.isDown(key) then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #buttons then selectedIndex = 1 end
        Title._updateSelection()
        return nil
    end

    if KeyMap.isConfirm(key) then
        if selectedIndex == 1 then return "play" end
        if selectedIndex == 2 then return "options" end
    end
    return nil
end

return Title
