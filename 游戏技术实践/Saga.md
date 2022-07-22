# 2D跟着3D旋转

```lua
self.RectTransform.localRotation = Quaternion.Euler(0, 0, -self.Transform.localEulerAngles.y)
```

# 把世界坐标转换为相对于父节点的本地坐标

```lua
 self.Transform:InverseTransformPoint(worldPos)
```
