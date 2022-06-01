--------------------------------------
--- Config: Partial
--- Hook: PostPartial
--------------------------------------

local unpack = unpack or table.unpack

local routes = {
    partialData = { "Container", "PartialData" },
    moduleInst = { "LuaInst", "ModuleInst" },
    stagedConfig = { "Container", "StagedConfig" },
    loader = { "Container", "loader" },
}

local partialType = {
    localPrefab = 1,
    component = 2,
}

---------------- Partial
local generateChildPartialItem = function(widget, rootTran, onComp, ...)
    if not widget then
        return
    end
    if GlobalFun.IsNull(rootTran) then
        return
    end
    local planeTable = UIDriver.new(widget)
    planeTable.args = { ... }
    UIManager:LoadViewPrefab(planeTable, rootTran, function()
        UIManager:OpenView(planeTable)
        GlobalFun.Try(onComp, planeTable)
    end)
end

local generateChildPartialObject = function(configKey, widgetPath, rootTran, ...)
    local transform = IndexTable(self, "transform")
    local widgetPrefab = GlobalFun.GetObj(transform, widgetPath)
    if GlobalFun.IsNull(widgetPrefab) then
        error("cannot find widget path")
        return
    end
    local widgetObject = MonoBehaviour.Instantiate(widgetPrefab, rootTran)
    local widgetTransform = IndexTable(widgetObject, "transform")
    local status, compTab = CallHook("PostPartial", configKey, widgetTransform)
    if not status then
        return
    end
    local partialTab = {
        compTab = compTab,
        object = widgetObject,
    }
    return partialTab
end

local getLocalHost
getLocalHost = function(host, newHost)
    if not host then
        host = self
        newHost = IndexTable(self, "Host")
    end
    if not newHost then
        return host
    end
    host = newHost
    newHost = newHost.Host
    return getLocalHost(host, newHost)
end

local generatePartialItem = function(configKey, onComp, ...)
    local partialConfig = IndexTable(self, ComposeTableRoute(routes.stagedConfig, "Partial", configKey))
    if not configKey or not partialConfig then
        return
    end
    local args = { ... }
    local root = partialConfig.Root
    if not root then
        error("未指定根节点")
        return
    end
    local rootTran
    local rootType = type(root)
    if rootType == "function" then
        rootTran = root(unpack(args))
    elseif rootType == "string" then
        local transform = self.transform
        rootTran = GlobalFun.GetTra(transform, root)
    else
        error("不支持的root类型")
        return
    end
    if GlobalFun.IsNull(rootTran) then
        error("无法获取到根节点")
        return
    end
    local widgetPath = partialConfig.WidgetPath
    local widget = partialConfig.Widget
    if widget then
        generateChildPartialItem(widget, rootTran, function(planeTable)
            GlobalFun.Try(onComp, partialType.component, planeTable)
        end, ...)
    elseif widgetPath then
        local widgetTable = generateChildPartialObject(configKey, widgetPath, rootTran)
        GlobalFun.Try(onComp, partialType.localPrefab, widgetTable)
    end
end

function GetHostAllInst(luaInst, collTab)
    -- get top host
    if not collTab then
        collTab = {}
        collTab[self] = true
    end
    if not luaInst then
        luaInst = IndexTable(self, "LocalHost")
        collTab[luaInst] = true
    end
    if not luaInst then
        return
    end
    local partialData = IndexTable(luaInst, unpack(routes.partialData))
    if partialData then
        for _, partialItem in pairs(partialData) do
            local partialT = IndexTable(partialItem, "_partialType")
            if partialT == partialType.component then
                local itemInst = IndexTable(partialItem, ComposeTableRoute(routes.moduleInst, "self"))
                if itemInst then
                    collTab[itemInst] = true
                    GetHostAllInst(itemInst, collTab)
                end
            end
        end
    end
    return collTab
end

function CallPartial(instanceId, path, ...)
    local moduleInst = IndexTable(self, ComposeTableRoute(routes.partialData, instanceId, routes.moduleInst))
    local args = { ... }
    return SafeInvoke(function()
        if type(path) == "string" then
            return CallTable(moduleInst, path, unpack(args))
        elseif type(path) == "table" then
            return CallTable(moduleInst, unpack(path), unpack(args))
        end
    end, "ui call partial")
end

function AcquirePartial(configKey, onComp, ...)
    generatePartialItem(configKey, function(partialT, luaInst)
        if not luaInst then
            GlobalFun.Try(onComp)
            return
        end
        local instanceId = tostring(luaInst)
        SetTableValue(luaInst, self, "ModuleInst", "Host")
        SetTableValue(luaInst, instanceId, "ModuleInst", "InstanceId")
        local partialItem = {
            _type = configKey,
            _instanceId = instanceId,
            _partialType = partialT
        }
        SetTableValue(partialItem, luaInst, "LuaInst")
        SetTableValue(self, partialItem, ComposeTableRoute(routes.partialData, instanceId))
        if partialT == partialType.component then
            GlobalFun.Try(onComp, instanceId)
        elseif partialT == partialType.localPrefab then
            local compTab = IndexTable(luaInst, "compTab")
            GlobalFun.Try(onComp, instanceId, compTab)
        end
    end, ...)
end

function ReleasePartial(instanceId)
    local partialItem = IndexTable(self, ComposeTableRoute(routes.partialData, instanceId))
    SetTableValue(self, nil, ComposeTableRoute(routes.partialData, instanceId))
    local partialT = IndexTable(partialItem, "_partialType")
    local luaInst = IndexTable(partialItem, "LuaInst")
    if partialT == partialType.component then
        SafeInvoke(function()
            UIManager:CloseView(luaInst)
            UIManager:UnloadView(luaInst)
        end, "ui extension partial - close partial")
    elseif partialT == partialType.localPrefab then
        local object = IndexTable(luaInst,"object")
        if not GlobalFun.IsNull(object) then
            MonoBehaviour.Destroy(object)
        end
    end
end

function ReleasePartials(configKey)
    local partialData = IndexTable(self, unpack(routes.partialData))
    if not partialData then
        return
    end
    for instanceId, partialItem in pairs(partialData) do
        local configType = IndexTable(partialItem, "_type")
        if configType == configKey then
            ReleasePartial(instanceId)
        end
    end
end

function ReleaseAllPartials()
    local partialData = IndexTable(self, unpack(routes.partialData))
    if not partialData then
        return
    end
    for instanceId, _ in pairs(partialData) do
        ReleasePartial(instanceId)
    end
end

function CatchIndex(key)
    if key == "LocalHost" then
        local value = getLocalHost()
        rawset(core, key, value)
        return value
    end
end

function CatchNewIndex(key, value)
    if key == "Partial" then
        return WrapHookConfig(key, value)
    end
end

function ModuleStatusChanged(status)
    if status == UIStatus.BeforeExit then
        ReleaseAllPartials()
    end
end