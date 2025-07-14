local HUD = {}

-- Scale factor for duck icons (0.5 makes them 8×8 instead of full 16×16)
HUD.ICON_SCALE = 0.5
HUD.ICON_SPACING = 2  -- pixels between icons
HUD.MARGIN_RIGHT = 10 -- distance from right edge
HUD.MARGIN_TOP = 10   -- distance from top edge

-- Initialise HUD with references we need (should be called after player created)
function HUD.init(player, game_width)
    HUD.player = player
    HUD.game_width = game_width

    if player and player.sprite then
        -- Right-facing idle frame: column 1, row 4 in duck_sheet.png
        HUD.icon_image = player.sprite.image
        HUD.icon_quad  = player.sprite:getFrame(1, 4)
    end
end

-- Internal helper to draw duck icons for health
local function draw_health_icons()
    if not (HUD.player and HUD.icon_image and HUD.icon_quad) then return end

    local health     = HUD.player.health or 0
    local max_health = HUD.player.max_health or 3

    local icon_w     = 16 * HUD.ICON_SCALE
    local spacing    = HUD.ICON_SPACING
    local total_w    = max_health * icon_w + (max_health - 1) * spacing
    local start_x    = HUD.game_width - total_w - HUD.MARGIN_RIGHT
    local y          = HUD.MARGIN_TOP

    for i = 1, max_health do
        if i <= health then
            love.graphics.setColor(1, 0, 0, 1) -- red (filled heart equivalent)
        else
            love.graphics.setColor(0, 0, 0, 1) -- black (lost health)
        end
        local x = start_x + (i - 1) * (icon_w + spacing)
        love.graphics.draw(HUD.icon_image, HUD.icon_quad, x, y, 0, HUD.ICON_SCALE, HUD.ICON_SCALE)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Public draw call – draws the full HUD (score + health)
function HUD.draw(score)
    -- Score (top-left)
    local prevFont = love.graphics.getFont()
    local hudFont  = _G.UI_BIG_FONT or prevFont
    love.graphics.setFont(hudFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Score: " .. tostring(score), 10, HUD.MARGIN_TOP)

    -- Health icons (top-right)
    draw_health_icons()

    love.graphics.setFont(prevFont)
end

return HUD
