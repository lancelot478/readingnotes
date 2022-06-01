local _ENV = Boli2Env

local unpack = unpack or table.unpack

function reimport(name)
    local package = package
    package.loaded[name] = nil
    package.preload[name] = nil
    return require(name)
end

function c_require(moduleName)
    local status = SafeInvoke(function()
        reimport(moduleName)
    end, "require module")
    return status
end

function SafeInvoke(callback, message, length, blockReport, callbackError)
    if type(callback) ~= "function" then
        return
    end
    if type(callbackError) ~= "function" then
        callbackError = function(err)
            local defaultKey = "safe invoke with exception"
            local header = message and string.format("%s - %s: %s", defaultKey, tostring(message), err) or string.format("%s: %s", defaultKey, err)
            local exception = debug.traceback(header, length or 3)
            if not blockReport then
                error(exception)
            else
                print(exception)
            end
        end
    end
    return xpcall(callback, callbackError)
end

function CacheModuleMember(module, memberName, generate)
    if not module or memberName == nil then
        return
    end
    local member = module[memberName]
    if member == nil then
        if generate == nil then
            member = { }
        elseif type(generate) == "function" then
            member = generate()
        end
        module[memberName] = member
    end
    return member
end

function IndexTable(table, key, ...)
    if table == nil then
        return
    end
    if key == nil then
        return table
    end
    local item = table[key]
    return IndexTable(item, ...)
end

local _composeTableRoute
_composeTableRoute = function(acc, now, ...)
    if not acc then
        return
    end
    if now == nil then
        return unpack(acc)
    end
    if type(now) == "table" then
        for _, v in pairs(now) do
            table.insert(acc, v)
        end
    else
        table.insert(acc, now)
    end

    return _composeTableRoute(acc, ...)
end

function ComposeTableRoute(...)
    return _composeTableRoute({  }, ...)
end

function SetTableValue(table, value, key, nextKey, ...)
    if not table then
        return
    end
    if not key then
        return table
    end
    if type(table) ~= "table" then
        error("table path inspect invalid data")
    end
    local item = table[key]
    if item == nil or not nextKey then
        local preSet = nextKey and {} or value
        item = preSet
        table[key] = item
    end
    return SetTableValue(item, value, nextKey, ...)
end

function GetOrSet(table, defaultValue, key, nextKey, ...)
    if not table then
        return
    end
    if key == nil then
        return table
    end
    if type(table) ~= "table" then
        error("table path inspect invalid data")
    end
    local item = table[key]
    if item == nil then
        local preSet = nextKey and {} or defaultValue
        item = preSet
        table[key] = item
    end
    return GetOrSet(item, defaultValue, nextKey, ...)
end

function GetOrGenerate(table, defaultValue, key, nextKey, ...)
    if not table then
        return
    end
    if key == nil then
        return table
    end
    if type(table) ~= "table" then
        error("table path inspect invalid data")
    end
    local item = table[key]
    if item == nil then
        local preSet = nextKey and {} or (type(defaultValue) == "function" and defaultValue() or defaultValue)
        item = preSet
        table[key] = item
    end
    return GetOrGenerate(item, defaultValue, nextKey, ...)
end

function GetOrSetTable(table, ...)
    return GetOrSet(table, {}, ...)
end

function CallTable(tab, memberName, ...)
    local member = IndexTable(tab, memberName)
    if type(member) == "function" then
        local args = { ... }
        return member(unpack(args))
    else
        return member
    end
end

function CheckParam(...)
    local args = { ... }
    for _, arg in pairs(args) do
        if not arg then
            return false
        end
    end
    return true
end

local function getfenv(fn)
    local i = 1
    while true do
        local name, val = debug.getupvalue(fn, i)
        if name == "_ENV" then
            return val
        elseif not name then
            break
        end
        i = i + 1
    end
end

local function setfenv(fn, env)
    local i = 1
    while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
            debug.upvaluejoin(fn, i, (function()
                return env
            end), 1)
            break
        elseif not name then
            break
        end

        i = i + 1
    end
    return fn
end

function LoadRestrictedModule(moduleName, meta)
    if not moduleName then
        return
    end
    moduleName = string.gsub(moduleName, "%.", "/")
    local moduleFunc = loadfile(moduleName)
    if not moduleFunc then
        return
    end
    if not meta then
        meta = { __index = _ENV }
    end
    local moduleInst = {}
    setmetatable(moduleInst, meta)
    setfenv(moduleFunc, moduleInst)()
    return moduleInst
end