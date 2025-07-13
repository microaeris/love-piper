-- CustomMapDrawer for drawing map layers with individual shader support
local CustomMapDrawer = {}

-- Constructor
function CustomMapDrawer.new(map, layer_shader_manager, shader_manager)
    local self = setmetatable({}, { __index = CustomMapDrawer })

    self.map = map
    self.layer_shader_manager = layer_shader_manager
    self.shader_manager = shader_manager

    return self
end

-- Draw the map with layer-specific shaders
function CustomMapDrawer:draw(tx, ty, sx, sy)
    tx, ty = tx or 0, ty or 0
    sx, sy = sx or 1, sy or sx or 1

    -- Draw each layer individually
    for _, layer in ipairs(self.map.layers) do
        if layer.visible and layer.opacity > 0 then
            self:drawLayer(layer, tx, ty, sx, sy)
        end
    end
end

-- Draw a single layer with shader support
function CustomMapDrawer:drawLayer(layer, tx, ty, sx, sy)
    local px, py = layer.parallaxx or 1, layer.parallaxy or 1
    px, py = math.floor(tx * px), math.floor(ty * py)

    -- Use layer shader manager to draw with shader if assigned
    self.layer_shader_manager:drawLayerWithShader(layer, self.shader_manager, function()
        love.graphics.push()
        love.graphics.translate(px, py)

        -- Draw the layer based on its type
        if layer.type == "tilelayer" then
            self:drawTileLayer(layer)
        elseif layer.type == "objectgroup" then
            self:drawObjectLayer(layer)
        elseif layer.type == "imagelayer" then
            self:drawImageLayer(layer)
        end

        love.graphics.pop()
    end)
end

-- Draw a tile layer
function CustomMapDrawer:drawTileLayer(layer)
    local r, g, b, a = love.graphics.getColor()

    -- Apply layer tint if specified
    if layer.tintcolor then
        local tr, tg, tb, ta = unpack(layer.tintcolor)
        ta = ta or 255
        love.graphics.setColor(tr/255, tg/255, tb/255, ta/255 * layer.opacity)
    else
        love.graphics.setColor(r, g, b, a * layer.opacity)
    end

    -- Draw the layer using STI's internal drawing method
    self.map:drawTileLayer(layer)

    love.graphics.setColor(r, g, b, a)
end

-- Draw an object layer
function CustomMapDrawer:drawObjectLayer(layer)
    local r, g, b, a = love.graphics.getColor()

    -- Apply layer tint if specified
    if layer.tintcolor then
        local tr, tg, tb, ta = unpack(layer.tintcolor)
        ta = ta or 255
        love.graphics.setColor(tr/255, tg/255, tb/255, ta/255 * layer.opacity)
    else
        love.graphics.setColor(r, g, b, a * layer.opacity)
    end

    -- Draw the layer using STI's internal drawing method
    self.map:drawObjectLayer(layer)

    love.graphics.setColor(r, g, b, a)
end

-- Draw an image layer
function CustomMapDrawer:drawImageLayer(layer)
    local r, g, b, a = love.graphics.getColor()

    -- Apply layer tint if specified
    if layer.tintcolor then
        local tr, tg, tb, ta = unpack(layer.tintcolor)
        ta = ta or 255
        love.graphics.setColor(tr/255, tg/255, tb/255, ta/255 * layer.opacity)
    else
        love.graphics.setColor(r, g, b, a * layer.opacity)
    end

    -- Draw the layer using STI's internal drawing method
    self.map:drawImageLayer(layer)

    love.graphics.setColor(r, g, b, a)
end

-- Get layer names for easy assignment
function CustomMapDrawer:getLayerNames()
    local names = {}
    for _, layer in ipairs(self.map.layers) do
        table.insert(names, layer.name)
    end
    return names
end

return CustomMapDrawer