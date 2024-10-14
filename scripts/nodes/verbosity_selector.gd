
@tool
extends OptionButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if PennyPlugin.inst:
		selected = PennyPlugin.inst.dock.verbosity_selector.selected

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_selected(index:int) -> void:
	if HistoryHandler.inst:
		HistoryHandler.inst.verbosity = get_selected_id()
