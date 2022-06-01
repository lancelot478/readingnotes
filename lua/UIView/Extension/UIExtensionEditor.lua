
local isEditor = UnityEngine.Application.isEditor

local unloadSelf = function()
    local viewBase = IndexTable(self, "ViewBase")
    if not viewBase then
        return
    end
    UIManager:UnloadView(viewBase)
end

function ModuleStatusChanged(status)
    if not isEditor then
        return
    end
    if status == UIStatus.Exit then
        unloadSelf()
    end
end

