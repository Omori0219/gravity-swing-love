local Settings = require("settings")
local Stars = require("systems.stars")
local Audio = require("systems.audio")
local Save = require("lib.save")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screenshake")
local HUD = require("ui.hud")

-- States
local Title = require("states.title")
local Playing = require("states.playing")
local Paused = require("states.paused")
local GameOver = require("states.gameover")
local Options = require("states.options")

-- Game state
local currentState = "title"   -- "title", "playing", "paused", "gameover", "options"
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

    -- Initialize systems
    Stars.generate()
    Audio.init()
    highScore = Save.readHighScore()

    -- Enter title state
    Title.enter(fonts)
end

function love.update(dt)
    -- Cap dt to prevent physics explosion on lag
    dt = math.min(dt, 1/30)

    if currentState == "title" then
        Title.update(dt)
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
        Title.draw(highScore)
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
    if key == "escape" then
        if currentState == "options" then
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
            switchToTitle()
            return
        end
    end

    if currentState == "title" then
        local action = Title.keypressed(key)
        if action == "play" then
            switchToPlaying("normal")
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
        local action = GameOver.keypressed(key)
        if action == "play" then
            switchToPlaying(currentGameMode)
        end
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
            switchToPlaying("normal")
        elseif action == "play_timed" then
            switchToPlaying("timed")
        elseif action == "options" then
            switchToOptions()
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
        end
    end
end

-- State transitions

function switchToTitle()
    currentState = "title"
    Audio.stopBGM()
    Particles.clear()
    Title.enter(fonts)
end

function switchToOptions()
    currentState = "options"
    Options.enter(fonts)
end

function switchToPlaying(mode)
    currentGameMode = mode or "normal"
    currentState = "playing"
    Audio.init()
    Playing.enter(fonts, highScore, currentGameMode)
end

function switchToPaused()
    currentState = "paused"
    Audio.stopBGM()
    Paused.enter(fonts)
end

function switchToResume()
    currentState = "playing"
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

    local reason
    local header
    if Playing.isTimeUp() then
        header = "TIME UP!"
        reason = "Final score in 60 seconds"
    else
        header = "GAME OVER!"
        reason = "The earth destroyed."
    end

    currentState = "gameover"
    GameOver.enter(fonts, {
        score = finalScore,
        highScore = highScore,
        maxCombo = Playing.getMaxCombo(),
        playTime = HUD.formatPlayTime(Playing.getPlayTime()),
        reason = reason,
        header = header,
        isNewHighScore = isNewHighScore,
        gameMode = currentGameMode,
    })
end
