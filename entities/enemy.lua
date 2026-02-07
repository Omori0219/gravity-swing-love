local Settings = require("settings")
local Physics = require("systems.physics")

local Enemy = {}

function Enemy.createOne(existingEnemies, planet)
    local r = Settings.ENEMY_RADIUS
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
            if Physics.getDistance(e.x, e.y, x, y) < r * 4 then
                tooClose = true
                break
            end
        end
        if not tooClose and planet then
            if Physics.getDistance(planet.x, planet.y, x, y) < Settings.PLANET_RADIUS + r + Settings.ENEMY_SPAWN_SEPARATION then
                tooClose = true
            end
        end
        if not tooClose then break end
    until false

    return {
        x = x,
        y = y,
        radius = r,
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
    love.graphics.setColor(Settings.COLORS.ENEMY)
    love.graphics.circle("fill", enemy.x, enemy.y, enemy.radius)
    love.graphics.setColor(Settings.COLORS.ENEMY_STROKE)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", enemy.x, enemy.y, enemy.radius)
    love.graphics.setLineWidth(1)
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
