extends GraphNode

class_name TrisExpressionNode

func get_class():
	return "TrisExpressionNode"

func is_class(name):
	return name == get_class() or .is_class(name)
