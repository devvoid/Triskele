extends Node2D


func _ready():
	var err = get_tree().change_scene("res://addons/triskele/TriskeleEditor.tscn")
	
	if err:
		print("Failed to change to scene")
