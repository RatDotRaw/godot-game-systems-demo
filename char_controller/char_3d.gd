extends RigidBody3D

@export var mouse_sensitivity: float = 0.002
@export var max_walk_speed: float = 5
@export var walk_acceleration: Curve # Each point on the curve directly represents the acceleration speed for a given normalized velocity.
@export var air_acceleration: Curve ## Acceleration while airborn
@export var ground_friction: float = 7.0

@export var air_jumps: int = 2 ## amount of mid air jumps the character can make
@export var coyote_time: int = 200 ## in miliseconds
@export var jump_buffer_time: int = 200 ## in miliseconds

@export var MAX_FLOOR_DEG: float = 40

@onready var orientation: Node3D = %Orientation
@onready var camera_gimbal: Node3D = %CameraGimbal
# labels
@onready var touching_floor_label: Label = %TouchingFloorLabel
@onready var current_velocity_label: Label = %CurrentVelocityLabel
@onready var air_jumps_left_label: Label = %AirJumpsLeftLabel
@onready var coyote_time_left_label: Label = %CoyoteTimeLeftLabel
@onready var floorvisualizer: Node3D = %Floorvisualizer

@onready var floor_normal: Vector3 = Vector3.DOWN
@onready var is_on_floor: bool = false
@onready var jumps_left: int = 0 # to track air jumps
@onready var coyote_time_left: float

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	floorvisualizer.look_at(floor_normal+floorvisualizer.global_position)
	touching_floor_label.text = str(floor_normal)
	current_velocity_label.text = str(linear_velocity.length())
	air_jumps_left_label.text = str(jumps_left) + "/" + str(air_jumps)
	coyote_time_left_label.text = str(coyote_time_left)
	#movement(delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var delta = state.step
	get_floor_info(state)
	movement(state, delta)
	jump(state, delta)

## movement + friction
func movement(state: PhysicsDirectBodyState3D, delta) -> void:
	
	# get player input
	var input_direction := Input.get_vector("LEFT", "RIGHT", "FORWARD", "BACKWARD") #.normalized()
	# Cap input vector length (so diagonals aren’t faster)
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()
	
	if is_on_floor:
		apply_floor_friction(state, delta, ground_friction)
	if input_direction == Vector2.ZERO:
		return
	
	# to world-space
	var desired_direction: Vector3 = orientation.global_transform.basis * Vector3(
			input_direction.x, 
			0, 
			input_direction.y
		).normalized()
	
	# project desired_direction to floor_normal
	desired_direction = desired_direction.slide(floor_normal).normalized()
	
	print(desired_direction)
	# quake 1 style movement math + my extra
	var wish_speed: float = min(input_direction.length(), 1.0) * max_walk_speed
	# get current speed in desired direction
	var current_speed = state.linear_velocity.dot(desired_direction)
	
	# calculate target speed
	#var target_speed = input_direction.length() * max_walk_speed
	# how much more speed to add
	var add_speed: float = wish_speed - current_speed # how much more speed to add
	if add_speed <= 0.0: #already above target speed
		return
	
	var accel_speed: float = 10 * delta * wish_speed  # walk accel * max * delta
	var speed_fraction = clamp(state.linear_velocity.length() / max_walk_speed, 0.0, 1.0)
	if is_on_floor:
		accel_speed = walk_acceleration.sample(speed_fraction) * delta * wish_speed
	else:
		accel_speed = air_acceleration.sample(speed_fraction) * delta * wish_speed
	
	if accel_speed > add_speed:
		accel_speed = add_speed
	state.linear_velocity += desired_direction * accel_speed

func apply_floor_friction(state: PhysicsDirectBodyState3D, delta: float, friction: float) -> void:
	var horizontal_velocity = Vector3(state.linear_velocity.x, 0, state.linear_velocity.z)
	var speed = horizontal_velocity.length()
	if speed < 0.01:
		state.linear_velocity = Vector3.ZERO
		return
	var drop = speed * friction * delta
	state.linear_velocity *= max(speed - drop, 0) / speed


func jump(state: PhysicsDirectBodyState3D, delta: float) -> void:
	coyote_time_left += -delta
	
	if is_on_floor:
		jumps_left = air_jumps
		coyote_time_left = coyote_time / 1000.0 # to milisecondsz
	
	if not Input.is_action_just_pressed("ui_accept"):
		return
	
	print("jump")
	if is_on_floor:
		state.linear_velocity.y = 5
	elif coyote_time_left > 0: # coyote time
		coyote_time_left = 0
		state.linear_velocity.y = 5
	elif jumps_left > 0:
		state.linear_velocity.y = 5
		jumps_left += -1

func get_floor_info(state: PhysicsDirectBodyState3D) -> void:
	# check if on floor and get average normalized floor vector (contact based ground detecton)
	var average_normal: Vector3 = Vector3.ZERO
	for i in range(state.get_contact_count()):
		var collider: Vector3 = state.get_contact_local_normal(i)
		var angle = Vector3.UP.angle_to(collider) # returns radians
		if deg_to_rad(MAX_FLOOR_DEG) > angle:
			average_normal += collider
	floor_normal = average_normal.normalized()
	is_on_floor = true if average_normal != Vector3.ZERO else false

func _input(event: InputEvent) -> void:
	# quit game
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		get_tree().quit()

var yaw = 0.0

func _unhandled_input(event: InputEvent) -> void:
	# camera movement input logic
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative
		var delta_x: float = mouse_delta.x * mouse_sensitivity
		var delta_y: float = mouse_delta.y * mouse_sensitivity
		
		yaw += -delta_x
		
		orientation.rotation.y -= delta_x
		camera_gimbal.rotation.y -= delta_x
		camera_gimbal.rotation.x -= delta_y
		camera_gimbal.rotation.x = clamp(camera_gimbal.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
