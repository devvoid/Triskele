tool
extends EditorImportPlugin


enum Presets { DEFAULT }


func get_importer_name():
	return "void.triskele"


func get_visible_name():
	return "Triskele Dialog Tree"


func get_recognized_extensions():
	return ["json"]


func get_save_extension():
	return "tris"


func get_resource_type():
	return "TriskeleDialogTree"


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
			return [
			]
		_:
			return []


func get_option_visibility(option, options):
	return true


func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	pass
