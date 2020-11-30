tool
extends EditorPlugin

const EditorPanel = preload("res://addons/triskele/Scenes/TriskeleMain.tscn")
const ICON = preload("res://addons/triskele/icon.svg")
const RESOURCE_SCRIPT = preload("res://addons/triskele/triskele_dialog_tree.gd")
const IMPORTER = preload("res://addons/triskele/triskele_importer.gd")

var editor
var importer

func _enter_tree():
	editor = EditorPanel.instance()
	get_editor_interface().get_editor_viewport().add_child(editor)
	make_visible(false)
	
	importer = IMPORTER.new()
	add_import_plugin(importer)
	
	add_custom_type("TriskeleDialogTree", "Resource", RESOURCE_SCRIPT, ICON)


func _exit_tree():
	if editor:
		editor.queue_free()
	
	if importer:
		remove_import_plugin(importer)
		importer = null
	
	remove_custom_type("TriskeleDialogTree")


func has_main_screen():
	return true


func make_visible(visible):
	if editor:
		editor.visible = visible


func get_plugin_name():
	return "Triskele"


func get_plugin_icon():
	return ICON
