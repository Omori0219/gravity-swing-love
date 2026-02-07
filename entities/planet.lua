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
    -- Earth body
    love.graphics.setColor(0.2, 0.5, 0.9, 1)
    love.graphics.circle("fill", planet.x, planet.y, planet.radius)

    -- Atmosphere glow
    love.graphics.setColor(0.4, 0.7, 1.0, 0.15)
    love.graphics.circle("fill", planet.x, planet.y, planet.radius + 3)

    love.graphics.setColor(1, 1, 1, 1)
end

return Planet
