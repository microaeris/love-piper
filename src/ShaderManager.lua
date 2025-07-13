-- ShaderManager class for handling shaders in the game
local ShaderManager = {}

-- Constructor
function ShaderManager.new()
    local self = setmetatable({}, { __index = ShaderManager })

    -- Shader storage
    self.shaders = {}
    self.active_shader = nil
    self.shader_enabled = true

    -- Shader parameters
    self.uniforms = {}

    return self
end

-- Load a shader from file
function ShaderManager:loadShader(name, filepath)
    local success, shader = pcall(love.graphics.newShader, filepath)
    if success then
        self.shaders[name] = shader
        print("Loaded shader: " .. name)
        return shader
    else
        print("Failed to load shader " .. name .. ": " .. tostring(shader))
        return nil
    end
end

-- Set active shader
function ShaderManager:setActiveShader(name)
    if self.shaders[name] then
        self.active_shader = self.shaders[name]
        love.graphics.setShader(self.active_shader)
        print("Active shader set to: " .. name)
    else
        print("Shader not found: " .. name)
    end
end

-- Disable shader
function ShaderManager:disableShader()
    self.active_shader = nil
    love.graphics.setShader()
    print("Shader disabled")
end

-- Set uniform value for active shader
function ShaderManager:setUniform(name, value)
    if self.active_shader then
        local success, err = pcall(function()
            self.active_shader:send(name, value)
        end)
        if success then
            self.uniforms[name] = value
        else
            -- Uniform doesn't exist in this shader, which is fine
            -- print("Warning: Uniform '" .. name .. "' not found in shader")
        end
    end
end

-- Set multiple uniforms at once
function ShaderManager:setUniforms(uniforms)
    if self.active_shader then
        for name, value in pairs(uniforms) do
            local success, err = pcall(function()
                self.active_shader:send(name, value)
            end)
            if success then
                self.uniforms[name] = value
            end
        end
    end
end

-- Get uniform value
function ShaderManager:getUniform(name)
    return self.uniforms[name]
end

-- Update shader with time-based effects
function ShaderManager:update(dt)
    if self.active_shader then
        -- Update time-based uniforms
        self:setUniform("time", love.timer.getTime())
        self:setUniform("delta_time", dt)
    end
end

-- Draw with shader effect
function ShaderManager:drawWithShader(draw_function)
    if self.active_shader and self.shader_enabled then
        love.graphics.setShader(self.active_shader)
        draw_function()
        love.graphics.setShader()
    else
        draw_function()
    end
end

-- Toggle shader on/off
function ShaderManager:toggleShader()
    self.shader_enabled = not self.shader_enabled
    print("Shader enabled: " .. tostring(self.shader_enabled))
end

-- Load all shaders from assets/shaders directory
function ShaderManager:loadAllShaders()
    -- Load existing shaders
    self:loadShader("lighting", "assets/shaders/lighting.glsl")
    self:loadShader("ripples", "assets/shaders/ripples.glsl")
    self:loadShader("crt", "assets/shaders/crt.glsl")

    print("Loaded " .. #self.shaders .. " shaders")
end

-- Get list of available shaders
function ShaderManager:getShaderList()
    local list = {}
    for name, _ in pairs(self.shaders) do
        table.insert(list, name)
    end
    return list
end

return ShaderManager