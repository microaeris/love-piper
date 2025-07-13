-- Include Simple Tiled Implementation into project
local sti = require "lib.Simple-Tiled-Implementation.sti"

-- Import local modules
local Player = require("src.Player")
local Camera = require("src.Camera")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")
local Menu = require("src.Menu")
local SoundManager = require("src.SoundManager")

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
    game.soundManager:playMusic()

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

    -- Create player entity - start them at a reasonable position on screen
    game.player = Player.new(CONFIG.game_width / 4, CONFIG.game_height / 2, 48, 48)

    -- ripple_shader = love.graphics.newShader("assets/shaders/ripples.glsl")
    -- love.graphics.setShader(ripple_shader)


    -- lighting_shader = love.graphics.newShader("assets/shaders/lighting.glsl")
    -- love.graphics.setShader(lighting_shader)

    -- lighting_shader:send("topColor", { 0.05, 0.05, 0.15 }) -- blue
    -- lighting_shader:send("bottomColor", { 0.4, 0.2, 0.3 })


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

        -- Keep player within screen bounds
        if entity == game.player then
            if entity.x < entity.width / 2 then
                entity.x = entity.width / 2
            elseif entity.x > CONFIG.game_width - entity.width / 2 then
                entity.x = CONFIG.game_width - entity.width / 2
            end
            if entity.y < entity.height / 2 then
                entity.y = entity.height / 2
            elseif entity.y > CONFIG.game_height - entity.height / 2 then
                entity.y = CONFIG.game_height - entity.height / 2
            end
        else
            -- Other entities bounce off screen bounds
            if entity.x - entity.width / 2 < 0 or entity.x + entity.width / 2 > CONFIG.game_width then
                entity.vx = -entity.vx
            end
            if entity.y - entity.height / 2 < 0 or entity.y + entity.height / 2 > CONFIG.game_height then
                entity.vy = -entity.vy
            end
        end
    end
end

local function handle_collisions(dt)
    for i, entity in ipairs(game.entities) do
        if entity ~= game.player and game.player:collidesWith(entity) then
            entity.color = utils.colors.blend(entity.color, utils.colors.red, 0.1)
            entity.rotation = entity.rotation + dt * 2
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
end

function love.update(dt)
    -- Only update game when playing
    if game.state == "playing" then
        -- Update camera (constant scrolling)
        game.camera:update(dt, map)

        -- Update world
        map:update(dt)

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
        -- Draw scrolling background
        game.camera:draw_scrolling_map(map)

        -- Draw entities without camera transform (they move freely on screen)
        draw_entities()
        debug_helpers.draw()
    elseif game.state == "paused" then
        -- Draw the game in the background
        game.camera:draw_scrolling_map(map)

        draw_entities()
        debug_helpers.draw()
        -- Draw pause overlay
        Menu.draw_pause_menu(CONFIG.game_width, CONFIG.game_height)
    end

    -- Switch back to main screen and draw the scaled canvas
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(game.canvas, 0, 0, 0, CONFIG.scale_factor, CONFIG.scale_factor)

    -- love.graphics.print("Hello World", 0, 0)
end

function love.keypressed(key)
    game.state = Menu.handle_input(key, game.state, init_game)
end
