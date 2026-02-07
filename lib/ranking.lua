local Ranking = {}

local RANKING_FILE = "ranking.dat"
local MAX_ENTRIES = 10

local list = {}

function Ranking.load()
    list = {}
    if love.filesystem.getInfo(RANKING_FILE) then
        local data = love.filesystem.read(RANKING_FILE)
        for line in data:gmatch("[^\n]+") do
            local name, score = line:match("^(.+),(%d+)$")
            if name and score then
                table.insert(list, { name = name, score = tonumber(score) })
            end
        end
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    -- Trim to max
    while #list > MAX_ENTRIES do
        table.remove(list)
    end
end

function Ranking.save()
    local lines = {}
    for _, entry in ipairs(list) do
        table.insert(lines, entry.name .. "," .. tostring(entry.score))
    end
    love.filesystem.write(RANKING_FILE, table.concat(lines, "\n"))
end

function Ranking.isQualified(score)
    if score <= 0 then return false end
    if #list < MAX_ENTRIES then return true end
    return score > list[#list].score
end

function Ranking.insert(name, score)
    table.insert(list, { name = name, score = score })
    table.sort(list, function(a, b) return a.score > b.score end)
    while #list > MAX_ENTRIES do
        table.remove(list)
    end
    Ranking.save()
end

function Ranking.getList()
    return list
end

function Ranking.getHighScore()
    if #list > 0 then
        return list[1].score
    end
    return 0
end

return Ranking
