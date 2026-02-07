function love.conf(t)
    t.identity = "gravity-swing-love"
    t.version = "11.5"
    t.window.title = "Gravity Swing"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.highdpi = true
    t.window.vsync = 1
    t.modules.physics = false
    t.modules.joystick = false
    t.modules.video = false
end
