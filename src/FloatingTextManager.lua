-- FloatingTextManager: spawns & updates floating combat text ("juice" pop-ups)
-- Usage:
--   local ftm = FloatingTextManager.new()
--   ftm:add("+10", x, y)
--   ftm:update(dt)
--   ftm:draw()   -- call while world-transform is active

local FloatingTextManager   = {}
FloatingTextManager.__index = FloatingTextManager

-- Constants ------------------------------------------------------------------------------
local DEFAULT_LIFETIME      = 0.6         -- seconds text stays on-screen
local FLOAT_SPEED           = 20          -- pixels per second upward motion
local START_ALPHA           = 1.0         -- initial opacity
local DEFAULT_COLOR         = { 1, 1, 1 } -- white

local FONT_PATH             = "assets/fonts/PixelOperatorMono8.ttf"
local FONT_SIZE             = 4
local SMALL_FONT            = love.graphics.newFont(FONT_PATH, FONT_SIZE)
SMALL_FONT:setFilter("nearest", "nearest")

-- Constructor -----------------------------------------------------------------------------
function FloatingTextManager.new()
    local self = setmetatable({}, FloatingTextManager)
    self.texts = {}
    return self
end

-- Spawn a new floating text ---------------------------------------------------------------
-- text    : string to display (e.g., "+100")
-- x, y    : world-space coordinates to spawn at (centre point)
-- color   : optional table {r,g,b} (0-1 range) ; defaults to white
-- lifetime: optional custom lifetime in seconds
function FloatingTextManager:add(text, x, y, color, lifetime)
    table.insert(self.texts, {
        text     = text,
        x        = x,
        y        = y,
        life     = lifetime or DEFAULT_LIFETIME,
        max_life = lifetime or DEFAULT_LIFETIME,
        color    = color or DEFAULT_COLOR,
    })
end

-- Update all active texts -----------------------------------------------------------------
function FloatingTextManager:update(dt)
    for i = #self.texts, 1, -1 do
        local t = self.texts[i]
        -- Move upward
        t.y = t.y - FLOAT_SPEED * dt
        -- Countdown life
        t.life = t.life - dt
        -- Cull expired
        if t.life <= 0 then
            table.remove(self.texts, i)
        end
    end
end

-- Draw texts (expects world transform active) ---------------------------------------------
function FloatingTextManager:draw()
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(SMALL_FONT)
    for _, t in ipairs(self.texts) do
        local alpha = (t.life / t.max_life) * START_ALPHA
        love.graphics.setColor(t.color[1], t.color[2], t.color[3], alpha)
        love.graphics.print(t.text, math.floor(t.x), math.floor(t.y))
    end
    love.graphics.setFont(prevFont)
    love.graphics.setColor(1, 1, 1, 1)
end

return FloatingTextManager
