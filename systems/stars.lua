local Settings = require("settings")

local Stars = {}
local bgImage = nil
local gravityShader = nil

local shaderCode = [[
    extern vec2 planetUV;       // planet position in texture UV space
    extern vec2 screenSize;     // screen dimensions in pixels
    extern float strength;      // distortion strength
    extern float maxDistortion; // cap to prevent extreme warping
    extern float radius;        // influence radius in pixels

    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
    {
        vec2 dir = planetUV - uv;
        float dist = length(dir * screenSize);

        if (dist > radius) {
            return Texel(tex, uv) * color;
        }

        float falloff = 1.0 - dist / radius;
        float distNorm = dist / screenSize.y;
        float distortion = strength / (distNorm * distNorm + 0.01);
        distortion = distortion * falloff;
        distortion = min(distortion, maxDistortion);

        vec2 distortedUV = uv - normalize(dir) * distortion;
        distortedUV = clamp(distortedUV, 0.0, 1.0);

        return Texel(tex, distortedUV) * color;
    }
]]

function Stars.generate()
    local ok, img = pcall(love.graphics.newImage, "assets/images/space-retouch.png")
    if ok then
        bgImage = img
        bgImage:setFilter("linear", "linear")
    end
    gravityShader = love.graphics.newShader(shaderCode)
end

function Stars.draw(planetX, planetY)
    if bgImage then
        local w, h = Settings.CANVAS_WIDTH, Settings.CANVAS_HEIGHT
        local imgW, imgH = bgImage:getDimensions()
        local scale = math.max(w / imgW, h / imgH)
        local ox = (w - imgW * scale) / 2
        local oy = (h - imgH * scale) / 2

        if gravityShader and planetX then
            -- Convert planet screen position to texture UV
            local pu = (planetX - ox) / (imgW * scale)
            local pv = (planetY - oy) / (imgH * scale)
            gravityShader:send("planetUV", {pu, pv})
            gravityShader:send("screenSize", {w, h})
            gravityShader:send("strength", Settings.GRAVITY_LENS_STRENGTH)
            gravityShader:send("maxDistortion", Settings.GRAVITY_LENS_MAX_DISTORTION)
            gravityShader:send("radius", Settings.GRAVITY_LENS_RADIUS)
            love.graphics.setShader(gravityShader)
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bgImage, ox, oy, 0, scale, scale)

        if gravityShader and planetX then
            love.graphics.setShader()
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Stars
