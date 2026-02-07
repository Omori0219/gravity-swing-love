local Settings = require("settings")
local Stars = require("systems.stars")
local Audio = require("systems.audio")
local Enemy = require("entities.enemy")
local Save = require("lib.save")
local Ranking = require("lib.ranking")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screenshake")
local HUD = require("ui.hud")

-- States
local Title = require("states.title")
local Playing = require("states.playing")
local Paused = require("states.paused")
local GameOver = require("states.gameover")
local Options = require("states.options")
local Ready = require("states.ready")

-- Game state
local currentState = "title"   -- "title", "ready", "playing", "paused", "gameover", "options"
local highScore = 0
local currentGameMode = "normal"  -- "normal" or "timed"
local fonts = {}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    -- Load fonts
    local fontPath = "assets/fonts/PressStart2P.ttf"
    fonts.tiny = love.graphics.newFont(fontPath, 8)
    fonts.small = love.graphics.newFont(fontPath, 10)
    fonts.medium = love.graphics.newFont(fontPath, 16)
    fonts.large = love.graphics.newFont(fontPath, 24)
    fonts.title = love.graphics.newFont(fontPath, 28)
    fonts.timer = love.graphics.newFont(fontPath, 48)
    fonts.floating = love.graphics.newFont(fontPath, Settings.FLOATING_SCORE_FONT_SIZE)

    -- Initialize systems
    Stars.generate()
    Audio.init()
    Enemy.loadImage()
    Ranking.load()

    -- Migrate: seed ranking from old high score if ranking is empty
    if #Ranking.getList() == 0 then
        local oldHigh = Save.readHighScore()
        if oldHigh > 0 then
            Ranking.insert("???", oldHigh)
        end
    end

    highScore = Ranking.getHighScore()

    -- Enter title state
    Title.enter(fonts, Ranking.getList())
end

function love.update(dt)
    -- Cap dt to prevent physics explosion on lag
    dt = math.min(dt, 1/30)

    if currentState == "title" then
        Title.update(dt)
    elseif currentState == "ready" then
        Ready.update(dt)
    elseif currentState == "options" then
        Options.update(dt)
    elseif currentState == "playing" then
        Playing.update(dt)
        -- Check if game over happened during update
        if Playing.isGameOver() then
            switchToGameOver()
        end
    elseif currentState == "paused" then
        Paused.update(dt)
    elseif currentState == "gameover" then
        -- Still update particles and screen shake in playing state
        Playing.update(dt)
        GameOver.update(dt)
    end
end

function love.draw()
    love.graphics.setColor(Settings.COLORS.BACKGROUND)
    love.graphics.rectangle("fill", 0, 0, Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT)

    if currentState == "title" then
        Title.draw()
    elseif currentState == "ready" then
        Playing.draw()
        Ready.draw()
    elseif currentState == "options" then
        Options.draw()
    elseif currentState == "playing" then
        Playing.draw()
    elseif currentState == "paused" then
        Playing.draw()
        Paused.draw()
    elseif currentState == "gameover" then
        Playing.draw()
        GameOver.draw()
    end
end

function love.keypressed(key)
    if key == "f5" then
        love.event.quit("restart")
        return
    end

    if key == "escape" then
        if currentState == "ready" then
            switchToTitle()
            return
        elseif currentState == "options" then
            Audio.saveVolumes()
            switchToTitle()
            return
        elseif currentState == "playing" then
            switchToPaused()
            return
        elseif currentState == "paused" then
            switchToResume()
            return
        elseif currentState == "gameover" then
            if GameOver.getPhase() == "result" then
                switchToTitle()
            end
            return
        end
    end

    if currentState == "title" then
        local action = Title.keypressed(key)
        if action == "play" then
            switchToReady()
        end
    elseif currentState == "ready" then
        local action = Ready.keypressed(key)
        if action == "start" then
            switchToPlaying(currentGameMode)
        end
    elseif currentState == "options" then
        local action = Options.keypressed(key)
        if action == "back" then
            switchToTitle()
        end
    elseif currentState == "playing" then
        local action = Playing.keypressed(key)
        if action == "pause" then
            switchToPaused()
        end
    elseif currentState == "paused" then
        local action = Paused.keypressed(key)
        if action == "resume" then
            switchToResume()
        elseif action == "quit" then
            switchToTitle()
        end
    elseif currentState == "gameover" then
        local action, name = GameOver.keypressed(key)
        if action == "name_confirmed" then
            Ranking.insert(name, Playing.getScore())
            highScore = Ranking.getHighScore()
        elseif action == "play" then
            switchToPlaying(currentGameMode)
        end
    end
