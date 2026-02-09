local KeyMap = {}

function KeyMap.isConfirm(key)
    return key == "return" or key == "kpenter" or key == "space"
end

function KeyMap.isCancel(key)
    return key == "escape"
end

function KeyMap.isUp(key)
    return key == "up"
end

function KeyMap.isDown(key)
    return key == "down"
end

function KeyMap.isLeft(key)
    return key == "left"
end

function KeyMap.isRight(key)
    return key == "right"
end

return KeyMap
