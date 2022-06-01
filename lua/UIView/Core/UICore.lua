---------------- Core Define
local unpack = unpack or table.unpack

local routes = {
    extensionList = { "Container", "ExtensionList" },
    hookList = { "Container", "HookList" },
    stagedConfig = { "Container", "StagedConfig" },
}

local getExtensionMember = function(memberName)
    if not memberName then
        return
    end
    local extensionList = IndexTable(core, unpack(routes.extensionList))
    if not extensionList then
        return
    end
    for _, module in pairs(extensionList) do
        local member = rawget(module, memberName)
        if member then
            return member
        end
    end
end

local toastExtension = function(functionName, callback)
    if not functionName then
        return
    end
    local extensionList = IndexTable(core, unpack(routes.extensionList))
    if not extensionList then
        return
    end
    for _, module in pairs(extensionList) do
        local member = rawget(module, functionName)
        if member then
            SafeInvoke(function()
                callback(member)
            end, "call core extension function")
        end
    end
end

function CallExtension(memberName, ...)
    local args = { ... }
    return SafeInvoke(function()
        local member = getExtensionMember(memberName)
        if type(member) == "function" then
            return member(unpack(args))
        else
            return member
        end
        error(string.format("ui core extension member not found: %s", tostring(memberName)))
    end, "call ui core extension")
end

function WrapHookConfig(hookName, config, index, newIndex)
    local configInterface = rawget(core, hookName)
    if configInterface then
        logError("config already initialized, cannot reassign data: ", hookName)
        return
    end
    if not index then
        index = function(_, key)
            return key
        end
    end
    local tab = {}
    setmetatable(tab, { __index = index, __newindex = newIndex })
    rawset(core, hookName, tab)
    SetTableValue(core, config, ComposeTableRoute(routes.stagedConfig, hookName))
    return true
end
---------------- Before Module Initialize Complete
local onAddHookData = function(hookName, key, value)
    if not key then
        logError(string.format("add hook data but index is nil", hookName))
        return
    end
    local hookTable = IndexTable(core, ComposeTableRoute(routes.hookList, hookName))
    if not hookTable then
        return
    end
    local oldData = rawget(hookTable, key)
    if oldData then
        logError(string.format("list [%s] already has element named [%s]", hookName, key))
    end
    rawset(hookTable, key, value)
end

local onRegisterExtension = function(moduleName, extendModule)
    if not moduleName or not extendModule then
        error("empty ui core extension module")
    end
    SetTableValue(core, extendModule, ComposeTableRoute(routes.extensionList, moduleName))
end

local genAutoCreateTable
genAutoCreateTable = function()
    local tab = {}
    setmetatable(tab, { __index = function(t, k)
        local data = rawget(t, k)
        if not data then
            local status = GetStatus()
            if status < UIStatus.UIInitialized then
                data = genAutoCreateTable()
                rawset(t, k, data)
            end
        end
        return data
    end })
    return tab
end

local onIndexHook = function(hookName)
    local hookTable = GetOrGenerate(core, function()
        local tab = {}
        setmetatable(tab, { __newindex = function(_, newKey, newValue)
            onAddHookData(hookName, newKey, newValue)
        end, __index = function(_, key)
            local hookList = IndexTable(core, ComposeTableRoute(routes.hookList, hookName))
            if not hookList then
                return
            end
            local value = rawget(hookList, key)
            if not value then
                value = genAutoCreateTable()
                rawset(hookList, key, value)
            end
            return value
        end })
        rawset(core, hookName, tab)
        return tab
    end, ComposeTableRoute(routes.hookList, hookName))
    return hookTable
end

---------------- Framework API ----------------
function Initialize(viewBase)
    -- viewBase
    SetTableValue(self, viewBase, "ViewBase")

    -- 注册接口
    local transform = CallViewBase("tra")
    SetTableValue(self, transform, "transform")
end

function RegisterExtension(modulePath, extendModule)
    local status = SafeInvoke(function()
        onRegisterExtension(modulePath, extendModule)
    end, "ui core register extension")
    if not status then
        logError("register ui core extension module failed: ", modulePath)
        return
    end
