local Settings = require("settings")

local Save = {}

function Save.writeHighScore(score)
    love.filesystem.write(Settings.HIGH_SCORE_FILE, tostring(score))
end

function Save.readHighScore()
    if love.filesystem.getInfo(Settings.HIGH_SCORE_FILE) then
        return tonumber(love.filesystem.read(Settings.HIGH_SCORE_FILE)) or 0
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

return Save
