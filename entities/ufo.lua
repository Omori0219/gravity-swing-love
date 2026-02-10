local Settings = require("settings")
local Asteroid = require("entities.asteroid")

local UFO = {}

local UFO_RADIUS = 20
local UFO_AMPLITUDE = 80
local UFO_FREQUENCY = 4

function UFO.new()
    local fromLeft = math.random(2) == 1
    local speed = Settings.ASTEROID_INITIAL_VX * Settings.ASTEROID_SPEED_MAX * 0.5
    local W = Settings.CANVAS_WIDTH
    local H = Settings.CANVAS_HEIGHT
    local baseY = H * 0.2 + math.random() * H * 0.6

    return {
        x = fromLeft and -40 or W + 40,
        y = baseY,
        baseY = baseY,
        vx = fromLeft and speed or -speed,
        elapsed = 0,
        radius = UFO_RADIUS,
        amplitude = UFO_AMPLITUDE,
        frequency = UFO_FREQUENCY,
    }
end

function UFO.update(ufo, dt)
    local timeScale = dt * Settings.BASE_FPS * Settings.PHYSICS_TIME_SCALE
    ufo.x = ufo.x + ufo.vx * timeScale
    ufo.elapsed = ufo.elapsed + dt
    ufo.y = ufo.baseY + ufo.amplitude * math.sin(ufo.frequency * ufo.elapsed)
end

function UFO.draw(ufo)
    if not ufo then return end
    if Asteroid.isCatMode() then
        UFO._drawFish(ufo)
    else
        UFO._drawSaucer(ufo)
    end
end

function UFO._drawSaucer(ufo)
    local x, y, r = ufo.x, ufo.y, ufo.radius

    -- Saucer body
    love.graphics.setColor(0.6, 0.65, 0.7, 0.9)
    love.graphics.ellipse("fill", x, y, r * 1.5, r * 0.5)

    -- Dome
    love.graphics.setColor(0.3, 0.8, 1, 0.7)
    love.graphics.ellipse("fill", x, y - r * 0.3, r * 0.7, r * 0.5)

    -- Pulsing lights around saucer
    local pulse = 0.5 + 0.5 * math.sin(ufo.elapsed * 8)
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2 + ufo.elapsed * 3
        local lx = x + math.cos(angle) * r * 1.2
        local ly = y + math.sin(angle) * r * 0.3
        love.graphics.setColor(1, 1, pulse, 0.9)
        love.graphics.circle("fill", lx, ly, 3)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function UFO._drawFish(ufo)
    local x, y, r = ufo.x, ufo.y, ufo.radius
    local dir = ufo.vx > 0 and 1 or -1

    -- Body (golden)
    love.graphics.setColor(1, 0.75, 0.2, 1)
    love.graphics.ellipse("fill", x, y, r * 1.3, r * 0.7)

    -- Tail
    love.graphics.setColor(1, 0.6, 0.1, 1)
    love.graphics.polygon("fill",
        x - dir * r * 1.2, y,
        x - dir * r * 2, y - r * 0.7,
        x - dir * r * 2, y + r * 0.7)

    -- Dorsal fin
    love.graphics.setColor(1, 0.65, 0.15, 1)
    love.graphics.polygon("fill",
        x - dir * r * 0.2, y - r * 0.6,
        x + dir * r * 0.3, y - r * 1.1,
        x + dir * r * 0.5, y - r * 0.6)

    -- Eye
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", x + dir * r * 0.6, y - r * 0.15, 5)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", x + dir * r * 0.65, y - r * 0.15, 2.5)

    love.graphics.setColor(1, 1, 1, 1)
end

function UFO.checkCollision(ufo, asteroid)
    if not ufo or not asteroid or asteroid.dying then return false end
    local dx = ufo.x - asteroid.x
    local dy = ufo.y - asteroid.y
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist < ufo.radius + asteroid.radius
end

function UFO.isOffScreen(ufo)
    if not ufo then return true end
    return ufo.x < -60 or ufo.x > Settings.CANVAS_WIDTH + 60
end

return UFO
