extends GraphNode

signal add_pressed
signal remove_pressed


var conditions_visible: bool = false


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
