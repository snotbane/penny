## Main viewer that displays one or more records and awaits user input to continue.
class_name PennyMain extends HistoryUser

class SaveData extends JSONFileResource:
	var user : PennyMain

	func _init(__user__: PennyMain, __save_data__: String = generate_save_path()) -> void:
		user = __user__
		super._init(__save_data__)

	func _export_json(json: Dictionary) -> void:
		json.merge({
			&"git_rev_penny": PennyUtils.get_git_commit_id("res://addons/penny_godot/"),
			&"git_rev_project": PennyUtils.get_git_commit_id(),
			&"screenshot": null,
			&"state": Save.any(Cell.ROOT),
			&"history": user.active_history.export_json()
		})


# ## If enabled, the host will begin execution on ready.
# @export var autostart := false

# ## The label in Penny scripts to start at. Make sure this is populated with a valid label.
# @export var start_label := &"start"

# ## If enabled, the user will be able to move the cursor forward and backward through the history.
# @export var allow_rolling := true

var save_data : SaveData

func _ready() -> void:
	active_history = History.new()
	create_save_data.call_deferred()

func create_save_data() -> void:
	save_data = SaveData.new(self)
	save_data.shell_open_location()

func save_changes() -> void:
	save_data.save_changes()

