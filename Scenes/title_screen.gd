extends Control


# A textureRect can be used in place of a "Label" if the name of the game is some image or texture file, or if you'd want to use a logo instead of a game name

# The background image can & should be changed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start__pressed():
	# Start the game 
	get_tree().change_scene_to_file("res://Scenes/random_test_scene.tscn")

func _on_exit__pressed():
	# Exit the game
	get_tree().quit()

func _on_credits__pressed():
	# Display the credits
	print('Should display the end credits')
