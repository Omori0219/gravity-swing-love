local Settings = require("settings")

local Save = {}

function Save.writeHighScore(score)
    love.filesystem.write(Settings.HIGH_SCORE_FILE, tostring(score))
end

function Save.readHighScore()
    if love.filesystem.getInfo(Settings.HIGH_SCORE_FILE) then
        local data = love.filesystem.read(Settings.HIGH_SCORE_FILE)
        return tonumber(data) or 0
    end
    return 0
end

function Save.writeMuteState(isMuted)
    love.filesystem.write(Settings.MUTE_STATE_FILE, isMuted and "1" or "0")
end

function Save.readMuteState()
    if love.filesystem.getInfo(Settings.MUTE_STATE_FILE) then
        return love.filesystem.read(Settings.MUTE_STATE_FILE) == "1"
    end
    return false
end

function Save.writeVolumes(bgmVol, sfxVol)
    love.filesystem.write("volumes.dat", string.format("%.2f,%.2f", bgmVol, sfxVol))
end

function Save.readVolumes()
    if love.filesystem.getInfo("volumes.dat") then
        local data = love.filesystem.read("volumes.dat")
        local bgm, sfx = data:match("([%d%.]+),([%d%.]+)")
        return {
            bgm = tonumber(bgm) or 0.5,
            sfx = tonumber(sfx) or 0.5,
        }
    end
    return { bgm = 0.5, sfx = 0.5 }
end

function Save.writeEternalMode(isEnabled)
    love.filesystem.write(Settings.ETERNAL_MODE_FILE, isEnabled and "1" or "0")
end

function Save.readEternalMode()
    if love.filesystem.getInfo(Settings.ETERNAL_MODE_FILE) then
        return love.filesystem.read(Settings.ETERNAL_MODE_FILE) == "1"
    end
    return false
end

function Save.writeDisplay(fullscreen, windowW, windowH)
    love.filesystem.write("display.dat", string.format("%s,%d,%d",
        fullscreen and "1" or "0", windowW, windowH))
end

function Save.readDisplay()
    if love.filesystem.getInfo("display.dat") then
        local data = love.filesystem.read("display.dat")
        local fs, w, h = data:match("([01]),(%d+),(%d+)")
        if fs then
            return {
                fullscreen = fs == "1",
                windowW = tonumber(w),
                windowH = tonumber(h),
            }
        end
    end
    return { fullscreen = false, windowW = Settings.CANVAS_WIDTH, windowH = Settings.CANVAS_HEIGHT }
end

return Save
