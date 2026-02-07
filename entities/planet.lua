local Settings = require("settings")

local Planet = {}

local earthImage = nil
local imgW, imgH = 0, 0
local glowTimer = 0

function Planet.loadImage()
    local ok, img = pcall(love.graphics.newImage, "assets/images/Earth.png")
    if ok then
        earthImage = img
        earthImage:setFilter("linear", "linear")
        imgW, imgH = earthImage:getDimensions()
    end
end

function Planet.new()
    return {
        x = Settings.CANVAS_WIDTH / 2,
        y = Settings.CANVAS_HEIGHT / 2,
        radius = Settings.PLANET_RADIUS,
        mass = Settings.PLANET_MASS,
        suckInRadius = Settings.PLANET_SUCK_IN_RADIUS,
    }
end

function Planet.update(dt)
    glowTimer = glowTimer + dt
end

function Planet.updatePosition(planet, mx, my)
    planet.x = math.max(planet.radius, math.min(Settings.CANVAS_WIDTH - planet.radius, mx))
    planet.y = math.max(planet.radius, math.min(Settings.CANVAS_HEIGHT - planet.radius, my))
end

function Planet.draw(planet)
    local r = planet.radius
    local pulse = 0.5 + 0.5 * math.sin(glowTimer * Settings.PLANET_GLOW_PULSE_SPEED)
    local gc = Settings.PLANET_GLOW_COLOR
    local layers = Settings.PLANET_GLOW_LAYERS
    local spread = Settings.PLANET_GLOW_SPREAD
    local peakAlpha = Settings.PLANET_GLOW_ALPHA

    -- Pulsing glow
    for i = layers, 1, -1 do
        local t = i / layers
        local glowR = r + (r * (spread - 1)) * t
        local alpha = peakAlpha * (1 - t) * (0.6 + 0.4 * pulse)
        love.graphics.setColor(gc[1], gc[2], gc[3], alpha)
        love.graphics.circle("fill", planet.x, planet.y, glowR)
    end

    if earthImage then
        local diameter = planet.radius * 2
        local sx = diameter / imgW
        local sy = diameter / imgH
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(earthImage,
            planet.x - planet.radius, planet.y - planet.radius, 0, sx, sy)
    else
        love.graphics.setColor(0.2, 0.5, 0.9, 1)
        love.graphics.circle("fill", planet.x, planet.y, planet.radius)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Planet
