local Settings = require("settings")

local Particles = {}
Particles.list = {}

function Particles.spawn(x, y, type)
    local count = (type == "hit") and Settings.PARTICLE_COUNT_HIT or Settings.PARTICLE_COUNT_GAMEOVER

    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random() * 3 + 1
        local color, radius, life

        if type == "hit" then
            local colors = Settings.COLORS.PARTICLE_HIT
            color = colors[math.random(#colors)]
            radius = math.random() * 3 + 1
            life = math.random() * 0.5 + 0.5
        else
            color = Settings.COLORS.PARTICLE_GAMEOVER
            radius = math.random() * 4 + 2
            life = math.random() * 0.8 + 0.7
        end

        table.insert(Particles.list, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            radius = radius,
            color = color,
            life = life,
            initialLife = life,
        })
    end
end

function Particles.update(dt)
    local timeScale = dt * Settings.BASE_FPS * Settings.PHYSICS_TIME_SCALE

    for i = #Particles.list, 1, -1 do
        local p = Particles.list[i]
        p.x = p.x + p.vx * timeScale
        p.y = p.y + p.vy * timeScale
        p.vy = p.vy + Settings.PARTICLE_GRAVITY * timeScale
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Particles.list, i)
        end
    end
end

function Particles.draw()
    for _, p in ipairs(Particles.list) do
        local alpha = math.max(0, p.life / p.initialLife)
        if #p.color == 4 then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.color[4] * alpha)
        else
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        end
        love.graphics.circle("fill", p.x, p.y, p.radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Particles.clear()
    Particles.list = {}
end

return Particles
