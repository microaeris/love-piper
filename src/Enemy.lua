-- Enemy class that extends Entity
local Entity = require("src.Entity")
local Sprite = require("src.Sprite")
local utils = require("src.utils")

local Enemy = Entity:extend()

-- Enemy types with different behaviors
local ENEMY_TYPES = {
    {
        name = "basic",
        speed = 30,
        color = utils.colors.blue,
        width = 16,
        height = 16,
        health = 1,
        behavior = "straight_left"
    },
    {
        name = "fast",
        speed = 60,
        color = utils.colors.orange,
        width = 16,
        height = 16,
        health = 1,
        behavior = "straight_left"
    },
    {
        name = "wobbler",
        speed = 25,
        color = utils.colors.purple,
        width = 16,
        height = 16,
        health = 1,
        behavior = "wobble_left"
    }
}

-- Constructor for creating a new enemy
function Enemy.new(x, y, enemy_type)
    local enemy_type = enemy_type or ENEMY_TYPES[1]
    local self = Entity.new(x, y, enemy_type.width, enemy_type.height)
    setmetatable(self, Enemy)

    -- Narrow collision box so player can squeeze between spaced enemies
    self.collision_width  = enemy_type.width * 0.65 -- slimmer
    self.collision_height = enemy_type.height * 0.8

    -- Enemy-specific properties
    self.speed            = enemy_type.speed
    -- Copy the color table so each enemy has its own instance (avoid shared reference)
    self.color            = { unpack(enemy_type.color) }
    -- Keep a copy of the original color so we can flash red on hit and revert later
    self.original_color   = { unpack(self.color) }

    -- Timer for red flash when hit
    self.hit_timer        = 0
    self.health           = enemy_type.health
    self.behavior         = enemy_type.behavior
    self.enemy_type       = enemy_type.name

    -- Behavior-specific properties
    self.wobble_time      = 0
    self.wobble_amplitude = 30
    self.wobble_frequency = 3

    -- Sprite setup (use player sprite but recolor it)
    self.sprite           = Sprite.new('assets/images/sprites/player_sheet.png', 16, 16)
    self.sprite:addAnimation('walk_left', '9-12,1', 0.1)
    self.sprite:addAnimation('idle', { { 1, 1 } }, 0.1)
    self.current_animation = 'walk_left'
    self.animation = self.sprite:cloneAnimation('walk_left')

    -- Set initial velocity based on behavior
    if self.behavior == "straight_left" then
        self:setVelocity(-self.speed, 0)
    elseif self.behavior == "wobble_left" then
        self:setVelocity(-self.speed, 0)
    end

    return self
end

-- Update enemy behavior
function Enemy:update(map, dt)
    if not self.active then return end

    -- Handle hit flash timer – while >0 keep red tint, then revert
    if self.hit_timer > 0 then
        self.hit_timer = self.hit_timer - dt
        if self.hit_timer <= 0 then
            -- Restore the original colour when flash period ends
            self.color = { unpack(self.original_color) }
        end
    end

    -- Handle different behaviors
    if self.behavior == "straight_left" then
        -- Simple straight movement to the left
        self:setVelocity(-self.speed, 0)
    elseif self.behavior == "wobble_left" then
        -- Wobble up and down while moving left
        self.wobble_time = self.wobble_time + dt
        local wobble_vy = math.sin(self.wobble_time * self.wobble_frequency) * self.wobble_amplitude
        self:setVelocity(-self.speed, wobble_vy)
    end

    -- TODO(jm): Should change this.
    -- Update position directly (enemies ignore map collision)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self:setPosition(self.x, self.y)

    -- Update animation
    if self.animation then
        self.animation:update(dt)
    end

    -- Check if enemy has moved off-screen (left side)
    if self.x < -self.width then
        self.active = false
    end
end

-- Override draw method to use sprite with color tinting
function Enemy:draw()
    if not self.active then return end

    -- Centre-on-pivot, then snap to pixel grid
    local sprite_x = math.floor(self.x - self.width / 2 + 0.5)
    local sprite_y = math.floor(self.y - self.height / 2 + 0.5)

    -- Apply color tinting based on enemy type
    love.graphics.setColor(self.color)

    if self.animation then
        self.animation:draw(self.sprite.image, sprite_x, sprite_y, self.rotation)
    else
        self.sprite:drawFrame(1, 1, sprite_x, sprite_y, self.rotation)
    end
end

-- Take damage
function Enemy:takeDamage(amount)
    self.health = self.health - (amount or 1)
    if self.health <= 0 then
        self.active = false
    end
end

-- Get a random enemy type
function Enemy.getRandomType()
    return ENEMY_TYPES[math.random(1, #ENEMY_TYPES)]
end

-- Return the Enemy class
function Enemy.getTypeByName(name)
    for _, t in ipairs(ENEMY_TYPES) do
        if t.name == name then
            return t
        end
    end
    -- Fallback to first type if not found
    return ENEMY_TYPES[1]
end

return Enemy
