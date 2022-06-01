local _ENV = Boli2Env

if not UIKit then
    UIKit = {}
end

-- 设置Object状态
function UIKit.SetObjectState(object, state)
    if GlobalFun.IsNull(object) then
        return
    end
    object:SetActive(state)
end

-- 设置组件状态
function UIKit.SetComponentState(comp, state)
    if GlobalFun.IsNull(comp) then
        return
    end
    state = not not state
    comp.enabled = state
end

function UIKit.GetChild(tran, path)
    if not path then
        return
    end
    if GlobalFun.IsNull(tran) then
        return
    end
    local child = tran:Find(path)
    return child
end

function UIKit.GetChildObject(tran, path)
    local child = UIKit.GetChild(tran, path)
    if GlobalFun.IsNull(child) then
        return
    end
    local object = child.gameObject
    return object
end

function UIKit.GetComponent(tran, componentName, path)
    if path then
        tran = UIKit.GetChild(tran, path)
    end
    if GlobalFun.IsNull(tran) then
        return
    end
    local component = tran:GetComponent(componentName)
    return component
end

function UIKit.SetScaleX(tran, x)
    if not x then
        x = 1
    end
    if GlobalFun.IsNull(tran) then
        return
    end
    tran.localScale = Vector3(x, 1, 1)
end

function UIKit.SetText(comp, value)
    if GlobalFun.IsNull(comp) then
        return
    end
    if not value then
        value = ""
    end
    comp.text = value
end

function UIKit.GetInputText(comp)
    if GlobalFun.IsNull(comp) then
        return
    end
    return comp.text or ""
end