class_name BaseNode

extends GraphNode

enum NodeType {
	NODE_START,
	NODE_DIALOG,
	NODE_EXPRESSION,
	NODE_OPTIONS,
	NODE_CONDITION,
	NODE_END,
	NODE_UNDEFINED
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_type():
	return NodeType.NODE_UNDEFINED
