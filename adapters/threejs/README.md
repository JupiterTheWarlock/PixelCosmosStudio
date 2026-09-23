# three.js 接入

示例固定使用 three.js 0.180.0，vendor 包含官方模块和 MIT 许可。请通过 HTTP 访问，不能直接双击 HTML。

在 pixel-cosmos 目录运行 `python -m http.server 19387 --bind 127.0.0.1`，然后打开：
`http://127.0.0.1:19387/adapters/threejs/`

默认加载 exports/v2/planet 示例。页面也可选择自己的 GLB；只选 GLB 时没有 manifest，因此不自动播放动画。

```js
import {loadPlanet, loadSky, usePixelLighting} from './cosmos.js';
const asset = await loadPlanet('/assets/planet.glb', '/assets/manifest.json');
scene.add(asset.root);
// 使用游戏自己的环境光、点光源或方向光。
asset.update(deltaSeconds); // 可选自转/云层动画
scene.background = await loadSky('/assets/sky/');
// 可选像素分段材质，返回函数可恢复普通材质：
const restore = usePixelLighting(asset.root, 4);
```

纹理颜色采用 sRGB；保持 nearest 过滤可以保留像素纹理。示例关闭 tone mapping，游戏可按自己的管线调整。
Godot 与 three.js 的灯光强度单位和默认响应不同，不应复制相同灯光数值后期待逐像素一致。
分段材质使用 three.js 自带 Toon 光照；Godot 的点阵扩展不在 three.js Toon 示例中强制启用。
