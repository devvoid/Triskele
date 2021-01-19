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
onready var LoadDialog = $Popups/Load

# A reference to the current graph
var current_graph = null

# A reference to the editor interface; used to get the keybinds
var editor_settings = null

# Whether or not the MenuBarFile popup was opened by right-clicking graph list.
var context_menu_opened = false

## GODOT FUNCTIONS
func _ready():
	# Tool scripts add items to the list sometimes
	EditorList.clear()
	
	# Open files provided via command-line
	# Necessary for Windows's open-with function to work
	if !Engine.editor_hint:
		for i in OS.get_cmdline_args():
			if i.ends_with(".tris"):
				_load_graph(i)
	
	_setup_signals()
	_setup_keybinds()


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
	var popupFile = MenuBarFile.get_popup()
	var popupEdit = MenuBarEdit.get_popup()
	var popupHelp = MenuBarHelp.get_popup()
	
	popupFile.connect("id_pressed", self, "_on_File_option_selected")
	popupEdit.connect("id_pressed", self, "_on_Edit_option_selected")
	popupHelp.connect("id_pressed", self, "_on_Help_option_selected")
	
	popupFile.connect("mouse_exited", self, "_on_menu_mouse_exit", [popupFile])


# Add all keybinds
# Note: In future, this should access keybinds from EditorSettings so that they
# can be rebound; for now, we use one layout for both.
# Issue: https://github.com/godotengine/godot/issues/44307
func _setup_keybinds():
	var FileNewFile = ShortCut.new()
	var FileSave = ShortCut.new()
	var FileSaveAs = ShortCut.new()
	var FileOpenFile = ShortCut.new()
	var FileCloseFile = ShortCut.new()
	
	var EditUndo = ShortCut.new()
	var EditRedo = ShortCut.new()
	var EditEndNodeToCursor = ShortCut.new()
	var EditSelectAll = ShortCut.new()
	var EditSelectAllToRight = ShortCut.new()
	var EditSelectAllToLeft = ShortCut.new()
	
	var HelpAbout = ShortCut.new()
	
	# Editor-only; do nothing for now
	if Engine.editor_hint:
		if editor_settings == null:
			return
		
		# In future, set shortcuts based on EditorSettings
	#else: # INDENT NEXT BLOCK & UNCOMMENT
	# Standalone
	var HotkeyNewFile = InputEventKey.new()
	HotkeyNewFile.control = true
	HotkeyNewFile.scancode = KEY_N
	FileNewFile.shortcut = HotkeyNewFile
	
	var HotkeySave = InputEventKey.new()
	HotkeySave.control = true
	HotkeySave.scancode = KEY_S
	FileSave.shortcut = HotkeySave
	
	var HotkeySaveAs = InputEventKey.new()
	HotkeySaveAs.control = true
	HotkeySaveAs.alt = true
	HotkeySaveAs.scancode = KEY_S
	FileSaveAs.shortcut = HotkeySaveAs
	
	var HotkeyOpenFile = InputEventKey.new()
	HotkeyOpenFile.control = true
	HotkeyOpenFile.scancode = KEY_O
	FileOpenFile.shortcut = HotkeyOpenFile
	
	var HotkeyCloseFile = InputEventKey.new()
	HotkeyCloseFile.control = true
	HotkeyCloseFile.scancode = KEY_W
	FileCloseFile.shortcut = HotkeyCloseFile
	
	var HotkeyUndo = InputEventKey.new()
	HotkeyUndo.control = true
	HotkeyUndo.scancode = KEY_Z
	EditUndo.shortcut = HotkeyUndo
	
	var HotkeyRedo = InputEventKey.new()
	HotkeyRedo.control = true
	HotkeyRedo.scancode = KEY_Y
	EditRedo.shortcut = HotkeyRedo
	
	var HotkeyEndNodeToCursor = InputEventKey.new()
	HotkeyEndNodeToCursor.control = true
	HotkeyEndNodeToCursor.scancode = KEY_E
	EditEndNodeToCursor.shortcut = HotkeyEndNodeToCursor
	
	var HotkeySelectAll = InputEventKey.new()
	HotkeySelectAll.control = true
	HotkeySelectAll.scancode = KEY_A
	EditSelectAll.shortcut = HotkeySelectAll
	
	var HotkeySelectAllToRight = InputEventKey.new()
	var HotkeySelectAllToLeft = InputEventKey.new()
	
	var HotkeyHelp = InputEventKey.new()
	HotkeyHelp.control = true
	HotkeyHelp.scancode = KEY_H
	HelpAbout.shortcut = HotkeyHelp
	
	# Now set the hotkeys!
	var filePopup = MenuBarFile.get_popup()
	filePopup.set_item_shortcut(0, FileNewFile)
	filePopup.set_item_shortcut(2, FileSave)
	filePopup.set_item_shortcut(3, FileSaveAs)
	filePopup.set_item_shortcut(5, FileOpenFile)
	filePopup.set_item_shortcut(7, FileCloseFile)
	
	var editPopup = MenuBarEdit.get_popup()
	editPopup.set_item_shortcut(0, EditUndo)
	editPopup.set_item_shortcut(1, EditRedo)
	editPopup.set_item_shortcut(2, EditEndNodeToCursor)
	
	var helpPopup = MenuBarHelp.get_popup()
	helpPopup.set_item_shortcut(0, HelpAbout)


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
	
	new_graph.connect("edited", self, "_on_Graph_edited", [new_graph])
	
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
	context_menu_opened = false
	
	match id:
		# New File
		0:
			_add_graph()
		
		# Save
		1:
			if !current_graph:
				return
			
			_save_graph(false, current_graph)
		
		# Save-As
		2:
			if !current_graph:
				return
			
			_save_graph(true, current_graph)
		
		# Open File
		3:
			LoadDialog.popup()
		
		# Close
		4:
			if EditorList.get_selected_items().empty():
				return
			
			var to_close = EditorList.get_selected_items()[0]
			
			if !GraphsList.get_child(to_close).is_saved:
				ConfirmClose.popup_centered()
			else:
				_on_ConfirmClose_confirmed()


func _on_Edit_option_selected(id):
	if !current_graph:
		return
	
	match id:
		0:
			current_graph.undo()
		1:
			current_graph.redo()
		2:
			current_graph.end_node_to_cursor()
		3:
			current_graph.select_all()
		4:
			current_graph.select_all_to_right()
		5:
			current_graph.select_all_to_left()


func _on_Help_option_selected(_id):
	OS.alert("There is no help.")


# Switch graphs when an item in the EditorList is selected
func _on_EditorList_item_selected(index):
	print(GraphsList)
	if current_graph:
		current_graph.hide()
	current_graph = GraphsList.get_child(index)
	current_graph.show()


# Display context menu when EditorList is right-clicked
func _on_EditorList_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			var popup = MenuBarFile.get_popup()
			popup.rect_position = event.global_position - Vector2(10, 10)
			popup.show()
			context_menu_opened = true


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


func _on_menu_mouse_exit(menu):
	if context_menu_opened:
		menu.hide()
		context_menu_opened = false
