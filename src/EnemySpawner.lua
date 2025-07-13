-- EnemySpawner class for managing enemy spawning
local Enemy = require("src.Enemy")
local debug_helpers = require("src.debug_helpers")

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

-- Constructor for creating a new enemy spawner
function EnemySpawner.new(config)
    local self = setmetatable({}, EnemySpawner)

    -- Configuration
    self.spawn_interval = config.enemy_spawn_interval or 2.0
    self.spawn_chance = config.enemy_spawn_chance or 0.7
    self.max_enemies = config.max_enemies or 8
    self.game_width = config.game_width
    self.game_height = config.game_height

    -- State
    self.spawn_timer = 0

    return self
end

-- Update the spawner (call this every frame)
function EnemySpawner:update(dt, entities, camera_x)
    self.spawn_timer = self.spawn_timer + dt

    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = 0

        -- Random chance to spawn an enemy
        if math.random() < self.spawn_chance then
            self:spawnEnemy(entities, camera_x)
        end
    end
end

-- Spawn a new enemy
function EnemySpawner:spawnEnemy(entities, camera_x)
    -- Don't spawn if we're at the max
    local enemy_count = self:countActiveEnemies(entities)

    if enemy_count >= self.max_enemies then
        return
    end

    -- Spawn enemy just off the right side of the current camera viewport
    -- Use camera_x so that enemies always spawn relative to the visible world,
    -- ensuring correct alignment with the camera translation applied in love.draw.
    local cam_x = camera_x or 0
    local spawn_x = cam_x + self.game_width + 50 -- Start off-screen to the right of the camera
    local spawn_y = math.random(20, self.game_height - 20)

    local enemy_type = Enemy.getRandomType()
    local enemy = Enemy.new(spawn_x, spawn_y, enemy_type)

    table.insert(entities, enemy)
    debug_helpers.log("Enemy spawned: " .. enemy.enemy_type .. " at (" .. spawn_x .. ", " .. spawn_y .. ")", "DEBUG")
end

-- Count active enemies in the entities list
function EnemySpawner:countActiveEnemies(entities)
    local count = 0
    for _, entity in ipairs(entities) do
        if entity.enemy_type and entity.active then
            count = count + 1
        end
    end
    return count
end

-- Clean up inactive enemies from the entities list
function EnemySpawner:cleanupInactiveEnemies(entities)
    for i = #entities, 1, -1 do
        local entity = entities[i]
        if entity.enemy_type and not entity.active then
            table.remove(entities, i)
        end
    end
end

-- Update spawner configuration
function EnemySpawner:setSpawnInterval(interval)
    self.spawn_interval = interval
end

function EnemySpawner:setSpawnChance(chance)
    self.spawn_chance = chance
end

function EnemySpawner:setMaxEnemies(max)
    self.max_enemies = max
end

-- Get current spawn statistics
function EnemySpawner:getStats(entities)
    return {
        active_enemies = self:countActiveEnemies(entities),
        max_enemies = self.max_enemies,
        spawn_timer = self.spawn_timer,
        spawn_interval = self.spawn_interval
    }
end

-- Return the EnemySpawner class
return EnemySpawner
