local unpack = unpack or table.unpack

local callUIFunc = function(funcName, ...)
    local member = IndexTable(self, funcName)
    if type(member) ~= "function" then
        return member
    end
    local args = { ... }
    local status, ret = SafeInvoke(function()
        return member(unpack(args))
    end, "call ui inst function")
    if not status then
        return
    end
    return ret
end

---------------- Life cycle ----------------
function InitPanel()
    local status = callUIFunc("GetStatus")
    if status > UIStatus.UIInitialized or status < UIStatus.ModuleInitialized then
        return
    end
    local param = callUIFunc("Param")
    callUIFunc("InitPanel", param)
    callUIFunc("SetStatus", UIStatus.UIInitialized)
end

function OnEnter()
    local status = callUIFunc("GetStatus")
    if status == UIStatus.Displaying then
        return
    end
    local param = callUIFunc("Param")
    callUIFunc("OnEnter", unpack(param or {}))
    callUIFunc("SetStatus", UIStatus.Displaying)
end

function OnExit()
    local status = callUIFunc("GetStatus")
    if status ~= UIStatus.Displaying then
        return
    end
    callUIFunc("SetStatus", UIStatus.BeforeExit)
    callUIFunc("OnExit")
    callUIFunc("SetStatus", UIStatus.Exit)
end

---------------- API ----------------
function ModuleInitialize(viewBase, param)
    callUIFunc("Initialize", viewBase)
    SetParam(param)
end

function SetParam(param)
    callUIFunc("SetParam", param)
end

function GetViewType()
    return callUIFunc("ViewType")
end