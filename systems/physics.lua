local Settings = require("settings")

local Physics = {}

function Physics.applyGravity(asteroid, planet, dt)
    local dx = planet.x - asteroid.x
    local dy = planet.y - asteroid.y
    local distSq = dx * dx + dy * dy
    local dist = math.sqrt(distSq)
    local timeScale = dt * Settings.BASE_FPS * Settings.PHYSICS_TIME_SCALE

    if dist > 1 then
        local weight = asteroid.weightFactor or 1
        local force = (Settings.GRAVITY_CONSTANT * planet.mass) / distSq / weight
        local fx = (dx / dist) * force
        local fy = (dy / dist) * force

        -- Cap per-axis
        local maxF = Settings.MAX_GRAVITY_FORCE
        if math.abs(fx) > maxF then fx = (fx > 0 and maxF or -maxF) end
        if math.abs(fy) > maxF then fy = (fy > 0 and maxF or -maxF) end

        asteroid.vx = asteroid.vx + fx * timeScale
        asteroid.vy = asteroid.vy + fy * timeScale
    end

    asteroid.x = asteroid.x + asteroid.vx * timeScale
    asteroid.y = asteroid.y + asteroid.vy * timeScale
end

function Physics.getDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

return Physics