end

function OnIndex(key)
    local value
    -- Hooks
    if not value then
        if string.match(key, "^Post.*") then
            value = onIndexHook(key)
        end
    end

    local status = GetStatus()
    if status >= UIStatus.ExtensionInitialized then
        if not value then
            toastExtension("CatchIndex", function(func)
                if value then
                    return
                end
                if type(func) ~= "function" then
                    return
                end
                value = func(key)
            end)
        end

        if not value then
            return getExtensionMember(key)
        end
    end
    return value
end

function OnNewIndex(base, key, value)
    local result
    local status = GetStatus()
    if status >= UIStatus.ExtensionInitialized then
        if not result then
            toastExtension("CatchNewIndex", function(func)
                if result then
                    return
                end
                if type(func) ~= "function" then
                    return
                end
                result = func(key, value)
            end)
        end
    end

    if not result then
        rawset(base, key, value)
    end
end

function CallViewBase(memberName, ...)
    local viewBase = IndexTable(self, "ViewBase")
    local member = IndexTable(viewBase, memberName)
    if type(member) == "function" then
        local args = { ... }
        return member(viewBase, unpack(args))
    else
        return member
    end
end

function CallHook(hookName, hookKey, ...)
    local hookHandler = IndexTable(core, ComposeTableRoute(routes.hookList, hookName, hookKey))
    if type(hookHandler) ~= "function" then
        return
    end
    local args = { ... }
    return SafeInvoke(function()
        return hookHandler(unpack(args))
    end, "call ui hook")
end

function LocalAreaBroadcast(funcName, ...)
    local status, allInst = CallExtension("GetHostAllInst")
    if not status or not allInst then
        return
    end
    local args = { ... }
    for luaInst, _ in pairs(allInst) do
        SafeInvoke(function()
            local member = IndexTable(luaInst, funcName)
            if type(member) ~= "function" then
                logError("ui local area broad cast func name is invalid: ", funcName)
                return
            end
            local arg1, arg2, arg3, arg4, arg5 = args[1], args[2], args[3], args[4], args[5]
            member(arg1, arg2, arg3, arg4, arg5)
        end, "ui local area broadcast")
    end
end

function LocalAreaForeach(callback)
    local status, allInst = CallExtension("GetHostAllInst")
    if not status or not allInst then
        return
    end
    for luaInst, _ in pairs(allInst) do
        local _, breakFlag = SafeInvoke(function()
            callback(luaInst)
        end, "ui local area broadcast")
        if breakFlag then
            break
        end
    end
end

function SetStatus(status)
    rawset(core, "Status", status)
    if status >= UIStatus.ExtensionInitialized then
        toastExtension("ModuleStatusChanged", function(func)
            if type(func) ~= "function" then
                return
            end
            func(status)
        end)
    end
end

function GetStatus()
    local status = rawget(core, "Status")
    return status or UIStatus.Uninitialized
end

function SetParam(param)
    self.Param = param
end

---------------- Internal API ----------------
function RegisterExtension(modulePath, extendModule)
    local status = SafeInvoke(function()
        onRegisterExtension(modulePath, extendModule)
    end, "ui core register extension")
    if not status then
        logError("register ui core extension module failed: ", modulePath)
        return
    end
end

function OnIndex(key)
    local value
    -- Hooks
    if not value then
        if string.match(key, "^Post.*") then
            value = onIndexHook(key)
        end
    end

    local status = GetStatus()
    if status >= UIStatus.ExtensionInitialized then
        if not value then
            toastExtension("CatchIndex", function(func)
                if value then
                    return
                end
                if type(func) ~= "function" then
                    return
                end
                value = func(key)
            end)
        end

        if not value then
            return getExtensionMember(key)
        end
    end
    return value
end

function OnNewIndex(base, key, value)
    local result
    local status = GetStatus()
    if status >= UIStatus.ExtensionInitialized then
        if not result then
            toastExtension("CatchNewIndex", function(func)
                if result then
                    return
                end
                if type(func) ~= "function" then
                    return
                end
                result = func(key, value)
            end)
        end
    end
    if not result then
        rawset(base, key, value)
    end
end