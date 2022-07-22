https://www.notion.so/xindong/Unity-0237272d68124f5fb835e2292963bbc5

```csharp

base.OnInspectorGUI ();[CustomEditor (typeof (Camera))]
public class CameraExtensionInspector : Editor {

    Camera _target;

    private void OnEnable () {
		_target = (Camera)target;
	}

    public override void OnInspectorGUI () {
		base.OnInspectorGUI ();
		if (GUILayout.Button ("Set Camera Randomly")) {

		}
	}
}
```


```csharp

[CustomEditor (typeof (SceneAsset))]
		public class DefaultAssetsInspector : Editor {

				SceneAsset _target;

				private void OnEnable () {
						_target = (SceneAsset)target;
				}

				public override void OnInspectorGUI () {
						EditorGUILayout.HelpBox ("This is a Unity scene named \"" + _target.name + "\".", MessageType.None);
				}
		}
```
