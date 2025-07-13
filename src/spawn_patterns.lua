-- Pattern functions for enemy wave spawns
-- Each function returns dx, dy offsets based on the enemy's index in the wave
-- index:   1-based index of the enemy in the current wave
-- count:   total enemies in the wave
-- spacing: pixel spacing between consecutive enemies

local patterns = {}

-- Horizontal line moving rightwards (x offset increases)
function patterns.horizontal_line(index, count, spacing)
    return (index - 1) * spacing, 0
end

-- Vertical line moving downward (y offset increases)
function patterns.vertical_line(index, count, spacing)
    return 0, (index - 1) * spacing
end

-- Down-right diagonal line
function patterns.diagonal_down(index, count, spacing)
    local offset = (index - 1) * spacing
    return offset, offset
end

-- V-shape (⩓). Enemies on the edges are lower than those near the centre.
function patterns.v_shape(index, count, spacing)
    local mid = (count + 1) / 2
    local dx = (index - 1) * spacing
    local dy = math.abs(index - mid) * spacing
    return dx, dy
end

-- Circle pattern – enemies evenly distributed on a circle
function patterns.circle(index, count, spacing)
    -- Distribute points uniformly around a circle
    local angle = (index - 1) / count * 2 * math.pi
    -- Make radius scale with count a bit so large waves spread out
    local radius = spacing * ((count - 1) / (2 * math.pi) + 1)
    return math.cos(angle) * radius, math.sin(angle) * radius
end

-- Sine-wave pattern moving left-to-right while oscillating vertically
function patterns.sine_wave(index, count, spacing)
    local dx = (index - 1) * spacing
    local amplitude = spacing * 2
    local frequency = 2 * math.pi / count
    local dy = math.sin((index - 1) * frequency) * amplitude
    return dx, dy
end

-- Zig-zag pattern (alternating up/down offsets)
function patterns.zigzag(index, count, spacing)
    local dx = (index - 1) * spacing
    local amplitude = spacing
    local dy = (index % 2 == 0) and amplitude or -amplitude
    return dx, dy
end

-- Random cluster pattern – scatter within a square of radius based on spacing
function patterns.random_cluster(index, count, spacing)
    local radius = spacing * count / 2
    local dx = (math.random() * 2 - 1) * radius
    local dy = (math.random() * 2 - 1) * radius
    return dx, dy
end

-- Fallback pattern (alias of horizontal_line)
patterns.default = patterns.horizontal_line

return patterns
