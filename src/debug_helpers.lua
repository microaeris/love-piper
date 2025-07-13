-- Debug helper functions for Love2D development
local debug_helpers = {}

-- Constants for debugging
debug_helpers.DEBUG_MODE = true -- Set to false for release builds
debug_helpers.SHOW_FPS = true
debug_helpers.SHOW_HITBOXES = false
debug_helpers.SHOW_PATHS = false

-- Initialize the debugger if available
function debug_helpers.init()
    -- Check if we're in debug mode with the Local Lua Debugger
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        -- Load the debugger library
        local lldebugger = require("lldebugger")
        lldebugger.start()

        -- Add a global function to set breakpoints in code
        -- Usage: debugger() -- Will pause execution when this line is reached
        _G.debugger = function()
            lldebugger.stop()
        end

        print("Debugger initialized. Use debugger() to set breakpoints in code.")
    else
        -- Create a dummy debugger function that does nothing
        _G.debugger = function() end
    end
end

-- Draw debug information on screen
function debug_helpers.draw()
    if not debug_helpers.DEBUG_MODE then return end

    local stats = {}

    -- Show FPS
    if debug_helpers.SHOW_FPS then
        table.insert(stats, "FPS: " .. love.timer.getFPS())
    end

    -- Show memory usage
    local mem = collectgarbage("count")
    table.insert(stats, string.format("Memory: %.2f KB", mem))

    -- Show draw calls
    table.insert(stats, "Draw calls: " .. love.graphics.getStats().drawcalls)

    -- Draw stats in the top-right corner
    love.graphics.setColor(1, 1, 1, 0.8)
    local x = love.graphics.getWidth() - 200
    local y = 10

    for i, stat in ipairs(stats) do
        love.graphics.print(stat, x, y + (i - 1) * 20)
    end
end

-- Draw hitboxes for debugging collision
function debug_helpers.drawHitboxes(entities)
    if not debug_helpers.DEBUG_MODE or not debug_helpers.SHOW_HITBOXES then return end

    love.graphics.setColor(0, 1, 0, 0.5)
    for _, entity in ipairs(entities) do
        if entity.active then
            -- Draw the entity's hitbox
            love.graphics.rectangle(
                "line",
                entity.x - entity.width / 2,
                entity.y - entity.height / 2,
                entity.width,
                entity.height
            )
        end
    end
end

-- Log a message with timestamp (only in debug mode)
function debug_helpers.log(message, level)
    if not debug_helpers.DEBUG_MODE then return end

    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[%s] [%s] %s", timestamp, level, message))
end

-- Create a watch value that will be displayed in the debugger
function debug_helpers.watch(name, value)
    if not debug_helpers.DEBUG_MODE then return end

    -- This creates a global variable that will be visible in the debugger
    _G["__WATCH_" .. name] = value
end

return debug_helpers