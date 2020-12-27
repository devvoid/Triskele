tool
extends Control

signal save_finished
signal edited

const BACKUP_PATH = "user://backups/"

# NOTE: Using class_name.new() results in not creating any of the children nodes.
# This could probably be gotten around by overloading the new() function, but
# doing it this way is simpler for now.
onready var NodeStart = preload("res://addons/triskele/Scenes/TrisNodes/Start.tscn")
onready var NodeDialog = preload("res://addons/triskele/Scenes/TrisNodes/Dialog.tscn")
onready var NodeExpression = preload("res://addons/triskele/Scenes/TrisNodes/Expression.tscn")
onready var NodeOptions = preload("res://addons/triskele/Scenes/TrisNodes/Options.tscn")
onready var NodeCondition = preload("res://addons/triskele/Scenes/TrisNodes/Condition.tscn")
onready var NodeEnd = preload("res://addons/triskele/Scenes/TrisNodes/End.tscn")

# The graph itself
onready var Graph = $GraphEdit

# The text editor
onready var TextEditor = $TextEditor

# File path. "" represents no path (when the graph is new)
var file_path: String = ""

# Whether or not all changes have been saved.
# This is set to false in _on_edit, and true in save_file and load_file
# DO NOT SET THIS ANYWHERE ELSE
var is_saved: bool = false

# Undo-Redo for this editor
var undo_redo = UndoRedo.new()

# The Add-Node button
var AddNodeButton = null

# The currently-selected node, used to select where the next node goes
var selected_node = null

# Whether or not the mouse is on this graph or not
var mouse_on_graph = false

## Godot Functions
func _ready():
	# Add-Node button
	_setup_add_node_button()
	
	# Set scroll to the middle of the screen
	Graph.scroll_offset = -(rect_size / 2)
	
	# Hide text editor
	TextEditor.hide()
	
	# Add Start and End nodes to the graph
	# TODO: Replace 400 with calculation based on size of the screen
	var start = NodeStart.instance()
	start.name = "Start"
	start.offset.x -= 400
	start.connect("dragged", self, "_on_node_dragged", [start])
	Graph.add_child(start)
	
	var end = NodeEnd.instance()
	end.name = "End"
	end.offset.x += 400
	end.connect("dragged", self, "_on_node_dragged", [end])
	Graph.add_child(end)
	
	# Select the Start node
	selected_node = start
	Graph.set_selected(start)


## TRISKELE FUNCTIONS
# Undo the last action
func undo():
	if TextEditor.visible:
		pass#TextEditor.get_node("TabContainer/en_US").undo()
	else:
		undo_redo.undo()


# Redo the last undone action
func redo():
	if TextEditor.visible:
		pass#TextEditor.get_node("TabContainer/en_US").redo()
	else:
		undo_redo.redo()


