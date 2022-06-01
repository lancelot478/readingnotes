--------------------------------------
--- Config: Memo
--- Hook: PostMemo\PostMemoCompare
--------------------------------------

local unpack = unpack or table.unpack

local routes = {
    memoData = { "Container", "MemoData" },
    initializeMemo = { "Container", "InitializeMemo" },
    hookList = { "Container", "HookList" },
}

local memoCompare = function(memo, value, old)
    local status, state = CallHook("PostMemoCompare", memo, value, old)
    if status then
        return state
    else
        if type(value) == "table" then
            return
        end
        return old == value
    end
end

function OnMemoEvent(memo, value, old)
    local instanceId = self.InstanceId
    CallHook("PostMemo", memo, value, old, instanceId)
end

local injectMemoData = function(initializeConfig)
    local memoConfig = rawget(core, "Memo")
    if memoConfig then
        error("cannot reset memo definition")
    end
    SetTableValue(core, initializeConfig, unpack(routes.initializeMemo))
    memoConfig = {}
    local memoMeta = { __index = function(_, key)
        local currentStatus = CallTable(core, "GetStatus")
        local moduleInitialized = currentStatus >= UIStatus.ModuleInitialized
        if not moduleInitialized then
            return key
        else
            local value
            local uiInitialized = currentStatus >= UIStatus.UIInitialized
            if uiInitialized then
                value = IndexTable(core, ComposeTableRoute(routes.memoData, key))
                if not value then
                    LocalAreaForeach(function(inst)
                        if value ~= nil then
                            return true
                        end
                        value = IndexTable(inst, ComposeTableRoute(routes.memoData, key))
                    end)
                end
            else
                value = IndexTable(core, ComposeTableRoute(routes.initializeMemo, key))
            end
            return value
        end
    end, __newindex = function(_, key, value)
        local currentStatus = CallTable(core, "GetStatus")
        local uiDisplaying = currentStatus >= UIStatus.Displaying
        if not uiDisplaying then
            SetTableValue(core, value, ComposeTableRoute(routes.initializeMemo, key))
            return
        end
        local old = IndexTable(core, ComposeTableRoute(routes.memoData, key))
        local isSame = memoCompare(key, value, old)
        if isSame then
            return
        end
        SetTableValue(core, value, ComposeTableRoute(routes.memoData, key))
        SafeInvoke(function()
            LocalAreaBroadcast("OnMemoEvent", key, value, old)
        end, "handle ui memo")
    end }
    setmetatable(memoConfig, memoMeta)
    rawset(core, "Memo", memoConfig)
    return memoConfig
end

local initializeMemo = function()
    -- 默认值赋值
    local initializeConfig = IndexTable(self, unpack(routes.initializeMemo))
    if initializeConfig then
        for key, value in pairs(initializeConfig) do
            SetTableValue(self, value, ComposeTableRoute(routes.memoData, key))
        end
    end
end

local firstCallMemo = function()
    -- 所有钩子key
    local memoHooks = IndexTable(self, ComposeTableRoute(routes.hookList, "PostMemo"))
    if not memoHooks then
        return
    end
    for key, _ in pairs(memoHooks) do
        local value = IndexTable(self, "Memo", key)
        OnMemoEvent(key, value)
    end
end
---------------- Module API ----------------
function ClearMemo()
    local memoData = IndexTable(self, unpack(routes.memoData))
    if not memoData then
        return
    end
    for key, _ in pairs(memoData) do
        SetTableValue(self, nil, "Memo", key)
    end
end

function ModuleStatusChanged(status)
    if status == UIStatus.Displaying then
        initializeMemo()
        firstCallMemo()
    end
end

function CatchIndex(key)
    if key == "Memo" then
        local value = injectMemoData()
        return value
    end
end

function CatchNewIndex(key, value)
    if key == "Memo" then
        return SafeInvoke(function()
            injectMemoData(value)
        end, "ui core inject memo")
    end
end