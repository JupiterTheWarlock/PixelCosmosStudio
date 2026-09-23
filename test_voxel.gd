extends SceneTree
const Geometry=preload("res://geometry.gd")
const Schema=preload("res://parameters.gd")
const Motion=preload("res://noise_motion.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var image:=Image.create(8,8,false,Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8: image.set_pixel(x,y,Color(x/7.0,y/7.0,.3))
	var images: Array[Image]=[image,image,image,image,image,image]
	for density in [12,13]:
		var mesh:=Geometry.voxel(images,density)
		var arrays:=mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var colors: PackedColorArray=arrays[Mesh.ARRAY_COLOR]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var expected_faces:=0
		var half: float=1.0/density
		for z in density:
			for y in density:
				for x in density:
					var center: Vector3=(Vector3(x,y,z)+Vector3.ONE*.5)*2*half-Vector3.ONE
					if center.length_squared()>1: continue
					for n in [Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.BACK,Vector3.FORWARD]:
						if (center+n*2*half).length_squared()>1: expected_faces+=1
		assert(indices.size()==expected_faces*6,"Surface shell must match occupied cube boundary")
		var cell_colors: Dictionary={}
		for start in range(0,indices.size(),6):
			var center:=Vector3.ZERO
			for i in 6: center+=vertices[indices[start+i]]/6.0
			center-=normals[indices[start]]*half
			var cell:=Vector3i(((center+Vector3.ONE)/(2*half)-Vector3.ONE*.5).round())
			if not cell_colors.has(cell): cell_colors[cell]=colors[indices[start]]
			for i in 6: assert(colors[indices[start+i]].is_equal_approx(cell_colors[cell]),"Cube faces must share one sampled color")
		mesh.free()
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(512,512)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.4
	camera.position=Vector3(0,0,3)
	viewport.add_child(camera)
	var p:=Schema.type_defaults(5)
	p.voxel=true
	p.pixels=12
	p.dither=false
	p.noise_scale=15.0
	var voxel:=Geometry.voxel(images,12)
	var material:=Motion.planet_material(p,false)
	var unlit:=Shader.new()
	unlit.code=material.shader.code.replace("render_mode cull_disabled;","render_mode cull_disabled, unshaded;")
	material.shader=unlit
	Motion.configure(material,"planet",p)
	material.set_shader_parameter("voxel_surface",true)
	material.set_shader_parameter("voxel_density",12.0)
	voxel.material_override=material
	viewport.add_child(voxel)
	for time in [0.0,6.0]:
		material.set_shader_parameter("noise_time",time)
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered:=viewport.get_texture().get_image()
		for u in range(3,9):
			for v in range(3,9):
				var base:=Vector3(-1.0+u/6.0,-1.0+v/6.0,1.0)
				var samples: Array[Color]=[]
				for offset in [Vector3(.03,.03,0),Vector3(.08,.08,0),Vector3(.13,.13,0)]:
					var screen:=camera.unproject_position(base+offset)
					samples.append(rendered.get_pixel(int(screen.x),int(screen.y)))
				assert(samples[0].is_equal_approx(samples[1]) and samples[0].is_equal_approx(samples[2]),"Animated cube face contains multiple base colors")
	voxel.free()
	viewport.queue_free()
	await process_frame
	print("VOXEL_TEST_OK: odd/even density, exposed faces, uniform static and animated cell colors")
	quit()
