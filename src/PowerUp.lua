local Collectible             = require("src.Collectible")
local utils                   = require("src.utils")

-- PowerUp class that extends Collectible
local PowerUp                 = Collectible:extend()

-- Default per-type durations (seconds) – a duration of 0 means instant and permanent/no expiry
local DEFAULT_DURATIONS       = {
    invincibility = 5,
    slow_enemies  = 5,
    gun           = 5,
    clear_enemies = 0, -- instant, no duration
}

-- Colour hints per type (purely visual)
local TYPE_COLOURS            = {
    invincibility = utils.colors.cyan,
    slow_enemies  = utils.colors.orange,
    gun           = utils.colors.purple,
    clear_enemies = utils.colors.red,
}

-- Default probabilities (percent values) – should sum to 100 but will be normalised if not.
local DEFAULT_PROBABILITIES   = {
    invincibility = 5,  -- 5%
    slow_enemies  = 50, -- 50%
    gun           = 25, -- 25%
    clear_enemies = 20, -- 20%
}

-- EFFECT HANDLERS ---------------------------------------------------------------------------
-- Each handler receives (game, powerupInstance)
local EFFECT_HANDLERS         = {}

-- 1. INVINCIBILITY --------------------------------------------------------------------------
EFFECT_HANDLERS.invincibility = function(game, pu)
    if game.player and game.player.activateInvincibility then
        game.player:activateInvincibility(pu.duration)
    end
end

-- 2. SLOW ENEMIES ---------------------------------------------------------------------------
EFFECT_HANDLERS.slow_enemies  = function(game, pu)
    local mul = 0.25
    _G.ENEMY_SPEED_MULT = mul
    for _, entity in ipairs(game.entities) do
        if entity.enemy_type then
            if not entity.original_speed then
                entity.original_speed = entity.speed
            end
            entity.speed = entity.speed * mul

            -- Also slow vertical wobble amplitude if present
            if entity.wobble_amplitude then
                if not entity.original_wobble_amplitude then
                    entity.original_wobble_amplitude = entity.wobble_amplitude
                end
                entity.wobble_amplitude = entity.wobble_amplitude * mul
            end
        end
    end
    -- Track timed effect for later restoration
    table.insert(game.activeEffects, { type = "slow_enemies", remaining = pu.duration, multiplier = mul })
end

-- 3. GUN / SHOOT -----------------------------------------------------------------------------
EFFECT_HANDLERS.gun           = function(game, pu)
    if game.player then
        game.player.has_gun = true
    end
    table.insert(game.activeEffects, { type = "gun", remaining = pu.duration })
end

-- 4. CLEAR ENEMIES ---------------------------------------------------------------------------
EFFECT_HANDLERS.clear_enemies = function(game, pu)
    for _, entity in ipairs(game.entities) do
        if entity.enemy_type and entity.active then
            entity.active = false
            game.score = game.score + 2 -- points per enemy cleared
        end
    end
end

-- -------------------------------------------------------------------------------------------

-- Constructor -------------------------------------------------------------------------------
-- x, y         : spawn position
-- power_type   : string key for effect (see handlers above)
-- value        : score value on pickup (defaults 5)
-- duration     : overrides default if provided
function PowerUp.new(x, y, power_type, value, duration)
    local self = Collectible.new(x, y, value or 5)
    setmetatable(self, PowerUp)

    self.collectible_type = "powerup"

    self.power_type       = power_type or "invincibility"
    self.duration         = duration or DEFAULT_DURATIONS[self.power_type] or 0

    -- Visual: tint based on type so testers can differentiate
    self.color            = TYPE_COLOURS[self.power_type] or utils.colors.cyan

    return self
end

-- Invoked when the player picks up the power-up ------------------------------------------------
function PowerUp:applyEffect(game)
    local handler = EFFECT_HANDLERS[self.power_type]
    if handler then
        handler(game, self)
    end
end

-- Choose a power-up type strictly based on the provided probability table (percent values).
-- The table MUST sum to 100 (±0.01). If it doesn’t, an assertion error is raised.
-- If no table is supplied, DEFAULT_PROBABILITIES is used.
function PowerUp.getRandomType(probTable)
    local weights = probTable or DEFAULT_PROBABILITIES

    -- Calculate total and build cumulative thresholds
    local total = 0
    local cumulative = {}
    for t, p in pairs(weights) do
        if p > 0 then
            total = total + p
            table.insert(cumulative, { type = t, threshold = total })
        end
    end

    -- Enforce exact total of 100
    assert(math.abs(total - 100) < 0.01, "Power-up probability table must sum to 100 (got " .. total .. ")")

    -- Random selection
    local r = math.random() * 100
    for _, entry in ipairs(cumulative) do
        if r <= entry.threshold then
            return entry.type
        end
    end

    -- Should never reach here if probabilities are correct
    error("Failed to select power-up type – check probability table")
end

return PowerUp
