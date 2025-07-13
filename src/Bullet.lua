local Entity       = require("src.Entity")
local utils        = require("src.utils")

local Bullet       = Entity:extend()

local BULLET_SPEED = 180

function Bullet.new(x, y, dir)
    local self = Entity.new(x, y, 4, 2)
    setmetatable(self, Bullet)

    self.dir = dir or 1 -- 1 = right, -1 = left
    self:setVelocity(BULLET_SPEED * self.dir, 0)

    self.color = utils.colors.white
    self.is_bullet = true

    return self
end

function Bullet:update(map, dt)
    if not self.active then return end

    -- Move straightforward; ignore map collisions
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self:setPosition(self.x, self.y)

    -- Deactivate if off-screen (beyond viewport + margin)
    local cam_x = 0
    if _G.GAME_CAMERA_GET_X then cam_x = _G.GAME_CAMERA_GET_X() end
    if self.x > cam_x + love.graphics.getWidth() / (_G.CONFIG and _G.CONFIG.scale_factor or 1) + 20 then
        self.active = false
    end
end

function Bullet:draw()
    if not self.active then return end
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return Bullet
