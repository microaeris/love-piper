-- Enemy class that extends Entity
local Entity                   = require("src.Entity")
local Sprite                   = require("src.Sprite")
local utils                    = require("src.utils")

-- Constants
local COLLISION_WIDTH_SCALE    = 0.65 -- Collision hitbox width relative to sprite width
local COLLISION_HEIGHT_SCALE   = 0.8  -- Collision hitbox height relative to sprite height
local WOBBLE_DEFAULT_AMPLITUDE = 30   -- Base amplitude (pixels) for wobble movement
local WOBBLE_DEFAULT_FREQUENCY = 3    -- Wobbles per second
local PIXEL_ALIGN_OFFSET       = 0.5  -- Offset used when rounding positions for crisp pixels

local Enemy                    = Entity:extend()

-- Enemy types with different behaviors
local ENEMY_TYPES              = {
    -- Each enemy type corresponds to a column in the sprite sheet’s first row
    {
        name = "basic",
        speed = 30,
        frame = 1,
        width = 16,
        height = 16,
        health = 1,
        behavior = "straight_left",
    },
    {
        name = "fast",
        speed = 60,
        frame = 2,
        width = 16,
        height = 16,
        health = 1,
        behavior = "straight_left",
    },
    {
        name = "wobbler",
        speed = 25,
        frame = 3,
        width = 16,
        height = 16,
        health = 1,
        behavior = "wobble_left",
    }
}

-- Constructor for creating a new enemy
function Enemy.new(x, y, enemy_type)
    local enemy_type = enemy_type or ENEMY_TYPES[1]
    local self = Entity.new(x, y, enemy_type.width, enemy_type.height)
    setmetatable(self, Enemy)

    -- Narrow collision box so player can squeeze between spaced enemies
    self.collision_width  = enemy_type.width * COLLISION_WIDTH_SCALE -- slimmer
    self.collision_height = enemy_type.height * COLLISION_HEIGHT_SCALE

    -- Enemy-specific properties
    -- Apply global speed multiplier if active (set by power-ups)
    local mult            = _G.ENEMY_SPEED_MULT or 1
    self.speed            = enemy_type.speed * mult
    -- Default colour is white (no sprite tint). We still use colour for red hit flashes.
    self.color            = { 1, 1, 1, 1 }
    self.original_color   = { 1, 1, 1, 1 }

    -- Timer for red flash when hit
    self.hit_timer        = 0
    self.health           = enemy_type.health
    self.behavior         = enemy_type.behavior
    self.enemy_type       = enemy_type.name

    -- Behavior-specific properties
    self.wobble_time      = 0
    self.wobble_amplitude = WOBBLE_DEFAULT_AMPLITUDE * mult
    self.wobble_frequency = WOBBLE_DEFAULT_FREQUENCY

    -- Sprite setup
    self.sprite           = Sprite.new('assets/images/sprites/enemy_sheet.png', 16, 16)
    -- Select the correct frame for this enemy type (column = enemy_type.frame)
    self.frame_quad       = self.sprite:getFrame(enemy_type.frame or 1, 1)
    self.animation        = nil -- no animation frames

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

    -- If a global speed multiplier reset to 1 and we had stored original wobble amplitude, restore it.
    if self.original_wobble_amplitude and (_G.ENEMY_SPEED_MULT or 1) == 1 then
        self.wobble_amplitude          = self.original_wobble_amplitude
        self.original_wobble_amplitude = nil
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
    local sprite_x = math.floor(self.x - self.width / 2 + PIXEL_ALIGN_OFFSET)
    local sprite_y = math.floor(self.y - self.height / 2 + PIXEL_ALIGN_OFFSET)

    love.graphics.setColor(self.color)

    -- Draw static frame (no animation)
    love.graphics.draw(self.sprite.image, self.frame_quad, sprite_x, sprite_y, self.rotation)
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
