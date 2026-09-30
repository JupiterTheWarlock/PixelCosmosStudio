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

# One density unit is one cube across the diameter, including odd densities.
# Only emit the two ends of each occupied sphere column, never scan its volume.
static func voxel(images: Array[Image], density: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = 1.0/float(density)
	var directions: Array[Vector3] = [Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.BACK,Vector3.FORWARD]
	for face in 6:
		var axis: int = face/2
		for u in density:
			for v in density:
				var a: float = -1.0+(u+.5)*2.0*half
				var b: float = -1.0+(v+.5)*2.0*half
				var remainder: float = 1.0-a*a-b*b
				if remainder<0.0: continue
				var last: int = floori((sqrt(remainder)+1.0)/(2.0*half)-.5)
				if last < density/2: continue
				var cell: int = last if face%2==0 else density-1-last
				var center := Vector3.ZERO
				center[axis] = -1.0+(cell+.5)*2.0*half
				center[(axis+1)%3] = a
				center[(axis+2)%3] = b
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

static func voxel_face(st: SurfaceTool, center: Vector3, half: float, face: int, color: Color) -> void:
	var directions: Array[Vector3]=[Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.BACK,Vector3.FORWARD]
	for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
		st.set_color(color)
		st.set_normal(directions[face])
		st.add_vertex(center+cube_point(face,corner)*half)

static func finish_voxels(st: SurfaceTool, transparent: bool=false) -> MeshInstance3D:
	var mat:=StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.vertex_color_is_srgb=true
	mat.roughness=1.0
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if transparent: mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	st.set_material(mat)
	st.index()
	var instance:=MeshInstance3D.new()
	instance.mesh=st.commit()
	return instance

# One cube thick shell. All cubes remain available to the animated shader,
# including initially transparent cubes; otherwise clouds could never grow.
static func voxel_clouds(images: Array[Image], density: int, clearance_radius: float) -> MeshInstance3D:
	var half: float=1.0/density
	var step_size: float=2.0*half
	var outer: float=clearance_radius+step_size+sqrt(3.0)*half
	var low: int=ceili((1.0-outer)/step_size-.5)
	var high: int=floori((1.0+outer)/step_size-.5)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(low,high+1):
		for y in range(low,high+1):
			var cx: float=-1.0+(x+.5)*step_size
			var cy: float=-1.0+(y+.5)*step_size
			var xy: float=cx*cx+cy*cy
			if xy>outer*outer: continue
			var z_outer: float=sqrt(maxf(0,outer*outer-xy))
			var z_inner: float=sqrt(maxf(0,clearance_radius*clearance_radius-xy))
			# Skip the empty interior rather than scanning a filled volume.
			var ranges: Array=[Vector2(-z_outer,-z_inner),Vector2(z_inner,z_outer)]
			if z_inner==0.0: ranges=[Vector2(-z_outer,z_outer)]
			for interval in ranges:
				for z in range(ceili((1.0+interval.x)/step_size-.5),floori((1.0+interval.y)/step_size-.5)+1):
					var center:=Vector3(cx,cy,-1.0+(z+.5)*step_size)
					var closest: float=(center.abs()-Vector3.ONE*half).max(Vector3.ZERO).length()
					if closest<clearance_radius or closest>clearance_radius+step_size: continue
					var color:=sample_direction(images,center)
					for face in 6: voxel_face(st,center,half,face,color)
	return finish_voxels(st,true)

# A one-cell-thick annulus; tilt is applied to the finished rigid cube mesh.
static func voxel_ring(inner: float, width: float, density: int, bands: int, color: Color, seed_value: int) -> MeshInstance3D:
	var half: float=1.0/density
	var step_size: float=2.0*half
	var outer: float=inner+width
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	var shades: Array[float]=[]
	for band in bands: shades.append(rng.randf_range(.6,1.0))
	var cells: Dictionary={}
	var low: int=ceili((1.0-outer)/step_size-.5)
	var high: int=floori((1.0+outer)/step_size-.5)
	for x in range(low,high+1):
		for z in range(low,high+1):
			var r: float=Vector2(-1.0+(x+.5)*step_size,-1.0+(z+.5)*step_size).length()
			if r<inner or r>=outer: continue
			var shade: float=shades[clampi(int((r-inner)/width*bands),0,bands-1)]
			if shade<.64: continue
			cells[Vector3i(x,0,z)]=Color(color.r*shade,color.g*shade,color.b*shade,1)
	if cells.is_empty():
		var empty:=MeshInstance3D.new()
		empty.mesh=ArrayMesh.new()
		return empty
	var directions: Array[Vector3i]=[Vector3i.RIGHT,Vector3i.LEFT,Vector3i.UP,Vector3i.DOWN,Vector3i.BACK,Vector3i.FORWARD]
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell in cells:
		var center:=Vector3(-1.0+(cell.x+.5)*step_size,0,-1.0+(cell.z+.5)*step_size)
		for face in 6:
			if not cells.has(cell+directions[face]): voxel_face(st,center,half,face,cells[cell])
	return finish_voxels(st)

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