# Get rid of all tris nodes to empty the graph
func _clear_nodes():
	for i in Graph.get_children():
		if i.is_in_group("trisnode"):
			# queue_free() doesn't properly delete Start/End; engine bug?
			i.free()


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
	# TODO: Add a manual translation path, which works the same way as file_path,
	# so that there can be a different translation path for storing in a sub-
	# folder.
	var translation_path = file_path.replace(".tris", ".csv")
	
	# Backup files before attempting the save
	# Check the background directory.
	var backup_dir = Directory.new()
	if !backup_dir.dir_exists(BACKUP_PATH):
		var err = backup_dir.make_dir(BACKUP_PATH)
		
		if err:
			push_error("Unable to create backup directory!")
	
	backup_dir.open(BACKUP_PATH)
	
	# Get the paths
	var tris_backup_path = "%s%s.bck" % [BACKUP_PATH, file_path.get_file()]
	var trans_backup_path = "%s%s.bck" % [BACKUP_PATH, translation_path.get_file()]
	
	# Copy the files to the backup path
	if backup_dir.file_exists(file_path):
		backup_dir.copy(file_path, tris_backup_path)
	
	if backup_dir.file_exists(translation_path):
		backup_dir.copy(translation_path, trans_backup_path)
	
	# Start saving
	var output = {
		"version_major": 1,
		"version_minor": 0,
		"supported_languages": ["en_US"],
		"translation_file": file_path.get_file().replace(".tris", ".csv"),
		"nodes": {}
	}
	
	# Use a second dictionary for the nodes to decrease nesting
	var nodes: Dictionary
	
	# Create a CSV file for translations
	var translation = File.new()
	translation.open(translation_path, File.WRITE)
	
	# Add language header to the CSV File
	translation.store_csv_line(["", "en_US"])
	# Godot can't properly parse a translation file if it doesn't have any keys
	translation.store_csv_line(["TRISDUMMY", "Placeholder!"])
	
	# Fill dictionary with nodes
	## Step 1: Fill with nodes
	for i in Graph.get_children():
		# If it isn't a tris node, we don't care, ignore it.
		if !i.is_in_group("trisnode"):
			continue
		
		# Write info that all nodes have (name, position, size)
		var current_node = {}
		current_node["name"] = i.name
		current_node["position"] = i.offset
		current_node["size"] = i.rect_size
		
		# Write node-specific info, and type
		match i.get_class():
			# Start and End have no special parameters at this stage.
			"TrisStartNode":
				current_node["type"] = "Start"
				current_node["next"] = "NULL"
			"TrisEndNode":
				current_node["type"] = "End"
			
			# Dialog node
			"TrisDialogNode":
				current_node["type"] = "Dialog"
				current_node["next"] = "NULL"
				
				# Get the translation key
				var translation_key
				# If no explicit translation key is defined, use the node name
				if i.translation_key == "":
					translation_key = i.name.to_upper()
				else:
					translation_key = i.translation_key
				
				# Add key to the node
				current_node["translation_key"] = translation_key
				
				# Write to the CSV file, using the name as a translation key
				translation.store_csv_line([translation_key, i.text["en_US"]])
			
			# Expression node just needs to write its expression
			"TrisExpressionNode":
				current_node["type"] = "Expression"
				current_node["expression"] = i.get_node("Expression").get_text()
				current_node["next"] = "NULL"
			
			# Options node needs to write its options
			"TrisOptionsNode":
				current_node["type"] = "Options"
				current_node["uses_conditions"] = i.conditions_visible
				current_node["options"] = []
				
				for j in i.get_children():
					# Skip top bar
					if j is HBoxContainer:
						continue
					
					var new_option = {}
					new_option["option"] = j.get_node("OptionText").get_text()
					new_option["condition"] = j.get_node("Condition").get_text()
					new_option["next"] = "NULL"
					
					current_node["options"].append(new_option)
			
			# Condition node just needs to write its condition
			"TrisConditionNode":
				current_node["type"] = "Condition"
				current_node["condition"] = i.get_node("Condition").get_text()
				current_node["next_true"] = "NULL"
				current_node["next_false"] = "NULL"
			
			# Default is used as an error handler
			_:
				OS.alert("Tried to save unknown node type %s; skipping" % [i.get_class()])
		
		# All the node data is written; add to the dictionary
		nodes[i.name] = current_node
	
	## Step 2: Sort connections list into a more easily-usable state
	var raw_connection_list = Graph.get_connection_list()
	
	# Format:
	# "node_name": [ "connection1", "connection2", ...]
	# This can be roughly translated into connect_node("node_name", array position, "other_node"[array position], 0)
	# The to_port is ignored because all nodes only have one input.
	var connection_list = {}
	
	# Fill connection list
	for connection in raw_connection_list:
		# If this node doesn't have an entry in the list yet,
		# make it an empty array.
		if !connection_list.has(connection.from):
			connection_list[connection.from] = []
		
		# If the array is too small to contain the new connection, resize it
		if connection_list[connection.from].size() <= connection.from_port:
			connection_list[connection.from].resize(connection.from_port + 1)
		
		# Setup the connection
		connection_list[connection.from][connection.from_port] = connection.to
	
	## Step 3: Add all connections
	for key in connection_list.keys():
		# End has no connections; it will never appear as a key in the
		# connections list
		
		# For Start, Dialog, and Expression, set "next" to first member of the
		# connections array
		if nodes[key].has("next"):
			nodes[key]["next"] = connection_list[key][0]
		
		# For Condition, set true to the first member and false to the second
		elif nodes[key].has("next_true"):
			# Check how many connections this node has.
			var size = connection_list[key].size()
			
			# If there are two connections, that means both True and False are
			# connected. If there's only one, that means only one or the other
			# is connected
			
			# NOTE: There currently isn't a way to detect which is which, so
			# Triskele will always connect it to next_true.
			if size == 1:
				nodes[key]["next_true"] = connection_list[key][0]
			else:
				nodes[key]["next_true"] = connection_list[key][0]
				nodes[key]["next_false"] = connection_list[key][1]
		
		# Options is just Dialog but in a loop.
		elif nodes[key].has("options"):
			for i in connection_list[key].size():
				nodes[key]["options"][i]["next"] = connection_list[key][i]
		
		else:
			push_error("Unknown node type!")
	
	# Add nodes to main dictionary
	output["nodes"] = nodes
	
	# Save to file
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(JSON.print(output, "\t"))
	file.close()
	
	# All done, so delete the backups
	backup_dir.remove(tris_backup_path)
	backup_dir.remove(trans_backup_path)
	
	# Alert the main scene that a save just happened
	is_saved = true
	emit_signal("save_finished")


