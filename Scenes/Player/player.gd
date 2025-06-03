class_name Player
extends CharacterBody3D

## =============================================
## Variables
## =============================================

## --------------------------------------------
## Player export variables, should be self-explanatory
## --------------------------------------------
@export_category("Player")
@export_range(1, 35, 1) var speed: float = 10  # m/s
@export_range(10, 400, 1) var acceleration: float = 100  # m/s^2
@export_range(0.1, 3.0, 0.1) var jump_height: float = 1  # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1 # camera sensitivity

## --------------------------------------------
## Internal physics based variables
## --------------------------------------------
var jumping: bool = false
#When initializing the player, assume the gravity will be the default value defined in the project settings so it can easily be changed globally.
#Scenes that have different gravity than the project's default could also change this property when appropriate.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2  # Input direction for movement
var look_dir: Vector2  # Input direction for look/aim

var walk_vel: Vector3  # Walking velocity
var grav_vel: Vector3  # Gravity velocity
var jump_vel: Vector3  # Jumping velocity


## --------------------------------------------
## Camera variables
## --------------------------------------------
## This uses a basic 3rd Person View Camera. It should follow and rotate around the player.
## It can be achieved by setting a camera as a child of the character. 
## However if you do this without extra steps the camera will always be at the same distance.
## You'll quickly notice this does not look good as the camera clips through geometry in the scene.
## This is why a pivot with a SpringArm3D is used. 
## The pivot will be slightly above the actual character for us not to keep looking at their back.
## If the spring collides with an object, the camera goes up to that collision point.
## Reference the tutorial in Godot 4.4 documentation:
## @tutorial: https://docs.godotengine.org/en/latest/tutorials/3d/spring_arm.html#third-person-camera-with-spring-arm
var mouse_captured: bool = false
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera
#This spotlight was added just for demonstration purposes as the starting scene was currently pretty dark at testing time
#It could be removed from the player scene and this references from the script with no detrimental effects.
#Or it could easily act as a flashlight to be turned on/off by a input.
@onready var spot_light: SpotLight3D = $SpotLight

## =============================================
## Variables - END
## =============================================


## =============================================
## 1. Initialization
## =============================================
## Functions that should be run to correctly initialize the character 
## or as soon as this entity is ready

func _ready() -> void:
	#Start capturing the mouse for camera movement as soon as this entity is ready
	capture_mouse()

## =============================================
## 1. Initialization - END
## =============================================



## =============================================
## 2. Input Handling
## =============================================
## Functions that deal with capturing input that should be handled immediately upon detection rather than waiting to the next physics update cycle.
## For reference, _input is best used for handling discrete events that might trigger immediate actions 
## (like Input.is_action_just_pressed("jump") for a single jump trigger, or mouse motion for camera rotation).
## Other things such as precise timing for shooting attacks or interactions should go here.

## Checks for Mouse Movement, Jump or possibly other inputs in the future.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: #Checks for mouse movement
		#Calculates the look_dir based on the mouse's relative movement since the last frame. The 0.001 is a scaling factor to adjust sensitivity.
		look_dir = event.relative * 0.001 
		if mouse_captured: #Only rotates the camera if the mouse is captured.
			_rotate_camera()
	if Input.is_action_just_pressed("jump"): # Checks for the "jump" input action
		jumping = true # Setting this will trigger the _jump logic in _physics_process

## =============================================
## 2. Input Handling - END
## =============================================


## =============================================
## 3. Physics Process
## =============================================
## This part deals in the physics processing or what actually happens to the character.
## This is where continuous, state-based input (like held movement keys/sticks) should be processed to influence physics simulations.
## It currently only has character movement, but throwing things, charging melee attacks or taking damage could also be here.

