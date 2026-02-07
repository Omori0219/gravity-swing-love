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

return Save
