# Godot 可选像素光照

普通 GLB 导入后已经能接受 Godot 实时灯光。pixel_lit.gdshader 提供可选分段明暗。工具 studio_v2.gd 中 apply_style() 展示纹理、顶点颜色与透明裁切的完整配置，可复用该方法给每个表面设置覆盖材质。

工具导出始终使用普通标准材质，可选 shader 不写进 GLB。它不替换你的全屏渲染管线。

以 rotate_y(deg_to_rad(速度)*delta) 旋转星球根节点与 CloudShell，可复现 manifest 的自转和相对云层运动，无需重建贴图。
