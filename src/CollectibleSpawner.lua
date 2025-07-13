-- CollectibleSpawner class for managing collectible spawning
local Collectible          = require("src.Collectible")
local PowerUp              = require("src.PowerUp")
local debug_helpers        = require("src.debug_helpers")

local CollectibleSpawner   = {}
CollectibleSpawner.__index = CollectibleSpawner

-- Constructor for creating a new collectible spawner
function CollectibleSpawner.new(config)
    local self            = setmetatable({}, CollectibleSpawner)

    -- Configuration
    self.spawn_interval   = config.collectible_spawn_interval or 2.0
    self.spawn_chance     = config.collectible_spawn_chance or 0.75
    self.powerup_chance   = config.powerup_chance or 0.15 -- Chance that a spawned collectible is a power-up
    self.max_collectibles = config.max_collectibles or 10
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
function CollectibleSpawner:update(dt, entities, camera_x)
    self.spawn_timer = self.spawn_timer + dt

    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = 0

        if math.random() < self.spawn_chance then
            self:spawnCollectible(entities, camera_x)
        end
    end
end

-- Spawn a new collectible ahead of the camera
function CollectibleSpawner:spawnCollectible(entities, camera_x)
    -- Respect max limit
    local count = self:countActiveCollectibles(entities)
    if count >= self.max_collectibles then return end

    local cam_x   = camera_x or 0
    local spawn_x = cam_x + self.game_width + self.spawn_offset_x
    local spawn_y = math.random(self.spawn_margin_y, self.game_height - self.spawn_margin_y)

    -- Decide whether to spawn a regular collectible or a power-up
    local collectible
    if math.random() < self.powerup_chance then
        local ptype = PowerUp.getRandomType()
        collectible = PowerUp.new(spawn_x, spawn_y, ptype)
    else
        collectible = Collectible.new(spawn_x, spawn_y, 1)
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
