local Settings = {}

-- Color Palette
Settings.COLORS = {
    BACKGROUND = {0.102, 0.102, 0.180},        -- #1a1a2e
    GAME_BG = {0.165, 0.165, 0.306},            -- #2a2a4e
    ENEMY = {0.914, 0.271, 0.376},              -- #e94560
    ENEMY_STROKE = {0.753, 0.188, 0.314},       -- #c03050
    CANNON = {0.8, 0.8, 0.8},                   -- #cccccc
    PARTICLE_HIT = {
        {1, 0.843, 0},       -- #FFD700
        {1, 0.647, 0},       -- #FFA500
        {1, 0.271, 0},       -- #FF4500
        {0.529, 0.808, 0.98},-- #87CEFA
        {1, 1, 1},           -- #FFFFFF
    },
    PARTICLE_GAMEOVER = {0.392, 0.392, 0.588, 0.7}, -- rgba(100,100,150,0.7)
    FPS = {0, 1, 0},                            -- #00FF00
    WHITE = {1, 1, 1},
    BLACK = {0, 0, 0},
    YELLOW = {1, 0.922, 0.231},                  -- #ffeb3b
    RED = {0.957, 0.263, 0.212},                 -- #f44336
    GREEN = {0.298, 0.686, 0.314},               -- #4CAF50
    BLUE = {0.275, 0.510, 0.706},                -- #4682b4
    GRAY = {0.459, 0.459, 0.459},                -- #757575
    GOLD = {1, 0.843, 0},                        -- #FFD700
}

-- Canvas
Settings.CANVAS_WIDTH = 1200
Settings.CANVAS_HEIGHT = 900

-- Base canvas size (tuned at 800x600)
Settings.BASE_CANVAS_WIDTH = 800
Settings.BASE_CANVAS_HEIGHT = 600

local scale = Settings.CANVAS_WIDTH / Settings.BASE_CANVAS_WIDTH

-- Gameplay tuning knobs (edit these to adjust gravity feel)
local BASE_PLANET_MASS = 8000
local BASE_MAX_GRAVITY_FORCE = 2.0
-- NOTE: Settings.PLANET_MASS / MAX_GRAVITY_FORCE are auto-scaled from these. Don't edit those directly.

-- Asteroid (projectile)
Settings.ASTEROID_LAUNCH_DELAY_MIN = 1.2       -- seconds
Settings.ASTEROID_LAUNCH_DELAY_MAX = 2.5       -- seconds
Settings.ASTEROID_INITIAL_VX = 5.5
Settings.ASTEROID_SPEED_MIN = 1.0
Settings.ASTEROID_SPEED_MAX = 3.0
Settings.ASTEROID_RADIUS = 10
Settings.ASTEROID_TRAIL_LENGTH = 33
Settings.ASTEROID_BOUNDARY_BUFFER = 80
Settings.ASTEROID_INITIAL_COMBO_MIN = 0
Settings.ASTEROID_INITIAL_COMBO_MAX = 8
Settings.ASTEROID_INITIAL_COMBO_BIAS = 2.0    -- higher = more likely to be low

-- Planet (player-controlled gravity source)
Settings.PLANET_RADIUS = 10
Settings.PLANET_MASS = BASE_PLANET_MASS * scale * scale
Settings.PLANET_SUCK_IN_RADIUS = 8

-- Enemies
Settings.NUM_ENEMIES =7
Settings.ENEMY_RADIUS = 20
Settings.ENEMY_SPAWN_MARGIN_X = 50
Settings.ENEMY_SPAWN_MARGIN_Y = 30
Settings.ENEMY_SPAWN_SEPARATION = 30
Settings.ENEMY_SPAWN_MAX_ATTEMPTS = 50

-- Physics
Settings.GRAVITY_CONSTANT = 0.1
Settings.MAX_GRAVITY_FORCE = BASE_MAX_GRAVITY_FORCE * scale
Settings.BASE_FPS = 60
Settings.PHYSICS_TIME_SCALE = 1.0

-- Particles
Settings.PARTICLE_COUNT_HIT = 15
Settings.PARTICLE_COUNT_GAMEOVER = 30
Settings.PARTICLE_GRAVITY = 0.05

-- Visual effects
Settings.BASE_BONUS_FONT_SIZE = 24
Settings.BONUS_FONT_SIZE_INCREMENT = 4
Settings.SCREEN_SHAKE_DURATION = 0.4          -- seconds
Settings.SCREEN_SHAKE_INTENSITY = 20

-- Cannon
Settings.CANNON_X = 50
Settings.CANNON_WIDTH = 40
Settings.CANNON_HEIGHT = 20
Settings.CANNON_BARREL_LENGTH = 15
Settings.CANNON_BARREL_WIDTH = 8

-- Stars
Settings.STARS_COUNT = 100

-- Floating score
Settings.FLOATING_SCORE_DURATION = 1.0        -- seconds
Settings.FLOATING_SCORE_FONT_SIZE = 20

-- Asteroid appearance levels (combo-based color changes)
Settings.ASTEROID_APPEARANCE = {
    { type = "solid", color = {1, 1, 1} },                    -- combo 0: white
    { type = "solid", color = {0.529, 0.808, 0.980} },       -- combo 1: sky blue #87CEFA
    { type = "solid", color = {1, 0.843, 0} },               -- combo 2: gold #FFD700
    { type = "solid", color = {1, 0.647, 0} },               -- combo 3: orange #FFA500
    { type = "solid", color = {1, 0.271, 0} },               -- combo 4: red-orange #FF4500
    { type = "solid", color = {0.863, 0.078, 0.235} },       -- combo 5: crimson #DC143C
    { type = "gradient", colors = {{1,0,0}, {0.545,0,0}} },                    -- combo 6
    { type = "gradient", colors = {{0.541,0.169,0.886}, {1,0,0}} },            -- combo 7
    { type = "gradient", colors = {{1,1,1}, {1,0.843,0}, {0.863,0.078,0.235}} }, -- combo 8+
}

-- Audio
Settings.BGM_VOLUME = 0.18                    -- ~= 10^(-15/20)
Settings.HIT_SOUND_PITCH = 523.25            -- C5 in Hz
Settings.HIT_SOUND_DURATION = 0.15
Settings.GAMEOVER_SOUND_PITCH = 65.41         -- C2 in Hz
Settings.GAMEOVER_SOUND_DURATION = 1.5

-- Save keys
Settings.HIGH_SCORE_FILE = "highscore.dat"
Settings.MUTE_STATE_FILE = "mutestate.dat"

-- Debug
Settings.DEBUG = false

return Settings
