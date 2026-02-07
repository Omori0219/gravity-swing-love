local Settings = require("settings")
local Physics = require("systems.physics")

local Enemy = {}

local planets = {}

-- Real radius (km): Mercury 2440, Venus 6052, Mars 3390, Jupiter 69911,
-- Saturn 58232, Uranus 25362, Neptune 24622, Pluto 1188
-- Normalized to Jupiter=1.0, then sqrt-scaled for visual balance
local planetDefs = {
    { name = "Mercury", ratio = 0.035 },
    { name = "Venus",   ratio = 0.087 },
    { name = "Mars",    ratio = 0.049 },
    { name = "Jupiter", ratio = 1.000 },
    { name = "Saturn",  ratio = 0.833 },
    { name = "Uranus",  ratio = 0.363 },
    { name = "Neptune", ratio = 0.352 },
    { name = "Pluto",   ratio = 0.017 },
}

local function computeRadius(ratio)
    local minR = Settings.ENEMY_RADIUS_MIN
    local maxR = Settings.ENEMY_RADIUS_MAX
    local sqrtMin = math.sqrt(0.017)
    local sqrtMax = math.sqrt(1.000)
    local t = (math.sqrt(ratio) - sqrtMin) / (sqrtMax - sqrtMin)
    return math.floor(minR + t * (maxR - minR) + 0.5)
end

function Enemy.loadImage()
    for _, def in ipairs(planetDefs) do
        local ok, img = pcall(love.graphics.newImage, "assets/images/" .. def.name .. ".png")
        if ok then
            img:setFilter("linear", "linear")
            table.insert(planets, {
                name = def.name,
                image = img,
                radius = computeRadius(def.ratio),
            })
        end
    end
end

function Enemy.update(dt)
end

function Enemy.createOne(existingEnemies, gravityPlanet)
    local p = nil
    local r = Settings.ENEMY_RADIUS_MAX
    if #planets > 0 then
        p = planets[math.random(#planets)]
        r = p.radius
    end

    local minX = r + Settings.ENEMY_SPAWN_MARGIN_X
    local maxX = Settings.CANVAS_WIDTH - r - Settings.ENEMY_SPAWN_MARGIN_X
    local minY = r + Settings.ENEMY_SPAWN_MARGIN_Y
    local maxY = Settings.CANVAS_HEIGHT - r - Settings.ENEMY_SPAWN_MARGIN_Y

    local x, y
    local attempts = 0
    repeat
        x = math.random() * (maxX - minX) + minX
        y = math.random() * (maxY - minY) + minY
        attempts = attempts + 1
        if attempts > Settings.ENEMY_SPAWN_MAX_ATTEMPTS then break end

        local tooClose = false
        for _, e in ipairs(existingEnemies) do
            if Physics.getDistance(e.x, e.y, x, y) < math.max(r, e.radius) * 4 then
                tooClose = true
                break
            end
        end
        if not tooClose and gravityPlanet then
            if Physics.getDistance(gravityPlanet.x, gravityPlanet.y, x, y) < Settings.PLANET_RADIUS + r + Settings.ENEMY_SPAWN_SEPARATION then
                tooClose = true
            end
        end
        if not tooClose then break end
    until false

    return {
        x = x,
        y = y,
        radius = r,
        name = p and p.name or nil,
        image = p and p.image or nil,
    }
end

function Enemy.initializeAll(planet)
    local enemies = {}
    for i = 1, Settings.NUM_ENEMIES do
        table.insert(enemies, Enemy.createOne(enemies, planet))
    end
    return enemies
end

function Enemy.draw(enemy)
    -- Soft glow behind the planet
    local r = enemy.radius
    local layers = Settings.ENEMY_GLOW_LAYERS
    local spread = Settings.ENEMY_GLOW_SPREAD
    local peakAlpha = Settings.ENEMY_GLOW_ALPHA
    local gc = Settings.ENEMY_GLOW_COLOR
    for i = layers, 1, -1 do
        local t = i / layers
        local glowR = r + (r * (spread - 1)) * t
        local alpha = peakAlpha * (1 - t)
        love.graphics.setColor(gc[1], gc[2], gc[3], alpha)
        love.graphics.circle("fill", enemy.x, enemy.y, glowR)
    end

    if enemy.image then
        local diameter = r * 2
        local iw, ih = enemy.image:getDimensions()
        local sx = diameter / iw
        local sy = diameter / ih
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(enemy.image,
            enemy.x - r, enemy.y - r, 0, sx, sy)
    else
        love.graphics.setColor(Settings.COLORS.ENEMY)
        love.graphics.circle("fill", enemy.x, enemy.y, enemy.radius)
        love.graphics.setColor(Settings.COLORS.ENEMY_STROKE)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", enemy.x, enemy.y, enemy.radius)
        love.graphics.setLineWidth(1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy.drawAll(enemies)
    for _, enemy in ipairs(enemies) do
        Enemy.draw(enemy)
    end
end

function Enemy.checkCollision(enemy, asteroid)
    return Physics.getDistance(enemy.x, enemy.y, asteroid.x, asteroid.y) < enemy.radius + asteroid.radius
end

return Enemy
