## Creates a [Node] on execute and expects the user to do something with it. Used for dialogs and menues.
@abstract
@tool
class_name StmtNodePrompt
extends StmtPath

# ## Determines how to fetch the most recent prompt from the ledger.
# enum {
# 	## Returns null unless the most recent StmtNodePrompt's key exactly matches. This will create multiple of the same prompt unless they are created back-to-back. I don't know why anyone would use this.
# 	FETCH_EXCLUSIVE,
# 	## Returns the most recent StmtNodePrompt's prompt, regardless of its key. This will ensure that only one prompt OF ANY TYPE is visible.
# 	FETCH_ANY_PROMPT,
# 	## Returns the most recent StmtNodePrompt with a matching key, ignoring those where the key does not match. This allows prompts of differing types to be visible simultaneously.
# 	FETCH_MATCHING_KEY,
# }

func _get_verbosity() -> Verbosity:
	return Verbosity.NODE_ACTIVITY


@abstract
func _get_node_key() -> StringName


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = {}

	record.data.prompt_key = _get_node_key()

	record.data.subject = context_value_from_recent
	if record.data.subject is not Penny.Cell:
		record.data.subject = Penny.Cell.OBJECT

	assert(record.data.subject.has_data(record.data.prompt_key), "Dialog subject must have a dialog property.")

	record.data.prompt = record.data.subject.get_data_and_evaluate(record.data.prompt_key)
	assert(record.data.prompt is Penny.Cell, "Dialog object must be a Cell.")


func _execute(player: PennyPlayer, record: Penny.Record):
	var incoming_prompt : Penny.Cell = record.data.prompt
	var incoming_prompt_node : Node

	var previous_prompt : Penny.Cell = player.ledger.find_recent_prompt_from_key(record.data.prompt_key)
	var previous_prompt_node : Node

	var incoming_needs_creation: bool
	if previous_prompt:
		previous_prompt_node = previous_prompt.instance
		incoming_needs_creation = previous_prompt_node == null or previous_prompt != incoming_prompt
	else:
		incoming_needs_creation = true

	if incoming_needs_creation:
		if previous_prompt_node:
			if previous_prompt_node.has_method(&"exit"):
				await previous_prompt_node.exit(player, record)
			else:
				previous_prompt_node.queue_free()

		incoming_prompt_node = record.data.prompt.spawn(player, record)
	else:
		incoming_prompt_node = previous_prompt_node

	if incoming_prompt_node.has_method(&"enter"):
		await incoming_prompt_node.enter(player, record)

	assert(incoming_prompt_node.has_method(&"handle"))
	record.data.response = await incoming_prompt_node.handle(record)
