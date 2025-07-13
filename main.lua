-- Include Simple Tiled Implementation into project
local sti = require "lib.Simple-Tiled-Implementation.sti"

-- Import local modules
local Player = require("src.Player")
local Camera = require("src.Camera")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")
local Menu = require("src.Menu")
local SoundManager = require("src.SoundManager")
local ShaderManager = require("src.ShaderManager")

-- Game configuration
local CONFIG = {
    base_width = 160,
    base_height = 144,
    scale_factor = 5,
    skip_start_menu = true, -- Set to true to skip start menu for development
    scroll_speed = 60,      -- Pixels per second horizontal scroll speed (increased from 30)
}

-- Game state variables
local game = {
    -- Game settings
    entities = {},
    player = nil,
    soundManager = nil,
    camera = nil,
    shaderManager = nil,
    -- Canvas settings for scaled rendering
    canvas = nil,
    -- Game state management
    state = CONFIG.skip_start_menu and "playing" or "start", -- "start", "playing", "paused"
}

-- Helpers
local function init_window()
    -- Set default filter to nearest
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create canvas for low-resolution rendering
    -- game.canvas = love.graphics.newCanvas(window_width, window_height)
    game.canvas = love.graphics.newCanvas(CONFIG.base_width, CONFIG.base_height)
    game.canvas:setFilter("nearest", "nearest")

    CONFIG.game_width  = CONFIG.base_width
    CONFIG.game_height = CONFIG.base_height

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

    -- Initialize shader manager
    game.shaderManager = ShaderManager.new()
    game.shaderManager:loadAllShaders()
    game.shaderManager:setActiveShader("lighting")
    game.shaderManager:setActiveShader("ripples")
    game.shaderManager:setActiveShader("crt")

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

    table.insert(game.entities, game.player)
end

-- FIXME - create an entity controller class
local function draw_entities()
    for _, entity in ipairs(game.entities) do
        entity:draw()
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
            entity.color = utils.colors.blend(entity.color, utils.colors.red, 0.1)
            entity.rotation = entity.rotation + dt * 2
            game.soundManager:playCollisionTone()
            debug_helpers.log("Collision detected with entity " .. i, "DEBUG")
        end
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
        -- Update camera (constant scrolling)
        game.camera:update(dt, map)

        -- Update world
        map:update(dt)

        -- Update shader manager
        if game.shaderManager then
            game.shaderManager:update(dt)
        end

        update_entities(dt)
        handle_collisions(dt)
    end
end

function love.draw()
    -- Render to the low-resolution canvas
    love.graphics.setCanvas(game.canvas)
    love.graphics.clear(game.background_color)

    if game.state == "start" then
        Menu.draw_start_menu(CONFIG.game_width, CONFIG.game_height)
    elseif game.state == "playing" then
        -- Draw scrolling background (map)
        game.camera:draw_scrolling_map(map)

        -- Draw entities with camera transform
        love.graphics.push()
        local cam_x, cam_y = game.camera:get_position()
        love.graphics.translate(-cam_x, -cam_y)
        draw_entities()
        love.graphics.pop()

        -- Screen-space overlays (debug, UI)
        debug_helpers.draw()
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
        -- Draw pause overlay
        Menu.draw_pause_menu(CONFIG.game_width, CONFIG.game_height)
    end

    -- Switch back to main screen and draw the scaled canvas with shader
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    -- Apply shader to the final canvas draw
    if game.shaderManager then
        game.shaderManager:drawWithShader(function()
            love.graphics.draw(game.canvas, 0, 0, 0, CONFIG.scale_factor, CONFIG.scale_factor)
        end)
    else
        love.graphics.draw(game.canvas, 0, 0, 0, CONFIG.scale_factor, CONFIG.scale_factor)
    end
end

function love.keypressed(key)
    game.state = Menu.handle_input(key, game.state, init_game)
end
