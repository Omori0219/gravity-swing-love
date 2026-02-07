local ScreenShake = {}
ScreenShake.timer = 0
ScreenShake.duration = 0
ScreenShake.intensity = 0
ScreenShake.offsetX = 0
ScreenShake.offsetY = 0

function ScreenShake.trigger(duration, intensity)
    ScreenShake.timer = duration
    ScreenShake.duration = duration
    ScreenShake.intensity = intensity
end

function ScreenShake.update(dt)
    if ScreenShake.timer > 0 then
        ScreenShake.timer = ScreenShake.timer - dt
        local remaining = math.max(0, ScreenShake.timer / ScreenShake.duration)
        local currentIntensity = ScreenShake.intensity * remaining
        ScreenShake.offsetX = (math.random() - 0.5) * 2 * currentIntensity
        ScreenShake.offsetY = (math.random() - 0.5) * 2 * currentIntensity
    else
        ScreenShake.offsetX = 0
        ScreenShake.offsetY = 0
    end
end

function ScreenShake.getOffset()
    return ScreenShake.offsetX, ScreenShake.offsetY
end

return ScreenShake
