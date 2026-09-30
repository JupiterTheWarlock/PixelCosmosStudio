# itch 发布包

当前发布目标是桌面浏览器 WebGL 2 和 Windows x86-64。Godot 版本固定为 4.4.1，Compatibility 渲染，Web 使用单线程模板。

## 构建

1. 将 Godot 4.4.1 Windows 编辑器放入 `.tools/godot/`，或向构建脚本传入 `-GodotPath`。
2. 安装 Python 的 `requests`，运行 `python tools/fetch_templates.py`。脚本从 Godot 官方镜像只取所需的四个导出模板，解压时核对 ZIP CRC，保存到 `.tools/templates/4.4.1.stable/`。也可以手动将同版本模板放到该目录。
3. 从 [electron/rcedit v2.0.0](https://github.com/electron/rcedit/releases/tag/v2.0.0) 下载 `rcedit-x64.exe`，存为 `.tools/rcedit/rcedit.exe`。它用于写入 Windows 程序名称和版本，不随产品分发。
4. 在 PowerShell 运行 `./tools/build_release.ps1`。输出为 `dist/PixelCosmosStudio-web.zip` 和 `dist/PixelCosmosStudio-windows.zip`，包含字体、Godot 及原作许可。Web ZIP 根目录有 `index.html`；Windows ZIP 包含 EXE 和同名 PCK，两者必须一起解压。
5. 使用有图形界面的 Godot 运行 `--path . --script tools/capture_presskit.gd`，生成 `dist/presskit/` 的封面与四张实际界面截图。

构建日志保存在 `dist/`，产物与模板不提交到源码仓库。Windows 包未签名。项目自身的源码授权以仓库实际 `LICENSE` 为准；构建脚本仅在该文件存在时带入发布包，不自行决定授权。

## 本机网页预览

```powershell
python -m http.server 8844 --bind 127.0.0.1 --directory dist/web
```

打开 `http://127.0.0.1:8844`。不能直接双击 HTML：WebAssembly 与资源需要 HTTP 服务。初次打开默认英文，语言和命名预设保存在这个站点的 localStorage。

Web 导出先在工具内部生成，再显示“文件已准备好”，需要点击“下载文件”。静态资产与动画各下载一个 ZIP；配置与色板下载 JSON，导入使用浏览器文件选择器。实现说明与预设 JSON 使用可选择的文本弹窗，剪贴板受限时仍可手动复制。

## 上架

文案与平台设置见 [ITCH_PAGE.md](ITCH_PAGE.md)。先建立草稿，在 itch 实际嵌入页面里再次核对加载、存档和下载，然后公开。当前本地浏览器验证不等于 itch iframe 验证；手机触控、Safari 与 Firefox 未宣称通过。

官方约束：[itch HTML5 文档](https://itch.io/docs/creators/html5)、[Godot 4.4 Web 导出](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html)。