end

function love.textinput(text)
    if currentState == "gameover" then
        GameOver.textinput(text)
    end
end

function love.mousemoved(x, y)
    if currentState == "options" then
        Options.mousemoved(x, y)
    end
end

function love.mousereleased(x, y, button)
    if currentState == "options" then
        Options.mousereleased(x, y, button)
    end
end

function love.mousepressed(x, y, button)
    if currentState == "title" then
        local action = Title.mousepressed(x, y, button)
        if action == "play" then
            switchToReady()
        elseif action == "options" then
            switchToOptions()
        end
    elseif currentState == "ready" then
        local action = Ready.mousepressed(x, y, button)
        if action == "start" then
            switchToPlaying(currentGameMode)
        end
    elseif currentState == "options" then
        local action = Options.mousepressed(x, y, button)
        if action == "back" then
            switchToTitle()
        end
    elseif currentState == "playing" then
        Playing.mousepressed(x, y, button)
    elseif currentState == "gameover" then
        local action = GameOver.mousepressed(x, y, button)
        if action == "play" then
            switchToPlaying(currentGameMode)
        elseif action == "title" then
            switchToTitle()
        end
    end
end

-- State transitions

function switchToTitle()
    currentState = "title"
    love.mouse.setVisible(true)
    Audio.stopBGM()
    Particles.clear()
    Title.enter(fonts, Ranking.getList())
end

function switchToOptions()
    currentState = "options"
    Options.enter(fonts)
end

function switchToReady()
    currentGameMode = Options.isEternalMode() and "normal" or "timed"
    currentState = "ready"
    Playing.enter(fonts, highScore, currentGameMode)
    Ready.enter(fonts, currentGameMode)
end

function switchToPlaying(mode)
    currentGameMode = mode or "normal"
    currentState = "playing"
    love.mouse.setVisible(false)
    Audio.init()
    Playing.enter(fonts, highScore, currentGameMode)
end

function switchToPaused()
    currentState = "paused"
    love.mouse.setVisible(true)
    Audio.stopBGM()
    Paused.enter(fonts)
end

function switchToResume()
    currentState = "playing"
    love.mouse.setVisible(false)
    Audio.playBGM()
end

function switchToGameOver()
    local finalScore = Playing.getScore()
    local isNewHighScore = finalScore > highScore
    if isNewHighScore then
        highScore = finalScore
        Save.writeHighScore(highScore)
    end
    Playing.setHighScore(highScore)

    local qualified = Ranking.isQualified(finalScore)

    local reason
    local header
    if Playing.isTimeUp() then
        header = "TIME UP!"
        reason = "Final score in 120 seconds"
    else
        header = "GAME OVER!"
        reason = "The earth destroyed."
    end

    currentState = "gameover"
    love.mouse.setVisible(true)
    GameOver.enter(fonts, {
        score = finalScore,
        highScore = highScore,
        maxCombo = Playing.getMaxCombo(),
        playTime = HUD.formatPlayTime(Playing.getPlayTime()),
        reason = reason,
        header = header,
        isNewHighScore = isNewHighScore,
        gameMode = currentGameMode,
        qualified = qualified,
    })
end
