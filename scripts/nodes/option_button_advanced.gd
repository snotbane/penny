extends OptionButton

signal item_selected_id(id: int)

func _init() -> void:
	self.item_selected.connect(on_item_selected_id)

func on_item_selected_id(index: int) -> void:
	item_selected_id.emit(self.get_item_id(index))
