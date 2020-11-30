extends GraphNode

# All text in all different languages
var text: Dictionary = {
	
}

# TODO: Hack; find a better way of doing this
func _ready():
	_on_Dialog_resize_request(rect_size)

func _on_Dialog_resize_request(new_minsize):
	$TextEdit.rect_min_size.y = new_minsize.y - 35
