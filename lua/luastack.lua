---@class Stack
Stack = class("Stack")

function Stack:ctor()
    self._array = {}
end

function Stack:Peek()
    return self._array[#self._array]
end

function Stack:Pop()
    return table.remove(self._array, #self._array)
end

function Stack:Push(object)
    table.insert(self._array, object)
end

function Stack:Contains(object)
    for k, v in pairs(self._array) do
        if v == object then
            return true
        end
    end
    return false
end

function Stack:Size()
    return #self._array
end

function Stack:IsEmpty()
    return (self:Size() == 0)
end

function Stack:Clear()
    self._array = {}
end
