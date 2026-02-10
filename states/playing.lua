local Settings = require("settings")
local Planet = require("entities.planet")
local Asteroid = require("entities.asteroid")
local Enemy = require("entities.enemy")
local Physics = require("systems.physics")
local Stars = require("systems.stars")
local Particles = require("systems.particles")
local FloatingScore = require("systems.floating_score")
local ScreenShake = require("systems.screenshake")
local Audio = require("systems.audio")
local HUD = require("ui.hud")
local UFO = require("entities.ufo")

local Playing = {}

local planet, asteroid, enemies
local score, highScore, consecutiveHits, maxConsecutiveHits
local destroyedPlanets
local currentChainKills
local chainClearTimer
local canLaunch, launchDelayTimer
local gameStartTime, gameOver
local fonts

-- Extra asteroids for max combo cat rush
local extraAsteroids
local extraSpawnTimer
local EXTRA_SPAWN_INTERVAL = 1.5

-- Timed mode
local gameMode          -- "normal" or "timed"
local timeRemaining     -- seconds left (120s mode)
local timeUp            -- true when timer expired
local TIMED_DURATION = 120

-- UFO bonus system
local ufo
local ufoSpawnTimer
local scoreMultiplier
local scoreMultiplierTimer
local flashTimer

-- Super Saiyan aura effect
local function drawBonusAura(ast, ratio)
    local x, y = ast.x, ast.y
    local r = ast.radius
    local t = love.timer.getTime()

    -- Outer soft glow layers
    for i = 4, 1, -1 do
        local gr = r * (2.5 + i * 0.6) * (0.85 + 0.15 * math.sin(t * 3 + i))
        love.graphics.setColor(1, 0.843, 0, 0.06 * ratio)
        love.graphics.circle("fill", x, y, gr)
    end

    -- Inner bright glow
    local innerR = r * 2.2 * (0.9 + 0.1 * math.sin(t * 5))
    love.graphics.setColor(1, 0.9, 0.2, 0.2 * ratio)
    love.graphics.circle("fill", x, y, innerR)

    -- Flame wisps rising upward
    for i = 1, 8 do
        local baseAngle = (i / 8) * math.pi * 2 + t * 1.5
        local bx = x + math.cos(baseAngle) * r * 0.9
        local by = y + math.sin(baseAngle) * r * 0.9
        local flameH = r * (1.5 + 0.8 * math.sin(t * 4 + i * 1.7)) * ratio
        local flameW = r * 0.35
        local wave = math.sin(t * 5 + i * 2) * r * 0.15

        love.graphics.setColor(1, 0.85, 0.1, 0.25 * ratio)
        love.graphics.polygon("fill",
            bx - flameW, by,
            bx + wave, by - flameH,
            bx + flameW, by)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Super Saiyan spiky hair
local function drawBonusHair(ast, ratio)
    local x, y = ast.x, ast.y
    local r = ast.radius
    local t = love.timer.getTime()
    local headY = y - r * 1.3

    local spikes = {
        {-0.5, -1.8},
        {-0.2, -2.2},
        {0.1, -2.5},
        {0.35, -2.0},
        {0.6, -1.6},
    }

    for i, spike in ipairs(spikes) do
        local wave = math.sin(t * 3 + i * 0.8) * r * 0.08
        local tipX = x + spike[1] * r + wave
        local tipY = headY + spike[2] * r
        local baseW = r * 0.25

        -- Hair spike
        love.graphics.setColor(1, 0.85, 0, 0.9 * ratio)
        love.graphics.polygon("fill",
            x + spike[1] * r - baseW, headY,
            tipX, tipY,
            x + spike[1] * r + baseW, headY)

        -- Brighter highlight
        love.graphics.setColor(1, 1, 0.5, 0.5 * ratio)
        love.graphics.polygon("fill",
            x + spike[1] * r - baseW * 0.3, headY,
            tipX, tipY + r * 0.2,
            x + spike[1] * r + baseW * 0.3, headY)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Playing.enter(f, hs, mode)
    fonts = f
    planet = Planet.new()
    asteroid = nil
    enemies = Enemy.initializeAll(planet)
    score = 0
    highScore = hs
    consecutiveHits = 0
    maxConsecutiveHits = 0
    destroyedPlanets = {}
    currentChainKills = {}
    chainClearTimer = 0
    canLaunch = false
    launchDelayTimer = Settings.ASTEROID_FIRST_LAUNCH_DELAY
    gameStartTime = love.timer.getTime()
    gameOver = false

    gameMode = mode or "normal"
    timeRemaining = TIMED_DURATION
    timeUp = false

    extraAsteroids = {}
    extraSpawnTimer = 0
    Asteroid.clearWowCats()

    ufo = nil
    ufoSpawnTimer = Settings.UFO_SPAWN_MIN + math.random() * (Settings.UFO_SPAWN_MAX - Settings.UFO_SPAWN_MIN)
    scoreMultiplier = 1
    scoreMultiplierTimer = 0
    flashTimer = 0

    Particles.clear()
    FloatingScore.clear()
    Audio.setNyanMode(false)
    Audio.playBGM()
