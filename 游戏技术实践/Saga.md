# 2D跟着3D旋转

```lua
self.RectTransform.localRotation = Quaternion.Euler(0, 0, -self.Transform.localEulerAngles.y)
```
