-- Player class that extends Entity
local Entity = require("src.Entity")
local Sprite = require("src.Sprite")
local utils = require("src.utils")

local Player = Entity:extend()

-- Constructor for creating a new player
function Player.new(x, y, width, height)
    local self = Entity.new(x, y, width, height)
    setmetatable(self, Player)

    -- Player-specific properties
    self.speed = 70
    self.default_color = utils.colors.blue
    self.color = self.default_color
    self.is_hidden = false
    self.input_enabled = true

    -- Sprite setup
    self.sprite = Sprite.new('assets/images/sprites/player.png', 48, 48)
    -- Row one is walk down,
    -- Row two is walk up,
    -- Row three is walk left,
    -- Row four is walk right,
    -- (1,1) is idle.
    self.sprite:addAnimation('walk_down', '1-4,1', 0.1)
    self.sprite:addAnimation('walk_up', '1-4,2', 0.1)
    self.sprite:addAnimation('walk_left', '1-4,3', 0.1)
    self.sprite:addAnimation('walk_right', '1-4,4', 0.1)
    self.sprite:addAnimation('idle', { { 1, 1 } }, 0.1)
    self.current_animation = 'idle'
    self.animation = self.sprite:cloneAnimation('idle')

    -- Animation state
    self.is_moving = false
    self.facing_direction = 'down' -- Track which direction player is facing

    return self
end

-- Handle player input and return movement direction
function Player:handleInput()
    if not self.input_enabled then
        return 0, 0
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then dx = dx + 1 end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then dy = dy + 1 end

    -- Handle space key for hiding
    if love.keyboard.isDown("space") then
        self:hide()
    else
        self:show()
    end

    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
    end

    -- Determine direction and animation based on movement
    local moving = (dx ~= 0 or dy ~= 0)
    local new_direction = self.facing_direction

    if moving then
        -- Determine primary direction (prioritize vertical movement)
        if math.abs(dy) > math.abs(dx) then
            -- Vertical movement
            new_direction = dy > 0 and 'down' or 'up'
        else
            -- Horizontal movement
            new_direction = dx < 0 and 'left' or 'right'
        end
    end

    -- Update animation if movement state or direction changed
    if moving ~= self.is_moving or new_direction ~= self.facing_direction then
        self.is_moving = moving
        self.facing_direction = new_direction

        if moving then
            -- Start appropriate walking animation
            self.current_animation = 'walk_' .. new_direction
            self.animation = self.sprite:cloneAnimation(self.current_animation)
        else
            -- Return to idle animation when not moving
            self.current_animation = 'idle'
            self.animation = self.sprite:cloneAnimation('idle')
        end
    end

    return dx, dy
end

-- Update player with input handling and boundary checking
function Player:update(map, dt)
    if not self.active then return end

    -- Handle input and set velocity
    local dx, dy = self:handleInput()
    self:setVelocity(dx * self.speed, dy * self.speed)

    -- Call parent update method
    if not Entity.update(self, map, dt) then
        return
    end

    -- Update animation
    if self.animation then
        self.animation:update(dt)
    end
end

-- Override draw method to use sprite instead of rectangle
function Player:draw()
    if not self.active then return end

    -- centre-on-pivot, then snap to pixel grid
    local sprite_x = math.floor(self.x - self.width / 2 + 0.5)
    local sprite_y = math.floor(self.y - self.height / 2 + 0.5)

    -- tint if hidden
    if self.is_hidden then
        love.graphics.setColor(1, 0.5, 0.5, 0.8)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    if self.animation then
        self.animation:draw(self.sprite.image, sprite_x, sprite_y, self.rotation)
    else
        self.sprite:drawFrame(1, 1, sprite_x, sprite_y, self.rotation)
    end
end

-- Player-specific methods
function Player:hide()
    self.is_hidden = true
end

function Player:show()
    self.is_hidden = false
end

function Player:toggleVisibility()
    self.is_hidden = not self.is_hidden
end

function Player:disableInput()
    self.input_enabled = false
end

function Player:enableInput()
    self.input_enabled = true
end

function Player:setSpeed(speed)
    self.speed = speed or 200
end

function Player:setDefaultColor(color)
    self.default_color = color or utils.colors.blue
end

-- Return the Player class
return Player