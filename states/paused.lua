local Settings = require("settings")
local Button = require("ui.button")
local KeyMap = require("ui.keymap")
local Audio = require("systems.audio")

local Paused = {}
local fonts
local resumeBtn, quitBtn
local buttons = {}
local selectedIndex = 1

function Paused.enter(f)
    fonts = f
    local bw = 260
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    local cy = Settings.CANVAS_HEIGHT / 2

    resumeBtn = Button.new("Resume", cx, cy + 10, bw, 40, Settings.COLORS.GREEN, fonts.small)
    quitBtn = Button.new("Back to Title", cx, cy + 64, bw, 40, Settings.COLORS.GRAY, fonts.small)
    buttons = { resumeBtn, quitBtn }
    selectedIndex = 1
    Paused._updateSelection()
end

function Paused._updateSelection()
    for i, btn in ipairs(buttons) do
        btn.selected = (i == selectedIndex)
    end
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

    love.graphics.setColor(1, 1, 1, 1)
end

function Paused.keypressed(key)
    if KeyMap.isUp(key) then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = #buttons end
        Paused._updateSelection()
        Audio.playCursor()
        return nil
    elseif KeyMap.isDown(key) then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #buttons then selectedIndex = 1 end
        Paused._updateSelection()
        Audio.playCursor()
        return nil
    end

    if KeyMap.isConfirm(key) then
        Audio.playConfirm()
        if selectedIndex == 1 then return "resume" end
        if selectedIndex == 2 then return "quit" end
    end

    if KeyMap.isCancel(key) then
        Audio.playCancel()
        return "resume"
    end
    return nil
end

function Paused.mousepressed(x, y, button)
    if button == 1 and resumeBtn:isClicked(x, y) then
        Audio.playConfirm()
        return "resume"
    end
    if button == 1 and quitBtn:isClicked(x, y) then
        Audio.playConfirm()
        return "quit"
    end
    return nil
end

return Paused
