local _ENV = Boli2Env

require("Tools/UIView/Core/UIDriver")

if not UIController then
    UIController = {
        DebugState = false
    }
end

function UIController.Debug(...)
    local state = UIController.DebugState
    if not state then
        return
    end
    logError(...)
end

UIController.Extension = {
    "UIExtensionComponent",
    "UIExtensionMemo",
    "UIExtensionPartial",
    "UIExtensionEditor",
    "UIExtensionVIewInterface",
}

local bindUICoreExtension = function(uiCore)
    local extensionList = UIController.Extension
    if not extensionList then
        return
    end
    for _, moduleName in pairs(extensionList) do
        local modulePath = string.format("Tools/UIView/Extension/%s", moduleName)
        local extendModule = LoadRestrictedModule(modulePath, { __index = uiCore })
        CallTable(uiCore, "RegisterExtension", modulePath, extendModule)
    end
end

local loadUICore = function(uiModuleName)
    local newIndexFunc, indexFunc
    local uiCore = LoadRestrictedModule("Tools/UIView/Core/UICore", { __index = function(tab, key)
        local val = rawget(tab, key)
        if not val then
            val = (_ENV or _G)[key]
        end
        if not val and indexFunc then
            val = indexFunc(key)
        end
        return val
    end, __newindex = function(...)
        if newIndexFunc then
            newIndexFunc(...)
        else
            rawset(...)
        end
    end, __tostring = function()
        return string.format("%s.core", uiModuleName)
    end })
    if not uiCore then
        return
    end
    indexFunc = uiCore.OnIndex
    newIndexFunc = uiCore.OnNewIndex
    rawset(uiCore, "core", uiCore)
    bindUICoreExtension(uiCore)
    CallTable(uiCore, "SetStatus", UIStatus.ExtensionInitialized)
    return uiCore
end

local executeLoadUI = function(uiModuleName, modulePath)
    local loadFunc = LoadRestrictedModule
    local uiCore = loadUICore(uiModuleName)
    local uiMediator = loadFunc("Tools/UIView/Core/UICoreMediator")
    if not uiMediator or not uiCore then
        return
    end
    local uiModule = loadFunc(modulePath, { __index = uiCore, __newindex = uiCore, __tostring = function()
        return string.format("%s.module", uiModuleName)
    end })
    if not uiModule then
        return
    end
    rawset(uiCore, "self", uiModule)
    rawset(uiMediator, "self", uiModule)
    local uiInst = setmetatable({}, { __index = uiMediator })
    CallTable(uiModule, "SetStatus", UIStatus.ModuleInitialized)
    UIController.Debug(uiModule, uiCore)
    return uiInst
end

function UIController.LoadUI(uiModuleName)
    local _, uiInst = SafeInvoke(function()
        local modulePath = string.format("Views/%s", uiModuleName)
        return executeLoadUI(uiModuleName, modulePath)
    end, "ui controller load ui")
    return uiInst
end