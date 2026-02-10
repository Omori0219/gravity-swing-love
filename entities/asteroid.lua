local Settings = require("settings")

local Asteroid = {}

local lastEdge = 0
local gameMode = "normal"  -- "normal", "cat", "chaos"
local catImage = nil
local catNameFont = nil
local wowCatImage = nil
local wowCats = {}       -- persistent wow cats (chaos mode)
local wowCatTemp = nil   -- temporary wow cat (cat mode)

-- Random cat names for Cat Mode
local catNames = {
    "Mochi", "Luna", "Nyan", "Maru", "Tama",
    "Socks", "Miso", "Kiki", "Mimi", "Coco",
    "Pumpkin", "Salem", "Felix", "Gizmo", "Pepper",
    "Tofu", "Wasabi", "Sushi", "Matcha", "Azuki",
    "Simba", "Oreo", "Latte", "Mocha", "Chip",
    "Biscuit", "Nugget", "Pickles", "Waffles", "Bean",
}

local catTraits = {
    "Loves belly rubs",
    "Afraid of cucumbers",
    "Expert napper",
    "Chases lasers",
    "Professional purrer",
    "Space navigator",
    "Rainbow specialist",
    "Gravity defier",
    "Star collector",
    "Cosmic explorer",
    "Midnight zoomer",
    "Yarn destroyer",
    "Box connoisseur",
    "Keyboard sitter",
    "Sunbeam seeker",
    "Treat inspector",
    "Window watcher",
    "Tail chaser",
    "Whisker twister",
    "Cardboard critic",
}

function Asteroid.setGameMode(mode)
    gameMode = mode
    if mode ~= "normal" and not catImage then
        Asteroid._loadCatImage()
    end
end

function Asteroid.isCatMode()
    return gameMode == "cat" or gameMode == "chaos"
end

function Asteroid.isChaosMode()
    return gameMode == "chaos"
end

function Asteroid._loadCatImage()
    catImage = love.graphics.newImage("assets/images/mode-cats/nyan-cat.png")
    catImage:setFilter("nearest", "nearest")
    wowCatImage = love.graphics.newImage("assets/images/mode-cats/wow-cat.png")
    wowCatImage:setFilter("linear", "linear")
    catNameFont = love.graphics.newFont("assets/fonts/PressStart2P.ttf", 32)
end

-- Wow cat system
-- Cat mode: temporary (slide in, hold, slide out)
-- Chaos mode: persistent (accumulate on screen as penalty)
local WOW_SLIDE_IN = 0.3
local WOW_HOLD = 0.6
local WOW_SLIDE_OUT = 0.3
local WOW_TOTAL = WOW_SLIDE_IN + WOW_HOLD + WOW_SLIDE_OUT
local CHAOS_SLIDE_IN = 0.5

local function _chaosWowPosition()
    local W = Settings.CANVAS_WIDTH
    local H = Settings.CANVAS_HEIGHT
    local imgW, imgH = wowCatImage:getDimensions()
    local drawH = H * 0.4
    local drawScale = drawH / imgH
    local drawW = imgW * drawScale

    local edge = math.random(1, 4)
    local finalCX, finalCY, startCX, startCY, rotation

    if edge == 1 then      -- top
        local rx = drawW / 2 + math.random() * (W - drawW)
        finalCX, finalCY = rx, drawH / 2
        startCX, startCY = rx, -drawH / 2
        rotation = math.pi
    elseif edge == 2 then  -- bottom
        local rx = drawW / 2 + math.random() * (W - drawW)
        finalCX, finalCY = rx, H - drawH / 2
        startCX, startCY = rx, H + drawH / 2
        rotation = 0
    elseif edge == 3 then  -- left
        local ry = drawW / 2 + math.random() * (H - drawW)
        finalCX, finalCY = drawH / 2, ry
        startCX, startCY = -drawH / 2, ry
        rotation = math.pi / 2
    else                    -- right
        local ry = drawW / 2 + math.random() * (H - drawW)
        finalCX, finalCY = W - drawH / 2, ry
        startCX, startCY = W + drawH / 2, ry
        rotation = -math.pi / 2
    end

    return {
        timer = 0,
        startCX = startCX, startCY = startCY,
        finalCX = finalCX, finalCY = finalCY,
        drawScale = drawScale, rotation = rotation,
    }
end

function Asteroid.triggerWowCat()
    if gameMode == "normal" or not wowCatImage then return end

    if gameMode == "chaos" then
        table.insert(wowCats, _chaosWowPosition())
    else
        -- Cat mode: temporary display
        wowCatTemp = { active = true, timer = 0 }
    end
end

