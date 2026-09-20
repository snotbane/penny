extends PennyDebugTree

enum {
	COLUMN_PATH,

	COLUMN_MAX
}


@onready var panel: Node = get_parent().get_parent()

var item_scripts: Dictionary[TreeItem, PennyScript] = {}

var selected_script: PennyScript :
	get: return item_scripts.get(get_selected())


func _init() -> void:
	super._init()

	hide_root = true
	select_mode = Tree.SELECT_ROW

	columns = COLUMN_MAX


func _ready() -> void:
	super._ready()

	item_selected.connect((func() -> void:
		panel.script_selected.emit(selected_script)
	))



func _construct_tree() -> void:
	root = create_item()

	for script in Penny.LOADED_SCRIPTS:
		create_script_item(root, script)



func create_script_item(parent: TreeItem, script: PennyScript) -> TreeItem:
	var result := create_item(parent)

	if script:
		item_scripts[result] = script
		result.set_text(COLUMN_PATH, script.safe_path.get_file())
		result.set_tooltip_text(COLUMN_PATH, script.resource_path)


	return result
