--------------------------------------
--- Config: Component
--------------------------------------

local unpack = unpack or table.unpack

local routes = {
    componentData = { "Container", "ComponentData" },
    componentConfig = { "Container", "ComponentConfig" },
}

local registerLuaCallback = function(comp, componentName, func)
    if GlobalFun.IsNull(comp) then
        return
    end
    if not func then
        return
    end
    local callFunc
    if type(func) == "function" then
        callFunc = func
    elseif type(func) == "string" then
        callFunc = IndexTable(self, func)
    end
    if type(callFunc) ~= "function" then
        error("cannot bind target event, func is invalid.", func)
        return
    end
    if componentName == "Button" or componentName == "GameObject" then
        GlobalFun.SetBtnFun(comp, callFunc)
    elseif componentName == "Slider" or componentName == "InputField" or componentName == "Toggle" or componentName == "Scrollbar" then
        GlobalFun.BindChangeEvent(comp, callFunc)
    end
end

local getChildComponent = function(path, componentName, callback)
    local component = nil
    if not component and path then
        local transform = IndexTable(self, "transform")
        if not componentName or componentName == "GameObject" then
            component = GlobalFun.GetObj(transform, path)
        else
            component = GlobalFun.GetType(transform, path, componentName)
        end
    end
    registerLuaCallback(component, componentName, callback)
    if not component then
        error("warning: cannot get component: ", path, componentName)
    end
    return component
end

local generateComponentData
generateComponentData = function(componentConfig)
    if not componentConfig then
        return
    end
    local configType = type(componentConfig)
    if configType == "table" then
        -- parse param
        local path = IndexTable(componentConfig, "Path")
        local component = IndexTable(componentConfig, "Component")
        local callback = IndexTable(componentConfig, "Callback")

        local singleConfig = path and (component or callback or true)
        if singleConfig then
            return getChildComponent(path, component, callback)
        else
            local table = {}
            for configKey, value in pairs(componentConfig) do
                table[configKey] = generateComponentData(value)
            end
            return table
        end
    elseif configType == "function" then
        return componentConfig()
    else
        error("无法解析具体类型", configType, componentConfig)
    end
end

local initializeComponent = function()
    local componentConfig = IndexTable(self, unpack(routes.componentConfig))
    if not componentConfig then
        return
    end
    local componentData = generateComponentData(componentConfig)
    SetTableValue(self, componentData, unpack(routes.componentData))
end

local injectComponentData = function(componentConfig)
    local componentInterface = rawget(core, "Component")
    if componentInterface then
        error("cannot reset component definition")
    end

    SetTableValue(core, componentConfig, unpack(routes.componentConfig))

    -- create interface
    componentInterface = {}
    local compMeta = {
        __index = function(_, key)
            local currentStatus = CallTable(core, "GetStatus")
            local moduleInitialized = currentStatus >= UIStatus.UIInitialized
            if not moduleInitialized then
                error("cannot index component data before ui initialize complete")
            end
            local value = IndexTable(core, ComposeTableRoute(routes.componentData, key))
            return value
        end,
        __newindex = function()
            error("cannot set component data!")
        end
    }
    setmetatable(componentInterface, compMeta)
    rawset(core, "Component", componentInterface)
end

function CatchNewIndex(key, value)
    if key == "Component" then
        return SafeInvoke(function()
            injectComponentData(value)
        end, "ui core inject memo")
    end
end

function ModuleStatusChanged(status)
    if status == UIStatus.UIInitialized then
        initializeComponent()
    end
end

function BindLuaClick(comp, func)
    registerLuaCallback(comp, func)
end
