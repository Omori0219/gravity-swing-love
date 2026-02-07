local Settings = require("settings")
local Stars = require("systems.stars")
local Button = require("ui.button")
local Slider = require("ui.slider")
local Audio = require("systems.audio")
local Save = require("lib.save")

local Options = {}

local bgmSlider, sfxSlider, eternalBtn, backBtn
local fonts
local eternalMode = false

function Options.enter(f)
    fonts = f
    eternalMode = Save.readEternalMode()

    local sliderW = 300
    local sx = Settings.CANVAS_WIDTH / 2 - sliderW / 2

    bgmSlider = Slider.new("BGM Volume", sx, 260, sliderW, 16, Audio.bgmVolume, fonts.small)
    sfxSlider = Slider.new("SFX Volume", sx, 340, sliderW, 16, Audio.sfxVolume, fonts.small)

    local bw = 300
    local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
    eternalBtn = Options._makeEternalBtn(cx, 420, bw)

    local backW = 180
    backBtn = Button.new("Back", Settings.CANVAS_WIDTH / 2 - backW / 2, 500, backW, 40, Settings.COLORS.GRAY, fonts.small)
end

function Options._makeEternalBtn(x, y, w)
    if eternalMode then
        return Button.new("Eternal Mode: ON", x, y, w, 40, {0.9, 0.55, 0.1}, fonts.small)
    else
        return Button.new("Eternal Mode: OFF", x, y, w, 40, {0.4, 0.4, 0.4}, fonts.small)
    end
end

function Options.update(dt)
    local mx, my = love.mouse.getPosition()
    bgmSlider:updateHover(mx, my)
    sfxSlider:updateHover(mx, my)
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
    love.graphics.print(title, (Settings.CANVAS_WIDTH - tw) / 2, 120)

    -- Sliders
    bgmSlider:draw()
    sfxSlider:draw()

    -- Eternal mode toggle
    eternalBtn:draw()

    -- Back button
    backBtn:draw()

    -- Esc key hint next to Back
    love.graphics.setFont(fonts.tiny)
    local kh = 20
    local kx = backBtn.x + backBtn.w + 12
    local ky = backBtn.y + (backBtn.h - kh) / 2
    local kw = 40
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
    love.graphics.rectangle("line", kx, ky, kw, kh, 4, 4)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local escLabel = "Esc"
    local elw = fonts.tiny:getWidth(escLabel)
    love.graphics.print(escLabel, kx + (kw - elw) / 2, ky + (kh - fonts.tiny:getHeight()) / 2)

    love.graphics.setColor(1, 1, 1, 1)
end

function Options.mousepressed(x, y, button)
    bgmSlider:mousepressed(x, y, button)
    sfxSlider:mousepressed(x, y, button)

    if button == 1 and eternalBtn:isClicked(x, y) then
        eternalMode = not eternalMode
        Save.writeEternalMode(eternalMode)
        local bw = 300
        local cx = Settings.CANVAS_WIDTH / 2 - bw / 2
        eternalBtn = Options._makeEternalBtn(cx, 420, bw)
    end

    if button == 1 and backBtn:isClicked(x, y) then
        Audio.saveVolumes()
        return "back"
    end
    return nil
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
    if key == "escape" then
        Audio.saveVolumes()
        return "back"
    end
    return nil
end

function Options.isEternalMode()
    return eternalMode
end

return Options
