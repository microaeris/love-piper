-- Pattern definitions for enemy waves
-- Each pattern entry contains:
--   offsets(index, wave_size, spacing) -> dx, dy
--   wave_size  : number of enemies in the formation
--   spacing    : pixel spacing between consecutive enemies (optional)
--   enemy_type : preferred enemy template (optional)
--
-- EnemySpawner will request a random pattern via spawn_patterns.randomPattern().

local spawn_patterns = {}

---------------------------------------------------------------------
-- Utility helpers
---------------------------------------------------------------------
local function addPattern(name, def)
    spawn_patterns[name] = def
end

local function getKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    return keys
end

function spawn_patterns.randomPattern()
    local keys = {}
    for k, v in pairs(spawn_patterns) do
        if type(v) == "table" then
            table.insert(keys, k)
        end
    end
    assert(#keys > 0, "No patterns registered in spawn_patterns.lua")
    local name = keys[math.random(#keys)]
    return name, spawn_patterns[name]
end

---------------------------------------------------------------------
-- Pattern implementations
---------------------------------------------------------------------

-- 1. Vertical line of 3 fast enemies
addPattern("vertical_line", {
    wave_size = 3,
    spacing = 24,
    enemy_type = "fast",
    offsets = function(index, wave_size, spacing)
        return 0, (index - 1) * spacing
    end
})

-- 2. Horizontal line
addPattern("horizontal_line", {
    wave_size = 4,
    spacing = 24,
    enemy_type = "basic",
    offsets = function(index, wave_size, spacing)
        return (index - 1) * spacing, 0
    end
})

-- 3. Diagonal down-right
addPattern("diagonal_down", {
    wave_size = 4,
    spacing = 24,
    enemy_type = "basic",
    offsets = function(index, wave_size, spacing)
        local o = (index - 1) * spacing
        return o, o
    end
})

-- 4. V-shape
addPattern("v_shape", {
    wave_size = 5,
    spacing = 24,
    enemy_type = "wobbler",
    offsets = function(index, wave_size, spacing)
        local mid = (wave_size + 1) / 2
        local dx = (index - 1) * spacing
        local dy = math.abs(index - mid) * spacing
        return dx, dy
    end
})

return spawn_patterns
