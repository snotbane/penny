## The most crucial statement in Penny. Evaluates a [Penny.Message] and displays it to the user. The specific [PennyPlayer] can have its own implementation of how to handle this.
@tool
class_name StmtDialog
extends StmtPath

enum {
	DIALOG_DECLARATION_DEFAULT,
	DIALOG_DECLARATION_ADDITIVE,
}

@export_storage
var message : Variant

@export_storage
var dialog_declaration : int


func _get_verbosity() -> Verbosity:
	return Verbosity.USER_FACING


func _get_debug_message() -> String:
	return str(message)


func _populate(tokens: Array) -> void:
	super._populate(tokens)

	if tokens[0].type == PennyScript.Token.Type.OPERATOR and tokens[0].value == PennyScript.Token.Operator.ADD:
		dialog_declaration = DIALOG_DECLARATION_ADDITIVE
		tokens.pop_front()
	else:
		dialog_declaration = DIALOG_DECLARATION_DEFAULT

	message = tokens.pop_front().value

	assert(message is String or message is Penny.Message, "StmtDialog :: 'message' must be a String or Penny.Message.")


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = {}

	record.data.subject = context_value_from_recent
	if record.data.subject is not Penny.Cell:
		record.data.subject = Penny.Cell.OBJECT

	assert(record.data.subject.has_data(&"dialog"), "Dialog subject must have a dialog property.")

	record.data.dialog = record.data.subject.get_data_and_evaluate(&"dialog")
	assert(record.data.dialog is Penny.Cell, "Dialog object must be a Cell.")

	record.data.message = message.purified(record.data.subject)


func _execute(player: PennyPlayer, record: Penny.Record) -> void:
	var incoming_dialog : Penny.Cell = record.data.dialog
	var incoming_dialog_node : Node

	var previous_dialog : Penny.Cell = player.ledger.most_recent_dialog
	var previous_dialog_node : Node

	var incoming_needs_creation: bool
	if previous_dialog:
		previous_dialog_node = previous_dialog.instance
		incoming_needs_creation = previous_dialog_node == null or previous_dialog != incoming_dialog
	else:
		incoming_needs_creation = true

	if incoming_needs_creation:
		if previous_dialog_node:
			if previous_dialog_node.has_method(&"exit"):
				await previous_dialog_node.exit(player, record)
			else:
				previous_dialog_node.queue_free()

		incoming_dialog_node = record.data.dialog.spawn(player, record)
	else:
		incoming_dialog_node = previous_dialog_node

	if incoming_dialog_node.has_method(&"enter"):
		await incoming_dialog_node.enter(player, record)

	assert(incoming_dialog_node.has_method(&"handle"))
	await incoming_dialog_node.handle(record)
