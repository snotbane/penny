@tool extends CompositeVisualInstance3D

func refresh() -> void:
	super.refresh()
	self.draw_pass_1 = self.quad
