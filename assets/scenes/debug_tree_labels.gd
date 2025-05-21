extends DebugTree

enum {
	BUTTONS,
	LABEL,
}

enum {
	JUMP,
	CALL,
}

const JUMP_ICON : Texture2D = preload("uid://d1mqpjg3rn12i")
const CALL_ICON : Texture2D = preload("uid://dudvfcddqwr3d")


func _ready() -> void:
	super._ready()
	Penny.inst.on_reload_finish.connect(refresh.unbind(1))

	self.set_column_expand(LABEL, true)
	self.set_column_expand(BUTTONS, false)


func _get_sort_column() -> int: return LABEL


func refresh() -> void:
	super.refresh()

	for label in Penny.labels:
		create_label_item(label)


func create_label_item(label: StringName) -> TreeItem:
	var result := self.create_item(root)
	result.set_text(LABEL, label)
	result.add_button(BUTTONS, JUMP_ICON, JUMP, false, "Jump to this label.")
	result.add_button(BUTTONS, CALL_ICON, CALL, false, "Call to this label.")
	return result


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	if not mouse_button_index == MOUSE_BUTTON_LEFT: return
	match column:
		BUTTONS:
			match id:
				JUMP: PennyDebug.inst.host.jump_to(item.get_text(LABEL))
				CALL: PennyDebug.inst.host.call_to(item.get_text(LABEL))