end

function Playing.update(dt)
    if gameOver then
        Particles.update(dt)
        ScreenShake.update(dt)
        return
    end

    -- Countdown for timed mode
    if gameMode == "timed" then
        timeRemaining = timeRemaining - dt
        if timeRemaining <= 0 then
            timeRemaining = 0
            timeUp = true
            Playing.triggerGameOver()
            return
        end
    end

    -- Planet follows mouse
    local mx, my = love.mouse.getPosition()
    Planet.updatePosition(planet, mx, my)
    Planet.update(dt)

    -- Enemy animation
    Enemy.update(dt)

    -- Kill feed clear timer
    if chainClearTimer > 0 then
        chainClearTimer = chainClearTimer - dt
        if chainClearTimer <= 0 then
            currentChainKills = {}
            chainClearTimer = 0
        end
    end

    -- Particles & floating scores
    Particles.update(dt)
    FloatingScore.update(dt)
    ScreenShake.update(dt)
    Asteroid.updateWowCat(dt)

    -- UFO system
    ufoSpawnTimer = ufoSpawnTimer - dt
    if not ufo and ufoSpawnTimer <= 0 then
        ufo = UFO.new()
    end
    if ufo then
        UFO.update(ufo, dt)
        -- Check collision with main asteroid
        if asteroid and not asteroid.dying and UFO.checkCollision(ufo, asteroid) then
            scoreMultiplier = Settings.UFO_BONUS_MULTIPLIER
            scoreMultiplierTimer = Settings.UFO_BONUS_DURATION
            flashTimer = 0.3
            ScreenShake.trigger(0.3, 12)
            FloatingScore.spawn("BONUS x" .. scoreMultiplier, ufo.x, ufo.y, Settings.COLORS.GOLD, true, 5)
            Particles.spawn(ufo.x, ufo.y, "hit")
            Audio.playHit()
            ufo = nil
            ufoSpawnTimer = Settings.UFO_SPAWN_MIN + math.random() * (Settings.UFO_SPAWN_MAX - Settings.UFO_SPAWN_MIN)
        end
        -- Check collision with extra asteroids
        if ufo then
            for _, extra in ipairs(extraAsteroids) do
                if not extra.dying and UFO.checkCollision(ufo, extra) then
                    scoreMultiplier = Settings.UFO_BONUS_MULTIPLIER
                    scoreMultiplierTimer = Settings.UFO_BONUS_DURATION
                    flashTimer = 0.3
                    ScreenShake.trigger(0.3, 12)
                    FloatingScore.spawn("BONUS x" .. scoreMultiplier, ufo.x, ufo.y, Settings.COLORS.GOLD, true, 5)
                    Particles.spawn(ufo.x, ufo.y, "hit")
                    Audio.playHit()
                    ufo = nil
                    ufoSpawnTimer = Settings.UFO_SPAWN_MIN + math.random() * (Settings.UFO_SPAWN_MAX - Settings.UFO_SPAWN_MIN)
                    break
                end
            end
        end
        -- Off screen
        if ufo and UFO.isOffScreen(ufo) then
            ufo = nil
            ufoSpawnTimer = Settings.UFO_SPAWN_MIN + math.random() * (Settings.UFO_SPAWN_MAX - Settings.UFO_SPAWN_MIN)
        end
    end

    -- Score multiplier timer
    if scoreMultiplierTimer > 0 then
        scoreMultiplierTimer = scoreMultiplierTimer - dt
        if scoreMultiplierTimer <= 0 then
            scoreMultiplier = 1
            scoreMultiplierTimer = 0
        end
    end

    -- Flash timer
    if flashTimer > 0 then
        flashTimer = flashTimer - dt
        if flashTimer < 0 then flashTimer = 0 end
    end

    -- Launch delay
    if not canLaunch and launchDelayTimer > 0 then
        launchDelayTimer = launchDelayTimer - dt
        if launchDelayTimer <= 0 then
            canLaunch = true
            launchDelayTimer = 0
        end
    end

    -- Auto-launch
    if not asteroid and canLaunch then
        asteroid = Asteroid.new()
        local range = Settings.ASTEROID_INITIAL_COMBO_MAX - Settings.ASTEROID_INITIAL_COMBO_MIN
        consecutiveHits = Settings.ASTEROID_INITIAL_COMBO_MIN + math.floor(math.random() ^ Settings.ASTEROID_INITIAL_COMBO_BIAS * (range + 1))
        -- New asteroid: combo resets, switch back to normal BGM
        Audio.setNyanMode(false)
    end

    if not asteroid then return end

    -- Dying: drain trail then remove
    if asteroid.dying then
        Asteroid.updateTrail(asteroid)
        if Asteroid.isTrailGone(asteroid) then
            asteroid = nil
        end
        return
    end

    -- Physics
    Physics.applyGravity(asteroid, planet, dt)
    Asteroid.updateTrail(asteroid)

    -- Check planet collision (game over)
    local distToPlanet = Physics.getDistance(asteroid.x, asteroid.y, planet.x, planet.y)
    if distToPlanet < planet.suckInRadius then
        Playing.triggerGameOver()
        return
    end

    -- Check enemy collisions
    for i = #enemies, 1, -1 do
        if Enemy.checkCollision(enemies[i], asteroid) then
            local ex, ey = enemies[i].x, enemies[i].y
            table.insert(destroyedPlanets, { name = enemies[i].name, image = enemies[i].image })

            -- Combo
            consecutiveHits = consecutiveHits + 1
            chainClearTimer = 0
            local baseScore = enemies[i].baseScore or 1
            table.insert(currentChainKills, {
                name = enemies[i].name,
                baseScore = baseScore,
                comboLevel = consecutiveHits,
            })
            if consecutiveHits > maxConsecutiveHits then
                maxConsecutiveHits = consecutiveHits
            end

            -- Score = baseScore x combo x UFO bonus
            local comboMultiplier = math.max(1, consecutiveHits)
            local hitScore = baseScore * comboMultiplier * scoreMultiplier
            score = score + hitScore

            local appearance = Asteroid.getAppearance(consecutiveHits)
            local scoreColor
            if consecutiveHits >= 2 then
                if appearance.type == "solid" then
                    scoreColor = appearance.color
                else
                    scoreColor = appearance.colors[1]
                end
            else
                scoreColor = Settings.COLORS.WHITE
            end
            FloatingScore.spawn("+" .. hitScore, ex, ey, scoreColor, consecutiveHits >= 2, consecutiveHits)

            Particles.spawn(ex, ey, "hit")
            Audio.playHit()

            -- Cat grows bigger and heavier with each kill (chaos only)
            if Asteroid.isChaosMode() then
                asteroid.weightFactor = asteroid.weightFactor + 0.15
                asteroid.radius = asteroid.baseRadius * asteroid.weightFactor
            end

            -- Switch to nyan BGM at max combo in cat mode
            if Asteroid.isCatMode() and consecutiveHits + 1 >= #Settings.ASTEROID_APPEARANCE then
                Audio.setNyanMode(true)
            end

            -- Respawn enemy
            enemies[i] = Enemy.createOne(enemies, planet)
        end
    end

    -- Extra cat spawning at max combo in cat mode
    local isMaxCombo = Asteroid.isCatMode() and (consecutiveHits + 1 >= #Settings.ASTEROID_APPEARANCE)
    if isMaxCombo then
        extraSpawnTimer = extraSpawnTimer + dt
        if extraSpawnTimer >= EXTRA_SPAWN_INTERVAL then
            extraSpawnTimer = extraSpawnTimer - EXTRA_SPAWN_INTERVAL
            local extra = Asteroid.new()
            extra.shy = math.random(10) == 1
            table.insert(extraAsteroids, extra)
        end
    else
        extraSpawnTimer = 0
    end

    -- Update extra asteroids
    for i = #extraAsteroids, 1, -1 do
        local extra = extraAsteroids[i]
        if extra.dying then
            Asteroid.updateTrail(extra)
            if Asteroid.isTrailGone(extra) then
                table.remove(extraAsteroids, i)
            end
        else
            -- Shy cat: repelled by enemy planets
            if extra.shy then
                local timeScale = dt * Settings.BASE_FPS * Settings.PHYSICS_TIME_SCALE
                for _, enemy in ipairs(enemies) do
                    local dx = enemy.x - extra.x
                    local dy = enemy.y - extra.y
                    local distSq = dx * dx + dy * dy
                    local dist = math.sqrt(distSq)
                    if dist > 1 then
                        local force = (Settings.GRAVITY_CONSTANT * planet.mass * 0.2) / distSq
                        local fx = (dx / dist) * force
                        local fy = (dy / dist) * force
                        local maxF = Settings.MAX_GRAVITY_FORCE
                        if math.abs(fx) > maxF then fx = (fx > 0 and maxF or -maxF) end
                        if math.abs(fy) > maxF then fy = (fy > 0 and maxF or -maxF) end
                        extra.vx = extra.vx - fx * timeScale
                        extra.vy = extra.vy - fy * timeScale
                    end
                end
            end
            Physics.applyGravity(extra, planet, dt)
            Asteroid.updateTrail(extra)

            -- Extra cats pass through the planet (no game over)
            -- Check enemy collisions
            for j = #enemies, 1, -1 do
                if Enemy.checkCollision(enemies[j], extra) then
                    local ex, ey = enemies[j].x, enemies[j].y
                    table.insert(destroyedPlanets, { name = enemies[j].name, image = enemies[j].image })

                    consecutiveHits = consecutiveHits + 1
                    chainClearTimer = 0
                    local baseScore = enemies[j].baseScore or 1
                    table.insert(currentChainKills, {
                        name = enemies[j].name,
                        baseScore = baseScore,
                        comboLevel = consecutiveHits,
                    })
                    if consecutiveHits > maxConsecutiveHits then
                        maxConsecutiveHits = consecutiveHits
                    end

                    local comboMultiplier = math.max(1, consecutiveHits)
                    local hitScore = baseScore * comboMultiplier * scoreMultiplier
                    score = score + hitScore

                    local appearance = Asteroid.getAppearance(consecutiveHits)
                    local scoreColor
                    if consecutiveHits >= 2 then
                        if appearance.type == "solid" then
                            scoreColor = appearance.color
                        else
                            scoreColor = appearance.colors[1]
                        end
                    else
                        scoreColor = Settings.COLORS.WHITE
                    end
                    FloatingScore.spawn("+" .. hitScore, ex, ey, scoreColor, consecutiveHits >= 2, consecutiveHits)

                    Particles.spawn(ex, ey, "hit")
                    Audio.playHit()

                    enemies[j] = Enemy.createOne(enemies, planet)
                end
            end

            -- Remove out-of-bounds extras
            if Asteroid.isOutOfBounds(extra) then
                extra.dying = true
            end
        end
    end

    -- Out of bounds: start dying (trail drains out) and begin next launch timer
    if Asteroid.isOutOfBounds(asteroid) then
        Asteroid.triggerWowCat()
        asteroid.dying = true
        canLaunch = false
        -- Mark all extra asteroids as dying too
        for _, extra in ipairs(extraAsteroids) do
            extra.dying = true
        end
        if #currentChainKills > 0 then
            chainClearTimer = 1.5
        end
        launchDelayTimer = Settings.ASTEROID_LAUNCH_DELAY_MIN + math.random() * (Settings.ASTEROID_LAUNCH_DELAY_MAX - Settings.ASTEROID_LAUNCH_DELAY_MIN)
    end
end

function Playing.draw()
    love.graphics.push()
    local sx, sy = ScreenShake.getOffset()
    love.graphics.translate(sx, sy)

    -- Background
    love.graphics.setColor(Settings.COLORS.BLACK)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    Stars.draw(planet.x, planet.y)

    Planet.draw(planet)
    Enemy.drawAll(enemies)

    -- Bonus state on main asteroid
    local bonusRatio = 0
    if scoreMultiplier > 1 then
        bonusRatio = scoreMultiplierTimer / Settings.UFO_BONUS_DURATION
    end
    if asteroid then
        asteroid.bonusActive = scoreMultiplier > 1
        asteroid.bonusRatio = bonusRatio
    end
    if bonusRatio > 0 and asteroid and not asteroid.dying then
        drawBonusAura(asteroid, bonusRatio)
    end

    if asteroid then
        Asteroid.draw(asteroid, consecutiveHits, true)
    end

    -- Bonus hair on top of cat
    if bonusRatio > 0 and asteroid and not asteroid.dying then
        drawBonusHair(asteroid, bonusRatio)
    end

    for _, extra in ipairs(extraAsteroids) do
        Asteroid.draw(extra, consecutiveHits, false)
    end
    Particles.draw()
    Asteroid.drawWowCat()
    UFO.draw(ufo)

    love.graphics.pop()

    -- HUD (not affected by screen shake)
    local scoreY
    if gameMode == "timed" then
        HUD.drawTimer(timeRemaining, fonts.large)
        scoreY = 8 + fonts.large:getHeight() + 4
    else
        scoreY = 8
    end
    HUD.drawScore(score, fonts.timer, scoreY, scoreMultiplier > 1)
    HUD.drawHighScore(highScore, fonts.tiny, scoreY + fonts.timer:getHeight() + 4)
    local multiplierY = scoreY + fonts.timer:getHeight() + fonts.tiny:getHeight() + 8
    HUD.drawScoreMultiplier(scoreMultiplier, scoreMultiplierTimer, fonts.medium, multiplierY)
    FloatingScore.draw(fonts.floating)

    -- Kill feed
    HUD.drawKillFeed(currentChainKills, fonts.killFeed)

    -- Combo counter (next to kill feed)
    HUD.drawCombo(consecutiveHits, fonts.killFeed)

    -- Cat profile (top-right, cat/chaos mode only)
    if Asteroid.isCatMode() and asteroid then
        HUD.drawCatProfile(asteroid.catName, asteroid.catTrait, Asteroid.getCatImage(), fonts)
    end

    -- Mute indicator
    if Audio.isMuted then
        HUD.drawMuteIndicator(fonts.tiny)
    end

    -- Transform flash overlay
    if flashTimer > 0 then
        local alpha = (flashTimer / 0.3) * 0.7
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Playing.triggerGameOver()
    gameOver = true
    asteroid = nil
    extraAsteroids = {}
    ufo = nil
    canLaunch = false

    if not timeUp then
        -- Planet collision: shake + explosion
        ScreenShake.trigger(Settings.SCREEN_SHAKE_DURATION, Settings.SCREEN_SHAKE_INTENSITY)
        Particles.spawn(planet.x, planet.y, "gameover")
    end
    Audio.playGameOver()
    Audio.stopBGM()
end

function Playing.keypressed(key)
    if key == "space" and not gameOver then
        return "pause"
    end
    if key == "m" then
        Audio.toggleMute()
        if not Audio.isMuted and not gameOver then
            Audio.playBGM()
        end
    end
    return nil
end

function Playing.mousepressed(x, y, button)
    return nil
end

-- Getters for game state
function Playing.getScore() return score end
function Playing.getHighScore() return highScore end
function Playing.setHighScore(hs) highScore = hs end
function Playing.getMaxCombo() return maxConsecutiveHits end
function Playing.getPlayTime()
    return love.timer.getTime() - gameStartTime
end
function Playing.isGameOver() return gameOver end
function Playing.isTimeUp() return timeUp end
function Playing.getDestroyedPlanets() return destroyedPlanets end
function Playing.getGameMode() return gameMode end
function Playing.getConsecutiveHits() return consecutiveHits end

return Playing
