class_name ActorWalkMovement3D extends Node

@export var walk_speed : float = 100.0

@onready var character : CharacterBody3D = get_parent()

var move_direction : Vector3

func _physics_process(delta: float) -> void:
	character.velocity = Vector3.ZERO
	character.velocity += move_direction * walk_speed * delta

	if not character.is_on_floor():
		character.velocity += ProjectSettings.get_setting("physics/3d/default_gravity_vector") * ProjectSettings.get_setting("physics/3d/default_gravity")

	character.move_and_slide()


func teleport(global_pos: Vector3) -> void:
	character.global_position = global_pos


func move(direction: Vector3) -> void:
	if character.is_on_floor():
		move_direction = Plane(character.get_floor_normal()).project(direction)
	else:
		move_direction = direction * (Vector3.ONE - character.up_direction)
