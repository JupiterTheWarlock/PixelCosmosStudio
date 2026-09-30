# itch 页面文案与发布设置

Title: **Pixel Cosmos Studio**

在线体验与下载：[Pixel Cosmos Studio](https://jupiter-the-warlock.itch.io/pixel-cosmos-studio)。以下提供项目介绍与发布配置参考，线上页面的排版和文案可能有所调整。

Short description: **An open-source tool for pixel and voxel planets, plus space skyboxes. Free to try online.**

Classification: **Tools**. Kind: **HTML**. Languages: **English, Simplified Chinese**. Suggested tags: **Pixel Art, Voxel, Procedural Generation, Space, Godot, 3D**. Mark Windows only for the downloadable Windows executable; don't claim tested macOS, Linux or mobile support.

## Page description

**Pixel and voxel planets, plus space skyboxes.**

Open source and free to try online. The browser tool and Windows download have no minimum payment; donations are optional.

Pixel Cosmos Studio is a standalone planet and space generator inspired by Deep-Fold's PixelPlanets and PixelSpace. It brings their layered colors and pixel style into 3D, with separate planet and skybox workspaces.

- **Eight planet types:** terrestrial worlds, gas giants, ice and lava.
- **Pixels or cubes:** build round planets or true voxel planets, with voxel clouds and rings.
- **Animated noise:** drifting clouds, moving water, disturbed gas bands and evolving nebulae.
- **Space backgrounds:** generate six-face skyboxes and panoramas; switch Pixel art off for smooth noise and color transitions.
- **Real-time lighting:** preview with adjustable light; export base colors for your own rendering pipeline.
- **Save your setups:** named presets, editable palettes, JSON import/export and English / Simplified Chinese UI.

### What can I export?

Planet exports include a GLB model, PNG textures and the complete settings. Space exports include six PNG faces and a 2:1 panorama. Optional Godot Sky and Cubemap files are also included.

Animation exports contain PNG frame sequences and timing information. If you want editable noise in your game, copy the implementation context: it includes the actual shader algorithm and the same parameters used for the baked animation. The GLB does not contain a baked noise-animation track.

The browser version prepares one ZIP for download. The Windows version exports into a folder and is a better choice for large voxel models or long, high-resolution animations.

### Quick start

1. Choose **Planets** or **Space**.
2. Pick a planet type or palette, then adjust the settings. The preview updates automatically.
3. Drag the preview to look around. Scroll to zoom around a planet.
4. Open **Animation** to tune motion, or **Presets** to save a setup.
5. Choose **Export asset** or **Export animation**. In the browser, click **Download file** when the package is ready.

Browser presets and language are stored on the current device and site. They are not account-based cloud saves. Keep a JSON backup before clearing browser site data.

### Credits and usage

Original tools and visual foundations by **Deep-Fold**:

- [PixelPlanets](https://deep-fold.itch.io/pixel-planet-generator) · [source](https://github.com/Deep-Fold/PixelPlanets)
- [PixelSpace](https://deep-fold.itch.io/space-background-generator) · [source](https://github.com/Deep-Fold/PixelSpace)
- [PixelSpace fork](https://github.com/JupiterTheWarlock/PixelSpace) · [Pixel Cosmos Studio source](https://github.com/JupiterTheWarlock/PixelCosmosStudio)

This is an independent adaptation, not an official release by Deep-Fold. Third-party notices are included with the tool and generated asset packages. PixelSpace's upstream notice permits use in games and other projects, and asks that generated images not be distributed or sold on their own. Please retain the applicable notices when reusing source code or supplied materials.

Pixel Cosmos Studio's new source code is MIT-licensed. Third-party code and supplied materials retain the terms listed in the repository's notices.

Development used AI assistance for code and documentation. The planets, noise, and sky backgrounds are generated locally by procedural algorithms; generating an asset does not call a generative AI service.

## Publishing settings to review

发布包：`PixelCosmosStudio-web.zip` 用于“在浏览器中运行”，`PixelCosmosStudio-windows.zip` 用于 Windows 下载。

- Visibility: **Published**.
- Upload the Web ZIP and tick **This file will be played in the browser**.
- Embed size: **1062 × 600**, with click-to-play and the fullscreen button enabled.
- Single-threaded Godot Web build; no SharedArrayBuffer/extra cross-origin isolation requirement.
- Leave **Mobile friendly** unchecked until the touch layout has been tested.
- Upload the Windows ZIP as a downloadable Windows tool.
- AI disclosure: **Yes → Code, Text & Dialog** (code and documentation). Do not label procedural image output itself as an online AI image service.
- Pricing: **$0 minimum / optional donations** for both Web and Windows. New source code license: **MIT**; third-party materials retain their own terms.

Official references checked 2026-09-30: [HTML5 upload](https://itch.io/docs/creators/html5), [quality guidelines](https://itch.io/docs/creators/quality-guidelines), [AI disclosure fields](https://itch.io/t/4309690/generative-ai-disclosure-tagging), [Godot 4.4 Web export](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html).
