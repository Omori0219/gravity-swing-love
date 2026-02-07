local Settings = require("settings")

local Planet = {}

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
    -- Earth body (blue-green circle)
    love.graphics.setColor(0.2, 0.5, 0.9, 1)
    love.graphics.circle("fill", planet.x, planet.y, planet.radius)

    -- Landmass shapes (green patches)
    love.graphics.setColor(0.2, 0.7, 0.3, 0.8)
    love.graphics.circle("fill", planet.x - 4, planet.y - 3, 7)
    love.graphics.circle("fill", planet.x + 6, planet.y + 5, 5)
    love.graphics.circle("fill", planet.x - 2, planet.y + 8, 4)

    -- Atmosphere glow
    love.graphics.setColor(0.4, 0.7, 1.0, 0.15)
    love.graphics.circle("fill", planet.x, planet.y, planet.radius + 4)

    love.graphics.setColor(1, 1, 1, 1)
end

return Planet
