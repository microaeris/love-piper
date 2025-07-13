-- Include Simple Tiled Implementation into project
local sti                = require "lib.Simple-Tiled-Implementation.sti"

-- Import local modules
local Player             = require("src.Player")
local EnemySpawner       = require("src.EnemySpawner")
local CollectibleSpawner = require("src.CollectibleSpawner")
local Camera             = require("src.Camera")
local utils              = require("src.utils")
local debug_helpers      = require("src.debug_helpers")
local Menu               = require("src.Menu")
local SoundManager       = require("src.SoundManager")
local Collectible        = require("src.Collectible")
local PowerUp            = require("src.PowerUp")
local Bullet             = require("src.Bullet")

-- Game configuration
local CONFIG             = {
    game_width = 160,
    game_height = 144,
    scale_factor = 5,
    skip_start_menu = true,               -- Set to true to skip start menu for development
    allow_debug_gameOver = true,          -- Set to true if want to press '0' to auto-gameOver
    allow_debug_spawn_collectible = true, -- Press '9' to spawn a collectible/power-up for debugging
    scroll_speed = 60,                    -- Pixels per second horizontal scroll speed (increased from 30)
    -- Enemy spawning configuration
    enemy_spawn_interval = 2.0,           -- Seconds between enemy spawns
    enemy_spawn_chance = 0.7,             -- Probability of spawning an enemy each interval
    max_enemies = 8,                      -- Maximum number of enemies on screen at once
    -- Collectible spawning configuration
    collectible_spawn_interval = 0.5,     -- Seconds between collectible spawns (was 3.0)
    collectible_spawn_chance = 1.0,       -- Probability of spawning a collectible each interval (was 0.6)
    max_collectibles = 25,                -- Maximum number of collectibles on screen at once (was 12)

    -- UI configuration
    health_text_offset_x = 40, -- Pixels from right edge when drawing health text
}

local globalGameState    = {
    highScore = 0
}

-- Game state variables
local game               = {
    -- Game settings
    entities = {},
    player = nil,
    soundManager = nil,
    camera = nil,
    enemySpawner = nil,
    collectibleSpawner = nil,
    layerShaderManager = nil,
    customMapDrawer = nil,
    activeEffects = {},
    bulletShootTimer = 0,
    -- Canvas settings for scaled rendering
    canvas = nil,
    -- Game state management
    state = CONFIG.skip_start_menu and "playing" or "start", -- "start", "playing", "paused", "gameOver"
    score = 0,
}

-- Helper so Bullet can query camera X without circular require
_G.CONFIG                = CONFIG
_G.GAME_CAMERA_GET_X     = function()
    if game and game.camera then
        local x, _ = game.camera:get_position()
        return x
    end
    return 0
end
_G.ENEMY_SPEED_MULT      = 1

-- Helpers
local function init_window()
    -- Set default filter to nearest
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create canvas for low-resolution rendering
    -- game.canvas = love.graphics.newCanvas(window_width, window_height)
    game.canvas = love.graphics.newCanvas(CONFIG.game_width, CONFIG.game_height)
    game.canvas:setFilter("nearest", "nearest")

    game.shader = love.graphics.newShader("assets/shaders/ripples.glsl")

    -- love.window.setMode(window_width * CONFIG.scale_factor, window_height * CONFIG.scale_factor)
end

local function init_game()
    -- Load map file
    map = sti("assets/maps/test_map.lua")
    local layer = map:addCustomLayer("Sprites", 4)

    water_map = sti("assets/maps/water.lua")

    -- Init sound manager
    game.soundManager = SoundManager.new()
    game.soundManager:playAmbience()

    -- Initialize camera
    game.camera = Camera.new(CONFIG.scroll_speed)

    -- Get player spawn position
    local player_map_obj
    for k, object in pairs(map.objects) do
        if object.name == "Player" then
            player_map_obj = object
            break
        end
    end
    if not player_map_obj then
        error("Player spawn position not found in map")
    end

    -- Create player entity
    game.player = Player.new(player_map_obj.x, player_map_obj.y, 16, 16)

    -- Initialize enemy spawner
    local spawner_config = {
        enemy_spawn_interval = CONFIG.enemy_spawn_interval,
        enemy_spawn_chance = CONFIG.enemy_spawn_chance,
        max_enemies = CONFIG.max_enemies,
        game_width = CONFIG.game_width,
        game_height = CONFIG.game_height,
        spawn_margin_y = math.floor(CONFIG.game_height * 0.05),
        spawn_offset_x = math.floor(CONFIG.game_width * 0.08)
    }
    game.enemySpawner = EnemySpawner.new(spawner_config)

    -- Initialize collectible spawner
    local collectible_config = {
        collectible_spawn_interval = CONFIG.collectible_spawn_interval,
        collectible_spawn_chance = CONFIG.collectible_spawn_chance,
        max_collectibles = CONFIG.max_collectibles,
        game_width = CONFIG.game_width,
        game_height = CONFIG.game_height,
        spawn_margin_y = math.floor(CONFIG.game_height * 0.05),
        spawn_offset_x = math.floor(CONFIG.game_width * 0.08),
    }
    game.collectibleSpawner = CollectibleSpawner.new(collectible_config)

    game.entities = {}
    table.insert(game.entities, game.player)

    -- Initate the shaderes
    ripple_shader = love.graphics.newShader("assets/shaders/ripples.glsl")
    lighting_shader = love.graphics.newShader("assets/shaders/lighting.glsl")

    -- Reset score
    game.score = 0
    -- Clear any lingering timed effects
    game.activeEffects = {}
