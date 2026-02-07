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

local Playing = {}

local planet, asteroid, enemies
local score, highScore, consecutiveHits, maxConsecutiveHits
local canLaunch, launchDelayTimer
local gameStartTime, gameOver
local fonts

-- Timed mode
local gameMode          -- "normal" or "timed"
local timeRemaining     -- seconds left (60s mode)
local timeUp            -- true when timer expired
local TIMED_DURATION = 60

function Playing.enter(f, hs, mode)
    fonts = f
    planet = Planet.new()
    asteroid = nil
    enemies = Enemy.initializeAll(planet)
    score = 0
    highScore = hs
    consecutiveHits = 0
    maxConsecutiveHits = 0
    canLaunch = false
    launchDelayTimer = 1.0
    gameStartTime = love.timer.getTime()
    gameOver = false

    gameMode = mode or "normal"
    timeRemaining = TIMED_DURATION
    timeUp = false

    Particles.clear()
    FloatingScore.clear()
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

    -- Particles & floating scores
    Particles.update(dt)
    FloatingScore.update(dt)
    ScreenShake.update(dt)

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
    end

    if not asteroid then return end

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

            -- Base score
            score = score + 1
            FloatingScore.spawn("+1", ex, ey, Settings.COLORS.WHITE, false)
            Particles.spawn(ex, ey, "hit")
            Audio.playHit()

            -- Combo
            consecutiveHits = consecutiveHits + 1
            if consecutiveHits > maxConsecutiveHits then
                maxConsecutiveHits = consecutiveHits
            end

            -- Combo bonus
            if consecutiveHits >= 2 then
                local bonusScore = consecutiveHits - 1
                score = score + bonusScore

                local appearance = Asteroid.getAppearance(consecutiveHits)
                local bonusColor
                if appearance.type == "solid" then
                    bonusColor = appearance.color
                else
                    bonusColor = appearance.colors[1]
                end
                FloatingScore.spawn("+" .. bonusScore, ex, ey + 20, bonusColor, true, consecutiveHits)
            end

            -- Respawn enemy
            enemies[i] = Enemy.createOne(enemies, planet)
        end
    end

    -- Out of bounds
    if Asteroid.isOutOfBounds(asteroid) then
        asteroid = nil
        canLaunch = false
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

    Stars.draw()

    Planet.draw(planet)
    Enemy.drawAll(enemies)
    if asteroid then
        Asteroid.draw(asteroid, consecutiveHits)
    end
    Particles.draw()

    love.graphics.pop()

    -- HUD (not affected by screen shake)
    HUD.drawScore(score, fonts.medium)
    HUD.drawHighScore(highScore, fonts.tiny)
    FloatingScore.draw(fonts.floating)

    -- Timer display for timed mode
    if gameMode == "timed" then
        HUD.drawTimer(timeRemaining, fonts)
    end

    -- Mute indicator
    if Audio.isMuted then
        HUD.drawMuteIndicator(fonts.tiny)
    end
end

function Playing.triggerGameOver()
    gameOver = true
    asteroid = nil
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
function Playing.getGameMode() return gameMode end
function Playing.getConsecutiveHits() return consecutiveHits end

return Playing
