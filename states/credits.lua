local Settings = require("settings")
local Stars = require("systems.stars")
local Button = require("ui.button")
local KeyMap = require("ui.keymap")
local Audio = require("systems.audio")

local Credits = {}

local backBtn
local fonts

function Credits.enter(f)
    fonts = f
    local backW = 180
    backBtn = Button.new("Back", Settings.CANVAS_WIDTH / 2 - backW / 2, 560, backW, 40, Settings.COLORS.GRAY, fonts.small)
    backBtn.selected = true
end

function Credits.update(dt)
    local mx, my = love.mouse.getPosition()
    backBtn:updateHover(mx, my)
end

function Credits.draw()
    -- Background
    love.graphics.setColor(Settings.COLORS.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)
    Stars.draw()

    local cx = Settings.CANVAS_WIDTH / 2

    -- Header
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.large)
    local title = "Credits"
    local tw = fonts.large:getWidth(title)
    love.graphics.print(title, cx - tw / 2, 100)

    -- Game title
    love.graphics.setColor(Settings.COLORS.GOLD)
    love.graphics.setFont(fonts.medium)
    local gameTitle = "Gravity Swing"
    local gtw = fonts.medium:getWidth(gameTitle)
    love.graphics.print(gameTitle, cx - gtw / 2, 200)

    -- Developed by
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    love.graphics.setFont(fonts.small)
    local devLabel = "Developed by"
    local dlw = fonts.small:getWidth(devLabel)
    love.graphics.print(devLabel, cx - dlw / 2, 280)

    -- Studio name
    love.graphics.setColor(Settings.COLORS.WHITE)
    love.graphics.setFont(fonts.medium)
    local studio = "CAEN Inc."
    local sw = fonts.medium:getWidth(studio)
    love.graphics.print(studio, cx - sw / 2, 310)

    -- Built with
    love.graphics.setColor(0.667, 0.667, 0.667, 1)
    love.graphics.setFont(fonts.small)
    local builtWith = "Built with LOVE2D"
    local bww = fonts.small:getWidth(builtWith)
    love.graphics.print(builtWith, cx - bww / 2, 400)

    -- Copyright
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.setFont(fonts.tiny)
    local copyright = "2025 CAEN Inc."
    local cw = fonts.tiny:getWidth(copyright)
    love.graphics.print(copyright, cx - cw / 2, 480)

    -- Back button
    backBtn:draw()

    love.graphics.setColor(1, 1, 1, 1)
end

function Credits.keypressed(key)
    if KeyMap.isConfirm(key) then
        Audio.playCancel()
        return "back"
    end

    if KeyMap.isCancel(key) then
        Audio.playCancel()
        return "back"
    end
    return nil
end

function Credits.mousepressed(x, y, button)
    if button == 1 and backBtn:isClicked(x, y) then
        Audio.playCancel()
        return "back"
    end
    return nil
end

return Credits
