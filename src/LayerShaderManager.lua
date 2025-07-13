-- LayerShaderManager for applying shaders to individual map layers
local LayerShaderManager = {}

-- Constructor
function LayerShaderManager.new()
    local self = setmetatable({}, { __index = LayerShaderManager })

    -- Layer-specific shader assignments
    self.layer_shaders = {}
    self.layer_enabled = {}

    return self
end

-- Assign a shader to a specific layer
function LayerShaderManager:assignShader(layer_name, shader_name)
    self.layer_shaders[layer_name] = shader_name
    self.layer_enabled[layer_name] = true
    print("Assigned shader '" .. shader_name .. "' to layer '" .. layer_name .. "'")
end

-- Remove shader from a layer
function LayerShaderManager:removeShader(layer_name)
    self.layer_shaders[layer_name] = nil
    self.layer_enabled[layer_name] = false
    print("Removed shader from layer '" .. layer_name .. "'")
end

-- Toggle shader for a layer
function LayerShaderManager:toggleLayerShader(layer_name)
    if self.layer_enabled[layer_name] then
        self.layer_enabled[layer_name] = false
        print("Disabled shader for layer '" .. layer_name .. "'")
    else
        self.layer_enabled[layer_name] = true
        print("Enabled shader for layer '" .. layer_name .. "'")
    end
end

-- Get shader for a layer
function LayerShaderManager:getLayerShader(layer_name)
    return self.layer_shaders[layer_name]
end

-- Check if layer has shader enabled
function LayerShaderManager:isLayerShaderEnabled(layer_name)
    return self.layer_enabled[layer_name] == true
end

-- Draw a layer with its assigned shader
function LayerShaderManager:drawLayerWithShader(layer, shader_manager, draw_function)
    local layer_name = layer.name
    local shader_name = self:getLayerShader(layer_name)

    if shader_name and self:isLayerShaderEnabled(layer_name) and shader_manager then
        local shader = shader_manager.shaders[shader_name]
        if shader then
            -- Apply shader to this layer
            love.graphics.setShader(shader)
            draw_function()
            love.graphics.setShader()
        else
            -- Shader not found, draw without shader
            draw_function()
        end
    else
        -- No shader assigned, draw normally
        draw_function()
    end
end

-- Get all layer-shader assignments
function LayerShaderManager:getLayerAssignments()
    local assignments = {}
    for layer_name, shader_name in pairs(self.layer_shaders) do
        table.insert(assignments, {
            layer = layer_name,
            shader = shader_name,
            enabled = self.layer_enabled[layer_name]
        })
    end
    return assignments
end

return LayerShaderManager