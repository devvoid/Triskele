extends Control


func _ready():
	var err = get_tree().change_scene("res://addons/triskele/Scenes/TriskeleMain.tscn")
	
	if err:
		print("Failed to change to scene")
