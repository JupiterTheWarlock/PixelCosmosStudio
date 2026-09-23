extends RefCounted

static func cube_point(face: int, uv: Vector2) -> Vector3:
	var q: Vector2 = uv * 2.0 - Vector2.ONE
	match face:
		0: return Vector3(1, -q.y, -q.x)
		1: return Vector3(-1, -q.y, q.x)
		2: return Vector3(q.x, 1, q.y)
		3: return Vector3(q.x, -1, -q.y)
		4: return Vector3(q.x, -q.y, 1)
		_: return Vector3(-q.x, -q.y, -1)

static func material(image: Image, transparent: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 1.0
	mat.metallic_specular = 0.5
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = ImageTexture.create_from_image(image)
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	return mat

static func sphere(images: Array[Image], radius: float = 1.0, transparent: bool = false) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var steps: int = 32
	for face in 6:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for y in steps:
			for x in steps:
				for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)]:
					var uv: Vector2 = (Vector2(x,y)+corner)/float(steps)
					var normal: Vector3 = cube_point(face,uv).normalized()
					st.set_normal(normal)
					st.set_uv(uv)
					st.add_vertex(normal*radius)
		st.set_material(material(images[face], transparent))
		st.index()
		st.commit(mesh)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance

static func sample_direction(images: Array[Image], point: Vector3) -> Color:
	var a: Vector3 = point.abs()
	var face: int
	var q: Vector2
	if a.x >= a.y and a.x >= a.z:
		face = 0 if point.x > 0 else 1
		q = Vector2(-point.z if point.x > 0 else point.z,-point.y)/a.x
	elif a.y >= a.z:
		face = 2 if point.y > 0 else 3
		q = Vector2(point.x,point.z if point.y > 0 else -point.z)/a.y
	else:
		face = 4 if point.z > 0 else 5
		q = Vector2(point.x if point.z > 0 else -point.x,-point.y)/a.z
	var image: Image = images[face]
	var uv: Vector2 = (q+Vector2.ONE)*.5
	return image.get_pixel(clampi(int(uv.x*image.get_width()),0,image.get_width()-1),clampi(int(uv.y*image.get_height()),0,image.get_height()-1))

static func voxel(images: Array[Image], grid: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = 1.0/float(grid)
	var directions: Array[Vector3] = [Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.BACK,Vector3.FORWARD]
	for z in range(-grid,grid):
		for y in range(-grid,grid):
			for x in range(-grid,grid):
				var center: Vector3 = (Vector3(x,y,z)+Vector3.ONE*.5)*2.0*half
				if center.length_squared()>1.0: continue
				for face in 6:
					if (center+directions[face]*2.0*half).length_squared()<=1.0: continue
					var color: Color = sample_direction(images,center)
					if color.a<.5: continue
					for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
						st.set_color(color)
						st.set_normal(directions[face])
						st.add_vertex(center+cube_point(face,corner)*half)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 1.0
	mat.metallic_specular = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	st.set_material(mat)
	st.index()
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	return instance

static func ring(inner: float, width: float, bands: int, color: Color, seed_value: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for band in bands:
		var shade: float = rng.randf_range(.6,1.0)
		if shade<.64: continue
		var r0: float = inner+width*float(band)/bands
		var r1: float = inner+width*float(band+1)/bands
		for segment in 128:
			var a: float = TAU*segment/128.0
			var b: float = TAU*(segment+1)/128.0
			for v in [Vector2(a,r0),Vector2(b,r0),Vector2(a,r1),Vector2(b,r0),Vector2(b,r1),Vector2(a,r1)]:
				st.set_normal(Vector3.UP)
				st.set_color(Color(color.r*shade,color.g*shade,color.b*shade,1))
				st.add_vertex(Vector3(cos(v.x)*v.y,0,sin(v.x)*v.y))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mat.metallic_specular = 0.5
	st.set_material(mat)
	st.index()
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	return instance

# Use actual voxel corners, not the nominal unit sphere, when placing shells.
static func outer_radius(mesh: Mesh) -> float:
	var radius := 0.0
	for surface in mesh.get_surface_count():
		for vertex in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			radius = maxf(radius,vertex.length())
	return radius

static func sphere_inradius() -> float:
	# Conservative bound for normalized cube faces subdivided into 32 steps.
	# A face diagonal is at most sqrt(8)/32 radians before normalization.
	return cos(sqrt(8.0)/32.0)
