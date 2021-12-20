Queue = class("Queue")

function Queue:ctor()
    self._array = {}
end

function Queue:Peek()
    return self._array[1]
end

function Queue:Dequeue()
    return table.remove(self._array, 1)
end

function Queue:Enqueue(object)
    table.insert(self._array, object)
end

function Queue:Contains(object)
    for k, v in pairs(self._array) do
        if v == object then
            return true
        end
    end
    return false
end

function Queue:Size()
    return #self._array
end

function Queue:IsEmpty()
    return (self:Size() == 0)
end

function Queue:Clear()
    self._array = {}
end
