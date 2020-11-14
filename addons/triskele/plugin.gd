tool
extends EditorPlugin

const EditorPanel = preload("res://addons/triskele/TriskeleEditor.tscn")
var tex = preload("res://addons/triskele/icon.svg")

var editor
var importer

func _enter_tree():
	editor = EditorPanel.instance()
	get_editor_interface().get_editor_viewport().add_child(editor)
	make_visible(false)
	
	importer = preload("triskele_importer.gd").new()
	add_import_plugin(importer)


func _exit_tree():
	if editor:
		editor.queue_free()
	
	if importer:
		remove_import_plugin(importer)
		importer = null


func has_main_screen():
	return true


func make_visible(visible):
	if editor:
		editor.visible = visible


func get_plugin_name():
	return "Triskele"


func get_plugin_icon():
	return tex