end

-- FIXME - create an entity controller class
local function draw_entities()
    for i, entity in ipairs(game.entities) do
        if entity.active then
            entity:draw()
        end
    end
end

local function update_entities(dt)
    for _, entity in ipairs(game.entities) do
        entity:update(map, dt)
    end
end

local function handle_collisions(dt)
    for i, entity in ipairs(game.entities) do
        -- Bullet vs Enemy collisions
        if entity.is_bullet and entity.active then
            for _, target in ipairs(game.entities) do
                if target.enemy_type and target.active and entity:collidesWith(target) then
                    target.active = false
                    entity.active = false
                    -- Award points for defeating an enemy
                    game.score = game.score + 2
                    break
                end
            end
        end

        if entity ~= game.player and game.player:collidesWith(entity) then
            if entity.collectible_type then
                -- Collect the item and increment score
                game.score = game.score + (entity.value or 1)

                -- Apply collectible-specific effects (e.g., power-ups)
                if entity.applyEffect then
                    entity:applyEffect(game)
                end

                entity.active = false
            else
                -- Enemy collision feedback
                entity.color = utils.colors.red
                entity.hit_timer = 0.05 -- seconds

                -- Apply damage to player if not currently invincible
                if not game.player.invincible then
                    game.player:takeDamage(1)
                    game.soundManager:playCollisionTone()
                end
            end
        end
    end
end

local function transition_to_gameOver_if_needed(forceTransition)
    if game.state ~= "playing" then return end

    if ((game.player and game.player.health and game.player.health <= 0) or forceTransition) then
        if globalGameState.highScore <= game.score then
            globalGameState.highScore = game.score
        end
        game.soundManager:stopAmbience()
        game.state = "gameOver"
    end
end

-- Main game loop
function love.load()
    init_window()
    -- Game will be initialized when player starts, or immediately if skip_start_menu is true
    if CONFIG.skip_start_menu then
        init_game()
    end

    -- player is inserted into game.entities during init_game
end

function love.update(dt)
    -- Only update game when playing
    if game.state == "playing" then
        -- Update camera (constant scrolling) and get wrap information
        local wrapped, wrap_offset = game.camera:update(dt, map)

        -- If camera wrapped, shift all entities so they stay in the same logical place
        if wrapped and wrap_offset > 0 then
            for _, entity in ipairs(game.entities) do
                entity.x = entity.x - wrap_offset
                if entity.sprite_x then
                    entity.sprite_x = entity.sprite_x - wrap_offset
                end
            end
        end

        -- Update world
        map:update(dt)

        -- Update enemy spawning (pass current camera position so spawns are in world coords)
        local cam_x, _ = game.camera:get_position()
        game.enemySpawner:update(dt, game.entities, cam_x)
        -- Update collectible spawning
        game.collectibleSpawner:update(dt, game.entities, cam_x)

        update_entities(dt)

        -- Auto-shoot bullets while gun power is active
        if game.player.has_gun then
            local shootInterval = 0.25
            game.bulletShootTimer = game.bulletShootTimer + dt
            if game.bulletShootTimer >= shootInterval then
                game.bulletShootTimer = game.bulletShootTimer - shootInterval

                local bullet_x = game.player.x + game.player.width / 2 + 2
                local bullet_y = game.player.y
                local bullet = Bullet.new(bullet_x, bullet_y, 1)
                table.insert(game.entities, bullet)
            end
        else
            game.bulletShootTimer = 0
        end

        -- Tick active timed effects (power-ups etc.)
        for i = #game.activeEffects, 1, -1 do
            local eff = game.activeEffects[i]
            eff.remaining = eff.remaining - dt
            if eff.remaining <= 0 then
                if eff.type == "slow_enemies" then
                    local mul = eff.multiplier or 0.5
                    for _, entity in ipairs(game.entities) do
                        if entity.enemy_type then
                            if entity.original_speed then
                                entity.speed = entity.original_speed
                                entity.original_speed = nil
                            end
                        end
                    end
                    _G.ENEMY_SPEED_MULT = 1
                elseif eff.type == "gun" then
                    if game.player then game.player.has_gun = false end
                end
                table.remove(game.activeEffects, i)
            end
        end

        handle_collisions(dt)

        -- If player moves off-screen, inflict damage (once) and respawn near center of current view.
        do
            local cam_x, cam_y = game.camera:get_position()
            local screen_x     = game.player.x - cam_x
            local screen_y     = game.player.y - cam_y

            local off_horiz    = (screen_x < -game.player.width) or (screen_x > CONFIG.game_width + game.player.width)
            local off_vert     = (screen_y < -game.player.height) or (screen_y > CONFIG.game_height + game.player.height)

            if off_horiz or off_vert then
                -- Apply damage only if not already invincible (prevents rapid double hits)
                if not game.player.invincible then
                    game.player:takeDamage(1)
                end

                -- Compute safe respawn position
                local centre_x = cam_x + CONFIG.game_width / 2
                local centre_y = cam_y + CONFIG.game_height / 2
                local safe_x, safe_y = utils.findSafeStandPosition(
                    map,
                    centre_x,
                    centre_y,
                    game.player.width,
                    game.player.height,
                    game.player.foot_offset
                )

                game.player:setPosition(safe_x, safe_y)
                game.player:setVelocity(0, 0)
            end
        end

        -- Clean up inactive entities
        game.enemySpawner:cleanupInactiveEnemies(game.entities)
        game.collectibleSpawner:cleanupInactiveCollectibles(game.entities)

        -- Clean up other inactive entities
        for i = #game.entities, 1, -1 do
            if not game.entities[i].active and not game.entities[i].enemy_type then
                table.remove(game.entities, i)
            end
        end

        transition_to_gameOver_if_needed(false)
    end
