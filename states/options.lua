local Settings = require("settings")
local push = require("lib.push")
local Stars = require("systems.stars")
local Button = require("ui.button")
local Slider = require("ui.slider")
local Audio = require("systems.audio")
local Save = require("lib.save")
local KeyMap = require("ui.keymap")

local Asteroid = require("entities.asteroid")

local Options = {}

local bgmSlider, sfxSlider
local fullscreenBtn, eternalBtn, catModeBtn, catNameBtn, backBtn
local sizeButtons = {}
local fonts
local eternalMode = false
local gameMode = "normal"  -- "normal", "cat", "chaos"
local isFullscreen = false
local fromPause = false
local catNameIndex = 1  -- index into catNames list
local editingCatName = false
local editBuffer = ""
local CAT_NAME_MAX_LEN = 12

local WINDOW_SIZES = {
    { w = 800,  h = 600,  label = "800x600" },
    { w = 1200, h = 900,  label = "1200x900" },
    { w = 1600, h = 1200, label = "1600x1200" },
}
local currentSizeIndex = 2  -- default: 1200x900
local selectedSizeIndex = 2 -- cursor position (may differ from currentSizeIndex)

-- Navigation: rows are "fullscreen", "size", "eternal", "catmode", "catname", "back"
local NAV_ROWS = { "fullscreen", "size", "eternal", "catmode", "catname", "back" }
local selectedRow = 1

function Options.enter(f, isPaused)
    fonts = f
    fromPause = isPaused or false
    eternalMode = Save.readEternalMode()
    gameMode = Save.readGameMode()
    Asteroid.setGameMode(gameMode)
    Stars.setGameMode(gameMode)
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
    catModeBtn = Options._makeGameModeBtn(cx, 550, bw)

    -- Restore chosen cat name index
    local names = Asteroid.getCatNames()
    local saved = Asteroid.getChosenCatName()
    catNameIndex = 1
    if saved then
        for i, n in ipairs(names) do
            if n == saved then catNameIndex = i; break end
        end
    end
    catNameBtn = Options._makeCatNameBtn(cx, 620, bw)

    local backW = 180
    backBtn = Button.new("Back", Settings.CANVAS_WIDTH / 2 - backW / 2, 700, backW, 40, Settings.COLORS.GRAY, fonts.small)

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
    if fromPause then
        local label = eternalMode and "Eternal Mode: ON" or "Eternal Mode: OFF"
        btn = Button.new(label, x, y, w, 40, {0.25, 0.25, 0.25}, fonts.small)
    elseif eternalMode then
        btn = Button.new("Eternal Mode: ON", x, y, w, 40, {0.9, 0.55, 0.1}, fonts.small)
    else
        btn = Button.new("Eternal Mode: OFF", x, y, w, 40, {0.4, 0.4, 0.4}, fonts.small)
    end
    return btn
end

function Options._makeGameModeBtn(x, y, w)
    if gameMode == "chaos" then
        return Button.new("Mode: Chaos", x, y, w, 40, {0.9, 0.2, 0.2}, fonts.small)
    elseif gameMode == "cat" then
        return Button.new("Mode: Cat", x, y, w, 40, {0.9, 0.4, 0.6}, fonts.small)
    else
        return Button.new("Mode: Normal", x, y, w, 40, {0.4, 0.4, 0.4}, fonts.small)
    end
end

function Options._makeCatNameBtn(x, y, w)
    local label
    if editingCatName then
        local cursor = math.floor(love.timer.getTime() * 2) % 2 == 0 and "_" or ""
        label = "Cat: " .. editBuffer .. cursor
    else
        local currentName = Asteroid.getChosenCatName()
        if currentName then
            label = "Cat: " .. currentName
        else
            local names = Asteroid.getCatNames()
            label = "Cat: " .. (names[catNameIndex] or "Mochi")
        end
    end
    if gameMode == "normal" then
        return Button.new(label, x, y, w, 40, {0.25, 0.25, 0.25}, fonts.small)
    elseif editingCatName then
        return Button.new(label, x, y, w, 40, {0.7, 0.4, 0.8}, fonts.small)
    else
        return Button.new(label, x, y, w, 40, {0.5, 0.3, 0.6}, fonts.small)
    end
end

