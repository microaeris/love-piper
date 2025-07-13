-- CollectibleSpawner class for managing collectible spawning
local Collectible               = require("src.Collectible")
local PowerUp                   = require("src.PowerUp")
local debug_helpers             = require("src.debug_helpers")
local utils                     = require("src.utils")

-- Constants ------------------------------------------------------------------------------
local DEFAULT_SPAWN_INTERVAL    = 0.5                 -- Seconds between spawn checks
local DEFAULT_SPAWN_CHANCE      = 1.0                 -- Probability of spawning each interval
local DEFAULT_POWERUP_CHANCE    = 0.15                -- Chance that a spawned collectible is a power-up
local DEFAULT_MAX_COLLECTIBLES  = 25                  -- Maximum number of active collectibles
local DEFAULT_COLLECTIBLE_VALUE = 1                   -- Score value for basic collectibles
local MAX_SPAWN_ATTEMPTS        = 10                  -- Maximum attempts to find a walkable spawn position
local COLLECTIBLE_SIZE          = 8                   -- Width and height (pixels) of collectibles (matches Collectible.lua)

local PLAYER_WIDTH              = 16                  -- Player width used to validate standable tiles
local PLAYER_HEIGHT             = 16                  -- Player height used to validate standable tiles
local PLAYER_FOOT_OFFSET        = PLAYER_HEIGHT * 0.5 -- As per Player.lua FOOT_OFFSET_RATIO

local CollectibleSpawner        = {}
CollectibleSpawner.__index      = CollectibleSpawner

-- Constructor for creating a new collectible spawner
function CollectibleSpawner.new(config)
    local self            = setmetatable({}, CollectibleSpawner)

    -- Configuration
    self.spawn_interval   = DEFAULT_SPAWN_INTERVAL
    self.spawn_chance     = DEFAULT_SPAWN_CHANCE
    self.powerup_chance   = DEFAULT_POWERUP_CHANCE
    self.max_collectibles = DEFAULT_MAX_COLLECTIBLES
    self.game_width       = config.game_width
    self.game_height      = config.game_height

    -- Offsets and margins
    assert(config.spawn_margin_y, "spawn_margin_y must be provided in collectible spawner config")
    assert(config.spawn_offset_x, "spawn_offset_x must be provided in collectible spawner config")
    self.spawn_margin_y = config.spawn_margin_y
    self.spawn_offset_x = config.spawn_offset_x

    -- State
    self.spawn_timer = 0

    return self
end

-- Update the spawner (call every frame)
function CollectibleSpawner:update(dt, entities, camera_x, map)
    self.spawn_timer = self.spawn_timer + dt

    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = 0

        if math.random() < self.spawn_chance then
            self:spawnCollectible(entities, camera_x, map)
        end
    end
end

-- Spawn a new collectible ahead of the camera
function CollectibleSpawner:spawnCollectible(entities, camera_x, map)
    -- Respect max limit
    local count = self:countActiveCollectibles(entities)
    if count >= self.max_collectibles then return end

    local cam_x    = camera_x or 0
    local spawn_x  = cam_x + self.game_width + self.spawn_offset_x

    -- Find a walkable spawn position
    local spawn_y  = nil
    local attempts = 0

    while attempts < MAX_SPAWN_ATTEMPTS do
        attempts = attempts + 1

        -- Try a random Y position within the spawn bounds
        local candidate_y = math.random(self.spawn_margin_y, self.game_height - self.spawn_margin_y)

        -- Check if this position is walkable for a collectible
        -- Validate using player dimensions to ensure the player could reach the tile
        local safe_x, safe_y = utils.findSafeSpawnPosition(
            map,
            spawn_x,
            candidate_y,
            PLAYER_WIDTH,
            PLAYER_HEIGHT,
            PLAYER_FOOT_OFFSET,
            2
        )

        -- If we found a safe position reasonably close to our desired spawn point
        if safe_x and safe_y and math.abs(safe_y - candidate_y) < 32 then
            spawn_x = safe_x
            spawn_y = safe_y
            break
        end
    end

    -- If we couldn't find a walkable position after multiple attempts, don't spawn
    if not spawn_y then
        debug_helpers.log("Could not find walkable spawn position for collectible", "DEBUG")
        return
    end

    -- Decide whether to spawn a regular collectible or a power-up
    local collectible
    if math.random() < self.powerup_chance then
        local ptype = PowerUp.getRandomType()
        collectible = PowerUp.new(spawn_x, spawn_y, ptype)
    else
        collectible = Collectible.new(spawn_x, spawn_y, DEFAULT_COLLECTIBLE_VALUE)
    end

    table.insert(entities, collectible)

    debug_helpers.log(
        string.format("Collectible spawned at (%d,%d) type=%s", spawn_x, spawn_y, collectible.collectible_type), "DEBUG")
end

-- Count active collectibles currently in entity list
function CollectibleSpawner:countActiveCollectibles(entities)
    local count = 0
    for _, e in ipairs(entities) do
        if e.collectible_type and e.active then
            count = count + 1
        end
    end
    return count
end

-- Clean up inactive collectibles
function CollectibleSpawner:cleanupInactiveCollectibles(entities)
    for i = #entities, 1, -1 do
        local e = entities[i]
        if e.collectible_type and not e.active then
            table.remove(entities, i)
        end
    end
end

return CollectibleSpawner
