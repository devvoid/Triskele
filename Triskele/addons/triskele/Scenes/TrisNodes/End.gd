tool
extends GraphNode

class_name TrisEndNode

func get_class():
	return "TrisEndNode"

func is_class(name):
	return name == get_class() or .is_class(name)
