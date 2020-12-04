tool
extends Panel

const NEW_GRAPH = preload("res://addons/triskele/Scenes/TriskeleEditor.tscn")

onready var MenuBarFile = $VBox1/MenuBar/File
onready var MenuBarEdit = $VBox1/MenuBar/Edit
onready var MenuBarHelp = $VBox1/MenuBar/Help

onready var Filter = $VBox1/HSplit1/StatusBar/HBox1/Filter

onready var EditorList = $VBox1/HSplit1/StatusBar/Sidebar/Scroll/EditorList

onready var GraphsList = $VBox1/HSplit1/Graphs

onready var ConfirmQuit = $Popups/ConfirmQuit
onready var ConfirmClose = $Popups/ConfirmClose
onready var ContextMenu = $Popups/ContextMenu
onready var LoadDialog = $Popups/Load

var current_graph = null

## GODOT FUNCTIONS
func _ready():
	# Open files provided via command-line
	# Necessary for Windows's open-with function to work
	if !Engine.editor_hint:
		for i in OS.get_cmdline_args():
			if i.ends_with(".tris"):
				_load_graph(i)
	
	# If none are provided, make a new empty graph.
	if GraphsList.get_child_count() == 0:
		EditorList.clear()
		_add_graph()
	
	_setup_signals()


func _process(_delta):
	if !current_graph:
		return
	
	if Input.is_action_just_pressed("undo"):
		current_graph.undo()
	
	if Input.is_action_just_pressed("redo"):
		current_graph.redo()
	
	if Input.is_action_just_pressed("save"):
		_save_graph(false, current_graph)
	
	if Input.is_action_just_pressed("save_as"):
		_save_graph(true, current_graph)


func _notification(what):
	if Engine.editor_hint:
		return
	
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# Check if any of the graphs are not saved.
		for i in GraphsList.get_children():
			# If one of them isn't saved, show the confirmation dialog and stop.
			if i.is_saved == false:
				ConfirmQuit.popup_centered()
				return
		
		# If all the graphs are saved, just close.
		_on_exit()


## TRISKELE FUNCTIONS
# Initialize PopupMenu signals
func _setup_signals():
	MenuBarFile.get_popup().connect("id_pressed", self, "_on_File_option_selected")
	MenuBarEdit.get_popup().connect("id_pressed", self, "_on_Edit_option_selected")
	MenuBarHelp.get_popup().connect("id_pressed", self, "_on_Help_option_selected")


# Add a new editor
func _add_graph():
	if current_graph:
		current_graph.hide()
	
	var new_graph = NEW_GRAPH.instance()
	
	#var new_name = tr("NEW_FILE_NAME") + tr("UNSAVED_FILE_INDICATOR")
	var new_name = "(new file)(*)"
	new_graph.name = new_name
	
	new_graph.connect("edited", self, "_on_Graph_edited", [new_graph])
	
	GraphsList.add_child(new_graph)
	EditorList.add_item(new_name)
	
	EditorList.select(EditorList.get_item_count() - 1)
	
	current_graph = new_graph


# Load a graph
func _load_graph(load_path: String):
	if current_graph:
		current_graph.hide()
	
	var new_graph = NEW_GRAPH.instance()
	
	new_graph.name = load_path.get_file()
	
	GraphsList.add_child(new_graph)
	EditorList.add_item(load_path.get_file())
	
	EditorList.select(EditorList.get_item_count() - 1)
	
	new_graph.load_file(load_path)
	
	current_graph = new_graph


# Save a graph
func _save_graph(save_as, graph):
	# Tell the graph to start saving
	graph.save_file(save_as)
	
	# Wait until finished
	yield(graph, "save_finished")
	
	# Update ItemList
	var index = GraphsList.get_children().find(graph)
	EditorList.set_item_text(index, graph.file_path.get_file())


## SIGNALS
# When the program should close
func _on_exit():
	get_tree().call_deferred("quit")


# When an option in the File menu is selected
func _on_File_option_selected(id):
	match id:
		0:
			_add_graph()
		1:
			if !current_graph:
				return
			
			_save_graph(false, current_graph)
		2:
			if !current_graph:
				return
			
			_save_graph(true, current_graph)
		3:
			LoadDialog.popup()


func _on_Edit_option_selected(id):
	if !current_graph:
		return
	
	match id:
		0:
			current_graph.undo()
		1:
			current_graph.redo()


func _on_Help_option_selected(_id):
	OS.alert("There is no help.")


# Switch graphs when an item in the EditorList is selected
func _on_EditorList_item_selected(index):
	if current_graph:
		current_graph.hide()
	current_graph = GraphsList.get_child(index)
	current_graph.show()


# Display context menu when EditorList is right-clicked
func _on_EditorList_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			ContextMenu.rect_position = event.global_position
			ContextMenu.show()


# Hide the context menu when the mouse exits it.
func _on_ContextMenu_mouse_exited():
	ContextMenu.hide()


func _on_ContextMenu_id_pressed(id):
	match id:
		# Save
		0:
			if !current_graph:
				return
			
			_save_graph(false, current_graph)
		
		# Save-As
		1:
			if !current_graph:
				return
			
			_save_graph(true, current_graph)
		
		# Close
		2:
			# Only one graph can be selected at a time.
			if EditorList.get_selected_items().empty():
				return
			var to_close = EditorList.get_selected_items()[0]
			
			if !GraphsList.get_child(to_close).is_saved:
				ConfirmClose.popup_centered()
			else:
				_on_ConfirmClose_confirmed()
		
		# Close-All
		3:
			print("Unimplemented!")
		
		# Close Other Tabs
		4:
			print("Unimplemented!")


# Load the file selected
func _on_Load_file_selected(path):
	_load_graph(path)


# Mark graph as not-saved
func _on_Graph_edited(graph):
	var index = GraphsList.get_children().find(graph)
	EditorList.set_item_text(index, graph.file_path.get_file() + "(*)")


func _on_ConfirmClose_confirmed():
	# The EditorList only lets you select one item, so it'll always either be
	# empty, or have just one entry
	if EditorList.get_selected_items().empty():
		return
	var to_close = EditorList.get_selected_items()[0]
	
	GraphsList.get_child(to_close).queue_free()
	EditorList.remove_item(to_close)
