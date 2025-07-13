local Menu = {}

-- Menu drawing functions
function Menu.draw_start_menu(game_width, game_height)
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()

    -- Title
    local title = "LOVE PIPER"
    local title_width = font:getWidth(title)
    love.graphics.print(title, (game_width - title_width) / 2, game_height / 2 - 30)

    -- Instructions
    local instruction = "Press ENTER to start"
    local instruction_width = font:getWidth(instruction)
    love.graphics.print(instruction, (game_width - instruction_width) / 2, game_height / 2 + 10)
end

function Menu.draw_pause_menu(game_width, game_height)
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, game_width, game_height)

    -- Draw pause text
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()

    local pause_text = "PAUSED"
    local pause_width = font:getWidth(pause_text)
    love.graphics.print(pause_text, (game_width - pause_width) / 2, game_height / 2 - 20)

    local instruction = "Press ESC to resume"
    local instruction_width = font:getWidth(instruction)
    love.graphics.print(instruction, (game_width - instruction_width) / 2, game_height / 2 + 10)
end

-- Handle menu input and state transitions
function Menu.handle_input(key, current_state, init_game_callback)
    if current_state == "start" then
        if key == "return" then
            init_game_callback()
            return "playing"
        end
    elseif current_state == "playing" then
        if key == "escape" then
            return "paused"
        end
    elseif current_state == "paused" then
        if key == "escape" then
            return "playing"
        end
    end

    return current_state -- No state change
end

return Menu
