-- Imports
local utils = require("src.utils")

-- Entity class for game objects
local Entity = {}
Entity.__index = Entity

-- Helpers

function Entity:tryMove(map, dx, dy, dt)
    local next_x = self.x + dx * self.speed * dt
    local next_y = self.y + dy * self.speed * dt

    if utils.is_walkable(map, next_x, next_y) then
        self:setPosition(next_x, next_y)
        return true
    end
    return false
end

-- Entity class

-- Constructor for creating a new entity
function Entity.new(x, y, width, height)
    local self = setmetatable({}, Entity)

    -- Position and dimensions
    self.x = x or 0
    self.y = y or 0
    self.width = width or 32
    self.height = height or 32

    -- Velocity
    self.vx = 0
    self.vy = 0

    -- Additional properties
    self.rotation = 0
    self.scale = 1
    self.color = { 1, 1, 1, 1 }
    self.active = true

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

    return self.x - self.width / 2 < other.x + other.width / 2 and
        self.x + self.width / 2 > other.x - other.width / 2 and
        self.y - self.height / 2 < other.y + other.height / 2 and
        self.y + self.height / 2 > other.y - other.height / 2
end

-- Set the entity's velocity
function Entity:setVelocity(vx, vy)
    self.vx = vx or 0
    self.vy = vy or 0
end

-- Set the entity's position
function Entity:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y

    -- Round to the sprite position to the nearest pixel
    self.sprite_x = math.floor(self.x + 0.49)
    self.sprite_y =  math.floor(self.y + 0.49)
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