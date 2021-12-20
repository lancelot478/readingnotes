GlobalPool = {}

local poolInfoManArr = {}

local function CheckCollect(poolInfoMan)
    for _, v in ipairs(poolInfoMan.objInfoArr) do
        -- local a = Time.realtimeSinceStartup
        -- local count = 0
        if poolInfoMan.updateFun ~= nil and GlobalFun.IsActiveSelf(v.obj) then
            poolInfoMan.updateFun(v)
        -- count = count + 1
        end
        -- if Time.realtimeSinceStartup - a >= 0.001 then
        -- print("@@", poolInfoMan.path count, Time.realtimeSinceStartup - a)
        -- end
    end
    GlobalPool.CollectWithTime(poolInfoMan)
end

function GlobalPool.UpdateAction()
    for _, v in ipairs(poolInfoManArr) do
        CheckCollect(v)
    end
end
--初始化对象
local function GetInitPoolInfo(info)
    local poolInfo = {}
    poolInfo.tra = GlobalFun.InstTra(info.preObj)
    poolInfo.obj = poolInfo.tra.gameObject
    poolInfo.man = info
    return poolInfo
end
--初始化对象池
function GlobalPool.InitPoolInfo(info, tra, path, startFun, updateFun)
    info.objInfoArr = {} -- 当前使用中的对象
    info.idleInfoArr = {} -- 池中的对象
    info.waitInfoArr = {} -- 待收集的对象
    info.preObj = GlobalFun.GetPreObj(tra, path)
    info.preTra = info.preObj.transform
    info.path = path
    info.startFun = startFun
    info.updateFun = updateFun
    table.insert(poolInfoManArr, info)
end
--获取对象
function GlobalPool.GetPoolInfo(info, key, index)
    local poolInfo = nil
    if #info.idleInfoArr > 0 then
        poolInfo = info.idleInfoArr[1]
        table.remove(info.idleInfoArr, 1)
    end
    if poolInfo == nil then
        poolInfo = GetInitPoolInfo(info)
    end
    table.insert(info.objInfoArr, poolInfo)
    poolInfo.obj:SetActive(true)
    poolInfo.key = key
    poolInfo.index = index
    if poolInfo.isInit == nil then
        poolInfo.isInit = true
        if info.startFun ~= nil then
            info.startFun(poolInfo)
        end
    end
    return poolInfo
end

function GlobalPool.Collect(poolInfo, delay)
    GlobalPool.CollectPoolInfo(poolInfo.man, poolInfo, delay)
end

function GlobalPool.CollectAll(info)
    for _, v in ipairs(info.objInfoArr) do
        GlobalPool.Collect(v, 0)
    end
end

function GlobalPool.GetPoolInfoWithIndex(info, index)
    if info.objInfoArr == nil then
        return
    end
    local poolInfo = info.objInfoArr[index]
    if poolInfo == nil then
        poolInfo = GlobalPool.GetPoolInfo(info, nil, index)
        info.objInfoArr[index] = poolInfo
    end
    poolInfo.obj:SetActive(true)
    return poolInfo
end
function GlobalPool.PoolContainsKey(info, key)
    if info.objInfoArr == nil then
        return false
    end
    for _, v in ipairs(info.objInfoArr) do
        if v.key == key then
            return true
        end
    end
    return false
end

function GlobalPool.GetPoolInfoWithKey(info, key)
    if info.objInfoArr == nil then
        return
    end
    local poolInfo = nil
    for _, v in ipairs(info.objInfoArr) do
        if v.key == key then
            poolInfo = v
            break
        end
    end
    if poolInfo == nil then
        poolInfo = GlobalPool.GetPoolInfo(info, key, nil)
    end
    poolInfo.obj:SetActive(true)
    return poolInfo
end

function GlobalPool.SetPoolShowTime(poolInfo, time)
    poolInfo.endTime = Time.time + time
end

function GlobalPool.CollectWithTime(poolInfoMan)
    for _, v in ipairs(poolInfoMan.objInfoArr) do
        if v.endTime ~= nil and Time.time >= v.endTime then
            GlobalPool.CollectPoolInfo(poolInfoMan, v)
        end
    end
    GlobalPool.CleanPoolInfo(poolInfoMan)
end

function GlobalPool.CollectWithDie(poolInfoMan)
    for _, v in ipairs(poolInfoMan.objInfoArr) do
        if v.role:IsDie() then
            GlobalPool.CollectPoolInfo(poolInfoMan, v)
        end
    end
    GlobalPool.CleanPoolInfo(poolInfoMan)
end

function GlobalPool.CollectWithIndex(poolInfoMan, index)
    GlobalPool.CollectPoolInfo(poolInfoMan, poolInfoMan.objInfoArr[index])
    GlobalPool.CleanPoolInfo(poolInfoMan)
end

function GlobalPool.CollectWithIndexAll(poolInfoMan)
    for i, v in ipairs(poolInfoMan.objInfoArr) do
        GlobalPool.CollectWithIndex(poolInfoMan, i)
    end
end

function GlobalPool.HasPoolWithKey(poolInfoMan, key)
    for _, v in ipairs(poolInfoMan.objInfoArr) do
        if v.key == key then
            return true
        end
    end
    return false
end

function GlobalPool.CollectWithKey(poolInfoMan, key)
    for _, v in ipairs(poolInfoMan.objInfoArr) do
        if v.key == key then
            GlobalPool.CollectPoolInfo(poolInfoMan, v)
            break
        end
    end
    GlobalPool.CleanPoolInfo(poolInfoMan)
end

function GlobalPool.CollectPoolInfo(manInfo, poolInfo, delay)
    if poolInfo == nil then
        return
    end
    if delay == nil then
        delay = 0
    end
    if poolInfo.delayTraArr ~= nil then
        for _, v in ipairs(poolInfo.delayTraArr) do
            v:SetParent(poolInfo.tra.parent)
        end
    end
    poolInfo.key = nil
    poolInfo.data = nil
    poolInfo.collectEndTime = Time.time + delay
    poolInfo.obj:SetActive(false)
    poolInfo.tra:SetParent(manInfo.preTra.parent)
    table.insert(manInfo.waitInfoArr, poolInfo)
end

function GlobalPool.CleanPoolInfo(info)
    local index = 1
    while index <= #info.waitInfoArr do
        local isCollect = false
        local waitInfo = info.waitInfoArr[1]
        for i, v in ipairs(info.objInfoArr) do
            if v == waitInfo then
                isCollect = Time.time >= v.collectEndTime
                if isCollect then
                    if v.delayTraArr ~= nil then
                        for _, k in ipairs(v.delayTraArr) do
                            k:SetParent(v.delayParentTra)
                        end
                    end
                    table.remove(info.waitInfoArr, 1)
                    table.insert(info.idleInfoArr, v)
                    table.remove(info.objInfoArr, i)
                end
                break
            end
        end
        if not isCollect then
            index = index + 1
        end
    end
end

function GlobalPool.CollectAndClean(manInfo, poolInfo, delay)
    GlobalPool.CollectPoolInfo(manInfo, poolInfo, delay)
    GlobalPool.CleanPoolInfo(manInfo)
end

function GlobalPool.SetDelayTra(poolInfo, path)
    if poolInfo.delayTraArr == nil then
        poolInfo.delayTraArr = {}
    end
    local tra = GlobalFun.GetTra(poolInfo.tra, path)
    if poolInfo.delayParentTra == nil then
        poolInfo.delayParentTra = tra.parent
    end
    table.insert(poolInfo.delayTraArr, tra)
end
