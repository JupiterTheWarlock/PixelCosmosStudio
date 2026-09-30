# 预设库与 Web 准备

“配置 → 我的预设”保存完整参数快照。星球和星空分别列出；同名保存会新增一条，不会覆盖旧预设。选择条目可查看完整 JSON、应用、复制或删除。删除前有确认。粘贴导入先校验配置版本、页面和参数，失败不会改动当前配置；成功后可填写名称存入库。

## 两种存储

- 桌面：`user://preset_library.json`，Windows 通常位于 `%APPDATA%/Godot/app_userdata/Pixel Cosmos Studio/`。先写临时文件再替换，保留上一份 `.bak`；如果保存中断导致主文件缺失，会读取备份。格式错误的原文件不会被覆盖。
- Web：通过 JavaScriptBridge 写入 `localStorage`，键为 `pixel-cosmos-studio.library.v1`。同一浏览器、同一站点下重新打开可以读取；不是账号云同步，也不跨设备。写入异常和配额不足会显示失败，内存里的已保存列表不会假装更新成功。

库文件包含版本、语言设置、命名预设、保存时间及原有 version 2 参数格式。只保存少量配置数据，不存 PNG、GLB 或动画帧。预设数据保留原参数键名，不随界面语言改变。

没有语言存档时默认 English。设置中选择简体中文会立即切换并写入库文件的 `settings.locale = "zh_CN"`；选择 English 则保存 `en`。再次启动优先读取已保存的选择。中文与英文均注册独立翻译表，避免中文缺失时回退到英文。`tests/test_locale_persistence.gd` 分两次独立进程验证切换和重启后的读取。

浏览器清除站点数据、无痕模式、存储权限或 itch 嵌入页面限制都可能使数据丢失或无法保存。因此界面保留 JSON 检视、复制和粘贴导入，建议自行备份。读取被阻止时，允许站点存储后点击“重新读取预设库”重试。

## 当前验证范围

已验证桌面写入、重复写入、重新打开读取、快照独立性、语言保存、删除、损坏文件保护；已运行与 JavaScriptBridge 完全相同的 JavaScript 存储代码，模拟重新加载、特殊字符、存储禁止及配额错误。设置弹窗、中英文切换和预设应用也已在 Godot 中检查。

2026-09-30 已在实际 Chromium WebGL 页面验证：初次默认英文，切换中文后即时显示；命名预设与语言刷新后保留；JSON 文件选择器导入有效配置、拒绝越界数值；预设 JSON 可在浏览器文本弹窗中检视与复制。静态星球资产和 96 帧动画均实际下载为 ZIP，并检查解压内容与完整性。

Web 版使用浏览器文件选择器和下载确认弹窗；桌面版继续选择本机目录。动画包生成后点击“下载文件”才开始下载，取消导出会清理本次浏览器临时文件。小型预设库使用 localStorage，导出的 PNG/GLB/ZIP 不会保存在预设库中。

工具已发布到 itch。这里记录的同源浏览器验证不覆盖 itch 嵌入页面的存储与下载权限；实际 iframe 中的加载、刷新后存档和文件下载仍需单独确认。

相关官方文档：[Godot 数据路径](https://docs.godotengine.org/en/4.4/tutorials/io/data_paths.html)、[Web 导出](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html)、[JavaScriptBridge](https://docs.godotengine.org/en/4.4/classes/class_javascriptbridge.html)。Godot 自身的 Web `user://` 使用 IndexedDB；本工具的小型预设库选择显式 localStorage 读写，方便即时检查存储错误，二者不是同一存储位置。
