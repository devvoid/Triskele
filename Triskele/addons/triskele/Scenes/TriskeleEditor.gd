tool
extends Control

signal saved(file_path)
signal edited()

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
# This is set to false in _on_edit, and true in _save
# DO NOT SET THIS ANYWHERE ELSE
var is_saved: bool = false

# Undo-Redo for this editor
onready var undo_redo = UndoRedo.new()

# The Add-Node button
onready var AddNodeButton = null

# The currently-selected node, used to select where the next node goes
onready var selected_node = null

onready var Graph = $GraphEdit

onready var TextEditor = $TextEditor

## Godot Functions
func _ready():
	_setup_add_node_button()
	Graph.scroll_offset = -(rect_size / 2)
	
	if !Engine.editor_hint:
		TextEditor.hide()


func _process(_delta):
	if !visible:
		return
	
	if Input.is_action_just_pressed("undo"):
		undo_redo.undo()
	
	if Input.is_action_just_pressed("redo"):
		undo_redo.redo()
	
	if Input.is_action_just_pressed("save"):
		_on_save_requested(file_path, false)
	
	if Input.is_action_just_pressed("save_as"):
		_on_save_requested(file_path, true)


## TRISKELE FUNCTIONS
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


# Save this file to disk
# NOTE: This should ONLY be called from _on_save_requested
# or else the filepath might be null, and Save-As won't work!
func _save():
	is_saved = true
	emit_signal("saved", file_path)


# Load file from the disk
func load_file(_file_path: String):
	pass


## SIGNALS
# Handle updating the file path, then save file.
func _on_save_requested(new_path: String, save_as: bool = false):
	if file_path == "" or save_as:
		file_path = new_path
	
	_save()


# Add node to the graph
func _on_add_node(node_id):
	# Make the node
	var new_node
	match node_id:
		1:
			new_node = NodeDialog.instance()
		2:
			new_node = NodeExpression.instance()
		3:
			new_node = NodeOptions.instance()
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
	undo_redo.add_do_method(self, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.add_do_method(self, "_on_edit")
	undo_redo.add_undo_method(self, "connect_node", from, from_slot, to, to_slot)
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


func _on_Panel_gui_input(event):
	if Engine.editor_hint:
		return
	
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		
		if event.button_index != BUTTON_LEFT and event.button_index != BUTTON_RIGHT:
			return
		
		TextEditor.hide()
