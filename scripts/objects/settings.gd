
## Contains basic necessary data to link Penny scripts to the engine.
class_name PennySettings extends Resource

## Allows the user to roll back through the Penny script to view earlier text. Visual novels generally should use true; others use false. To lock rollback after a specific point, see (unimplemented)
@export var allow_roll_controls : bool = true
