extends Node3D
class_name RocketProjectile3D

@export var speed = 20.0
@export var owner_node: Node3D ## Player or entity who shot the rocket that should be ignored during collision checks

@export var explosion_radius: float = 1.0
@export var force_falloff: Curve

@onready var explosion_shape: CollisionShape3D = $ExplosionArea3D/Explosion_shape
@onready var explosion_area_3d: Area3D = $ExplosionArea3D

func _ready() -> void:
	explosion_shape.shape.radius = explosion_radius

func _process(delta: float) -> void:
	position += transform.basis * Vector3(0,0, -20) * delta

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == owner_node:
		return
	# enable explosion
	var bodies: Array[Node3D] = explosion_area_3d.get_overlapping_bodies()
	# apply knocback force
	for candidate in bodies:
		if candidate is not PhysicsBody3D:
			continue
		var impulse_force: float = force_falloff.sample_baked(clampf(global_position.distance_to(body.global_position)/explosion_radius, 0, explosion_radius))
		print("yipee", global_position.distance_to(body.global_position)/explosion_radius)
		candidate.apply_central_impulse((candidate.global_position - global_position).normalized() * impulse_force)
	queue_free()
