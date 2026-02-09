local Settings = require("settings")
local push = require("lib.push")
local Stars = require("systems.stars")
local Button = require("ui.button")
local Slider = require("ui.slider")
local Audio = require("systems.audio")
local Save = require("lib.save")
local KeyMap = require("ui.keymap")

local Options = {}

local bgmSlider, sfxSlider
local fullscreenBtn, eternalBtn, backBtn
local sizeButtons = {}
local fonts
local eternalMode = false
local isFullscreen = false

local WINDOW_SIZES = {
    { w = 800,  h = 600,  label = "800x600" },
    { w = 1200, h = 900,  label = "1200x900" },
    { w = 1600, h = 1200, label = "1600x1200" },
}
local currentSizeIndex = 2  -- default: 1200x900
local selectedSizeIndex = 2 -- cursor position (may differ from currentSizeIndex)

-- Navigation: rows are "fullscreen", "size", "eternal", "back"
local NAV_ROWS = { "fullscreen", "size", "eternal", "back" }
local selectedRow = 1

function Options.enter(f)
    fonts = f
    eternalMode = Save.readEternalMode()
    isFullscreen = love.window.getFullscreen()

    -- Detect current window size
    local curW, curH = love.window.getMode()
    for i, size in ipairs(WINDOW_SIZES) do
        if curW == size.w and curH == size.h then
            currentSizeIndex = i
            break
        end
    end

    local sliderW = 300
    local sx = Settings.CANVAS_WIDTH / 2 - sliderW / 2

    bgmSlider = Slider.new("BGM Volume", sx, 200, sliderW, 16, Audio.bgmVolume, fonts.small)
    sfxSlider = Slider.new("SFX Volume", sx, 270, sliderW, 16, Audio.sfxVolume, fonts.small)

    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2

    Options._makeFullscreenBtn(cx, 350, bw)
    selectedSizeIndex = currentSizeIndex
    Options._makeSizeButtons(410)
    eternalBtn = Options._makeEternalBtn(cx, 480, bw)

    local backW = 180
    backBtn = Button.new("Back", Settings.CANVAS_WIDTH / 2 - backW / 2, 560, backW, 40, Settings.COLORS.GRAY, fonts.small)

    selectedRow = 1
    Options._updateSelection()
end

function Options._makeFullscreenBtn(x, y, w)
    if isFullscreen then
        fullscreenBtn = Button.new("Fullscreen: ON", x, y, w, 40, {0.275, 0.510, 0.706}, fonts.small)
    else
        fullscreenBtn = Button.new("Fullscreen: OFF", x, y, w, 40, {0.4, 0.4, 0.4}, fonts.small)
    end
    Options._updateSelection()
end

function Options._makeSizeButtons(y)
    sizeButtons = {}
    local btnW = 90
    local gap = 10
    local totalW = #WINDOW_SIZES * btnW + (#WINDOW_SIZES - 1) * gap
    local startX = Settings.CANVAS_WIDTH / 2 - totalW / 2

    for i, size in ipairs(WINDOW_SIZES) do
        local x = startX + (i - 1) * (btnW + gap)
        local color
        if isFullscreen then
            color = {0.25, 0.25, 0.25}
        elseif i == currentSizeIndex then
            color = {0.275, 0.510, 0.706}
        else
            color = {0.4, 0.4, 0.4}
        end
        sizeButtons[i] = Button.new(size.label, x, y, btnW, 36, color, fonts.tiny)
    end
    Options._updateSelection()
end

function Options._makeEternalBtn(x, y, w)
    local btn
    if eternalMode then
        btn = Button.new("Eternal Mode: ON", x, y, w, 40, {0.9, 0.55, 0.1}, fonts.small)
    else
        btn = Button.new("Eternal Mode: OFF", x, y, w, 40, {0.4, 0.4, 0.4}, fonts.small)
    end
    return btn
end

function Options._updateSelection()
    -- Clear all
    if fullscreenBtn then fullscreenBtn.selected = false end
    for _, btn in ipairs(sizeButtons) do btn.selected = false end
    if eternalBtn then eternalBtn.selected = false end
    if backBtn then backBtn.selected = false end

    local row = NAV_ROWS[selectedRow]
    if row == "fullscreen" then
        if fullscreenBtn then fullscreenBtn.selected = true end
    elseif row == "size" then
        if sizeButtons[selectedSizeIndex] then
            sizeButtons[selectedSizeIndex].selected = true
        end
    elseif row == "eternal" then
        if eternalBtn then eternalBtn.selected = true end
    elseif row == "back" then
        if backBtn then backBtn.selected = true end
    end
end

function Options.update(dt)
    local mx, my = love.mouse.getPosition()
    bgmSlider:updateHover(mx, my)
    sfxSlider:updateHover(mx, my)
    fullscreenBtn:updateHover(mx, my)
    for _, btn in ipairs(sizeButtons) do
        btn:updateHover(mx, my)
    end
    eternalBtn:updateHover(mx, my)
    backBtn:updateHover(mx, my)

    -- Apply volume changes in real time
    Audio.setBGMVolume(bgmSlider.value)
    Audio.setSFXVolume(sfxSlider.value)
