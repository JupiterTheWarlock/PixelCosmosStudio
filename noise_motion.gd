extends RefCounted

const VERSION = "cosmos-periodic-warp-v1"
const PLANET = preload("res://noise_planet.gdshader")
const SKY = preload("res://noise_sky.gdshader")
static var toon_shader: Shader

static func fields(domain: String) -> Array:
	var result: Array = [
		["noise_enabled","启用动态噪声",true,0,0,0,"动态噪声"],
		["noise_duration","循环时长（秒）",24.0,2,120,.5,"动态噪声"],
		["noise_frames","导出帧数",96,8,480,1,"动态噪声"]]
	var layers: Array = [["cloud","云层",.35,1],["water","海水",.5,2],["gas","气态条带",.35,1]] if domain=="planet" else [["nebula","星云",.22,1]]
	for layer in layers:
		result.append([layer[0]+"_motion",layer[1]+"动态",true,0,0,0,"动态噪声"])
		result.append([layer[0]+"_strength",layer[1]+"变化幅度",layer[2],0,2,.01,"动态噪声"])
		result.append([layer[0]+"_cycles",layer[1]+"每轮变化次数",layer[3],1,8,1,"动态噪声"])
	return result

static func configure(mat: ShaderMaterial, domain: String, p: Dictionary, seconds: float = 0.0) -> void:
	for entry in mat.shader.get_shader_uniform_list():
		var key: String = entry.name
		if p.has(key):
			var value: Variant = p[key]
			if value is String: value=Color(value)
			mat.set_shader_parameter(key,value)
	mat.set_shader_parameter("seed",float(p.seed)*.001+1.0)
	mat.set_shader_parameter("kind",0 if domain=="planet" else 1)
	mat.set_shader_parameter("planet_type",p.get("type",2))
	mat.set_shader_parameter("noise_time",fposmod(seconds,p.noise_duration))
	mat.set_shader_parameter("linear_output",RenderingServer.get_current_rendering_method()!="gl_compatibility")
	mat.set_shader_parameter("star_atlas",preload("res://assets/stars-special.png"))

static func planet_material(p: Dictionary, clouds: bool, toon: bool = false, levels: float = 4.0, dither_amount: float = .08) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader=PLANET
	if toon:
		if toon_shader==null:
			toon_shader=Shader.new()
			var lighting: String=FileAccess.get_file_as_string("res://adapters/godot/pixel_lit.gdshader")
			toon_shader.code=PLANET.code.replace("render_mode cull_disabled;","render_mode cull_disabled, specular_disabled;")+"\nuniform float levels=4.0;\nuniform float dither_strength=.08;\n"+lighting.substr(lighting.find("void light()"))
		mat.shader=toon_shader
		mat.set_shader_parameter("levels",levels)
		mat.set_shader_parameter("dither_strength",dither_amount)
	configure(mat,"planet",p)
	mat.set_shader_parameter("clouds_only",clouds)
	mat.set_shader_parameter("voxel_surface",p.voxel and not clouds)
	mat.set_shader_parameter("voxel_density",float(p.pixels))
	mat.set_shader_parameter("material_roughness",p.roughness)
	mat.set_shader_parameter("material_metallic",p.metallic)
	return mat

static func sky_material(p: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader=SKY
	configure(mat,"sky",p)
	return mat

static func contract(domain: String, p: Dictionary) -> Dictionary:
	return {"algorithm":VERSION,"domain":domain,"parameters":p.duplicate(true),"uniform_bindings":{"seed":"float(parameters.seed) * 0.001 + 1.0","kind":0 if domain=="planet" else 1,"planet_type":p.get("type",2),"colors":"sRGB hex to 0..1 RGB; no automatic input linearization","clouds_only":"true for CloudShell, false for surface/sky","noise_time":"time_seconds modulo noise_duration"},"duration_seconds":p.noise_duration,"frames":p.noise_frames,"fps":float(p.noise_frames)/p.noise_duration,"sample_time":"frame_index * duration_seconds / frames; endpoint excluded","noise_time_unit":"seconds","space":"normalized object-local direction; sky world direction","voxel_sampling":"For voxel surfaces, sample once at cube center: cell_size=2/pixels; center=(floor((local_position-local_face_normal*cell_size*0.001+1)/cell_size)+0.5)*cell_size-1. All faces of a cube share this direction and color; lighting remains per-face. Cloud shell uses continuous direction.","lighting_baked":false,"source":"noise_core.gdshaderinc","source_sha256":FileAccess.get_sha256("res://noise_core.gdshaderinc")}

static func context(domain: String, p: Dictionary) -> String:
	return "请在当前游戏项目中复现以下 Pixel Cosmos 动态效果，按项目已有引擎与渲染管线接入，不安装插件。\n"+\
		"使用显式秒数驱动 noise_time。完整循环时长内各层次数为整数。保持海岸、陆地和星点固定，动态仅作用于对应图层。颜色输出为 sRGB 本色，交给场景实时光照；云层保留透明裁切。天空不受光。\n"+\
		"不要用目标引擎默认噪声替换以下算法；种子与参数相同不代表不同算法结果相同。将以下 GLSL 风格参考实现按目标语言移植，保留方向、色板、hash 和采样规则。星形图案使用随资产导出的 stars-special.png。不同 GPU 浮点精度可有微小差异。\n"+\
		"云壳旋转与整个星球自转是独立效果，本循环约定仅保证动态噪声首尾衔接。\n配置：\n"+JSON.stringify(contract(domain,p),"\t")+\
		"\n算法：\n```glsl\n"+FileAccess.get_file_as_string("res://noise_core.gdshaderinc")+"\n```\n验证：对照导出的 0、1/4、1/2、3/4 周期画面，检查顶部接缝、循环边界、海岸和星点不移动。"
