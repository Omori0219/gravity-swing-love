local Settings = require("settings")
local Stars = require("systems.stars")
local Button = require("ui.button")
local Slider = require("ui.slider")
local Audio = require("systems.audio")

local Options = {}

local bgmSlider, sfxSlider, backBtn
local fonts

function Options.enter(f)
    fonts = f
    local sliderW = 300
    local sx = Settings.CANVAS_WIDTH / 2 - sliderW / 2

    bgmSlider = Slider.new("BGM Volume", sx, 260, sliderW, 16, Audio.bgmVolume, fonts.small)
    sfxSlider = Slider.new("SFX Volume", sx, 340, sliderW, 16, Audio.sfxVolume, fonts.small)

    local bw = 180
    backBtn = Button.new("Back", Settings.CANVAS_WIDTH / 2 - bw / 2, 440, bw, 40, Settings.COLORS.GRAY, fonts.small)
end

function Options.update(dt)
    local mx, my = love.mouse.getPosition()
    bgmSlider:updateHover(mx, my)
    sfxSlider:updateHover(mx, my)
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

    -- Back button
    backBtn:draw()

    love.graphics.setColor(1, 1, 1, 1)
end

function Options.mousepressed(x, y, button)
    bgmSlider:mousepressed(x, y, button)
    sfxSlider:mousepressed(x, y, button)

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

return Options
