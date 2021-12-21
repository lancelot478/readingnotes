TreeNode = class("TreeNode")
local class = TreeNode

function class:ctor(_data)
    self.data = _data
    self.children = {}
end

function class:Clear()
    self.data = nil
    self.children = {}
end

function class:SetData(_value)
    self.data = _value
end

function class:GetData()
    return self.data
end

function class:FindNode(_data)
    local node = self
    repeat
    until (node.data == _data)
    return node
end

function class:GetChildren()
    return self.children
end

function class:AddChild(_node)
    table.insert(self.children, _node)
end

function class:RemoveChild(_node)
    for k, v in pairs(self.children) do
        if v == _node then
            table.remove(self.children, k)
            break
        end
    end
end
