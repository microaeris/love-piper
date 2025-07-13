-- Include Simple Tiled Implementation into project
local sti = require "lib.Simple-Tiled-Implementation.sti"

function love.load()
	-- Load map file
	map = sti("assets/maps/test_map.lua")
end

function love.update(dt)
	-- Update world
	map:update(dt)
end

function love.draw()
	-- Draw world
	map:draw()


    love.graphics.print("Hello World", 0, 0)
end
