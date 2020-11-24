tool
extends GraphEdit

signal saved(file_path)
signal edited()

# File path. "" represents no path (when the graph is new)
var file_path: String = ""

# Whether or not all changes have been saved.
# This is set to false in _on_edit, and true in _save
# DO NOT SET THIS ANYWHERE ELSE
var is_saved: bool = false


## Godot Functions
func _ready():
	_setup_add_node_button()


func _setup_add_node_button():
	# Add the "ADD NODE" button
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


## TRISKELE FUNCTIONS
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
	print("Adding node " + str(node_id))


# Called whenever the graph is edited; sets is_saved to false,
# and signals the main scene to add the (*) to the file path.
func _on_edit():
	is_saved = false
	emit_signal("edited")
