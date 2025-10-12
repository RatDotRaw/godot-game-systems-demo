extends Node3D

@export var speed = 20

func _process(delta: float) -> void:
	position += transform.basis * Vector3(0,0, -speed) * delta


func _on_area_3d_body_entered(body: Node3D) -> void:
	queue_free()
