local Settings = require("settings")

local Asteroid = {}

local lastEdge = 0
local catMode = false
local catImage = nil
local catNameFont = nil
local wowCatImage = nil
local wowCat = { active = false, timer = 0, phase = "idle" }

-- Random cat names for Cat Mode
local catNames = {
    "Mochi", "Luna", "Nyan", "Maru", "Tama",
    "Socks", "Miso", "Kiki", "Mimi", "Coco",
    "Pumpkin", "Salem", "Felix", "Gizmo", "Pepper",
    "Tofu", "Wasabi", "Sushi", "Matcha", "Azuki",
    "Simba", "Oreo", "Latte", "Mocha", "Chip",
    "Biscuit", "Nugget", "Pickles", "Waffles", "Bean",
}

function Asteroid.setCatMode(enabled)
    catMode = enabled
    if enabled and not catImage then
        Asteroid._loadCatImage()
    end
end

function Asteroid.isCatMode()
    return catMode
end

function Asteroid._loadCatImage()
    catImage = love.graphics.newImage("assets/images/mode-cats/nyan-cat.png")
    catImage:setFilter("nearest", "nearest")
    wowCatImage = love.graphics.newImage("assets/images/mode-cats/wow-cat.png")
    wowCatImage:setFilter("linear", "linear")
    catNameFont = love.graphics.newFont("assets/fonts/PressStart2P.ttf", 32)
end

-- Wow cat animation: slides up from bottom-left when nyan cat goes out of bounds
local WOW_SLIDE_IN = 0.3
local WOW_HOLD = 0.6
local WOW_SLIDE_OUT = 0.3
local WOW_TOTAL = WOW_SLIDE_IN + WOW_HOLD + WOW_SLIDE_OUT

function Asteroid.triggerWowCat()
    if catMode and wowCatImage then
        wowCat.active = true
        wowCat.timer = 0
    end
end

function Asteroid.updateWowCat(dt)
    if not wowCat.active then return end
    wowCat.timer = wowCat.timer + dt
    if wowCat.timer >= WOW_TOTAL then
        wowCat.active = false
        wowCat.timer = 0
    end
end

