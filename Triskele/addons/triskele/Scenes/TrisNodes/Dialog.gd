extends GraphNode

class_name TrisDialogNode

signal clicked

# The translation key for this node. If blank, the exporter will use
# the node name.
var translation_key: String = ""


# All text in all different languages
var text: Dictionary = {
	"en_US": ""
}


# TODO: Find a way to make Label stretch vertically to fit container
func _ready():
	print(get_children())
	_on_Dialog_resize_request(rect_size)


func get_class():
	return "TrisDialogNode"


func is_class(name):
	return name == get_class() or .is_class(name)


func set_text(locale: String, new_text: String):
	text[locale] = new_text
	$Preview.text = new_text


func update_preview():
	$Preview.text = text["en_US"]


func _on_Dialog_resize_request(new_minsize):
	$Preview.rect_min_size.y = new_minsize.y - 35


func _on_Preview_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			emit_signal("clicked")