function Asteroid.updateWowCat(dt)
    -- Chaos: animate slide-in for persistent cats
    for _, wc in ipairs(wowCats) do
        if wc.timer < CHAOS_SLIDE_IN then
            wc.timer = math.min(wc.timer + dt, CHAOS_SLIDE_IN)
        end
    end
    -- Cat: temporary animation
    if wowCatTemp and wowCatTemp.active then
        wowCatTemp.timer = wowCatTemp.timer + dt
        if wowCatTemp.timer >= WOW_TOTAL then
            wowCatTemp.active = false
        end
    end
end

function Asteroid.drawWowCat()
    if not wowCatImage then return end
    local imgW, imgH = wowCatImage:getDimensions()

    -- Chaos mode: persistent cats from edges
    for _, wc in ipairs(wowCats) do
        local progress = wc.timer / CHAOS_SLIDE_IN
        progress = 1 - (1 - progress) * (1 - progress)

        local cx = wc.startCX + (wc.finalCX - wc.startCX) * progress
        local cy = wc.startCY + (wc.finalCY - wc.startCY) * progress

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(wowCatImage, cx, cy,
            wc.rotation, wc.drawScale, wc.drawScale,
            imgW / 2, imgH / 2)
    end

    -- Cat mode: temporary bottom-left slide
    if wowCatTemp and wowCatTemp.active then
        local drawH = Settings.CANVAS_HEIGHT * 0.45
        local drawScale = drawH / imgH

        local t = wowCatTemp.timer
        local offsetY
        if t < WOW_SLIDE_IN then
            local p = t / WOW_SLIDE_IN
            p = 1 - (1 - p) * (1 - p)
            offsetY = drawH * (1 - p)
        elseif t < WOW_SLIDE_IN + WOW_HOLD then
            offsetY = 0
        else
            local p = (t - WOW_SLIDE_IN - WOW_HOLD) / WOW_SLIDE_OUT
            p = p * p
            offsetY = drawH * p
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(wowCatImage, 0,
            Settings.CANVAS_HEIGHT - drawH + offsetY,
            0, drawScale, drawScale)
    end
end

function Asteroid.getCatImage()
    return catImage
end

function Asteroid.clearWowCats()
    wowCats = {}
    wowCatTemp = nil
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
    if gameMode ~= "normal" then radius = radius * 3 end

    return {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        radius = radius,
        baseRadius = radius,
        weightFactor = 1,
        trail = {},
        catName = catNames[math.random(#catNames)],
        catTrait = catTraits[math.random(#catTraits)],
        shy = false,
    }
end

function Asteroid.updateTrail(asteroid)
    if asteroid.dying then
        table.remove(asteroid.trail, 1)
    else
        table.insert(asteroid.trail, {x = asteroid.x, y = asteroid.y})
        local maxLen = Settings.ASTEROID_TRAIL_LENGTH
        if gameMode ~= "normal" then maxLen = math.floor(maxLen * 1.5) end
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
        if gameMode ~= "normal" and catImage then
            -- Cat mode: draw nyan cat, flip horizontally based on direction
            local imgW, imgH = catImage:getDimensions()
            local drawScale = (asteroid.radius * 3) / imgH
            local sx = asteroid.vx >= 0 and drawScale or -drawScale
            local sy = asteroid.shy and -drawScale or drawScale
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(catImage,
                asteroid.x, asteroid.y,
                0,
                sx, sy,
                imgW / 2, imgH / 2)
            -- Draw cat name above the cat
            if asteroid.catName and catNameFont then
                local prevFont = love.graphics.getFont()
                love.graphics.setFont(catNameFont)
                local nameW = catNameFont:getWidth(asteroid.catName)
                local nameX = asteroid.x - nameW / 2
                local nameY = asteroid.y - (imgH / 2) * drawScale - 40
                if asteroid.shy then
                    love.graphics.setColor(1, 0.2, 0.2, 0.9)
                elseif isMain then
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
        if gameMode ~= "normal" then lineW = lineW * 3 end
        love.graphics.setLineWidth(lineW)

        local isMaxCombo = gameMode ~= "normal" and (comboLevel + 1 >= #Settings.ASTEROID_APPEARANCE)

        if asteroid.bonusActive then
            -- Golden bonus trail
            local alpha = 0.7 * (asteroid.bonusRatio or 1)
            love.graphics.setColor(1, 0.843, 0, alpha)
            local points = {}
            for _, p in ipairs(asteroid.trail) do
                table.insert(points, p.x)
                table.insert(points, p.y)
            end
            if #points >= 4 then
                love.graphics.line(points)
            end
        elseif isMaxCombo then
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
