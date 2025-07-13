-- Sprite class for handling sprite sheets with anim8
local anim8 = require('lib.anim8.anim8')

local Sprite = {}
Sprite.__index = Sprite

-- Constructor for creating a new sprite manager
function Sprite.new(imagePath, frameWidth, frameHeight)
    local self = setmetatable({}, Sprite)

    -- Load the sprite sheet
    self.image = love.graphics.newImage(imagePath or 'assets/player.png')
    self.frameWidth = frameWidth or 16
    self.frameHeight = frameHeight or 16

    -- Create the main grid for the sprite sheet
    self.grid = anim8.newGrid(
        self.frameWidth,
        self.frameHeight,
        self.image:getWidth(),
        self.image:getHeight()
    )

    -- Store animations
    self.animations = {}

    -- Calculate grid dimensions for reference
    self.gridWidth = math.floor(self.image:getWidth() / self.frameWidth)
    self.gridHeight = math.floor(self.image:getHeight() / self.frameHeight)

    return self
end

-- Add a named animation to the sprite
function Sprite:addAnimation(name, frames, duration, onLoop)
    duration = duration or 0.1

    if type(frames) == "string" then
        -- e.g. "1-4,2"
        local colRange, row = frames:match("([^,]+),(%d+)")
        if not colRange or not row then
            error("Invalid frame string format. Use 'start-stop,row', e.g. '1-4,2'")
        end
        row = tonumber(row)

        -- Uses anim8's shorthand: grid('1-4', 2)
        self.animations[name] = anim8.newAnimation(
            self.grid(colRange, row),
            duration,
            onLoop
        )
    elseif type(frames) == "table" then
        -- e.g. {{1,1}, {2,1}, {3,1}}
        local quads = {}
        for _, frame in ipairs(frames) do
            assert(#frame == 2, "Each frame must be {col, row}")
            local col, row = frame[1], frame[2]
            local quad = self.grid:getFrames(col, row)[1]
            table.insert(quads, quad)
        end

        self.animations[name] = anim8.newAnimation(quads, duration, onLoop)
    else
        error("Invalid frames argument: expected string or table")
    end
end

-- Get a specific animation
function Sprite:getAnimation(name)
    return self.animations[name]
end

-- Create a clone of an animation (useful for multiple instances)
function Sprite:cloneAnimation(name)
    local anim = self.animations[name]
    if anim then
        return anim:clone()
    end
    return nil
end

-- Get a single frame from the grid
function Sprite:getFrame(col, row)
    return self.grid:getFrames(col, row)[1]
end

-- Draw a single frame
function Sprite:drawFrame(col, row, x, y, r, sx, sy, ox, oy, kx, ky)
    local frame = self:getFrame(col, row)
    love.graphics.draw(self.image, frame, x, y, r, sx, sy, ox, oy, kx, ky)
end

-- Draw an animation
function Sprite:drawAnimation(animationName, x, y, r, sx, sy, ox, oy, kx, ky)
    local animation = self.animations[animationName]
    if animation then
        animation:draw(self.image, x, y, r, sx, sy, ox, oy, kx, ky)
    end
end

-- Update an animation
function Sprite:updateAnimation(animationName, dt)
    local animation = self.animations[animationName]
    if animation then
        animation:update(dt)
    end
end

-- Update all animations
function Sprite:updateAll(dt)
    for _, animation in pairs(self.animations) do
        animation:update(dt)
    end
end

-- Get sprite sheet info
function Sprite:getInfo()
    return {
        imageWidth = self.image:getWidth(),
        imageHeight = self.image:getHeight(),
        frameWidth = self.frameWidth,
        frameHeight = self.frameHeight,
        gridWidth = self.gridWidth,
        gridHeight = self.gridHeight,
        totalFrames = self.gridWidth * self.gridHeight
    }
end

-- Return the Sprite class
return Sprite