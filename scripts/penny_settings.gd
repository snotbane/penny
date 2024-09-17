
## Contains basic necessary data to link Penny scripts to the engine.
class_name PennySettings extends Resource

## Allows the user to roll back through the Penny script to view earlier text. Visual novels generally should use true; others use false. To lock rollback after a specific point, see (unimplemented)
@export var allow_roll_controls : bool = true

## Node at which to create new message receiver scenes.
@export var message_receiver_parent_node_name : String

## Default message receiver scene to use if a specific one has not been assigned.
@export var default_message_receiver_scene : PackedScene
