-- Include Simple Tiled Implementation into project
local sti = require "lib.Simple-Tiled-Implementation.sti"

-- Import local modules
local Player = require("src.Player")
local Enemy = require("src.Enemy")
local EnemySpawner = require("src.EnemySpawner")
local CollectibleSpawner = require("src.CollectibleSpawner")
local Camera = require("src.Camera")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")
local Menu = require("src.Menu")
local SoundManager = require("src.SoundManager")
local ShaderManager = require("src.ShaderManager")
local LayerShaderManager = require("src.LayerShaderManager")
local CustomMapDrawer = require("src.CustomMapDrawer")

-- Game configuration
local CONFIG = {
    game_width = 160,
    game_height = 144,
    scale_factor = 5,
    skip_start_menu = true,           -- Set to true to skip start menu for development
    allow_debug_gameOver = true,      -- Set to true if want to press '0' to auto-gameOver
    scroll_speed = 60,                -- Pixels per second horizontal scroll speed (increased from 30)
    -- Enemy spawning configuration
    enemy_spawn_interval = 2.0,       -- Seconds between enemy spawns
    enemy_spawn_chance = 0.7,         -- Probability of spawning an enemy each interval
    max_enemies = 8,                  -- Maximum number of enemies on screen at once
    -- Collectible spawning configuration
    collectible_spawn_interval = 3.0, -- Seconds between collectible spawns
    collectible_spawn_chance = 0.6,   -- Probability of spawning a collectible each interval
    max_collectibles = 12,            -- Maximum number of collectibles on screen at once
}

local globalGameState = {
    highScore = 0
}

-- Game state variables
local game = {
    -- Game settings
    entities = {},
    player = nil,
    soundManager = nil,
    camera = nil,
    shaderManager = nil,
    enemySpawner = nil,
    collectibleSpawner = nil,
    layerShaderManager = nil,
    customMapDrawer = nil,
    -- Canvas settings for scaled rendering
    canvas = nil,
    -- Game state management
    state = CONFIG.skip_start_menu and "playing" or "start", -- "start", "playing", "paused", "gameOver"
    score = 0,
}

-- Helpers
local function init_window()
    -- Set default filter to nearest
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create canvas for low-resolution rendering
    -- game.canvas = love.graphics.newCanvas(window_width, window_height)
    game.canvas = love.graphics.newCanvas(CONFIG.game_width, CONFIG.game_height)
    game.canvas:setFilter("nearest", "nearest")

    -- love.window.setMode(window_width * CONFIG.scale_factor, window_height * CONFIG.scale_factor)
end

local function init_game()
    -- Load map file
    map = sti("assets/maps/test_map.lua")
    local layer = map:addCustomLayer("Sprites", 4)

    -- Init sound manager
    game.soundManager = SoundManager.new()
    game.soundManager:playAmbience()

    -- Initialize camera
    game.camera = Camera.new(CONFIG.scroll_speed)

    -- Initialize shader managers
    game.shaderManager = ShaderManager.new()
    game.shaderManager:loadAllShaders()

    game.layerShaderManager = LayerShaderManager.new()

    -- Create custom map drawer
    game.customMapDrawer = CustomMapDrawer.new(map, game.layerShaderManager, game.shaderManager)

    -- Assign shaders to specific layers (example)
    game.layerShaderManager:assignShader("Water", "crt")
    game.layerShaderManager:assignShader("Grass", "lighting")
    -- game.layerShaderManager:assignShader("Hills", "ripples")

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
    game.player = Player.new(CONFIG.game_width / 2, CONFIG.game_height / 2, 16, 16)

    -- Initialize enemy spawner
    local spawner_config = {
        enemy_spawn_interval = CONFIG.enemy_spawn_interval,
        enemy_spawn_chance = CONFIG.enemy_spawn_chance,
        max_enemies = CONFIG.max_enemies,
        game_width = CONFIG.game_width,
        game_height = CONFIG.game_height
    }
    game.enemySpawner = EnemySpawner.new(spawner_config)

    -- Initialize collectible spawner
    local collectible_config = {
        collectible_spawn_interval = CONFIG.collectible_spawn_interval,
        collectible_spawn_chance = CONFIG.collectible_spawn_chance,
        max_collectibles = CONFIG.max_collectibles,
        game_width = CONFIG.game_width,
        game_height = CONFIG.game_height
    }
    game.collectibleSpawner = CollectibleSpawner.new(collectible_config)

    ripple_shader = love.graphics.newShader("assets/shaders/ripples.glsl")
    love.graphics.setShader(ripple_shader)

    lighting_shader = love.graphics.newShader("assets/shaders/lighting.glsl")
    love.graphics.setShader(lighting_shader)

    game.entities = {}
    table.insert(game.entities, game.player)
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
        if entity ~= game.player and game.player:collidesWith(entity) then
            if entity.collectible_type then
                -- Collect the item and increment score
                game.score = game.score + (entity.value or 1)
                entity.active = false
            else
                -- Enemy collision feedback
                entity.color = utils.colors.red
                entity.hit_timer = 0.05 -- seconds

                game.soundManager:playCollisionTone()
            end
        end
    end
end

local function transition_to_gameOver_if_needed(forceTransition)
    if game.state ~= "playing" then return end

    if (false or forceTransition) then -- TODO: Change to "if playerHealth <= 0"
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

    table.insert(game.entities, game.player)
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

        -- Update shader manager
        if game.shaderManager then
            game.shaderManager:update(dt)
        end

        -- Update enemy spawning (pass current camera position so spawns are in world coords)
        local cam_x, _ = game.camera:get_position()
        game.enemySpawner:update(dt, game.entities, cam_x)
        -- Update collectible spawning
        game.collectibleSpawner:update(dt, game.entities, cam_x)

        update_entities(dt)
        handle_collisions(dt)

        -- If player moves off-screen, reset them to their spawn position
        do
            local cam_x, cam_y = game.camera:get_position()
            local screen_x = game.player.x - cam_x
            local screen_y = game.player.y - cam_y

            if screen_x < -game.player.width or screen_x > CONFIG.game_width + game.player.width or screen_y < -game.player.height or screen_y > CONFIG.game_height + game.player.height then
                game.player:resetToSpawn()
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
        -- Draw scrolling background (map) with layer-specific shaders
        local map_width_px = map.width * map.tilewidth
        local start_offset = -math.floor(game.camera.x / map_width_px) * map_width_px

        for i = 0, 2 do -- Draw 3 instances for seamless looping
            local offset_x = start_offset + i * map_width_px - game.camera.x
            game.customMapDrawer:draw(offset_x, -game.camera.y)
        end

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
    elseif game.state == "paused" then
        -- Draw the game world in the background with layer-specific shaders
        local map_width_px = map.width * map.tilewidth
        local start_offset = -math.floor(game.camera.x / map_width_px) * map_width_px

        for i = 0, 2 do -- Draw 3 instances for seamless looping
            local offset_x = start_offset + i * map_width_px - game.camera.x
            game.customMapDrawer:draw(offset_x, -game.camera.y)
        end

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
    if game.state == "playing" and key == "0" and CONFIG.allow_debug_gameOver then
        transition_to_gameOver_if_needed(true)
        return
    end

    game.state = Menu.handle_input(key, game.state, init_game)
end
