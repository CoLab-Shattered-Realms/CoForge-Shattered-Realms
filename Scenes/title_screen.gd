extends Control

# The background image can & should be changed

# A textureRect can be used in place of a "Label" if the name of the game is some image or texture file, or if you'd want to use a logo instead of a game name

# necessary for adding a 'pulse' to the game title text
@onready var game_title := $title_text


var pulse_speed := 2.0			# determines how fast the pulse will be 
var pulse_scale := 0.05			# determines how big/small the pulse will get
var time_passed := 0.0			# determines how much time has passed since game start


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scale_title_text(delta)

func scale_title_text(delta):
	# adds up time as the game runs
	time_passed += delta
	
	# calculates and controls the scale(expansion & contraction) of the text through the sin()
	var scale_factor = 1.0 + sin(time_passed * pulse_speed) * pulse_scale
	
	# uses the 'scale_factor' to set how the the label is
	game_title.scale = Vector2(scale_factor, scale_factor)


func _on_start__pressed():
	# Start the game 
	get_tree().change_scene_to_file("res://Scenes/random_test_scene.tscn")

func _on_exit__pressed():
	# Exit the game
	get_tree().quit()

func _on_credits__pressed():
	# Display the credits
	print('Should display the end credits')