end

function love.draw()
    -- Render to the low-resolution canvas
    love.graphics.setCanvas(game.canvas)
    love.graphics.clear(game.background_color)

    if game.state == "start" then
        Menu.draw_start_menu(CONFIG.game_width, CONFIG.game_height)
    elseif game.state == "playing" then
        love.graphics.setShader(ripple_shader)
        local time = love.timer.getTime()
        ripple_shader:send("time", time)
        ripple_shader:send("wave_height", 0.02)
        ripple_shader:send("wave_speed", 0.1)
        ripple_shader:send("wave_freq", 5.0)
        love.graphics.push()
        game.camera:draw_scrolling_map(water_map)
        love.graphics.pop()
        love.graphics.setShader()

        -- Draw scrolling background (map)
        love.graphics.setShader(lighting_shader)
        love.graphics.push()
        game.camera:draw_scrolling_map(map)
        love.graphics.pop()
        love.graphics.setShader()

        -- Draw entities with camera transform
        love.graphics.push()
        local cam_x, cam_y = game.camera:get_position()
        love.graphics.translate(-cam_x, -cam_y)
        draw_entities()
        love.graphics.pop()



        -- Screen-space overlays (debug, UI)
        debug_helpers.draw()
        -- Draw score
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Score: " .. tostring(game.score), 10, 10)
        love.graphics.print("HP: " .. tostring(game.player.health), CONFIG.game_width - CONFIG.health_text_offset_x, 10)
    elseif game.state == "paused" then
        -- Draw the game world in the background
        game.camera:draw_scrolling_map(map)

        -- Draw entities with camera transform
        love.graphics.push()
        local cam_x, cam_y = game.camera:get_position()
        love.graphics.translate(-cam_x, -cam_y)
        draw_entities()
        love.graphics.pop()

        -- Screen-space overlays
        debug_helpers.draw()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Score: " .. tostring(game.score), 10, 10)
        love.graphics.print("HP: " .. tostring(game.player.health), CONFIG.game_width - CONFIG.health_text_offset_x, 10)
        -- Draw pause overlay
        Menu.draw_pause_menu(CONFIG.game_width, CONFIG.game_height)
    elseif game.state == "gameOver" then
        Menu.draw_gameOver_menu(CONFIG.game_width, CONFIG.game_height, game.score, globalGameState.highScore)
    end

    -- Switch back to main screen and draw the scaled canvas
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(game.canvas, 0, 0, 0, CONFIG.scale_factor, CONFIG.scale_factor)
end

function love.keypressed(key)
    -- DEBUG
    if game.state == "playing" and key == "9" and CONFIG.allow_debug_spawn_collectible then
        local spawn_x = game.player.x + game.player.width * 2
        local spawn_y = game.player.y

        local collectible
        if math.random() < 0.5 then
            local ptype = PowerUp.getRandomType()
            collectible = PowerUp.new(spawn_x, spawn_y, ptype)
        else
            collectible = Collectible.new(spawn_x, spawn_y, 1)
        end

        table.insert(game.entities, collectible)
        return -- Don't propagate further
    end
    -- Player dash
    if game.state == "playing" and key == "space" then
        if game.player and game.player.startDash then
            game.player:startDash()
        end
        return
    end
    if game.state == "playing" and key == "0" and CONFIG.allow_debug_gameOver then
        transition_to_gameOver_if_needed(true)
        return
    end

    game.state = Menu.handle_input(key, game.state, init_game)
end
