-- Include Simple Tiled Implementation into project
local sti = require "lib.Simple-Tiled-Implementation.sti"

-- Import local modules
local Player = require("src.Player")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")

-- Game configuration
local CONFIG = {
    base_width = 160,
    base_height = 144,
    scale_factor = 5,
}

-- Game state variables
local game = {
    -- Game settings
    entities = {},
    player = nil,
    -- Canvas settings for scaled rendering
    canvas = nil,
}

-- Helpers
local function init_window()
    -- Calculate scaling to fit window
    -- local window_width = love.graphics.getWidth()
    -- local window_height = love.graphics.getHeight()

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

-- FIXME - create an entity controller class
local function draw_entities()
    for _, entity in ipairs(game.entities) do
        entity:draw()
    end
end

local function update_entities(dt)
    for _, entity in ipairs(game.entities) do
        entity:update(map, dt)

        if entity ~= game.player then
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

    -- Load map file
    map = sti("assets/maps/test_map.lua")
    local layer = map:addCustomLayer("Sprites", 4)

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
    game.player = Player.new(player_map_obj.x, player_map_obj.y, 48, 48)

    table.insert(game.entities, game.player)
end

function love.update(dt)
    -- Update world
    map:update(dt)

    update_entities(dt)
    handle_collisions(dt)
end

function love.draw()
    -- Render to the low-resolution canvas
    love.graphics.setCanvas(game.canvas)
    love.graphics.clear(game.background_color)

    map:draw()
    draw_entities()
    debug_helpers.draw()

    -- Switch back to main screen and draw the scaled canvas
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(game.canvas, 0, 0, 0, CONFIG.scale_factor, CONFIG.scale_factor)

    -- love.graphics.print("Hello World", 0, 0)
end
