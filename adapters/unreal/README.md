# Unreal Engine 接入

本机未安装 UE，因此此目录是待实机验证的导入辅助与材质接线说明，不宣称已经测试通过。

通过 UE 的 glTF/Interchange 导入器导入 planet.glb。可选启用 Python Editor Script Plugin 后执行本目录 import_cosmos.py 的 import_planet(export_folder)。脚本保留导入选项窗口，不假定不同 UE 版本的配置完全相同。

普通材质接线：本色纹理 RGB → Base Color，Metallic/Roughness 按导入值；体素 Vertex Color → Base Color；云层 Alpha → Opacity Mask，Blend Mode=Masked，阈值 0.5。使用 Default Lit 和游戏自己的灯光，纹理设 sRGB、Nearest。glTF 使用米，UE 使用厘米，由导入器转换，避免二次缩放。

星空：导入 2:1 sky_panorama.png，用球面 UV 显示在天空球内侧，材质设 Unlit、Two Sided，RGB → Emissive。六面 PNG 也可交给现有 cubemap 转换流程；面向约定见 IMPORT_GUIDE.md，不能把六个 PNG 自动当成一个 UE TextureCube。

云层动画：按 manifest.parameters.cloud_speed 绕局部 +Y（glTF 坐标）转动；导入 UE 后应转换到对应的世界上轴。整体自转同理。

像素分段实时光照需要按项目的 UE 渲染管线选择 Toon 材质实现；标准 GLB 只承载通用受光材质，不包含 Godot Shader。当前不提供未经验证的 UE 自定义光照材质。