end

function Options.draw()
    -- Background
    love.graphics.setColor(Settings.COLORS.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)
    Stars.draw()

    -- Header
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.large)
    local title = "Options"
    local tw = fonts.large:getWidth(title)
    love.graphics.print(title, (Settings.CANVAS_WIDTH - tw) / 2, 100)

    -- Sliders
    bgmSlider:draw()
    sfxSlider:draw()

    -- Fullscreen toggle
    fullscreenBtn:draw()

    -- Window size label
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(isFullscreen and {0.4, 0.4, 0.4, 1} or {1, 1, 1, 1})
    local sizeLabel = "Window Size"
    local slw = fonts.small:getWidth(sizeLabel)
    love.graphics.print(sizeLabel, (Settings.CANVAS_WIDTH - slw) / 2, 388)

    -- Window size buttons
    for _, btn in ipairs(sizeButtons) do
        btn:draw()
    end

    -- Eternal mode toggle
    eternalBtn:draw()

    -- Back button
    backBtn:draw()

    love.graphics.setColor(1, 1, 1, 1)
end

function Options.mousepressed(x, y, button)
    bgmSlider:mousepressed(x, y, button)
    sfxSlider:mousepressed(x, y, button)

    if button == 1 and fullscreenBtn:isClicked(x, y) then
        Audio.playConfirm()
        Options._toggleFullscreen()
    end

    if button == 1 and not isFullscreen then
        for i, btn in ipairs(sizeButtons) do
            if btn:isClicked(x, y) then
                Audio.playConfirm()
                Options._selectSize(i)
                break
            end
        end
    end

    if button == 1 and eternalBtn:isClicked(x, y) then
        Audio.playConfirm()
        Options._toggleEternal()
    end

    if button == 1 and backBtn:isClicked(x, y) then
        Audio.playCancel()
        Audio.saveVolumes()
        return "back"
    end
    return nil
end

function Options._toggleFullscreen()
    push:switchFullscreen()
    isFullscreen = love.window.getFullscreen()
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    Options._makeFullscreenBtn(cx, 350, bw)
    Options._makeSizeButtons(410)
    Options._saveDisplay()
end

function Options._selectSize(i)
    currentSizeIndex = i
    local size = WINDOW_SIZES[i]
    love.window.setMode(size.w, size.h, { resizable = true, highdpi = true })
    push:resize(size.w, size.h)
    Options._makeSizeButtons(410)
    Options._saveDisplay()
end

function Options._toggleEternal()
    eternalMode = not eternalMode
    Save.writeEternalMode(eternalMode)
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    eternalBtn = Options._makeEternalBtn(cx, 480, bw)
    Options._updateSelection()
end

function Options._saveDisplay()
    local size = WINDOW_SIZES[currentSizeIndex]
    Save.writeDisplay(isFullscreen, size.w, size.h)
end

function Options.mousemoved(x, y)
    bgmSlider:mousemoved(x, y)
    sfxSlider:mousemoved(x, y)
end

function Options.mousereleased(x, y, button)
    bgmSlider:mousereleased()
    sfxSlider:mousereleased()
end

function Options.keypressed(key)
    if KeyMap.isUp(key) then
        selectedRow = selectedRow - 1
        if selectedRow < 1 then selectedRow = #NAV_ROWS end
        Options._updateSelection()
        Audio.playCursor()
        return nil
    elseif KeyMap.isDown(key) then
        selectedRow = selectedRow + 1
        if selectedRow > #NAV_ROWS then selectedRow = 1 end
        Options._updateSelection()
        Audio.playCursor()
        return nil
    end

    -- Left/right for size row (move cursor only, no apply)
    local row = NAV_ROWS[selectedRow]
    if row == "size" and not isFullscreen then
        if KeyMap.isLeft(key) then
            selectedSizeIndex = selectedSizeIndex - 1
            if selectedSizeIndex < 1 then selectedSizeIndex = #WINDOW_SIZES end
            Options._updateSelection()
            Audio.playCursor()
            return nil
        elseif KeyMap.isRight(key) then
            selectedSizeIndex = selectedSizeIndex + 1
            if selectedSizeIndex > #WINDOW_SIZES then selectedSizeIndex = 1 end
            Options._updateSelection()
            Audio.playCursor()
            return nil
        end
    end

    if KeyMap.isConfirm(key) then
        Audio.playConfirm()
        if row == "fullscreen" then
            Options._toggleFullscreen()
        elseif row == "size" and not isFullscreen then
            Options._selectSize(selectedSizeIndex)
        elseif row == "eternal" then
            Options._toggleEternal()
        elseif row == "back" then
            Audio.saveVolumes()
            return "back"
        end
        return nil
    end

    if KeyMap.isCancel(key) then
        Audio.playCancel()
        Audio.saveVolumes()
        return "back"
    end
    return nil
end

function Options.isEternalMode()
    return eternalMode
end

return Options
