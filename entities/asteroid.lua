local Settings = require("settings")

local Asteroid = {}

local lastEdge = 0

function Asteroid.new()
    local W = Settings.CANVAS_WIDTH
    local H = Settings.CANVAS_HEIGHT
    local buf = Settings.ASTEROID_RADIUS + 5

    -- Pick a random edge, avoiding the same edge as last time
    local edge
    repeat
        edge = math.random(1, 4)
    until edge ~= lastEdge
    lastEdge = edge

    local x, y

    if edge == 1 then      -- top
        x = math.random() * W
        y = -buf
    elseif edge == 2 then  -- bottom
        x = math.random() * W
        y = H + buf
    elseif edge == 3 then  -- left
        x = -buf
        y = math.random() * H
    else                   -- right
        x = W + buf
        y = math.random() * H
    end

    -- Aim toward center area with some spread
    local cx = W / 2 + (math.random() - 0.5) * W * 0.4
    local cy = H / 2 + (math.random() - 0.5) * H * 0.4
    local angle = math.atan2(cy - y, cx - x)
    -- Add some angular spread (±30 degrees)
    angle = angle + (math.random() - 0.5) * math.rad(60)

    -- Speed: base * random(1.0 ~ 2.0)
    local speedMultiplier = Settings.ASTEROID_SPEED_MIN + math.random() * (Settings.ASTEROID_SPEED_MAX - Settings.ASTEROID_SPEED_MIN)
    local speed = Settings.ASTEROID_INITIAL_VX * speedMultiplier

    return {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        radius = Settings.ASTEROID_RADIUS,
        trail = {},
    }
end

function Asteroid.updateTrail(asteroid)
    if asteroid.dying then
        table.remove(asteroid.trail, 1)
    else
        table.insert(asteroid.trail, {x = asteroid.x, y = asteroid.y})
        if #asteroid.trail > Settings.ASTEROID_TRAIL_LENGTH then
            table.remove(asteroid.trail, 1)
        end
    end
end

function Asteroid.isTrailGone(asteroid)
    return asteroid.dying and #asteroid.trail == 0
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
    elseif appearance.type == "gradient" then
        mainColor = appearance.colors[1]
    end

    if not asteroid.dying then
        if appearance.type == "solid" then
            love.graphics.setColor(mainColor)
            love.graphics.circle("fill", asteroid.x, asteroid.y, asteroid.radius)
        elseif appearance.type == "gradient" then
            local colors = appearance.colors
            local steps = 8
            for i = steps, 1, -1 do
                local t = i / steps
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
        end
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
