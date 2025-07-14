-- Player class that extends Entity
local Entity                  = require("src.Entity")
local Sprite                  = require("src.Sprite")
local utils                   = require("src.utils")

-- Constants
local INVINCIBLE_DURATION     = 2   -- seconds of invulnerability after a hit
local BLINK_INTERVAL          = 0.1 -- seconds between sprite visibility toggles
local MAX_HEALTH              = 3   -- starting health
local DASH_SPEED              = 220 -- pixels per second dash speed
local DASH_DURATION           = 0.15
local DASH_COOLDOWN           = 1.0

local FOOT_OFFSET_RATIO       = 0.5  -- Foot position is halfway down the sprite height
local HITBOX_SCALE            = 0.35 -- Collision hitbox is 35% of sprite dimensions
local PIXEL_ALIGN_OFFSET      = 0.5  -- Offset for sub-pixel rounding when drawing

-- Dash indicator colors
local INDICATOR_BG_COLOR      = { 0.2, 0.2, 0.2, 0.9 }
local INDICATOR_FILL_COLOR    = { 0, 0.8, 1, 1 }
local INDICATOR_OUTLINE_COLOR = { 0, 0, 0, 1 }
local DASH_INDICATOR_RADIUS   = 3 -- Radius of the dash cooldown indicator
local DASH_INDICATOR_Y_OFFSET = 6 -- Vertical offset (in pixels) for dash indicator above sprite

-- Ghost trail constants (avoid magic numbers)
local GHOST_SPAWN_INTERVAL    = 0.03 -- seconds between ghost spawns during dash
local GHOST_LIFETIME          = 0.25 -- seconds a ghost persists
local GHOST_START_ALPHA       = 0.7 -- starting alpha value for a ghost

local Player                  = Entity:extend()

-- Constructor for creating a new player
function Player.new(x, y, width, height)
    -- TODO(jm): Tuning point.
    -- Use a ratio of the sprite's height to determine the foot offset.
    local foot_offset = height * FOOT_OFFSET_RATIO
    local self = Entity.new(x, y, width, height, foot_offset)
    setmetatable(self, Player)

    -- Player-specific properties
    self.speed               = 100
    self.default_color       = utils.colors.blue
    self.color               = self.default_color
    self.input_enabled       = true

    -- Health & Invincibility
    self.max_health          = MAX_HEALTH
    self.health              = MAX_HEALTH
    self.invincible          = false
    self.invincibility_timer = 0
    self.blink_timer         = 0
    self.visible             = true

    -- Dash properties
    self.dashing             = false
    self.dash_timer          = 0
    self.dash_cooldown_timer = 0
    self.has_dashed          = false

    -- Ghost trail state
    self.ghosts              = {} -- active ghost sprites
    self.ghost_spawn_timer   = 0  -- accumulator for spawn cadence

    -- Collision box narrower than sprite for smoother navigation
    self.collision_width     = width * HITBOX_SCALE  -- narrower hitbox
    self.collision_height    = height * HITBOX_SCALE -- shorter hitbox

    -- Sprite setup
    self.sprite              = Sprite.new('assets/images/sprites/player_sheet.png', width, height)
    -- Row one is walk down,
    -- Row two is walk up,
    -- Row three is walk left,
    -- Row four is walk right,
    -- (1,1) is idle.
    self.sprite:addAnimation('walk_down', '1-4,1', 0.1)
    self.sprite:addAnimation('walk_up', '5-8,1', 0.1)
    self.sprite:addAnimation('walk_left', '9-12,1', 0.1)
    self.sprite:addAnimation('walk_right', '13-16,1', 0.1)
    self.sprite:addAnimation('idle', { { 1, 1 } }, 0.1)
    self.current_animation = 'idle'
    self.animation = self.sprite:cloneAnimation('idle')

    -- Remember the original spawn so we can reset later
    self.spawn_x, self.spawn_y = x, y

    -- Animation state
    self.is_moving = false
    self.facing_direction = 'down' -- Track which direction player is facing

    return self
end

-- Reset the player back to their original spawn location
function Player:resetToSpawn()
    self:setPosition(self.spawn_x, self.spawn_y)
    self:setVelocity(0, 0)
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

    -- (Hide functionality removed)

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
    if not self.dashing then
        self:setVelocity(dx * self.speed, dy * self.speed)
    end

    -- Cooldown tick
    if self.dash_cooldown_timer > 0 then
        self.dash_cooldown_timer = self.dash_cooldown_timer - dt
    end

    -- Handle dash
    if self.dashing then
        self.dash_timer = self.dash_timer - dt
        if self.dash_timer <= 0 then
            self.dashing = false
            self.dash_cooldown_timer = DASH_COOLDOWN
            self:setVelocity(0, 0)
        end

        -- Spawn ghosts while dashing
        self.ghost_spawn_timer = self.ghost_spawn_timer + dt
        while self.ghost_spawn_timer >= GHOST_SPAWN_INTERVAL do
            self:spawnGhost()
            self.ghost_spawn_timer = self.ghost_spawn_timer - GHOST_SPAWN_INTERVAL
        end
    end

    -- Handle invincibility timers and blinking
    if self.invincible then
        self.invincibility_timer = self.invincibility_timer - dt
        self.blink_timer = self.blink_timer - dt
        if self.blink_timer <= 0 then
            self.visible = not self.visible
            self.blink_timer = BLINK_INTERVAL
        end
        if self.invincibility_timer <= 0 then
            self.invincible = false
            self.visible = true
        end
    end

    -- Call parent update method - Move the player
    if not Entity.update(self, map, dt) then
        return
    end

    -- Update existing ghosts (fade & cull)
    for i = #self.ghosts, 1, -1 do
        local g = self.ghosts[i]
        g.life = g.life - dt
        if g.life <= 0 then
            table.remove(self.ghosts, i)
        end
    end

    -- Update animation
    if self.animation then
        self.animation:update(dt)
    end
