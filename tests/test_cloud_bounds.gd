extends SceneTree
const Geometry = preload("res://geometry.gd")
func _initialize() -> void:
	var image := Image.create(2,2,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var images: Array[Image] = [image,image,image,image,image,image]
	for diameter in [12,13,32,64,100]:
		var surface := Geometry.voxel(images,diameter)
		var extent := Geometry.outer_radius(surface.mesh)
		var radius := (extent+.005)/Geometry.sphere_inradius()
		var cloud := Geometry.sphere(images,radius,true)
		for i in cloud.mesh.get_surface_count():
			var arrays := cloud.mesh.surface_get_arrays(i)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for j in range(0,indices.size(),3):
				var a := vertices[indices[j]]
				var b := vertices[indices[j+1]]
				var c := vertices[indices[j+2]]
				var normal := (b-a).cross(c-a).normalized()
				assert(absf(normal.dot(a))>extent,"Cloud intersects voxel envelope")
		print("Cloud clearance verified at voxel diameter ",diameter)
		surface.free()
		cloud.free()
	print("CLOUD_BOUNDS_OK")
	quit()
