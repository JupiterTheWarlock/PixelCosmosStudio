extends Node

const Geometry = preload("res://geometry.gd")
const SHADER = preload("res://asset_generator.gdshader")
const FACES: Array[String] = ["px","nx","py","ny","pz","nz"]
var viewport: SubViewport
var rect: ColorRect
var material: ShaderMaterial

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	rect = ColorRect.new()
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("star_atlas",preload("res://assets/stars-special.png"))
	rect.material = material
	viewport.add_child(rect)

func configure(domain: String, p: Dictionary) -> void:
	for entry in SHADER.get_shader_uniform_list():
		var key: String = entry.name
		if p.has(key):
			var value: Variant = p[key]
			if value is String: value = Color(value)
			material.set_shader_parameter(key,value)
	material.set_shader_parameter("kind",0 if domain=="planet" else 1)
	material.set_shader_parameter("planet_type",p.get("type",2))
	material.set_shader_parameter("seed",float(p.seed)*.001+1.0)
	material.set_shader_parameter("resolution",float(p.face_size))
	material.set_shader_parameter("edge_test",false)
	material.set_shader_parameter("noise_time",0.0)

# Shared by the preview timeline, offline frame baking and implementation context.
func set_noise_time(seconds: float, p: Dictionary) -> void:
	material.set_shader_parameter("noise_time",fposmod(seconds,p.noise_duration))

func bake(face: int, dimensions: Vector2i, cloud_layer: bool = false) -> Image:
	viewport.size = dimensions
	rect.size = Vector2(dimensions)
	material.set_shader_parameter("face",face)
	material.set_shader_parameter("clouds_only",cloud_layer)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func generate(domain: String, parameters: Dictionary) -> Dictionary:
	if domain=="planet" and parameters.voxel and int(parameters.pixels)>preload("res://parameters.gd").MAX_VOXEL_DENSITY:
		return {"error":"体素密度超过 256，请降低“像素 / 体素密度”后生成。"}
	var p: Dictionary = parameters.duplicate(true)
	configure(domain,p)
	var images: Array[Image] = []
	var cloud_images: Array[Image] = []
	var size: int = p.face_size
	for face in 6:
		images.append(await bake(face,Vector2i(size,size)))
		if domain=="planet" and p.clouds_enabled:
			cloud_images.append(await bake(face,Vector2i(size,size),true))
	var result: Dictionary = {"domain":domain,"parameters":p,"images":images,"cloud_images":cloud_images}
	if domain=="sky":
		result.panorama = await bake(6,Vector2i(size*4,size*2))
		result.sky = make_sky(images,p.pixel_art)
	else:
		var root := Node3D.new()
		var surface_extent: float = p.radius
		root.name = "PixelCosmosPlanet"
		if p.surface_enabled:
			var surface: MeshInstance3D = Geometry.voxel(images,int(p.pixels)) if p.voxel else Geometry.sphere(images,1.0,not p.water_enabled)
			surface.name = "Surface"
			surface.scale = Vector3.ONE*p.radius
			root.add_child(surface)
			surface_extent = Geometry.outer_radius(surface.mesh)*p.radius
		if p.clouds_enabled:
			var clouds: MeshInstance3D = Geometry.sphere(cloud_images,(surface_extent+p.radius*p.cloud_height)/Geometry.sphere_inradius(),true)
			clouds.name = "CloudShell"
			clouds.rotation.y = deg_to_rad(p.phase)
			clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(clouds)
		if p.rings_enabled:
			var rings: MeshInstance3D = Geometry.ring(p.ring_radius*p.radius,p.ring_width*p.radius,p.ring_bands,Color(p.ring_color),p.seed)
			rings.name = "Rings"
			rings.rotation.x = deg_to_rad(p.ring_tilt)
			root.add_child(rings)
		for child in root.get_children():
			for index in child.mesh.get_surface_count():
				var mat: StandardMaterial3D = child.mesh.surface_get_material(index)
				mat.roughness = p.roughness
				mat.metallic = p.metallic
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST if p.pixel_art else BaseMaterial3D.TEXTURE_FILTER_LINEAR
		result.node = root
	return result

