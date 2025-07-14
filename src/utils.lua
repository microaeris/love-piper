-- Utility functions for the game
local utils = {}

-- Calculate distance between two points
function utils.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Check if a point is inside a circle
function utils.pointInCircle(px, py, cx, cy, radius)
    return utils.distance(px, py, cx, cy) <= radius
end

-- Clamp a value between min and max
function utils.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

-- Linear interpolation between two values
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Check if a tile is walkable
function utils.is_walkable(map, x, y, layer_index)
    local layer = map.layers[layer_index or 2] -- default to layer 2
    local num_tiles_x = map.width
    local tile_x = (math.floor(x / map.tilewidth) % (num_tiles_x)) + 1
    local tile_y = math.floor(y / map.tileheight)
    local tile = layer.data[tile_y] and layer.data[tile_y][tile_x]
    return tile == nil or tile.id == 0 -- or tile.gid ~= 0, depending on your map
end

-- This should be the same as is_walkable, but idk
function utils.is_spawnable(map, x, y, layer_index)
    local layer = map.layers[layer_index or 2] -- default to layer 2
    local num_tiles_x = map.width
    local tile_x = (math.floor(x / map.tilewidth) % (num_tiles_x)) + 1
    local tile_y = math.floor(y / map.tileheight) + 1 -- Difference is here.
    local tile = layer.data[tile_y] and layer.data[tile_y][tile_x]
    return tile == nil or tile.id == 0                      -- or tile.gid ~= 0, depending on your map
end

-- Color utilities
utils.colors = {
    -- Basic colors
    white = { 1, 1, 1 },
    black = { 0, 0, 0 },
    red = { 1, 0, 0 },
    green = { 0, 1, 0 },
    blue = { 0, 0, 1 },
    yellow = { 1, 1, 0 },
    cyan = { 0, 1, 1 },
    magenta = { 1, 0, 1 },
    orange = { 1, 0.5, 0 },
    purple = { 0.5, 0, 1 },

    -- Create a color with alpha
    withAlpha = function(color, alpha)
        return { color[1], color[2], color[3], alpha }
    end,

    -- Blend two colors
    blend = function(color1, color2, factor)
        return {
            utils.lerp(color1[1], color2[1], factor),
            utils.lerp(color1[2], color2[2], factor),
            utils.lerp(color1[3], color2[3], factor),
            utils.lerp(color1[4] or 1, color2[4] or 1, factor)
        }
    end
}

-- Find a nearby walkable position suitable for the player to stand.
-- centre_x, centre_y: starting point to search around (in pixels)
-- width, height, foot_offset: dimensions of the entity trying to stand
-- max_radius_tiles: how many tiles outward to search (defaults to 5)
function utils.findSafeStandPosition(map, centre_x, centre_y, width, height, foot_offset, max_radius_tiles)
    local tile_w, tile_h = map.tilewidth, map.tileheight
    foot_offset = foot_offset or 0
    max_radius_tiles = max_radius_tiles or 5

    -- helper to test if all four corners / feet are walkable
    local function can_stand(px, py)
        local half_w, half_h   = width / 2, height / 2

        -- Foot positions (use foot_offset like Entity:tryMove)
        local top_left_foot_x  = px - half_w
        local top_left_foot_y  = py - half_h + foot_offset
        local top_right_foot_x = px + half_w
        local top_right_foot_y = top_left_foot_y

        -- bottom corners (full bbox)
        local bottom_left_x    = px - half_w
        local bottom_left_y    = py + half_h
        local bottom_right_x   = px + half_w
        local bottom_right_y   = bottom_left_y

        return utils.is_walkable(map, top_left_foot_x, top_left_foot_y) and
            utils.is_walkable(map, top_right_foot_x, top_right_foot_y) and
            utils.is_walkable(map, bottom_left_x, bottom_left_y) and
            utils.is_walkable(map, bottom_right_x, bottom_right_y)
    end

    -- Directions to search: centre first, then outward rings in 8 dirs.
    local dirs = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 }
    }

    for r = 0, max_radius_tiles do
        for _, d in ipairs(dirs) do
            local candidate_x = centre_x + d[1] * r * tile_w
            local candidate_y = centre_y + d[2] * r * tile_h
            if can_stand(candidate_x, candidate_y) then
                return candidate_x, candidate_y
            end
        end
    end
    -- If nothing found (unlikely), return original centre
    return centre_x, centre_y
end

-- Variant for spawning items. Uses utils.is_spawnable (this is a horrible hack).
function utils.findSafeSpawnPosition(map, centre_x, centre_y, width, height, foot_offset, max_radius_tiles)
    local tile_w, tile_h = map.tilewidth, map.tileheight
    foot_offset = foot_offset or 0
    max_radius_tiles = max_radius_tiles or 5

    local function can_spawn(px, py)
        local half_w, half_h   = width / 2, height / 2

        -- Using same corner/foot positions as stand check
        local top_left_foot_x  = px - half_w
        local top_left_foot_y  = py - half_h + foot_offset
        local top_right_foot_x = px + half_w
        local top_right_foot_y = top_left_foot_y

        local bottom_left_x    = px - half_w
        local bottom_left_y    = py + half_h
        local bottom_right_x   = px + half_w
        local bottom_right_y   = bottom_left_y

        return utils.is_spawnable(map, top_left_foot_x, top_left_foot_y) and
            utils.is_spawnable(map, top_right_foot_x, top_right_foot_y) and
            utils.is_spawnable(map, bottom_left_x, bottom_left_y) and
            utils.is_spawnable(map, bottom_right_x, bottom_right_y)
    end

    local dirs = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 }
    }

    for r = 0, max_radius_tiles do
        for _, d in ipairs(dirs) do
            local candidate_x = centre_x + d[1] * r * tile_w
            local candidate_y = centre_y + d[2] * r * tile_h
            if can_spawn(candidate_x, candidate_y) then
                return candidate_x, candidate_y
            end
        end
    end

    return centre_x, centre_y
end

-- Return the module
return utils
