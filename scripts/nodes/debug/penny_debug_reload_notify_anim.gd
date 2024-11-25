extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func start() -> void:
	self.play("loop")


func finish(success: bool) -> void:
	if success:
		self.play("success")
	else:
		self.play("failure")


func cancel() -> void:
	self.play("RESET")
