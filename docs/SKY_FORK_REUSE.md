# PixelSpace fork 的去像素化模式

参考 [JupiterTheWarlock/PixelSpace](https://github.com/JupiterTheWarlock/PixelSpace)，固定版本 `4d86a586cbdb913ebc21a7cfbd7f1cf8589d0865`。此处移植的是 `pixel_art` 开关关闭后的平滑渲染；二维平铺与天空接缝处理是另外两项功能。

## 操作与复用范围

在星空页 **General / 常用 → Layers & display / 图层与显示** 中关闭 **Pixel art / 像素风格**。同一个参数存入预设，并用于静态资产、动画帧与复制的实现说明。默认仍开启像素风格；首次启动默认英文，已有语言选择按存档恢复。

| fork 的去像素化行为 | 三维生成器中的对应处理 |
|---|---|
| `Nebulae.shader`、`StarStuff.shader` 跳过 UV 取整 | `noise_core.gdshaderinc` 跳过采样方向的像素格量化，连续计算噪声 |
| 关闭像素点阵过渡 | `pixel_art=false` 时不加入点阵，像素密度和点阵参数不影响平滑星空 |
| 色板索引不再取整 | 在相邻色板颜色间连续插值，保留原配色 |
| `Planet.tscn` 用 `smoothstep(0.505, 0.485, d_to_center)` 柔化轮廓 | 平滑模式中按远景行星半径的 `0.97..1.01` 区间渐变透明度，并正确叠加后方图层 |
| 开关传给星云、星尘与远景行星 | 共用生成内核；天空资源与预览放大同步使用线性过滤，UI 自身仍保持像素风格 |

连续噪声采样和色板插值原来已有；2026-09-30 补齐了预览过滤与远景行星柔和边缘。PNG 直接写入 straight alpha，避免半透明轮廓被重复乘透明度而发黑；实时天空预览将透明图层合成到所选背景色上。

这不是给成品贴图加模糊。fork 的星云、星尘透明遮罩在平滑模式下仍使用 `step`；亮星仍使用原有像素素材。本工具保留这些特征，没有把整幅星空和星点一起模糊。独立星球页的地貌色阶、体素几何不属于这次 PixelSpace 模式移植；体素每格单色的约定保持不变。

二维 UV 噪声已适配为三维方向噪声，因此生成图案不是原二维工具的逐像素复制。

## 平铺功能与本开关不同

fork 的 [926c6b0](https://github.com/JupiterTheWarlock/PixelSpace/commit/926c6b0) 同时引入 seamless tiling 和 smooth render，[4d86a58](https://github.com/JupiterTheWarlock/PixelSpace/commit/4d86a58) 增加边缘留空和行星柔和轮廓。

二维边缘复制、坐标取模、边缘留空不适用于六面天空直接拼接。本工具以同一个三维方向生成各面；复制对象或留空会改变对象分布或制造暗缝，因此不移植这部分。它与去像素化模式是两个不同问题。

## 验证

- `tests/test_sky_smooth.gd`：真实 GPU 输出检查星云与星尘的中间色、平滑模式不受像素密度和点阵影响、像素模式仍受密度影响、平滑噪声循环、行星半透明边缘与 straight alpha 合成。
- `tests/test_ui.gd`：操作 Pixel art 开关后生成参数、预览过滤同步变化，再打开后恢复像素过滤；UI 自身过滤不改变。
- `tests/test_sky_continuity.gd`：像素和平滑模式下，12 条立方体共享边、全景左右接缝与两极连续；覆盖动态时刻、亮星及远景行星。

本地测试输出位于 `exports/smooth`，UI 截图为 `exports/v2/sky_smooth_tab.png`。素材与许可证见根目录 `THIRD_PARTY_NOTICES.md`。
