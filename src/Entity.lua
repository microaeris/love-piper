-- Imports
local utils = require("src.utils")

-- Entity class for game objects
local Entity = {}
Entity.__index = Entity

-- Helpers

-- Get the foot position (where the entity actually stands)
function Entity:getFootPosition()
    return self.x, self.y + self.foot_offset
end

-- Get the foot position as integers for tile-based collision
function Entity:getFootTilePosition()
    local foot_x, foot_y = self:getFootPosition()
    return math.floor(foot_x), math.floor(foot_y)
end

function Entity:tryMove(map, dx, dy, dt)
    -- Treat dx and dy as *displacements* that have already incorporated speed and dt.
    -- Calculate the prospective new top-left position.
    local next_x_top_left = self.x + dx
    local next_y_top_left = self.y + dy

    local next_x_top_right = next_x_top_left + self.width
    local next_y_top_right = next_y_top_left

    local next_x_bottom_left = next_x_top_left
    local next_y_bottom_left = next_y_top_left + self.height

    local next_x_bottom_right = next_x_top_right
    local next_y_bottom_right = next_y_bottom_left

    -- Use foot position for collision detection
    local next_x_top_left_foot = next_x_top_left
    local next_y_top_left_foot = next_y_top_left + self.foot_offset

    local next_x_top_right_foot = next_x_top_right
    local next_y_top_right_foot = next_y_top_right + self.foot_offset

    if utils.is_walkable(map, next_x_top_left_foot, next_y_top_left_foot) and
        utils.is_walkable(map, next_x_top_right_foot, next_y_top_right_foot) and
        utils.is_walkable(map, next_x_bottom_left, next_y_bottom_left) and
        utils.is_walkable(map, next_x_bottom_right, next_y_bottom_right) then
        self:setPosition(next_x_top_left, next_y_top_left)
        return true
    end
    return false
end

-- Entity class

-- Constructor for creating a new entity
function Entity.new(x, y, width, height, foot_offset)
    local self            = setmetatable({}, Entity)

    -- Position and dimensions
    self.x                = x or 0
    self.y                = y or 0
    self.width            = width or 0
    self.height           = height or 0

    -- Foot position offset (distance from top to foot)
    -- This is applied to the y axis only.
    self.foot_offset      = foot_offset or 0

    -- Collision box (can be narrower than visual sprite)
    self.collision_width  = width
    self.collision_height = height

    -- Velocity
    self.vx               = 0
    self.vy               = 0

    -- Additional properties
    self.rotation         = 0
    self.scale            = 1
    self.color            = { 1, 1, 1, 1 }
    self.active           = true

    return self
end

-- Update the entity's position based on velocity
function Entity:update(map, dt)
    if not self.active then return end

    return self:tryMove(map, self.vx * dt, self.vy * dt, dt)
end

-- Draw the entity (default implementation is a rectangle)
function Entity:draw()
    if not self.active then return end

    love.graphics.setColor(self.color)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.rectangle("fill", -self.width / 2, -self.height / 2, self.width, self.height)
    love.graphics.pop()
end

-- Check if this entity collides with another entity (simple AABB collision)
function Entity:collidesWith(other)
    if not self.active or not other.active then return false end

    local self_w  = self.collision_width or self.width
    local self_h  = self.collision_height or self.height
    local other_w = other.collision_width or other.width
    local other_h = other.collision_height or other.height

    return self.x - self_w / 2 < other.x + other_w / 2 and
        self.x + self_w / 2 > other.x - other_w / 2 and
        self.y - self_h / 2 < other.y + other_h / 2 and
        self.y + self_h / 2 > other.y - other_h / 2
end

-- Set the entity's velocity
function Entity:setVelocity(vx, vy)
    self.vx = vx or 0
    self.vy = vy or 0
end

-- Set the entity's position
function Entity:setPosition(x, y)
    -- Entity's internal position in float precision
    self.x = x or self.x
    self.y = y or self.y

    -- Round to the sprite position to the nearest pixel
    self.sprite_x = math.floor(self.x + 0.5)
    self.sprite_y = math.floor(self.y + 0.5)
end

-- Create a derived class from Entity
function Entity:extend()
    local cls = {}
    cls.__index = cls
    setmetatable(cls, self)
    return cls
end

-- Return the Entity class
return Entity
