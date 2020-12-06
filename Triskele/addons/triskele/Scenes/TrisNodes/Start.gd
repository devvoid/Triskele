tool
extends GraphNode

class_name TrisStartNode

func get_class():
	return "TrisStartNode"

func is_class(name):
	return name == get_class() or .is_class(name)