function Options._updateSelection()
    -- Clear all
    if fullscreenBtn then fullscreenBtn.selected = false end
    for _, btn in ipairs(sizeButtons) do btn.selected = false end
    if eternalBtn then eternalBtn.selected = false end
    if catModeBtn then catModeBtn.selected = false end
    if catNameBtn then catNameBtn.selected = false end
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
    elseif row == "catmode" then
        if catModeBtn then catModeBtn.selected = true end
    elseif row == "catname" then
        if catNameBtn then catNameBtn.selected = true end
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
    catModeBtn:updateHover(mx, my)
    catNameBtn:updateHover(mx, my)
    backBtn:updateHover(mx, my)

    -- Apply volume changes in real time
    Audio.setBGMVolume(bgmSlider.value)
    Audio.setSFXVolume(sfxSlider.value)

    -- Refresh cat name button for blinking cursor
    if editingCatName then
        local bw = 300
        local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
        catNameBtn = Options._makeCatNameBtn(cx, 620, bw)
        Options._updateSelection()
    end
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

    -- Cat mode toggle
    catModeBtn:draw()

    -- Cat name selector
    catNameBtn:draw()

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

    if button == 1 and not fromPause and eternalBtn:isClicked(x, y) then
        Audio.playConfirm()
        Options._toggleEternal()
    end

    if button == 1 and catModeBtn:isClicked(x, y) then
        Audio.playConfirm()
        Options._cycleGameMode()
    end

    if button == 1 and gameMode ~= "normal" and catNameBtn:isClicked(x, y) then
        if editingCatName then
            Audio.playConfirm()
            Options._confirmEditCatName()
        else
            Audio.playConfirm()
            Options._startEditCatName()
        end
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

function Options._cycleGameMode()
    if gameMode == "normal" then
        gameMode = "cat"
    elseif gameMode == "cat" then
        gameMode = "chaos"
    else
        gameMode = "normal"
    end
    Save.writeGameMode(gameMode)
    Asteroid.setGameMode(gameMode)
    Stars.setGameMode(gameMode)
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    catModeBtn = Options._makeGameModeBtn(cx, 550, bw)
    catNameBtn = Options._makeCatNameBtn(cx, 620, bw)
    Options._updateSelection()
end

function Options._cycleCatName(dir)
    if editingCatName then return end
    local names = Asteroid.getCatNames()
    catNameIndex = catNameIndex + dir
    if catNameIndex > #names then catNameIndex = 1 end
    if catNameIndex < 1 then catNameIndex = #names end
    local name = names[catNameIndex]
    Asteroid.setChosenCatName(name)
    Save.writeCatName(name)
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    catNameBtn = Options._makeCatNameBtn(cx, 620, bw)
    Options._updateSelection()
end

function Options._startEditCatName()
    editingCatName = true
    editBuffer = Asteroid.getChosenCatName() or ""
    love.keyboard.setTextInput(true)
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    catNameBtn = Options._makeCatNameBtn(cx, 620, bw)
    Options._updateSelection()
end

function Options._confirmEditCatName()
    editingCatName = false
    love.keyboard.setTextInput(false)
    local name = editBuffer
    if name == "" then
        name = Asteroid.getCatNames()[catNameIndex]
    end
    Asteroid.setChosenCatName(name)
    Save.writeCatName(name)
    -- Update catNameIndex if name matches a preset
    local names = Asteroid.getCatNames()
    for i, n in ipairs(names) do
        if n == name then catNameIndex = i; break end
    end
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    catNameBtn = Options._makeCatNameBtn(cx, 620, bw)
    Options._updateSelection()
end

function Options._cancelEditCatName()
    editingCatName = false
    love.keyboard.setTextInput(false)
    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    catNameBtn = Options._makeCatNameBtn(cx, 620, bw)
    Options._updateSelection()
end

function Options.textinput(text)
    if not editingCatName then return end
    if #editBuffer < CAT_NAME_MAX_LEN then
        editBuffer = editBuffer .. text
    end
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
    -- Text editing mode: intercept keys
    if editingCatName then
        if key == "backspace" then
            if #editBuffer > 0 then
                editBuffer = editBuffer:sub(1, -2)
            end
            return nil
        elseif key == "return" or key == "kpenter" then
            Audio.playConfirm()
            Options._confirmEditCatName()
            return nil
        elseif key == "escape" then
            Audio.playCancel()
            Options._cancelEditCatName()
            return nil
        end
        return nil
    end

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

    -- Left/right for cat name row
    if row == "catname" and gameMode ~= "normal" then
        if KeyMap.isLeft(key) then
            Options._cycleCatName(-1)
            Audio.playCursor()
            return nil
        elseif KeyMap.isRight(key) then
            Options._cycleCatName(1)
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
        elseif row == "eternal" and not fromPause then
            Options._toggleEternal()
        elseif row == "catmode" then
            Options._cycleGameMode()
        elseif row == "catname" and gameMode ~= "normal" then
            Options._startEditCatName()
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
