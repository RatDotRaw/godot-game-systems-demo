extends Node3D

@export var rocket = preload("uid://2tcq4g7p2mhs")
@export var owner_node: Node3D = null ## Player or entity who shot the rocket that should be ignored during collision checks
@export var cooldown_time: float = 1000

@onready var fire_spawn_point: Node3D = $FireSpawnPoint

var fire: bool = false
@onready var cooldown_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(cooldown_timer)
	cooldown_timer.autostart = true
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = cooldown_time / 1000.0
	
	assert(owner_node, "Owner node not assigned!")

func _physics_process(delta: float) -> void:
	if cooldown_timer.is_stopped() and fire:
		fire=false
		cooldown_timer.start()
		# get rocket ready
		var instance: RocketProjectile3D = rocket.instantiate()
		instance.transform = fire_spawn_point.global_transform
		instance.owner_node = owner_node
		get_tree().root.add_child(instance)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		fire = true
