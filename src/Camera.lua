-- Camera module for handling scrolling and transforms
local Camera = {}

-- Constructor for creating a new camera
function Camera.new(scroll_speed)
    local self = {
        x = 0,
        y = 0,
        scroll_speed = scroll_speed or 30, -- Default scroll speed
    }

    setmetatable(self, { __index = Camera })
    return self
end

-- Update camera position (constant horizontal scrolling)
function Camera:update(dt, map)
    -- Constantly scroll horizontally at fixed speed
    self.x = self.x + self.scroll_speed * dt

    -- Make camera loop when it exceeds map width
    local map_width = map.width * map.tilewidth
    if self.x >= map_width then
        self.x = self.x - map_width
    end
end

-- Draw the map with seamless looping using STI's built-in translation
function Camera:draw_scrolling_map(map)
    -- Draw map multiple times for seamless looping
    local map_width_px = map.width * map.tilewidth

    -- Calculate how many map instances we need to draw
    local start_offset = -math.floor(self.x / map_width_px) * map_width_px

    for i = 0, 2 do -- Draw 3 instances to ensure screen coverage
        local offset_x = start_offset + i * map_width_px - self.x
        map:draw(offset_x, -self.y)
    end
end

-- Getters/Setters
function Camera:get_position()
    return self.x, self.y
end

function Camera:set_position(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function Camera:set_scroll_speed(speed)
    self.scroll_speed = speed or 30
end

function Camera:get_scroll_speed()
    return self.scroll_speed
end

-- Return the Camera module
return Camera
