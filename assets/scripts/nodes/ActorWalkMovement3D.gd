class_name ActorWalkMovement3D extends Node

@export var walk_speed : float = 100.0

@onready var character : CharacterBody3D = get_parent()

var move_direction : Vector3

func _physics_process(delta: float) -> void:
	character.velocity = Vector3.ZERO
	character.velocity += move_direction * walk_speed * delta
	character.velocity += ProjectSettings.get_setting("physics/3d/default_gravity_vector") * ProjectSettings.get_setting("physics/3d/default_gravity")

	character.move_and_slide()


func update_move_vector(direction:Vector3) -> void:
	move_direction = direction
