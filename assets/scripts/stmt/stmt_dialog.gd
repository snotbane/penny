
class_name StmtDialog extends StmtNode

const DEPTH_REMOVAL_PATTERN := r"\n\t{0,%s}"
static var REGEX_WORD_COUNT := RegEx.create_from_string(r"\b\w+\b")
static var REGEX_CHAR_COUNT := RegEx.create_from_string(r"\S")


var subject_dialog_path : Path
var pure_text : String


func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING


func _get_is_rollable() -> bool:
	return true


func _populate(tokens: Array) -> void:
	var regex_whitespace := RegEx.create_from_string(DEPTH_REMOVAL_PATTERN % self.depth)
	pure_text = regex_whitespace.sub(tokens.pop_back().value, " ", true)

	super._populate(tokens)

	subject_dialog_path = subject_ref.duplicate()
	subject_dialog_path.ids.push_back(Cell.K_DIALOG)


func _pre_execute(record: Record) -> void:
	var incoming_dialog : Cell = subject_dialog_path.evaluate()

	record.data.merge({
		&"who": subject,
		&"what": DisplayString.new_from_pure(pure_text, Cell.ROOT, incoming_dialog),
		&"dialog": incoming_dialog
	})


func _execute(record: Record) :
	var incoming_dialog : Cell = record.data[&"dialog"]
	if not incoming_dialog:
		printerr("Attempted to create dialog box for '%s', but no such object exists" % self.subject_dialog_path)
		return
	var incoming_dialog_node : DialogNode
	var previous_dialog : Cell = record.host.last_dialog_object

	var previous_dialog_node : DialogNode
	var incoming_needs_creation : bool

	if previous_dialog != null:
		previous_dialog_node = previous_dialog.instance
		incoming_needs_creation = previous_dialog_node == null or previous_dialog != incoming_dialog
	else:
		incoming_needs_creation = true

	if incoming_needs_creation:
		if previous_dialog_node != null:
			await previous_dialog_node.exit()
		await incoming_dialog.enter(Funx.new(record.host, true))
		incoming_dialog_node = incoming_dialog.instance
	else:
		incoming_dialog_node = previous_dialog_node

	incoming_dialog_node.receive(record)
	await incoming_dialog_node.advanced


func _create_history_listing(record: Record) -> HistoryListing:
	var result : HistoryListing = load("res://addons/penny_godot/assets/scenes/history_listings/history_listing_dialog.tscn").instantiate()
	result.populate(record)
	return result


func _get_record_message(record: Record) -> String:
	return record.data[&"what"].text

func get_metrics() -> Dictionary:
	return DisplayString.get_metrics_from_pure(pure_text)
