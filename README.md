# Pixel Cosmos Studio v2

独立 Godot 4 工具：生成像素/体素 3D 星球与像素星空，导出供游戏使用。沿用 PixelPlanets / PixelSpace 的色板与图层思路，并适配三维空间。

## 打开与使用

使用 Godot 4.4.1 导入 `project.godot`，按 F5。Windows 可在配置 `GODOT_EXECUTABLE` 或将 `godot` 加入 PATH 后双击 `start.cmd`。运行验证后，截图和报告生成到 `exports/v2`。

1. 在“星球生成”“星空生成”两个页面之间切换。参数、相机和结果分别保存。
2. 左侧预览，右侧配置，与原仓库布局对齐。“常用”页直接选择类型、种子、配色和图层；修改后自动更新。星球提供 8 类预设、球体/体素形态、独立云层与星环。
3. 拖动预览旋转视角，滚轮缩放。下方环境光、点光源/方向光实时生效，不必重新生成。
4. “高级”页保留全部细节参数；“配置”页保存/载入完整配置。色板可单独导入导出、重置，星空提供原版 13 组配色方案。预览更新完成后即可导出。
5. “动态”页设置云、海水、气态条带或星云的变化幅度、循环时长和次数。下方时间轴支持播放、暂停、定位。
6. “导出静态资产”输出第 0 秒；“动态”页的“导出循环动画”输出 PNG 帧序列及播放配置。“复制动态实现说明”复制同一套算法、参数与接入约定。详细使用方式见 docs/ANIMATION_GUIDE.md。
7. 启动后默认播放噪声、自转并显示星空背景；三个开关可分别关闭。
8. 右上角“设置”切换简体中文 / English，语言选择会保存；面板内可访问原作者项目及 PixelSpace fork。
9. “配置”页的“我的预设”支持命名保存、选择应用、JSON 检视、复制、粘贴导入及删除。桌面保存到 `user://preset_library.json`，Web 保存到当前浏览器的站点存储。详见 [预设存储与 Web 准备](docs/PRESET_STORAGE.md)。
10. 体素模式同时应用于星球、云和星环，三者共用像素 / 体素密度。首次启动默认英文，已有语言存档时按上次选择恢复。
11. 星空“常用 → 图层与显示”关闭 **Pixel art / 像素风格**，使用 [PixelSpace fork](https://github.com/JupiterTheWarlock/PixelSpace) 的平滑模式思路：连续噪声采样、连续色板过渡、柔和的远景行星边缘。预览、静态导出、动画和实现说明共用这个开关。详见 [fork 复用说明](docs/SKY_FORK_REUSE.md)。

效果参数滑条的中点为默认效果，两端保留完整范围，数值不是等距分布。直接输入可精确调整；点击 ↺ 或双击滑条回到默认。种子及没有双向空间的边界参数保留输入框。与原项目的面板对照及取舍见 docs/UI_COMPARISON.md。

星球 70 项配置，星空 47 项，另有预览灯光控制。不同类型只使用适用的地形和动态参数。具体对应见 docs/PARAMETER_COVERAGE.md。

## 导出与接入

- 星球：标准 GLB、几何法线、UV、本色 PNG 或体素顶点颜色、独立云层/星环。普通受光材质，灯光没有烘焙进资产。
- 星空：六面 PNG、2:1 全景 PNG、可选 Godot Sky/Cubemap 资源。
- manifest.json：版本、参数、轴向、单位、色彩空间、过滤与动画约定。preset.json 可重新载入工具。
- adapters：Godot 可选分段光照 shader、three.js 示例、Unity glTFast 加载脚本、UE 导入辅助脚本。详见 docs/IMPORT_GUIDE.md。

生成器在工具内运行；导出资产在游戏中受实时光照、可旋转、更换材质。GLB 本身没有噪声动画轨道。动画包另带真实 PNG 帧序列和参考算法，实现说明供 Agent 移植可编辑噪声。不同引擎需要各自调整灯光、曝光和色调映射，不保证逐像素一致。

## itch 发布包

提供网页版和 Windows 下载版，免费使用，可自愿付费。新编写的源码采用 [MIT 许可](LICENSE)，原作、字体和素材继续保留各自的条款。

运行 `./tools/build_release.ps1` 可生成两个 ZIP；依赖准备、网页本机预览和截图生成见 [构建说明](docs/RELEASE_BUILD.md)，上架文案见 [itch 页面草稿](docs/ITCH_PAGE.md)。网页版资产与动画下载为 ZIP，配置和色板通过 JSON 文件导入导出。复制文本在浏览器弹窗中完成。

## 验证

在项目目录使用 Godot 4.4.1：
~~~powershell
Godot_v4.4.1-stable_win64_console.exe --path . --editor --headless --import --quit
Godot_v4.4.1-stable_win64_console.exe --path . -- --smoke
Godot_v4.4.1-stable_win64_console.exe --path . -- --motion-smoke
python tests/verify_exports.py
~~~

生成和动态检查需要真实图形渲染器，Python 导出检查需要 Pillow。验证两页面独立、配置往返、8 类星球、体素、天空、移动/关闭灯光、本色不变、GLB 回读与天空接缝。截图和报告在 exports/v2。

## 目录

- 根目录：项目入口、核心生成与保存代码、第三方许可。
- `ui/`：设置和预设库界面。
- `assets/`：色板、星点素材和语言资源。
- `docs/`：使用说明与技术参考；`NEXT_VERSION_DESIGN.md` 为历史设计。
- `tests/`：检查脚本；不属于产品操作界面。
- `adapters/`：现有接入示例，其中 Godot 光照 shader 用于工具预览。
- `exports/`、`.tools/`：本地输出和引擎，不提交到 Git。整理目录没有删除已有导出资产。

平台测试结果与已知问题见 docs/VALIDATION.md。源项目固定版本、素材许可要求见 THIRD_PARTY_NOTICES.md。

## Source parameter policy

See [docs/SOURCE_PARAMETERS.md](docs/SOURCE_PARAMETERS.md) for authored limits, per-type defaults, and explicit 3D adaptations. The original 2D algorithms and this 3D implementation are not pixel-identical. Generated exports and local engine binaries are not included in this repository.
