extends GraphNode

class_name TrisConditionNode

func get_class():
	return "TrisConditionNode"

func is_class(name):
	return name == get_class() or .is_class(name)
