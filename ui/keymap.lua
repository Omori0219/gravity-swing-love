local KeyMap = {}

function KeyMap.isConfirm(key)
    return key == "return" or key == "kpenter" or key == "space" or key == "z"
end

function KeyMap.isCancel(key)
    return key == "escape" or key == "x"
end

function KeyMap.isUp(key)
    return key == "up" or key == "w"
end

function KeyMap.isDown(key)
    return key == "down" or key == "s"
end

function KeyMap.isLeft(key)
    return key == "left" or key == "a"
end

function KeyMap.isRight(key)
    return key == "right" or key == "d"
end

return KeyMap
