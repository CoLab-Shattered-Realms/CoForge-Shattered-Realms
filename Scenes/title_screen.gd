extends Control

func _on_start__pressed():
	# Start the game 
	get_tree().change_scene_to_file("res://Scenes/first_game_scene.tscn")

func _on_exit__pressed():
	# Exit the game
	get_tree().quit()

func _on_credits__pressed():
	# Display the credits
	print('Should display the end credits')
