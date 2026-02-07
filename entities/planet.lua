local Settings = require("settings")

local Planet = {}

local earthImage = nil
local imgW, imgH = 0, 0

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

function Planet.updatePosition(planet, mx, my)
    planet.x = math.max(planet.radius, math.min(Settings.CANVAS_WIDTH - planet.radius, mx))
    planet.y = math.max(planet.radius, math.min(Settings.CANVAS_HEIGHT - planet.radius, my))
end

function Planet.draw(planet)
    -- Atmosphere glow
    love.graphics.setColor(0.4, 0.7, 1.0, 0.15)
    love.graphics.circle("fill", planet.x, planet.y, planet.radius + 3)

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
