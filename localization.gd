extends RefCounted

static func install() -> void:
	var translation:=Translation.new()
	translation.locale="en"
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/en.json"))
	for source in catalog: translation.add_message(source,catalog[source])
	# Parameter identifiers are stable and do not depend on displayed language.
	var labels: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/parameter_en.json"))
	for domain in ["planet","sky"]:
		for field in preload("res://parameters.gd").fields(domain):
			translation.add_message(field[1],labels.get(field[0],str(field[0]).replace("_"," ").capitalize()))
	TranslationServer.add_translation(translation)
