local Settings = require("settings")

local Asteroid = {}

function Asteroid.new(cannon)
    return {
        x = cannon.x + cannon.width / 2 + Settings.CANNON_BARREL_LENGTH,
        y = cannon.y,
        vx = Settings.ASTEROID_INITIAL_VX,
        vy = (math.random() - 0.5) * 0.5,
        radius = Settings.ASTEROID_RADIUS,
        trail = {},
    }
end

function Asteroid.updateTrail(asteroid)
    table.insert(asteroid.trail, {x = asteroid.x, y = asteroid.y})
    if #asteroid.trail > Settings.ASTEROID_TRAIL_LENGTH then
        table.remove(asteroid.trail, 1)
    end
end

function Asteroid.isOutOfBounds(asteroid)
    local buf = Settings.ASTEROID_BOUNDARY_BUFFER
    local r = asteroid.radius
    return asteroid.x < -r - buf
        or asteroid.x > Settings.CANVAS_WIDTH + r + buf
        or asteroid.y < -r - buf
        or asteroid.y > Settings.CANVAS_HEIGHT + r + buf
end

function Asteroid.getAppearance(comboLevel)
    local idx = math.min(comboLevel + 1, #Settings.ASTEROID_APPEARANCE)
    return Settings.ASTEROID_APPEARANCE[idx]
end

function Asteroid.draw(asteroid, comboLevel)
    if not asteroid then return end

    local appearance = Asteroid.getAppearance(comboLevel)
    local mainColor

    if appearance.type == "solid" then
        mainColor = appearance.color
        love.graphics.setColor(mainColor)
        love.graphics.circle("fill", asteroid.x, asteroid.y, asteroid.radius)
    elseif appearance.type == "gradient" then
        -- Simulate radial gradient with concentric circles
        local colors = appearance.colors
        local steps = 8
        for i = steps, 1, -1 do
            local t = i / steps
            -- Interpolate between colors
            local colorIdx = t * (#colors - 1) + 1
            local ci = math.floor(colorIdx)
            local cf = colorIdx - ci
            local c1 = colors[math.min(ci, #colors)]
            local c2 = colors[math.min(ci + 1, #colors)]
            love.graphics.setColor(
                c1[1] + (c2[1] - c1[1]) * cf,
                c1[2] + (c2[2] - c1[2]) * cf,
                c1[3] + (c2[3] - c1[3]) * cf
            )
            love.graphics.circle("fill", asteroid.x, asteroid.y, asteroid.radius * t)
        end
        mainColor = colors[1]
    end

    -- Trail
    if #asteroid.trail > 1 then
        local r = mainColor[1] or 1
        local g = mainColor[2] or 1
        local b = mainColor[3] or 1
        love.graphics.setColor(r, g, b, 0.5)
        love.graphics.setLineWidth(asteroid.radius * 0.56)
        local points = {}
        for _, p in ipairs(asteroid.trail) do
            table.insert(points, p.x)
            table.insert(points, p.y)
        end
        if #points >= 4 then
            love.graphics.line(points)
        end
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Asteroid
