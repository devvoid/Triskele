extends GraphNode

class_name TrisDialogNode

# All text in all different languages
var text: Dictionary = {
	"en_us": ""
}

# TODO: Find a way to make Label stretch vertically to fit container
func _ready():
	_on_Dialog_resize_request(rect_size)


func get_class():
	return "TrisDialogNode"


func is_class(name):
	return name == get_class() or .is_class(name)


func _on_Dialog_resize_request(new_minsize):
	$Preview.rect_min_size.y = new_minsize.y - 35
