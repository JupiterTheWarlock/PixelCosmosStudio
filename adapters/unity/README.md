# Unity 接入

基础资产：GLB + PNG + manifest.json。安装官方 `com.unity.cloud.gltfast` 后可导入 GLB，并使用当前管线的受光材质。不要设成 Unlit。

代码示例以 Unity 2022.3、glTFast 6.7.1、Built-in 管线为目标。把 CosmosLoader.cs、CosmosAnimation.cs 加入项目，再调用：

```csharp
var loader = gameObject.AddComponent<CosmosLoader>();
await loader.LoadFolder(absoluteExportDirectory);
```

模型使用自己的场景灯光。本色贴图为 sRGB，像素风格使用 Point 过滤；云层用 Alpha Clip/Cutout。
glTFast 负责坐标系转换，不要再手工翻转 Z。半径单位为米。

URP/HDRP 使用 glTFast 对应管线的材质支持；本目录不替换 Renderer Feature 或 Render Pipeline Asset。
可把导入材质替换为项目自己的 Toon/Shader Graph 材质，保留本色贴图、顶点颜色（体素）、Alpha Clip 和法线。
具体实测状态见项目根目录 VALIDATION.md；未测试的管线不标为通过。
