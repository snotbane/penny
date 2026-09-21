## Creates a [Node] on execute and expects the user to do something with it. Used for dialogs and menues.
@abstract
@tool
class_name StmtNodeInterface
extends StmtPath

# ## Determines how to fetch the most recent interface from the ledger.
# enum {
# 	## Returns null unless the most recent StmtNodeInterface's key exactly matches. This will create multiple of the same interface unless they are created back-to-back. I don't know why anyone would use this.
# 	FETCH_EXCLUSIVE,
# 	## Returns the most recent StmtNodeInterface's interface, regardless of its key. This will ensure that only one interface OF ANY TYPE is visible.
# 	FETCH_ANY_INTERFACE,
# 	## Returns the most recent StmtNodeInterface with a matching key, ignoring those where the key does not match. This allows interfaces of differing types to be visible simultaneously.
# 	FETCH_MATCHING_KEY,
# }

func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


@abstract
func _get_node_key() -> StringName


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = {}

	record.data.interface_key = _get_node_key()

	record.data.subject = context_value_from_recent
	if record.data.subject is not Penny.Cell:
		record.data.subject = Penny.Cell.OBJECT

	assert(record.data.subject.has_data(record.data.interface_key), "Dialog subject must have a dialog property.")

	record.data.interface = record.data.subject.get_data_and_evaluate(record.data.interface_key)
	assert(record.data.interface is Penny.Cell, "Dialog object must be a Cell.")


func _execute(player: PennyPlayer, record: Penny.Record):
	var incoming_interface : Penny.Cell = record.data.interface
	var incoming_interface_node : Node

	var previous_interface : Penny.Cell = player.ledger.find_recent_interface_from_key(record.data.interface_key)
	var previous_interface_node : Node

	var incoming_needs_creation: bool
	if previous_interface:
		previous_interface_node = previous_interface.instance
		incoming_needs_creation = previous_interface_node == null or previous_interface != incoming_interface
	else:
		incoming_needs_creation = true

	if incoming_needs_creation:
		if previous_interface_node:
			if previous_interface_node.has_method(&"exit"):
				await previous_interface_node.exit(player, record)
			else:
				previous_interface_node.queue_free()

		incoming_interface_node = record.data.interface.spawn(player, record)
	else:
		incoming_interface_node = previous_interface_node

	if incoming_interface_node.has_method(&"enter"):
		await incoming_interface_node.enter(player, record)

	assert(incoming_interface_node.has_method(&"handle"))
	record.data.response = await incoming_interface_node.handle(record)