static func make_cubemap(images: Array[Image]) -> Cubemap:
	var cube := Cubemap.new()
	var order: Array[Image] = images.duplicate()
	# Godot 4.4.1 GLES3 uploads layers as -X,+X,-Y,+Y,-Z,+Z.
	# Keep portable PNG filenames standard; compensate only for this backend.
	var version: Dictionary = Engine.get_version_info()
	if version.major==4 and version.minor==4 and version.patch<=1 and RenderingServer.get_current_rendering_method()=="gl_compatibility":
		order = [images[1],images[0],images[3],images[2],images[5],images[4]]
	cube.create_from_images(order)
	return cube

static func make_sky(images: Array[Image], nearest: bool = true) -> Sky:
	# Explicit face selection avoids renderer-specific Cubemap upload ordering.
	var shader := Shader.new()
	shader.code = """shader_type sky;
uniform sampler2D px:source_color,filter_nearest,repeat_disable;
uniform sampler2D nx:source_color,filter_nearest,repeat_disable;
uniform sampler2D py:source_color,filter_nearest,repeat_disable;
uniform sampler2D ny:source_color,filter_nearest,repeat_disable;
uniform sampler2D pz:source_color,filter_nearest,repeat_disable;
uniform sampler2D nz:source_color,filter_nearest,repeat_disable;
void sky(){
 vec3 d=EYEDIR,a=abs(d);vec2 q;
 if(a.x>=a.y&&a.x>=a.z){
  q=vec2(d.x>0.0?-d.z:d.z,-d.y)/a.x*.5+.5;
  COLOR=d.x>0.0?texture(px,q).rgb:texture(nx,q).rgb;
 }else if(a.y>=a.z){
  q=vec2(d.x,d.y>0.0?d.z:-d.z)/a.y*.5+.5;
  COLOR=d.y>0.0?texture(py,q).rgb:texture(ny,q).rgb;
 }else{
  q=vec2(d.z>0.0?d.x:-d.x,-d.y)/a.z*.5+.5;
  COLOR=d.z>0.0?texture(pz,q).rgb:texture(nz,q).rgb;
 }
}"""
	if not nearest: shader.code = shader.code.replace("filter_nearest","filter_linear")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	for face in 6: mat.set_shader_parameter(FACES[face],ImageTexture.create_from_image(images[face]))
	var sky := Sky.new()
	sky.sky_material = mat
	return sky

static func write_json(path: String, data: Dictionary) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	return OK

static func export_assets(result: Dictionary, folder: String) -> Error:
	var error: Error = DirAccess.make_dir_recursive_absolute(folder)
	if error!=OK: return error
	var domain: String = result.domain
	var p: Dictionary = result.parameters
	for face in 6:
		var name: String = ("base_color_" if domain=="planet" else "sky_")+FACES[face]+".png"
		error = result.images[face].save_png(folder.path_join(name))
		if error!=OK: return error
		if domain=="planet" and not result.cloud_images.is_empty():
			error = result.cloud_images[face].save_png(folder.path_join("clouds_"+FACES[face]+".png"))
			if error!=OK: return error
	if domain=="planet":
		var source: Node3D = result.node
		if source.get_child_count()==0: return ERR_INVALID_DATA
		var copy: Node3D = source.duplicate()
		copy.transform = Transform3D.IDENTITY
		# Export portable standard materials, never preview ShaderMaterial overrides/lights.
		for child in copy.get_children():
			for index in child.mesh.get_surface_count(): child.set_surface_override_material(index,null)
			if child.name=="CloudShell": child.rotation.y = deg_to_rad(p.phase)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		error = document.append_from_scene(copy,state)
		if error==OK: error = document.write_to_filesystem(state,folder.path_join("planet.glb"))
		copy.free()
		if error!=OK: return error
	else:
		error = result.panorama.save_png(folder.path_join("sky_panorama.png"))
		if error!=OK: return error
		var images: Array[Image] = result.images
		var cube: Cubemap = make_cubemap(images)
		error = ResourceSaver.save(cube,folder.path_join("sky_cubemap.res"),ResourceSaver.FLAG_COMPRESS)
		if error!=OK: return error
		error = ResourceSaver.save(make_sky(images,p.pixel_art),folder.path_join("sky.res"),ResourceSaver.FLAG_COMPRESS)
		if error!=OK: return error
	var manifest: Dictionary = {
		"format":"pixel-cosmos","version":2,"domain":domain,"parameters":p,
		"coordinate_system":{"handedness":"right","up":"+Y","forward":"-Z","unit":"meter"},
		"textures":{"color_space":"sRGB","alpha":"straight","filter":"nearest" if p.pixel_art else "linear","face_order":FACES},
		"lighting":{"baked":false,"material":"glTF metallic-roughness" if domain=="planet" else "unlit background"},
		"animation":{"Surface":"rotation_speed degrees/second about local +Y","CloudShell":"cloud_speed degrees/second relative to planet"} if domain=="planet" else {},
		"runtime_generation":false}
	manifest.noise = {"contract":preload("res://noise_motion.gd").contract(domain,p),"baked_time_seconds":0,"animation_embedded":false}
	error = write_json(folder.path_join("manifest.json"),manifest)
	if error!=OK: return error
	error = write_json(folder.path_join("preset.json"),{"format":"pixel-cosmos-preset","version":2,"domain":domain,"parameters":p})
	if error!=OK: return error
	for name in ["IMPORT_GUIDE.md","THIRD_PARTY_NOTICES.md"]:
		error = DirAccess.copy_absolute(ProjectSettings.globalize_path("res://"+name),folder.path_join(name))
		if error!=OK: return error
	return OK

