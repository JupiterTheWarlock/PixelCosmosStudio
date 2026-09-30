# PixelSpace fork 连续性核对

2026-09-30 核对用户仓库 [JupiterTheWarlock/PixelSpace](https://github.com/JupiterTheWarlock/PixelSpace)。远端 main 与已有参考副本均为 `4d86a586cbdb913ebc21a7cfbd7f1cf8589d0865`，不是仅参考未修改的上游版本。

| 改动 | fork 中的用途 | 当前工具的处理 |
|---|---|---|
| `926c6b0`：seamless tiling / smooth render | `_wrapped_offsets`、`_place_wrapped_object` 在二维图片边缘复制跨界星体；限制粒子生成边界；支持平滑模式 | 当前亮星和远景星体由统一的三维方向计算，各个面自然看到同一个对象，不需要在六个面上分别复制 |
| `4d86a58`：clear edge mode / smooth planet alpha | 二维输出边缘留空、限制对象生成位置、柔化行星边缘 | 天空盒边界应连续而非留空；直接套遮罩反而会出现暗缝，因此不移植留空模式 |
| 原有 tiling 噪声 | 给二维噪声坐标取模以重复图案 | 当前噪声采样三维单位方向，球面环绕无需二维平铺；保留连续三维采样 |

参考文件为 `BackgroundGenerator/BackgroundGenerator.gd`、`Nebulae.shader`、`StarStuff.shader` 和 `Planet.tscn`。对应提交：[926c6b0](https://github.com/JupiterTheWarlock/PixelSpace/commit/926c6b0)、[4d86a58](https://github.com/JupiterTheWarlock/PixelSpace/commit/4d86a58)。原有星点素材与配色仍继续复用该参考仓库，版权说明见根目录 `THIRD_PARTY_NOTICES.md`。

新增 `tests/test_sky_continuity.gd` 对真实 GPU 生成结果检查 12 条共享立方体边、全景左右接缝和两极；覆盖像素/平滑模式、0 秒/6 秒动态阶段，并启用亮星及远景行星。测试通过。本次没有把二维取模、边缘复制或留白代码强行搬入三维生成器。
