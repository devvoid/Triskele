tool
extends Control

signal save_finished
signal edited

# TODO: Maybe make scripts for the nodes and use class_name to remove this
onready var NodeStart = preload("res://addons/triskele/Scenes/TrisNodes/Start.tscn")
onready var NodeDialog = preload("res://addons/triskele/Scenes/TrisNodes/Dialog.tscn")
onready var NodeExpression = preload("res://addons/triskele/Scenes/TrisNodes/Expression.tscn")
onready var NodeOptions = preload("res://addons/triskele/Scenes/TrisNodes/Options.tscn")
onready var NodeCondition = preload("res://addons/triskele/Scenes/TrisNodes/Condition.tscn")
onready var NodeEnd = preload("res://addons/triskele/Scenes/TrisNodes/End.tscn")

# File path. "" represents no path (when the graph is new)
var file_path: String = ""

# Whether or not all changes have been saved.
# This is set to false in _on_edit, and true in save_file
# DO NOT SET THIS ANYWHERE ELSE
var is_saved: bool = false

# Undo-Redo for this editor
onready var undo_redo = UndoRedo.new()

# The Add-Node button
onready var AddNodeButton = null

# The currently-selected node, used to select where the next node goes
onready var selected_node = null

# The graph itself
onready var Graph = $GraphEdit

# The text editor
onready var TextEditor = $TextEditor

## Godot Functions
func _ready():
	# Add-Node button
	_setup_add_node_button()
	
	# Set scroll to the middle of the screen
	Graph.scroll_offset = -(rect_size / 2)
	
	# Hide text editor
	TextEditor.hide()
	
	# Add Start and End nodes to the graph
	var start = NodeStart.instance()
	start.name = "Start"
	start.offset.x -= 400
	Graph.add_child(start)
	
	var end = NodeEnd.instance()
	end.name = "End"
	end.offset.x += 400
	Graph.add_child(end)


## TRISKELE FUNCTIONS
# Undo the last action
func undo():
	if TextEditor.visible:
		TextEditor.get_node("TabContainer/en_us").undo()
	else:
		undo_redo.undo()


# Redo the last undone action
func redo():
	if TextEditor.visible:
		TextEditor.get_node("TabContainer/en_us").redo()
	else:
		undo_redo.redo()


# Get rid of all tris nodes to empty the graph
func _clear_nodes():
	for i in Graph.get_children():
		if i.is_in_group("trisnodes"):
			i.queue_free()


# Setup the "Add Node" button
func _setup_add_node_button():
	# Create the button
	AddNodeButton = MenuButton.new()
	
	# Set the button's name
	AddNodeButton.text = "Add Node"
	AddNodeButton.name = "AddNode"
	#button.name = "TRIS_ADD_NODE"
	AddNodeButton.flat = true
	
	# Add entries
	AddNodeButton.get_popup().add_item("Dialog", 1)
	AddNodeButton.get_popup().add_item("Expression", 2)
	AddNodeButton.get_popup().add_item("Option", 3)
	AddNodeButton.get_popup().add_item("Condition", 4)
	
	AddNodeButton.get_popup().connect("id_pressed", self, "_on_add_node")
	
	AddNodeButton.get_popup().connect("mouse_exited", self, "_on_AddNodeMenu_mouse_exited")
	
	# Add to scene
	Graph.get_zoom_hbox().add_child(AddNodeButton)


# Resolve filepath and save file
func save_file(save_as: bool = false):
	# If the user used Save-As, or if there isn't a filepath, use the save
	# dialog. This will call _save_file_internal once the filepath is set.
	if save_as or file_path == "":
		$SaveDialog.popup()
	else:
		_save_file_internal()
	
	# TODO: This and _save_file_internal could be combined if you could yield
	# on $SaveDialog until file_selected is called, but that doesn't work if
	# the user clicks off the SaveDialog instead of selecting a path. This is
	# because there's no known way of terminating the function if another signal
	# is called


# Save the file to disk
func _save_file_internal():
	var output = {
		"version_major": 1,
		"version_minor": 0,
		"nodes": {}
	}
	
	# Use a second dictionary for the nodes to decrease nesting
	var nodes: Dictionary
	
	# Fill dictionary with nodes
	
	# Add nodes to main dictionary
	output["nodes"] = nodes
	
	# Save to file
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(to_json(output))
	file.close()
	
	is_saved = true
	emit_signal("save_finished")


# Load file from the disk
func load_file(load_path: String):
	file_path = load_path
	name = load_path.get_file()
	
	var file = File.new()
	file.open(load_path, File.READ)
	var json;


## SIGNALS
# Add node to the graph
func _on_add_node(node_id):
	# Make the node, and do any node-specific setup
	var new_node
	match node_id:
		1:
			new_node = NodeDialog.instance()
		2:
			new_node = NodeExpression.instance()
		3:
			new_node = NodeOptions.instance()
			new_node.connect("add_pressed", self, "_on_Options_add_pressed", [new_node])
			new_node.connect("remove_pressed", self, "_on_Options_remove_pressed", [new_node])
		4:
			new_node = NodeCondition.instance()
		_:
			OS.alert("Invalid node ID: %s" % [node_id])
	
	# Connect signals
	new_node.connect("resize_request", self, "_on_node_resize_request", [new_node])
	new_node.connect("close_request", self, "_on_node_close_request", [new_node])
	
	# If we have a node selected, add this new one to the right of it.
	if selected_node:
		var new_position = selected_node.offset
		new_position.x += selected_node.rect_size.x
		new_position.x += 50
		new_node.offset = new_position
	
	# Add to the scene
	undo_redo.create_action("Create node of type %s" % [node_id])
	undo_redo.add_do_method(self, "_on_edit")
	undo_redo.add_do_method(Graph, "add_child", new_node, true)
	undo_redo.add_undo_method(Graph, "remove_child", new_node)
	undo_redo.add_undo_method(self, "_on_edit")
	undo_redo.commit_action()
	
	# Set node's title to the node name
	# HAS to be done after add_child, because that's when the unique node name
	# is set.
	new_node.title = new_node.name
	
	# Set the currently-selected node to this one
	Graph.set_selected(new_node)
	selected_node = new_node


