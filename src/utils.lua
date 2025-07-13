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
    local tile_x = math.floor(x / map.tilewidth)
    local tile_y = math.floor(y / map.tileheight)
    local tile = layer.data[tile_y] and layer.data[tile_y][tile_x]
    return tile and tile.id ~= 0 -- or tile.gid ~= 0, depending on your map
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

-- Return the module
return utils
