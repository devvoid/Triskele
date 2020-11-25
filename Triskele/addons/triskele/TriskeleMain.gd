tool
extends Panel

const NEW_GRAPH = preload("res://addons/triskele/TriskeleEditor.tscn")

onready var MenuBarFile = $VBox1/MenuBar/File
onready var MenuBarEdit = $VBox1/MenuBar/Edit

onready var Filter = $VBox1/HSplit1/StatusBar/HBox1/Filter

onready var EditorList = $VBox1/HSplit1/StatusBar/Sidebar/Scroll/EditorList

onready var GraphsList = $VBox1/HSplit1/Graphs

onready var Popups = $Popups

onready var current_graph = null

## GODOT FUNCTIONS
func _ready():
	if GraphsList.get_child_count() == 0:
		EditorList.clear()
		_add_graph()
	
	_setup_signals()


func _notification(what):
	if Engine.editor_hint:
		return
	
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# Check if any of the graphs are not saved.
		for i in GraphsList.get_children():
			# If one of them isn't saved, show the confirmation dialog and stop.
			if i.is_saved == false:
				$Popups.get_node("ConfirmationDialog").popup_centered()
				return
		
		# If all the graphs are saved, just close.
		_on_exit()


## TRISKELE FUNCTIONS
func _setup_signals():
	$Popups/ConfirmationDialog.connect("confirmed", self, "_on_exit")
	
	MenuBarFile.get_popup().connect("id_pressed", self, "_on_File_option_selected")


func _add_graph():
	if current_graph:
		current_graph.hide()
	
	var new_graph = NEW_GRAPH.instance()
	
	#var new_name = tr("NEW_FILE_NAME") + tr("UNSAVED_FILE_INDICATOR")
	var new_name = "(new file)(*)"
	new_graph.name = new_name
	
	GraphsList.add_child(new_graph)
	EditorList.add_item(new_name)
	
	current_graph = new_graph


## SIGNALS
# When the program should close
func _on_exit():
	get_tree().quit()


# When an option in the File menu is selected
func _on_File_option_selected(_id):
	_add_graph()
	


func _on_EditorList_item_selected(index):
	if current_graph:
		current_graph.hide()
	current_graph = GraphsList.get_child(index)
	current_graph.show()
