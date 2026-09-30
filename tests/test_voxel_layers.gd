extends SceneTree
const Geometry=preload("res://geometry.gd")
const Schema=preload("res://parameters.gd")
const Motion=preload("res://noise_motion.gd")

func check_cubes(mesh: Mesh, cell_size: float, clearance: float=0.0) -> bool:
	assert(mesh.get_surface_count()>0)
	var data:=mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=data[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray=data[Mesh.ARRAY_COLOR]
	var indices: PackedInt32Array=data[Mesh.ARRAY_INDEX]
	for start in range(0,indices.size(),6):
		var center:=Vector3.ZERO
		for i in 6:
			var idx: int=indices[start+i]
			center+=vertices[idx]/6.0
			assert(absf(normals[idx].abs().dot(Vector3.ONE)-1.0)<.001,"Faces must have cube normals")
			assert(colors[idx].is_equal_approx(colors[indices[start]]),"Cube face must be a single color")
		center-=normals[indices[start]]*cell_size*.5
		if clearance>0:
			assert((center.abs()-Vector3.ONE*cell_size*.5).max(Vector3.ZERO).length()>=clearance-.00001,"Cloud cube intersects planet")
		assert(is_equal_approx(vertices[indices[start]].distance_to(vertices[indices[start+1]]),cell_size),"Cube sizes differ between layers")

	return true

func _initialize() -> void:
	var image:=Image.create(2,2,false,Image.FORMAT_RGBA8)
	image.fill(Color(.7,.8,1,0))
	var images: Array[Image]=[image,image,image,image,image,image]
	for density in [12,13,32]:
		var planet:=Geometry.voxel([opaque(),opaque(),opaque(),opaque(),opaque(),opaque()],density)
		var clearance: float=Geometry.outer_radius(planet.mesh)+.005
		var clouds:=Geometry.voxel_clouds(images,density,clearance)
		assert(check_cubes(clouds.mesh,2.0/density,clearance))
		assert(clouds.mesh.get_surface_count()==1,"Transparent initial clouds must retain geometry for animation")
		var mat: StandardMaterial3D=clouds.mesh.surface_get_material(0)
		assert(mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
		var rings:=Geometry.voxel_ring(1.3,.6,density,32,Color.WHITE,7421)
		assert(check_cubes(rings.mesh,2.0/density))
		assert(is_equal_approx(rings.mesh.get_aabb().size.y,2.0/density),"Ring must have one-cell thickness")
		planet.free()
		clouds.free()
		rings.free()
	var p:=Schema.defaults("planet")
	p.voxel=true
	assert(Motion.planet_material(p,true).get_shader_parameter("voxel_surface"),"Animated clouds must sample whole cubes")
	assert(preload("res://preset_store.gd").new().data.settings.locale=="en")
	print("VOXEL_LAYERS_OK: equal cube size, cloud clearance, initially hidden cloud cells, ring thickness, English default")
	quit()

func opaque() -> Image:
	var image:=Image.create(2,2,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return image