# Load file from the disk
func load_file(load_path: String):
	# Since we're loading from a file, then by default it matches what that file
	# contains. Therefore, we're saved.
	is_saved = true
	
	_clear_nodes()
	
	# Load name and data from the provided file
	file_path = load_path
	name = load_path.get_file()
	
	var file = File.new()
	file.open(load_path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	
	# Check version
	if data["version_major"] != 1 and data["version_minor"] != 0:
		push_warning("Version mismatched in opened file! Errors may occur.")
	
	var translation_path = (load_path.get_base_dir() + "/" + data["translation_file"])
	
	# Load translation
	var file_trans = File.new()
	if !file.file_exists(translation_path):
		push_error("Translation file could not be found!")
	
	file_trans.open(translation_path, File.READ)
	# Parse the translation
	
	# Languages supported
	var languages = file_trans.get_csv_line()
	
	# Translation hash. Stored in format {"key": {"lang1": "translated", ...}, ...}
	var translation = {}
	
	# As of right now there doesn't seem to be a way to get all lines in a CSV
	# file, but when reading beyond the end of the file, the result is just an
	# empty PoolStringArray. We can use that to break when everything is loaded.
	
	# NOTE: For some reason, the empty PoolStringArray you get has a size of 1,
	# NOT 0.
	
	# NOTE: If using a manually-edited translation file, adding empty rows will
	# cause this to not load all the translations!!!
	while true:
		var next_key = file_trans.get_csv_line()
		
		if next_key.size() == 1 or next_key.size() == 0:
			break
		
		var new_key = {}
		
		var new_key_name
		
		for i in next_key.size():
			# First element is the key name
			if i == 0:
				new_key_name = next_key[0]
				continue
			
			# Next elements are the languages, in order.
			new_key[languages[i]] = next_key[i]
		
		translation[new_key_name] = new_key
	
	# We don't need the translation file anymore, so close.
	file_trans.close()
	
	# Load the data
	## Step 1: Load all nodes
	var nodes = data["nodes"]
	
	for node in nodes.values():
		# The node being loaded
		var new_node
		
		# Create node and set type-specific stuff
		match node["type"]:
			# Start and End have no specific stuff, but default is used for
			# catching unknown node types
			"Start":
				new_node = NodeStart.instance()
			"End":
				new_node = NodeEnd.instance()
			
			# Dialog node
			"Dialog":
				var transkey = node["translation_key"]
				
				new_node = NodeDialog.instance()
				
				new_node.translation_key = transkey
				new_node.text = translation[transkey]
				
				new_node.update_preview()
				
				new_node.connect("clicked", self, "_on_Dialog_clicked", [new_node])
			
			# Expression node
			"Expression":
				var expression = node["expression"]
				
				new_node = NodeExpression.instance()
				
				new_node.get_node("Expression").text = expression
			
			# Options node
			"Options":
				var options = node["options"]
				var uses_conditions = node["uses_conditions"]
				
				new_node = NodeOptions.instance()
				
				# Set conditions
				new_node.set_conditions(uses_conditions)
				
				new_node.connect("add_pressed", self, "_on_Options_add_pressed", [new_node])
				new_node.connect("remove_pressed", self, "_on_Options_remove_pressed", [new_node])
				
				for i in options.size():
					var new_option = HSplitContainer.new()
					
					# Write text to these
					
					var condition = LineEdit.new()
					condition.name = "Condition"
					condition.placeholder_text = "Condition"
					condition.text = options[i]["condition"]
					condition.size_flags_horizontal = SIZE_EXPAND_FILL
					
					var option_text = LineEdit.new()
					option_text.name = "OptionText"
					option_text.placeholder_text = "Option Text"
					option_text.text = options[i]["option"]
					option_text.size_flags_horizontal = SIZE_EXPAND_FILL
					
					new_option.add_child(condition)
					new_option.add_child(option_text)
					
					if !uses_conditions:
						condition.visible = false
					
					new_node.add_child(new_option, true)
					new_node.add_slot()
			
			# Condition node
			"Condition":
				var condition = node["condition"]
				
				new_node = NodeCondition.instance()
				
				new_node.get_node("Condition").text = condition
			
			_:
				push_error("Unknown node type %s" % [node["type"]])
		
		# Set type-independent stuff
		
		var node_size = node["size"].replace('(', '').replace(')', '').split(',')
		new_node.rect_size.x = float(node_size[0])
		new_node.rect_size.y = float(node_size[1])
		
		var node_pos = node["position"].replace('(', '').replace(')', '').split(',')
		new_node.offset.x = float(node_pos[0])
		new_node.offset.y = float(node_pos[1])
		
		new_node.connect("resize_request", self, "_on_node_resize_request", [new_node])
		new_node.connect("close_request", self, "_on_node_close_request", [new_node])
		new_node.connect("dragged", self, "_on_node_dragged", [new_node])
		
		Graph.add_child(new_node)
		new_node.name = node["name"]
		new_node.set_title(node["name"])
	
	## Step 2: Connect all nodes
	for node in nodes.values():
		# Start, Dialog, Expression
		if node.has("next"):
			if node["next"] != "NULL":
				Graph.connect_node(node["name"], 0, node["next"], 0)
		
		# Condition
		if node.has("next_true"):
			if node["next_true"] != "NULL":
				Graph.connect_node(node["name"], 0, node["next_true"], 0)
			
			if node["next_false"] != "NULL":
				Graph.connect_node(node["name"], 1, node["next_false"], 0)
		
		# Options
		if node.has("options"):
			for i in node["options"].size():
				if node["options"][i]["next"] != "NULL":
					Graph.connect_node(node["name"], i, node["options"][i]["next"], 0)


func end_node_to_cursor():
	var end_node = Graph.get_node("End")
	
	# Location where the node will be placed
	var pos
	
	if mouse_on_graph:
		# Get the mouse position relative to the Graph
		pos = get_viewport().get_mouse_position()
		pos += Graph.scroll_offset
		pos -= Graph.rect_global_position
	else:
		# Get graph center
		pos = Graph.rect_size / 2
		pos += Graph.scroll_offset
	
	# Put node at final position
	end_node.set_offset(pos)

## SIGNALS
# Add node to the graph
func _on_add_node(node_id):
	# Make the node, and do any node-specific setup
	var new_node
	match node_id:
		1:
			new_node = NodeDialog.instance()
			new_node.connect("clicked", self, "_on_Dialog_clicked", [new_node])
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
	new_node.connect("dragged", self, "_on_node_dragged", [new_node])
	
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
	if is_saved:
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


func _on_node_close_request(caller):
	# Get all connections that involve this node...
	var raw_connections = Graph.get_connection_list()
	var connections = []
	
	# Add all connections that don't involve this node
	for i in raw_connections:
		if i["from"] == caller.name or i["to"] == caller.name:
			connections.push_back(i)
	
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
	# TODO: Remove any old connections with the same from_slot
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


# Display add-node menu when EditorList is right-clicked. Reset selected node to
# null if it's a left click.
func _on_GraphEdit_gui_input(event):
	if event is InputEventMouseButton:
		# If the button wasn't pressed, we don't care
		if !event.pressed:
			return
		
		if event.button_index == BUTTON_RIGHT:
			if !AddNodeButton:
				return
			
			AddNodeButton.get_popup().rect_position = event.global_position - Vector2(10, 10)
			AddNodeButton.get_popup().show()
		
		# Doesn't work right now due to an engine bug; GraphNodes with mouse
		# filter "Stop" don't block signals from going to the parent like they
		# should.
		if event.button_index == BUTTON_LEFT:
			pass
			#selected_node = null


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
		
		_on_CloseTextEditor_pressed()


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
	var col = Color(1, 1, 1)
	undo_redo.create_action("Add option to %s" % [caller.name])
	undo_redo.add_do_method(caller, "add_child", new_option)
	undo_redo.add_do_method(caller, "add_slot")
	undo_redo.add_undo_method(caller, "remove_child", new_option)
	undo_redo.add_undo_method(caller, "remove_slot")
	undo_redo.commit_action()


# Remove the last option from an Options node
func _on_Options_remove_pressed(caller):
	# If there's only one child, then there are no options; abort
	if caller.get_child_count() == 1:
		return
	
	var option = caller.get_child(caller.get_child_count() - 1)
	
	undo_redo.create_action("Remove option from %s" % [caller.name])
	undo_redo.add_do_method(caller, "remove_child", option)
	undo_redo.add_do_method(caller, "remove_slot")
	undo_redo.add_undo_method(caller, "add_child", option)
	undo_redo.add_undo_method(caller, "add_slot")
	undo_redo.commit_action()


func _on_SaveDialog_file_selected(path):
	file_path = path
	_save_file_internal()


func _on_Dialog_clicked(caller):
	# Make the caller our selected node, so we can find it again later
	selected_node = caller
	Graph.set_selected(caller)
	
	# Initialize the text editor to the node's data
	TextEditor.get_node("TabContainer/en_US").text = caller.text["en_US"]
	TextEditor.get_node("BottomPanel/TranslationKey").text = caller.translation_key
	
	# Show the editor
	TextEditor.show()
	
	# Grab focus for the text editor
	TextEditor.get_node("TabContainer/en_US").grab_focus()


func _on_CloseTextEditor_pressed():
	# Save the data back to the node
	selected_node.set_text("en_US", TextEditor.get_node("TabContainer/en_US").text)
	selected_node.translation_key = TextEditor.get_node("BottomPanel/TranslationKey").text
	
	# Hide the text editor
	TextEditor.hide()


func _on_node_dragged(from, to, caller):
	undo_redo.create_action("Move node %s" % [caller.name])
	undo_redo.add_do_property(caller, "offset", to)
	undo_redo.add_undo_property(caller, "offset", from)
	undo_redo.commit_action()


func _on_Graph_mouse_entered():
	mouse_on_graph = true


func _on_GraphEdit_mouse_exited():
	mouse_on_graph = false