func export_animation(domain: String, p: Dictionary, folder: String, progress: Callable = Callable(), cancelled: Callable = Callable()) -> Error:
	var snapshot: Dictionary = p.duplicate(true)
	var result: Dictionary = await generate(domain,snapshot)
	var error: Error = export_assets(result,folder)
	if domain=="planet": result.node.free()
	if error!=OK: return error
	var recipe: Dictionary = preload("res://noise_motion.gd").contract(domain,snapshot)
	recipe.complete=false
	recipe.completed_frames=0
	recipe.frame_folder="frames/%04d"
	recipe.channels=["base_color"] if domain=="planet" else ["sky"]
	if domain=="planet" and snapshot.clouds_enabled: recipe.channels.append("clouds")
	recipe.face_order=FACES
	recipe.loop_seam="last frame wraps to frame zero; do not append a duplicate endpoint"
	error=write_json(folder.path_join("animation.json"),recipe)
	if error!=OK: return error
	for filename in ["noise_core.gdshaderinc","assets/stars-special.png"]:
		error=DirAccess.copy_absolute(ProjectSettings.globalize_path("res://"+filename),folder.path_join(filename.get_file()))
		if error!=OK: return error
	var context_file := FileAccess.open(folder.path_join("IMPLEMENTATION_CONTEXT.md"),FileAccess.WRITE)
	if context_file==null: return FileAccess.get_open_error()
	context_file.store_string(preload("res://noise_motion.gd").context(domain,snapshot))
	context_file.close()
	error=DirAccess.copy_absolute(ProjectSettings.globalize_path("res://ANIMATION_GUIDE.md"),folder.path_join("ANIMATION_GUIDE.md"))
	if error!=OK: return error
	configure(domain,snapshot)
	for frame in snapshot.noise_frames:
		if cancelled.is_valid() and cancelled.call(): return ERR_SKIP
		var frame_folder: String = folder.path_join("frames/%04d"%frame)
		error=DirAccess.make_dir_recursive_absolute(frame_folder)
		if error!=OK: return error
		set_noise_time(float(frame)*snapshot.noise_duration/snapshot.noise_frames,snapshot)
		for face in 6:
			var im: Image = await bake(face,Vector2i(snapshot.face_size,snapshot.face_size))
			error=im.save_png(frame_folder.path_join(("sky_" if domain=="sky" else "base_color_")+FACES[face]+".png"))
			if error!=OK: return error
			if domain=="planet" and snapshot.clouds_enabled:
				im=await bake(face,Vector2i(snapshot.face_size,snapshot.face_size),true)
				error=im.save_png(frame_folder.path_join("clouds_"+FACES[face]+".png"))
				if error!=OK: return error
		recipe.completed_frames=frame+1
		if progress.is_valid(): progress.call(frame+1,snapshot.noise_frames)
		# A partial export remains explicitly incomplete even if interrupted.
		error=write_json(folder.path_join("animation.json"),recipe)
		if error!=OK: return error
	recipe.complete=true
	return write_json(folder.path_join("animation.json"),recipe)
