extends RigidBody3D

@export var look_sensitivity: float = 0.02
@export var max_walk_speed: float = 5
@export var walk_acceleration: Curve # TODO: find out what units it uses.
@export var coyote_time: int = 200 ## in miliseconds
@export var jump_buffer_time: int = 200 ## in miliseconds

@export var MAX_FLOOR_DEG: float = 40


@onready var camera_gimbal: Node3D = %CameraGimbal
# labels
@onready var touching_floor_label: Label = %TouchingFloorLabel
@onready var current_velocity_label: Label = %CurrentVelocityLabel

@onready var floor_normal: Vector3 = Vector3.DOWN
@onready var is_on_floor: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	touching_floor_label.text = str(floor_normal)
	current_velocity_label.text = str(linear_velocity.length())
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor:
		linear_velocity.y = 5
	
	movement(delta)

func movement(delta: float) -> void:
	var vertical_velocity := Vector3(0, linear_velocity.y, 0)
	var horizontal_velocity := Vector3(linear_velocity.x, 0, linear_velocity.z)
	
	# get player input
	var input_direction := Input.get_vector("LEFT", "RIGHT", "FORWARD", "BACKWARD").normalized()
	var desired_direction: Vector3 = (transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized() # world-space
	
	var target_velocity: Vector3 = desired_direction * max_walk_speed
	
	# smooth accel/decel based on curve
	var accel_factor = walk_acceleration.sample(horizontal_velocity.length() / max_walk_speed)
	horizontal_velocity = horizontal_velocity.lerp(target_velocity, accel_factor * delta)
	
	# recombine with vertical velocity
	linear_velocity = horizontal_velocity + vertical_velocity
	
	# calculate velocity to not exceed maximum by walking/running
	#if (linear_velocity + delta_velocity).length() > max_walk_speed: # check if added velocity is over speed limit
		#delta_velocity = linear_velocity.length() /
		#pass

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# check if on floor and get average normalized floor vector
	var average_normal: Vector3 = Vector3.ZERO
	for i in range(state.get_contact_count()):
		var collider: Vector3 = state.get_contact_local_normal(i)
		var angle = Vector3.UP.angle_to(collider) # returns radians
		if deg_to_rad(MAX_FLOOR_DEG) > angle:
			average_normal += collider
	floor_normal = average_normal.normalized()
	is_on_floor = true if average_normal != Vector3.ZERO else false

func _unhandled_input(event: InputEvent) -> void:
	# quit game
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		get_tree().quit()

	# camera movement input logic
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative
		var delta_x: float = mouse_delta.x * look_sensitivity
		var delta_y: float = mouse_delta.y * look_sensitivity
		
		# rotate camera and body
		rotate_y(-delta_x)
		camera_gimbal.rotate_x(-delta_y)
		camera_gimbal.rotation.x = clamp(camera_gimbal.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
