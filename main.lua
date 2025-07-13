-- Include Simple Tiled Implementation into project
local sti = require "lib.Simple-Tiled-Implementation.sti"

-- Import local modules
local Entity = require("src.Entity")
local Player = require("src.Player")
local utils = require("src.utils")
local debug_helpers = require("src.debug_helpers")

-- Game configuration
local CONFIG = {
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
	local window_width = love.graphics.getWidth()
	local window_height = love.graphics.getHeight()

    -- Create canvas for low-resolution rendering
    game.canvas = love.graphics.newCanvas(window_width, window_height)
    game.canvas:setFilter("nearest", "nearest")

    -- Set window size to accommodate scaled resolution
    love.window.setMode(window_width * CONFIG.scale_factor,
                        window_height * CONFIG.scale_factor)
end

-- FIXME - create an entity controller class
local function draw_entities()
    for _, entity in ipairs(game.entities) do
        entity:draw()
    end
end

function love.load()
    init_window()

	-- Load map file
	map = sti("assets/maps/test_map.lua")
    local layer = map:addCustomLayer("Sprites", 4)

    -- Get player spawn object
	local player
	for k, object in pairs(map.objects) do
		if object.name == "Player" then
			player = object
			break
		end
	end



end

function love.update(dt)
	-- Update world
	map:update(dt)
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
