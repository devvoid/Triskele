tool
extends GraphEdit

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

onready var selected_node = null

## Godot Functions
func _ready():
	_setup_add_node_button()
	scroll_offset = - (rect_size / 2)


func _process(_delta):
	if Input.is_action_just_pressed("undo"):
		undo_redo.undo()
	
	if Input.is_action_just_pressed("redo"):
		undo_redo.redo()


## TRISKELE FUNCTIONS
# Setup the "Add Node" button
func _setup_add_node_button():
	# 
	var button = MenuButton.new()
	
	# Set the button's name
	button.text = "Add Node"
	#button.name = "TRIS_ADD_NODE"
	button.flat = true
	
	# Add entries
	button.get_popup().add_item("Dialog", 1)
	button.get_popup().add_item("Expression", 2)
	button.get_popup().add_item("Option", 3)
	button.get_popup().add_item("Condition", 4)
	
	button.get_popup().connect("id_pressed", self, "_on_add_node")
	
	# Add to scene
	get_zoom_hbox().add_child(button)

# Save this file to disk
# NOTE: This should ONLY be called from _on_save_requested
# or else the filepath might be null, and Save-As won't work!
func _save():
	is_saved = true
	emit_signal("saved", file_path)


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
	
	# If we have a node selected, add this new one to the right of it.
	if selected_node:
		var new_position = selected_node.offset
		new_position.x += selected_node.rect_size.x
		new_position.x += 50
		new_node.offset = new_position
	
	# Add to the scene
	add_child(new_node, true)
	
	# Set node's title to the node name
	# HAS to be done after add_child, because that's when the unique node name
	# is set.
	new_node.title = new_node.name
	
	# Set the currently-selected node to this one
	set_selected(new_node)
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


func _on_connection_request(from, from_slot, to, to_slot):
	undo_redo.create_action("Connect node %s to %s" % [from, to])
	undo_redo.add_do_method(self, "connect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.commit_action()


func _on_disconnection_request(from, from_slot, to, to_slot):
	undo_redo.create_action("Disconnect node %s from %s" % [from, to])
	undo_redo.add_do_method(self, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "connect_node", from, from_slot, to, to_slot)
	undo_redo.commit_action()


# Display add-node menu when EditorList is right-clicked
func _on_GraphEdit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			#ContextMenu.rect_position = event.global_position
			#ContextMenu.show()
			pass
