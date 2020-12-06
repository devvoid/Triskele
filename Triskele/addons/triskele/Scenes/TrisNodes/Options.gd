tool
extends GraphNode

class_name TrisOptionsNode


signal add_pressed
signal remove_pressed


var conditions_visible: bool = false


func get_class():
	return "TrisOptionsNode"


func is_class(name):
	return name == get_class() or .is_class(name)


func set_conditions(use_conditions):
	conditions_visible = use_conditions
	$TopBar/UseConditions.pressed = use_conditions

# Add and Remove slot need to be here because there's an issue with doing it on
# the UndoRedo itself, where Godot complains that only 5 arguments were provided
# when 7 are needed.
func add_slot():
	set_slot(
		get_child_count() - 1,
		false,
		0,
		Color(1, 1, 1),
		true,
		0,
		Color(1, 1, 1)
	)


func remove_slot():
	set_slot(
		get_child_count(),
		false,
		0,
		Color(1, 1, 1),
		false,
		0,
		Color(1, 1, 1)
	)

func _on_AddButton_pressed():
	emit_signal("add_pressed")


func _on_RemoveButton_pressed():
	emit_signal("remove_pressed")


func _on_UseConditions_toggled(button_pressed):
	# Update variable (used for adding new options in TriskeleEditor)
	conditions_visible = button_pressed
	
	# Update all children
	for i in get_children():
		if i is HSplitContainer:
			i.get_child(0).visible = conditions_visible
