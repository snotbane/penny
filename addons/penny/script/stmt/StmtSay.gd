## The most crucial statement in Penny. Evaluates a [Penny.Message] and displays it to the user. The specific [PennyPlayer] can have its own implementation of how to handle this.
@tool
class_name StmtSay
extends StmtNodeInterface

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


func _get_node_key() -> StringName:
	return &"interface_say"


func _populate(tokens: Array) -> void:
	super._populate(tokens)

	if tokens[0].type == PennyScript.Token.Type.OPERATOR and tokens[0].value == PennyScript.Token.Operator.ADD:
		dialog_declaration = DIALOG_DECLARATION_ADDITIVE
		tokens.pop_front()
	else:
		dialog_declaration = DIALOG_DECLARATION_DEFAULT

	message = tokens.pop_front().value

	assert(message is String or message is Penny.Message, "StmtSay :: 'message' must be a String or Penny.Message.")


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	super._draw(player, record)

	record.data.message = message.purified(record.data.subject)