func _physics_process(delta: float) -> void:
	if mouse_captured:
		_handle_joypad_camera_rotation(delta)
	
	##This is the core movement logic. The final velocity of the CharacterBody3D is the sum of:
	## _walk(delta): The horizontal movement velocity.
	## _gravity(delta): The vertical velocity due to gravity.
	## _jump(delta): The vertical velocity due to jumping.
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

## --------------------------------------------
## 3.1 Movement Functions
## --------------------------------------------
## Calculates the horizontal walking velocity.

func _walk(delta: float) -> Vector3:
	#Gets a Vector2 representing the player's movement input (e.g., WASD, left stick).
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	
	#Where the character is walking forward depends on where they are facing. Use the camera to see which direction is 'forward'.
	var forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(forward.x, 0, forward.z).normalized() #Extracts the horizontal components of the forward vector and normalizes it to get the pure direction.
	#Interpolate walk_vel towards the target walk velocity considering max speed and acceleration
	#walk_dir * speed: The desired maximum velocity in the walk_dir
	#move_dir.length(): Applies a multiplier so that if the player is only partially pressing a movement key (e.g., using an analog stick), the speed is reduced accordingly.
	#acceleration * delta: The maximum amount walk_vel can change in this physics frame, so the character doesn't have too sudden of an acceleration by the player mashing contrary directional inputs.
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel


## Calculates the vertical velocity component due to gravity.
func _gravity(delta: float) -> Vector3:
	
	grav_vel = (
		# gravity velocity should return zero if the character is on the floor, as they're not falling anymore
		Vector3.ZERO
		if is_on_floor() 
		# If not on the floor, gravity is applied.
		# Smoothly increases the downward grav_vel
		# The target velocity Vector3(0, velocity.y - gravity, 0) is a conceptual representation of continuous downward acceleration without a terminal velocity.
		# move_toward effectively applies gravity * delta downwards each frame if not on floor.
		else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	)
	return grav_vel


## Calculates the vertical velocity component due to jumping.
func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): #Checks if the player is on the floor before initiating a jump (prevents double-jumping unless specifically desired).
			# Calculates the initial jump velocity. This formula is derived from kinematics (sqrt(2 * h * g)) to achieve a specific jump height.
			jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = (
		# Resets jump_vel to Vector3.ZERO if character is on the floor.
		# If not on the floor, jump_vel is smoothly moved towards Vector3.ZERO by applying gravity * delta. 
		# This simulates the deceleration of the jump's upward motion due to gravity.
		Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	)
	return jump_vel

## --------------------------------------------
## 3.1 Movement Functions - END
## --------------------------------------------

## =============================================
## 3. Physics Process - END
## =============================================


## =============================================
## 4. Camera and Mouse Control
## =============================================
## This part is important for the camera to follow the mouse movement while the mouse is captured 
##(i.e., most of the game, except in menus or cutscenes for example).


##This function should be called whenever the mouse needs to be captured by this entity, like the player assuming direct control of the character
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


##This counterpart function should be called whenever the mouse needs to be released, like scrolling through menu options.
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


##This gets the joypad input for camera rotation.
func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	#Gets the vector from the joypad input
	var joypad_dir: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if joypad_dir.length() > 0:
		#If it's different from 0, use it for changing the look_dir for as long as it's inputted (also consider sensibility modifiers)
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod)
		#Zero look_dir after the operation so we don't have phantom joystick movement for no input for some reason, bit of safety
		look_dir = Vector2.ZERO


##This handles camera rotation, either from mouse (from _input) or joypad (from _handle_joypad_camera_rotation).
func _rotate_camera(sens_mod: float = 1.0) -> void:
	# Rotate the Pivot of the SpringArm3D instead of the camera directly
	camera_pivot.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5) # Adjusted clamp values for typical third-person view

	# SpotLight3D should still follow the camera's rotation relative to the player
	spot_light.rotation.y = camera_pivot.rotation.y
	spot_light.rotation.x = camera_pivot.rotation.x

## =============================================
## 4. Camera and Mouse Control - END
## =============================================
