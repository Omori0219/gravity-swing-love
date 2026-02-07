local Settings = require("settings")
local Save = require("lib.save")

local Audio = {}
Audio.bgm = nil
Audio.hitSound = nil
Audio.gameOverSound = nil
Audio.isMuted = false
Audio.initialized = false
Audio.bgmVolume = 0.5      -- 0.0 ~ 1.0
Audio.sfxVolume = 0.5      -- 0.0 ~ 1.0

local function generateTriangleWave(frequency, duration, sampleRate)
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Triangle wave
        local phase = (t * frequency) % 1
        local value = 2 * math.abs(2 * phase - 1) - 1

        -- ADSR envelope: attack=0.005, decay=0.045, sustain_level=0.05, release
        local env = 0
        if t < 0.005 then
            env = t / 0.005
        elseif t < 0.05 then
            env = 1.0 - (t - 0.005) / 0.045 * 0.95
        elseif t < duration - 0.02 then
            env = 0.05
        else
            env = 0.05 * (duration - t) / 0.02
        end

        -- Fade out last few samples to prevent click
        if i > samples - 50 then
            env = env * (samples - i) / 50
        end

        soundData:setSample(i, value * env * 0.5)
    end
    return soundData
end

local function generateSawtoothWave(frequency, duration, sampleRate)
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Sawtooth wave
        local phase = (t * frequency) % 1
        local value = 2 * phase - 1

        -- Envelope: quick attack, long decay
        local env = 0
        if t < 0.01 then
            env = t / 0.01
        else
            env = math.max(0, 1.0 - (t - 0.01) / (duration - 0.01))
        end

        -- Fade edges to prevent click
        if i < 50 then
            env = env * i / 50
        elseif i > samples - 50 then
            env = env * (samples - i) / 50
        end

        soundData:setSample(i, value * env * 0.3)
    end
    return soundData
end

function Audio.init()
    if Audio.initialized then return end

    -- BGM
    local bgmPath = "assets/sounds/bgm.mp3"
    if love.filesystem.getInfo(bgmPath) then
        Audio.bgm = love.audio.newSource(bgmPath, "stream")
        Audio.bgm:setLooping(true)
        Audio.bgm:setVolume(Settings.BGM_VOLUME)
    end

    -- Hit sound (triangle wave, C5)
    local hitData = generateTriangleWave(Settings.HIT_SOUND_PITCH, Settings.HIT_SOUND_DURATION, 44100)
    Audio.hitSound = love.audio.newSource(hitData)

    -- Game over sound (sawtooth wave, C2)
    local goData = generateSawtoothWave(Settings.GAMEOVER_SOUND_PITCH, Settings.GAMEOVER_SOUND_DURATION, 44100)
    Audio.gameOverSound = love.audio.newSource(goData)

    -- Load saved state
    Audio.isMuted = Save.readMuteState()
    local volumes = Save.readVolumes()
    Audio.bgmVolume = volumes.bgm
    Audio.sfxVolume = volumes.sfx
    Audio.bgm:setVolume(Audio.bgmVolume)

    Audio.initialized = true
end

function Audio.playBGM()
    if not Audio.initialized or Audio.isMuted or not Audio.bgm then return end
    if not Audio.bgm:isPlaying() then
        Audio.bgm:play()
    end
end

function Audio.stopBGM()
    if Audio.bgm and Audio.bgm:isPlaying() then
        Audio.bgm:pause()
    end
end

function Audio.playHit()
    if not Audio.initialized or Audio.isMuted or not Audio.hitSound then return end
    Audio.hitSound:setVolume(Audio.sfxVolume)
    Audio.hitSound:stop()
    Audio.hitSound:play()
end

function Audio.playGameOver()
    if not Audio.initialized or Audio.isMuted or not Audio.gameOverSound then return end
    Audio.gameOverSound:setVolume(Audio.sfxVolume)
    Audio.gameOverSound:stop()
    Audio.gameOverSound:play()
end

function Audio.toggleMute()
    Audio.isMuted = not Audio.isMuted
    Save.writeMuteState(Audio.isMuted)
    if Audio.isMuted then
        Audio.stopBGM()
    end
end

function Audio.setBGMVolume(vol)
    Audio.bgmVolume = math.max(0, math.min(1, vol))
    if Audio.bgm then
        Audio.bgm:setVolume(Audio.bgmVolume)
    end
end

function Audio.setSFXVolume(vol)
    Audio.sfxVolume = math.max(0, math.min(1, vol))
end

function Audio.saveVolumes()
    Save.writeVolumes(Audio.bgmVolume, Audio.sfxVolume)
end

return Audio
