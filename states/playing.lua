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
local destroyedPlanets
local currentChainKills
local chainClearTimer
local canLaunch, launchDelayTimer
local gameStartTime, gameOver
local fonts

-- Timed mode
local gameMode          -- "normal" or "timed"
local timeRemaining     -- seconds left (120s mode)
local timeUp            -- true when timer expired
local TIMED_DURATION = 120

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

            -- Score = baseScore x combo
            local comboMultiplier = math.max(1, consecutiveHits)
            local hitScore = baseScore * comboMultiplier
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

            -- Switch to nyan BGM at max combo in cat mode
            if Asteroid.isCatMode() and consecutiveHits + 1 >= #Settings.ASTEROID_APPEARANCE then
                Audio.setNyanMode(true)
            end

            -- Respawn enemy
            enemies[i] = Enemy.createOne(enemies, planet)
        end
    end

    -- Out of bounds: start dying (trail drains out) and begin next launch timer
    if Asteroid.isOutOfBounds(asteroid) then
        Asteroid.triggerWowCat()
        asteroid.dying = true
        canLaunch = false
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
    Asteroid.drawWowCat()

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

    -- Kill feed
    HUD.drawKillFeed(currentChainKills, fonts.killFeed)

    -- Combo counter
    HUD.drawCombo(consecutiveHits, fonts.small)

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
function Playing.getDestroyedPlanets() return destroyedPlanets end
function Playing.getGameMode() return gameMode end
function Playing.getConsecutiveHits() return consecutiveHits end

return Playing
