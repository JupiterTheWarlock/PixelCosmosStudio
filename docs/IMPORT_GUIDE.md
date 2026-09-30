# 资产接入说明（v2）

动态噪声版本：静态 GLB/PNG 仍为第 0 秒；循环动画请使用单独的“导出循环动画”，查看 animation.json 与 ANIMATION_GUIDE.md。动画资产和复制的实现说明共用完整参数及 noise_core.gdshaderinc 算法；没有将程序化噪声自动封装为各引擎插件。

## 共同约定

星球 GLB 使用 glTF 2.0 标准受光材质，不带灯光。贴图是本色，不含固定方向阴影。材质可以替换，模型不依赖 Godot 脚本。

右手坐标、+Y 向上、-Z 向前，长度单位为米。引擎导入器通常负责坐标转换。半径已存入 GLB，勿按 manifest.parameters.radius 再次缩放整个模型。

PNG 本色采用 sRGB、直接透明度；像素模式默认最近邻过滤。关闭 mipmap 保留像素，但可能增加远处闪烁。非像素模式采用线性过滤。体素通过标准 COLOR_0 顶点颜色传递本色，自定义材质需要读取它。云层使用 alpha clip，保留透明裁切。

天空顺序为 px,nx,py,ny,pz,nz（+X,-X,+Y,-Y,+Z,-Z）。每面 UV 从左上到右下；u=2U-1、v=2V-1，对应方向：(1,-v,-u),(-1,-v,u),(u,1,v),(u,-1,-v),(u,-v,1),(-u,-v,-1)。目标引擎约定不同则转换方向，或使用全景图。

天空只作为不受光背景。是否用于环境照明由游戏决定。PNG 是 LDR，非真实 HDR 光源数据。

## Godot 4.4

将 planet.glb 放入项目，实例化导入场景，添加游戏自己的 WorldEnvironment 与 OmniLight3D/DirectionalLight3D。天空可直接将 sky.res 赋给 Environment.sky。

优先使用 sky.res，它显式按方向读取六面纹理，可避开 Godot 4.4.1 Compatibility 的 Cubemap 面顺序问题。额外 sky_cubemap.res 按导出时的后端制作，不建议跨后端直接复用；跨引擎六面 PNG 顺序仍是标准 px,nx,py,ny,pz,nz。

星球根节点按 rotation_speed 度/秒绕本地 Y 轴旋转；CloudShell 按 cloud_speed 度/秒相对星球旋转。初始云相位已存进 GLB。可选分段光照见 adapters/godot。

## three.js

GLTFLoader 加载 GLB，普通 MeshStandardMaterial 即可受光。adapters/threejs 提供示例及加载、动画、可选 Toon 材质函数。在工具目录运行：
~~~sh
python -m http.server 19387 --bind 127.0.0.1
~~~
访问 http://127.0.0.1:19387/adapters/threejs/ 。

CubeTextureLoader 按上述顺序加载六面天空，设置 sRGB，赋给 scene.background。示例不强制替换游戏的后处理或环境照明。

## Unity

adapters/unity 基于 glTFast 6.7.1，目标 Unity 2022.3 / Built-in。先安装包，再复制脚本。调用 await loader.LoadFolder(绝对路径)，目录应包含 GLB 和 manifest。

天空用 sky_panorama.png，导入为 sRGB，按模式选择 Point/Bilinear。创建 Skybox/Panoramic 材质，赋给 Lighting 中的 Skybox Material。URP/HDRP 需要对应的 glTFast 材质实现与独立验证。

## Unreal Engine

UE 辅助脚本尚未做实际引擎验证。使用引擎 glTF 导入功能加载 planet.glb；表面使用 Default Lit，体素材质读取 Vertex Color，云层使用 Masked。模型原始单位为米，检查导入后的实际尺寸。

天空可用全景 PNG 贴到内向球体，以 Unlit/Emissive 材质显示；或按目标版本要求制作 cubemap。adapters/unreal 提供编辑器导入辅助脚本与说明。没有声称适配所有 UE 管线的像素 shader。

## 边界

普通材质是通用基础。Godot 分段 shader 和 three.js Toon 是可选风格层，GLB 不会自动传递任意 shader。当前输出本色/透明度和几何法线，不输出单独区域 mask、法线贴图或生成算法。云层动画是球壳旋转，非每帧重算噪声。源素材许可见 THIRD_PARTY_NOTICES.md。
