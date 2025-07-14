local Menu = {}

-- Menu drawing functions
function Menu.draw_start_menu(game_width, game_height)
    love.graphics.setColor(1, 1, 1, 1)
    local prevFont = love.graphics.getFont()
    local font = _G.UI_MENU_FONT or prevFont
    love.graphics.setFont(font)

    -- Title
    local title = "APOCALYPSE DUCK"
    local title_width = font:getWidth(title)
    love.graphics.print(title, (game_width - title_width) / 2, game_height / 2 - 30)

    -- Instructions
    local instruction = "Press ENTER to start"
    local instruction_width = font:getWidth(instruction)
    love.graphics.print(instruction, (game_width - instruction_width) / 2, game_height / 2 + 10)

    -- Restore previous font
    love.graphics.setFont(prevFont)
end

function Menu.draw_pause_menu(game_width, game_height)
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, game_width, game_height)

    -- Draw pause text
    love.graphics.setColor(1, 1, 1, 1)
    local prevFont = love.graphics.getFont()
    local font = _G.UI_MENU_FONT or prevFont
    love.graphics.setFont(font)

    local pause_text = "PAUSED"
    local pause_width = font:getWidth(pause_text)
    love.graphics.print(pause_text, (game_width - pause_width) / 2, game_height / 2 - 20)

    local instruction = "Press ESC to resume"
    local instruction_width = font:getWidth(instruction)
    love.graphics.print(instruction, (game_width - instruction_width) / 2, game_height / 2 + 10)

    -- Restore previous font
    love.graphics.setFont(prevFont)
end

function Menu.draw_gameOver_menu(game_width, game_height, score, highScore)
    love.graphics.setColor(1, 1, 1, 1)
    local prevFont = love.graphics.getFont()
    local font = _G.UI_MENU_FONT or prevFont
    love.graphics.setFont(font)

    -- Dynamic vertical spacing based on font size
    local fh = font:getHeight() -- font height
    local spacing = fh + 4      -- add a little extra padding
    -- Start drawing a few lines above vertical centre
    local y = game_height / 2 - spacing * 2.5

    -- Title
    local title = "GAME OVER"
    local title_width = font:getWidth(title)
    love.graphics.print(title, (game_width - title_width) / 2, y - 30)

    -- Next line
    y = y + spacing

    -- "Score" or "NEW HIGH SCORE!!!"
    local instruction = (score == highScore and score ~= 0) and "NEW HIGH SCORE!!!" or "SCORE"
    local instruction_width = font:getWidth(instruction)
    love.graphics.print(instruction, (game_width - instruction_width) / 2, y)

    -- Next line
    y = y + spacing

    -- Score number
    local scoreText = tostring(score)
    local score_width = font:getWidth(scoreText)
    love.graphics.print(scoreText, (game_width - score_width) / 2, y)

    -- Next line
    y = y + spacing

    -- "High Score" label
    local high_score_label = "HIGH SCORE"
    local high_score_width = font:getWidth(high_score_label)
    love.graphics.print(high_score_label, (game_width - high_score_width) / 2, y)

    -- Next line
    y = y + spacing

    -- High score number
    local high_score_num = tostring(highScore)
    local high_score_num_width = font:getWidth(high_score_num)
    love.graphics.print(high_score_num, (game_width - high_score_num_width) / 2, y)

    -- Extra gap before instruction
    y = y + spacing * 1.5

    local pressEnter = "Press ENTER to try again"
    local press_enter_width = font:getWidth(pressEnter)
    love.graphics.print(pressEnter, (game_width - press_enter_width) / 2, y + 15)

    -- Restore previous font
    love.graphics.setFont(prevFont)
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
    elseif current_state == "gameOver" then
        if key == "return" then
            init_game_callback()
            return "playing"
        end
    end

    return current_state -- No state change
end

return Menu
