# 2D跟着3D旋转

```lua
self.RectTransform.localRotation = Quaternion.Euler(0, 0, -self.Transform.localEulerAngles.y)
```

# 把世界坐标转换为相对于父节点的本地坐标

```lua
 self.Transform:InverseTransformPoint(worldPos)
```

# 2DUI绑定到3D 物体上

```lua
local point = cameraTra:WorldToScreenPoint(worldPos)
local dis = Vector3.Distance(cameraPos,worldPos)
point.x = point.x
point.y = point.y + 100/dis --相机距离物体越远，ui偏移越大
local uiTra.localPosition = point
```
