local Settings = require("settings")

function love.conf(t)
    t.identity = "gravity-swing-love"
    t.version = "11.5"
    t.window.title = "Gravity Swing"
    t.window.width = Settings.CANVAS_WIDTH
    t.window.height = Settings.CANVAS_HEIGHT
    t.window.resizable = true
    t.window.highdpi = true
    t.window.vsync = 1
    t.modules.physics = false
    t.modules.joystick = false
    t.modules.video = false
end