# Called whenever the graph is edited; sets is_saved to false,
# and signals the main scene to add the (*) to the file path.
func _on_edit():
	is_saved = false
	emit_signal("edited")


# When a node is requested to be resized
func _on_node_resize_request(new_minsize, caller):
	# TODO: Only Dialog gets resized on both axes, all others only resize on X
	undo_redo.create_action("Resize node %s" % caller.name, UndoRedo.MERGE_ENDS)
	undo_redo.add_do_property(caller, "rect_size", new_minsize)
	undo_redo.add_undo_property(caller, "rect_size", caller.rect_size)
	undo_redo.commit_action()


func _on_node_selected(node):
	selected_node = node


func _on_node_unselected(node):
	selected_node = null


func _on_node_close_request(caller):
	# Get all connections that involve this node...
	var connections = Graph.get_connection_list()
	
	# Remove all connections that don't involve this node
	for i in connections:
		if i["from"] != caller.name and i["to"] != caller.name:
			connections.erase(i)
	
	# Make action
	undo_redo.create_action("Close node %s" % caller.name)
	
	# Remove all connections involving this node...
	for i in connections:
		undo_redo.add_do_method(
			Graph,
			"disconnect_node",
			i["from"],
			i["from_port"],
			i["to"],
			i["to_port"]
		)
	
	# Remove the node and signal edit
	undo_redo.add_do_method(Graph, "remove_child", caller)
	undo_redo.add_do_method(self, "_on_edit")
	
	# Re-add connections
	for i in connections:
		undo_redo.add_undo_method(
			Graph,
			"connect_node",
			i["from"],
			i["from_port"],
			i["to"],
			i["to_port"]
		)
	
	# Re-add node and signal edit
	undo_redo.add_undo_method(Graph, "add_child", caller)
	undo_redo.add_undo_method(self, "_on_edit")
	undo_redo.commit_action()


func _on_connection_request(from, from_slot, to, to_slot):
	undo_redo.create_action("Connect node %s to %s" % [from, to])
	undo_redo.add_do_method(Graph, "connect_node", from, from_slot, to, to_slot)
	undo_redo.add_do_method(self, "_on_edit")
	undo_redo.add_undo_method(Graph, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "_on_edit")
	undo_redo.commit_action()


func _on_disconnection_request(from, from_slot, to, to_slot):
	undo_redo.create_action("Disconnect node %s from %s" % [from, to])
	undo_redo.add_do_method(Graph, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.add_do_method(self, "_on_edit")
	undo_redo.add_undo_method(Graph, "connect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "_on_edit")
	undo_redo.commit_action()


# Display add-node menu when EditorList is right-clicked
func _on_GraphEdit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			if !AddNodeButton:
				return
			
			AddNodeButton.get_popup().rect_position = event.global_position
			AddNodeButton.get_popup().show()


# Hide the AddNodeMenu popup when the mouse exits
func _on_AddNodeMenu_mouse_exited():
	if !AddNodeButton:
		return
	
	AddNodeButton.get_popup().hide()


# Close the TextEditor when the user clicks off it.
func _on_Panel_gui_input(event):
	if Engine.editor_hint:
		return
	
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		
		if event.button_index != BUTTON_LEFT and event.button_index != BUTTON_RIGHT:
			return
		
		TextEditor.hide()


# Add a new option to an Options node
func _on_Options_add_pressed(caller):
	var new_option = HSplitContainer.new()
	
	var condition = LineEdit.new()
	condition.name = "Condition"
	condition.placeholder_text = "Condition"
	condition.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var option_text = LineEdit.new()
	option_text.name = "OptionText"
	option_text.placeholder_text = "Option Text"
	option_text.size_flags_horizontal = SIZE_EXPAND_FILL
	
	new_option.add_child(condition)
	new_option.add_child(option_text)
	
	if !caller.conditions_visible:
		condition.visible = false
	
	undo_redo.create_action("Add option to %s" % [caller.name])
	undo_redo.add_do_method(caller, "add_child", new_option)
	undo_redo.add_undo_method(caller, "remove_child", new_option)
	undo_redo.commit_action()


# Remove the last option from an Options node
func _on_Options_remove_pressed(caller):
	# If there's only one child, then there are no options; abort
	if caller.get_child_count() == 1:
		return
	
	var option = caller.get_child(caller.get_child_count() - 1)
	
	undo_redo.create_action("Remove option from %s" % [caller.name])
	undo_redo.add_do_method(caller, "remove_child", option)
	undo_redo.add_undo_method(caller, "add_child", option)
	undo_redo.commit_action()


func _on_SaveDialog_file_selected(path):
	file_path = path
	_save_file_internal()
