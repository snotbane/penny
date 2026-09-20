extends PanelContainer

@onready var tree: PennyDebugTree = $v_box_container/tree


func on_script_selected(script: PennyScript) -> void:
	tree.on_script_selected(script)
