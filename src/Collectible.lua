-- Collectible class that extends Entity
local Entity              = require("src.Entity")
local utils               = require("src.utils")

-- Constants ------------------------------------------------------------------------------
local COLLECTIBLE_SIZE    = 8     -- Width and height (pixels) of the pickup hitbox
local DEFAULT_SCORE_VALUE = 1     -- Score awarded when player picks up a basic collectible
local BOB_SPEED           = 4     -- Speed multiplier for bobbing animation
local BOB_AMPLITUDE       = 2     -- Pixel amplitude of bob motion
local PIXEL_ALIGN_OFFSET  = 0.5   -- Offset for sub-pixel rounding when drawing

local Collectible         = Entity:extend()

-- Constructor for creating a new collectible
-- value: how much to add to the score when collected
function Collectible.new(x, y, value)
    local self = Entity.new(x, y, COLLECTIBLE_SIZE, COLLECTIBLE_SIZE)
    setmetatable(self, Collectible)

    -- Collectible-specific properties
    self.value = value or DEFAULT_SCORE_VALUE
    self.collectible_type = "basic" -- tag so other systems can identify us

    -- Visual properties
    self.base_y = y                                -- remember spawn height for bobbing effect
    self.bob_timer = math.random() * (2 * math.pi) -- randomise starting phase
    self.bob_amplitude = BOB_AMPLITUDE
    self.color = utils.colors.yellow

    return self
end

-- Update collectible (simple bobbing + off-screen cleanup)
function Collectible:update(map, dt)
    if not self.active then return end

    -- Bob up and down for a little life
    self.bob_timer = self.bob_timer + dt * BOB_SPEED -- speed of bobbing
    local offset_y = math.sin(self.bob_timer) * self.bob_amplitude
    self.y = self.base_y + offset_y
    self.sprite_y = math.floor(self.y + PIXEL_ALIGN_OFFSET)

    -- Deactivate if moved off the left side of the screen (world coordinates)
    if self.x < -self.width then
        self.active = false
    end
end

-- Draw the collectible as a simple coloured rectangle for now
function Collectible:draw()
    if not self.active then return end

    love.graphics.setColor(self.color)
    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )
end

return Collectible
