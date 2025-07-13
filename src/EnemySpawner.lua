-- EnemySpawner class for managing enemy spawning
local Enemy                   = require("src.Enemy")
local debug_helpers           = require("src.debug_helpers")
local spawn_patterns          = require("src.spawn_patterns")

-- Constants ------------------------------------------------------------------------------
local DEFAULT_SPAWN_INTERVAL  = 2.0 -- Seconds between spawn checks
local DEFAULT_SPAWN_CHANCE    = 0.7 -- Probability of spawning each interval
local DEFAULT_MAX_ENEMIES     = 24  -- Maximum number of active enemies
local DEFAULT_PATTERN_SPACING = 24  -- Default spacing between enemies inside a pattern

local EnemySpawner            = {}
EnemySpawner.__index          = EnemySpawner

-- Constructor for creating a new enemy spawner
function EnemySpawner.new(config)
    local self          = setmetatable({}, EnemySpawner)

    -- Configuration
    self.spawn_interval = DEFAULT_SPAWN_INTERVAL
    self.spawn_chance   = DEFAULT_SPAWN_CHANCE
    self.max_enemies    = DEFAULT_MAX_ENEMIES
    self.game_width     = config.game_width
    self.game_height    = config.game_height
    -- No pattern configuration here; handled entirely by spawn_patterns.lua
    -- Offsets and margins (must be provided by config)
    assert(config.spawn_margin_y, "spawn_margin_y must be provided in spawner config")
    assert(config.spawn_offset_x, "spawn_offset_x must be provided in spawner config")
    self.spawn_margin_y = config.spawn_margin_y
    self.spawn_offset_x = config.spawn_offset_x

    -- State
    self.spawn_timer = 0
    -- No pattern->enemy mapping here; pattern definitions include enemy_type

    return self
end

-- Update the spawner (call this every frame)
function EnemySpawner:update(dt, entities, camera_x)
    self.spawn_timer = self.spawn_timer + dt

    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = 0

        if math.random() < self.spawn_chance then
            local pattern_name, pattern_def = spawn_patterns.randomPattern()
            self:spawnPattern(pattern_name, pattern_def, entities, camera_x)
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
    local spawn_x = cam_x + self.game_width + self.spawn_offset_x
    local spawn_y = math.random(self.spawn_margin_y, self.game_height - self.spawn_margin_y)

    local enemy_type = Enemy.getRandomType()
    local enemy = Enemy.new(spawn_x, spawn_y, enemy_type)

    table.insert(entities, enemy)
    debug_helpers.log("Enemy spawned: " .. enemy.enemy_type .. " at (" .. spawn_x .. ", " .. spawn_y .. ")", "DEBUG")
end

-- Spawn enemies following a chosen pattern definition
function EnemySpawner:spawnPattern(pattern_name, pattern_def, entities, camera_x)
    -- Respect max enemy limit
    if self:countActiveEnemies(entities) >= self.max_enemies then return end

    local cam_x      = camera_x or 0
    local base_x     = cam_x + self.game_width + self.spawn_offset_x

    local wave_size  = pattern_def.wave_size or 1
    local spacing    = pattern_def.spacing or DEFAULT_PATTERN_SPACING
    local pattern_fn = pattern_def.offsets

    local wave_enemy_template
    if pattern_def.enemy_type then
        wave_enemy_template = Enemy.getTypeByName(pattern_def.enemy_type)
    end

    -- Pre-compute pattern offsets to preserve relative positions and keep the
    -- whole formation on-screen without clamping each enemy individually.
    local offsets = {}
    local min_dy, max_dy = math.huge, -math.huge
    for i = 1, wave_size do
        local dx, dy = pattern_fn(i, wave_size, spacing)
        offsets[i] = { dx = dx, dy = dy }
        if dy < min_dy then min_dy = dy end
        if dy > max_dy then max_dy = dy end
    end

    -- Determine a base_y such that the entire pattern fits between 20 and game_height-20
    local min_allowed = self.spawn_margin_y - min_dy
    local max_allowed = self.game_height - self.spawn_margin_y - max_dy
    if max_allowed < min_allowed then
        -- Pattern too tall; fallback to centre
        min_allowed, max_allowed = self.game_height / 2, self.game_height / 2
    end
    local base_y = math.random(min_allowed, max_allowed)

    local spawned = 0
    for i = 1, wave_size do
        if self:countActiveEnemies(entities) >= self.max_enemies then
            break
        end

        local dx, dy = offsets[i].dx, offsets[i].dy
        local spawn_x = base_x + dx
        local spawn_y = base_y + dy

        local enemy_type_template = wave_enemy_template or Enemy.getRandomType()
        local enemy = Enemy.new(spawn_x, spawn_y, enemy_type_template)
        table.insert(entities, enemy)
        spawned = spawned + 1
    end

    debug_helpers.log(string.format("Pattern '%s' spawned (%d enemies)", pattern_name, spawned), "DEBUG")
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