function Asteroid.drawWowCat()
    if not wowCat.active or not wowCatImage then return end

    local imgW, imgH = wowCatImage:getDimensions()
    local drawH = Settings.CANVAS_HEIGHT * 0.45
    local drawScale = drawH / imgH
    local drawW = imgW * drawScale

    -- Calculate vertical offset based on animation phase
    local t = wowCat.timer
    local offsetY
    if t < WOW_SLIDE_IN then
        -- Slide in (from below)
        local progress = t / WOW_SLIDE_IN
        progress = 1 - (1 - progress) * (1 - progress)  -- ease-out
        offsetY = drawH * (1 - progress)
    elseif t < WOW_SLIDE_IN + WOW_HOLD then
        -- Hold
        offsetY = 0
    else
        -- Slide out (back down)
        local progress = (t - WOW_SLIDE_IN - WOW_HOLD) / WOW_SLIDE_OUT
        progress = progress * progress  -- ease-in
        offsetY = drawH * progress
    end

    local x = 0
    local y = Settings.CANVAS_HEIGHT - drawH + offsetY

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(wowCatImage, x, y, 0, drawScale, drawScale)
end

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

    local radius = Settings.ASTEROID_RADIUS
    if catMode then radius = radius * 3 end

    return {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        radius = radius,
        trail = {},
        catName = catNames[math.random(#catNames)],
    }
end

function Asteroid.updateTrail(asteroid)
    if asteroid.dying then
        table.remove(asteroid.trail, 1)
    else
        table.insert(asteroid.trail, {x = asteroid.x, y = asteroid.y})
        local maxLen = Settings.ASTEROID_TRAIL_LENGTH
        if catMode then maxLen = math.floor(maxLen * 1.5) end
        if #asteroid.trail > maxLen then
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

function Asteroid.draw(asteroid, comboLevel, isMain)
    if not asteroid then return end

    local appearance = Asteroid.getAppearance(comboLevel)
    local mainColor

    if appearance.type == "solid" then
        mainColor = appearance.color
    elseif appearance.type == "gradient" then
        mainColor = appearance.colors[1]
    end

    if not asteroid.dying then
        if catMode and catImage then
            -- Cat mode: draw nyan cat, flip horizontally based on direction
            local imgW, imgH = catImage:getDimensions()
            local drawScale = (asteroid.radius * 3) / imgH
            local sx = asteroid.vx >= 0 and drawScale or -drawScale
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(catImage,
                asteroid.x, asteroid.y,
                0,
                sx, drawScale,
                imgW / 2, imgH / 2)
            -- Draw cat name above the cat
            if asteroid.catName and catNameFont then
                local prevFont = love.graphics.getFont()
                love.graphics.setFont(catNameFont)
                local nameW = catNameFont:getWidth(asteroid.catName)
                local nameX = asteroid.x - nameW / 2
                local nameY = asteroid.y - (imgH / 2) * drawScale - 40
                if isMain then
                    love.graphics.setColor(1, 0.843, 0, 0.9)
                else
                    love.graphics.setColor(1, 1, 1, 0.9)
                end
                love.graphics.print(asteroid.catName, nameX, nameY)
                love.graphics.setFont(prevFont)
            end
        elseif appearance.type == "solid" then
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
        local lineW = asteroid.radius * 0.56
        if catMode then lineW = lineW * 3 end
        love.graphics.setLineWidth(lineW)

        local isMaxCombo = catMode and (comboLevel + 1 >= #Settings.ASTEROID_APPEARANCE)

        if isMaxCombo then
            -- Nyan Cat rainbow: bands perpendicular to trail, with wave
            local rainbow = {
                {1, 0, 0},       -- red
                {1, 0.5, 0},     -- orange
                {1, 1, 0},       -- yellow
                {0, 1, 0},       -- green
                {0, 0.5, 1},     -- blue
                {0.3, 0, 1},     -- indigo
                {0.6, 0, 1},     -- violet
            }
            local bandCount = #rainbow
            local bandWidth = lineW / bandCount

            love.graphics.setLineWidth(bandWidth + 0.5)

            for bi = 1, bandCount do
                local c = rainbow[bi]
                love.graphics.setColor(c[1], c[2], c[3], 0.85)
                local bandOffset = (bi - (bandCount + 1) / 2) * bandWidth

                local points = {}
                for i = 1, #asteroid.trail do
                    local p = asteroid.trail[i]
                    local nx, ny = 0, -1
                    if i < #asteroid.trail then
                        local p2 = asteroid.trail[i + 1]
                        local dx, dy = p2.x - p.x, p2.y - p.y
                        local len = math.sqrt(dx * dx + dy * dy)
                        if len > 0 then nx, ny = -dy / len, dx / len end
                    elseif i > 1 then
                        local p2 = asteroid.trail[i - 1]
                        local dx, dy = p.x - p2.x, p.y - p2.y
                        local len = math.sqrt(dx * dx + dy * dy)
                        if len > 0 then nx, ny = -dy / len, dx / len end
                    end
                    table.insert(points, p.x + nx * bandOffset)
                    table.insert(points, p.y + ny * bandOffset)
                end

                if #points >= 4 then
                    love.graphics.line(points)
                end
            end
        else
            local r = mainColor[1] or 1
            local g = mainColor[2] or 1
            local b = mainColor[3] or 1
            love.graphics.setColor(r, g, b, 0.5)
            local points = {}
            for _, p in ipairs(asteroid.trail) do
                table.insert(points, p.x)
                table.insert(points, p.y)
            end
            if #points >= 4 then
                love.graphics.line(points)
            end
        end
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Asteroid
