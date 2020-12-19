tool
extends EditorImportPlugin


enum Presets { DEFAULT }


func get_importer_name():
	return "void.triskele"


func get_visible_name():
	return "Triskele Dialog Tree"


func get_recognized_extensions():
	return ["tris"]


func get_save_extension():
	return "res"


func get_resource_type():
	return "Resource"


func get_preset_count():
	return Presets.size()


func get_preset_name(preset):
	match preset:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"


func get_import_options(preset):
	match preset:
		Presets.DEFAULT:
			return []
		_:
			return []


func get_option_visibility(option, options):
	return true


func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED
	
	var RESOURCE_FORMAT = load("res://addons/triskele/triskele_dialog_tree.gd")
	
	# Create dialog tree and load json
	var output = RESOURCE_FORMAT.new()
	var data = parse_json(file.get_as_text())
	
	# Remove un-needed keys
	for i in data["nodes"].keys():
		data["nodes"][i].erase("position")
		data["nodes"][i].erase("size")
		data["nodes"][i].erase("name")
	
	output.version = "%s.%s" % [data["version_major"], data["version_minor"]]
	output.translation_path = data["translation_file"]
	output.supported_languages = data["supported_languages"]
	output.nodes = data["nodes"]
	
	# Add nodes to output file, then save
	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], output)