end

-- Override draw method to use sprite instead of rectangle
function Player:draw()
    if not self.active then return end

    if self.invincible and not self.visible then
        return -- skip drawing to create blinking effect
    end

    -- Draw ghost trail behind the player
    self:drawGhostTrail()

    -- centre-on-pivot, then snap to pixel grid
    local sprite_x = math.floor(self.x - self.width / 2 + PIXEL_ALIGN_OFFSET)
    local sprite_y = math.floor(self.y - self.height / 2 + PIXEL_ALIGN_OFFSET)
    love.graphics.setColor(1, 1, 1, 1) -- white for sprite

    if self.animation then
        self.animation:draw(self.sprite.image, sprite_x, sprite_y, self.rotation)
    else
        self.sprite:drawFrame(1, 1, sprite_x, sprite_y, self.rotation)
    end

    -- Dash cooldown indicator
    self:drawDashIndicator()
end

-- Draw the dash cooldown indicator (pie circle above head)
function Player:drawDashIndicator()
    -- Only after player has dashed at least once and while not fully ready
    local show_indicator = self.has_dashed and (self.dashing or self.dash_cooldown_timer > 0)
    if not show_indicator then return end

    local indicator_radius = DASH_INDICATOR_RADIUS
    local progress
    if self.dashing then
        progress = 0
    elseif self.dash_cooldown_timer > 0 then
        progress = 1 - (self.dash_cooldown_timer / DASH_COOLDOWN)
    else
        progress = 1
    end

    local ind_x = self.x
    local ind_y = self.y - self.height / 2 - DASH_INDICATOR_Y_OFFSET

    -- Background circle
    love.graphics.setColor(INDICATOR_BG_COLOR)
    love.graphics.circle("fill", ind_x, ind_y, indicator_radius)

    -- Filled arc for progress
    if progress > 0 then
        love.graphics.setColor(INDICATOR_FILL_COLOR)
        local start_angle = -math.pi / 2
        local end_angle   = start_angle + 2 * math.pi * progress
        love.graphics.arc("fill", ind_x, ind_y, indicator_radius, start_angle, end_angle)
    end

    -- Outline
    love.graphics.setColor(INDICATOR_OUTLINE_COLOR)
    love.graphics.circle("line", ind_x, ind_y, indicator_radius)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Helper to spawn a single ghost sprite at the player’s current frame
function Player:spawnGhost()
    local sprite_x = math.floor(self.x - self.width / 2 + PIXEL_ALIGN_OFFSET)
    local sprite_y = math.floor(self.y - self.height / 2 + PIXEL_ALIGN_OFFSET)

    -- Determine current frame quad
    local current_frame
    if self.animation and self.animation.frames then
        current_frame = self.animation.frames[self.animation.position]
    else
        current_frame = self.sprite:getFrame(1, 1)
    end

    table.insert(self.ghosts, {
        x     = sprite_x,
        y     = sprite_y,
        frame = current_frame,
        life  = GHOST_LIFETIME
    })
end

-- Draw all active ghost sprites
function Player:drawGhostTrail()
    for _, g in ipairs(self.ghosts) do
        local alpha = (g.life / GHOST_LIFETIME) * GHOST_START_ALPHA
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(self.sprite.image, g.frame, g.x, g.y)
    end
    -- Restore default color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Player-specific methods
-- Hide functionality removed
function Player:disableInput()
    self.input_enabled = false
end

function Player:enableInput()
    self.input_enabled = true
end

function Player:setSpeed(speed)
    self.speed = speed
end

function Player:setDefaultColor(color)
    self.default_color = color
end

-- Activate invincibility state for the given duration (in seconds)
function Player:activateInvincibility(duration)
    duration = duration or INVINCIBLE_DURATION
    -- If already invincible, just extend the timer
    if self.invincible then
        self.invincibility_timer = math.max(self.invincibility_timer, duration)
    else
        self.invincible = true
        self.invincibility_timer = duration
        -- Blink setup
        self.blink_timer = BLINK_INTERVAL
        self.visible = false
    end
end

function Player:takeDamage(amount)
    if self.invincible then return end -- already invincible, ignore
    amount = amount or 1
    self.health = math.max(0, self.health - amount)

    -- Start invincibility phase using the new helper
    self:activateInvincibility(INVINCIBLE_DURATION)
end

-- Trigger dash externally (called from love.keypressed)
function Player:startDash()
    if self.dashing or self.dash_cooldown_timer > 0 then return end

    -- Determine dash direction based on facing_direction
    local dir_x, dir_y = 0, 0
    if self.facing_direction == 'left' then
        dir_x = -1
    elseif self.facing_direction == 'right' then
        dir_x = 1
    elseif self.facing_direction == 'up' then
        dir_y = -1
    else -- down
        dir_y = 1
    end

    -- Fall back to no movement
    if dir_x == 0 and dir_y == 0 then dir_y = 1 end

    self:setVelocity(dir_x * DASH_SPEED, dir_y * DASH_SPEED)
    self.dashing = true
    self.dash_timer = DASH_DURATION
    self.has_dashed = true
end

-- Return the Player class
return Player
