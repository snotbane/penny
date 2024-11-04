
@tool
class_name StmtDialog extends StmtNode_

const DEPTH_REMOVAL_PATTERN := "(?<=\\n)\\t{0,%s}"
static var REGEX_WORD_COUNT := RegEx.create_from_string("\\b\\S+\\b")
static var REGEX_CHAR_COUNT := RegEx.create_from_string("\\S")

var subject_dialog_path : Path
var raw_text : String

var text_stripped : String :
	get:
		var result : String = raw_text
		# result = Message.REGEX_INTERPOLATION.sub(result, "$1", true)
		result = Message.INTERJECTION_PATTERN.sub(result, "", true)
		result = Message.DECO_TAG_PATTERN.sub(result, "", true)
		return result

var word_count : int :
	get: return REGEX_WORD_COUNT.search_all(text_stripped).size()


var char_count : int :
	get: return text_stripped.length()


var char_count_non_whitespace : int :
	get: return REGEX_CHAR_COUNT.search_all(text_stripped).size()


func _get_keyword() -> StringName:
	return 'dialog'


func _get_verbosity() -> Verbosity:
	return Verbosity.MAX


func _validate_self() -> PennyException:
	if tokens.back().type != Token.VALUE_STRING:
		return create_exception("The last token must be a String.")
	return null


func _validate_self_post_setup() -> void:
	var rx_whitespace = RegEx.create_from_string(DEPTH_REMOVAL_PATTERN % nest_depth)
	raw_text = rx_whitespace.sub(tokens.pop_back().value, "", true)


	super._validate_self_post_setup()
	subject_dialog_path = subject_path.duplicate()
	subject_dialog_path.ids.push_back(PennyObject.BILTIN_DIALOG_NAME)


# func _validate_cross() -> PennyException:
# 	return null


func _execute(host: PennyHost) -> Record:

	var previous_dialog : PennyObject = host.last_dialog_object
	var previous_dialog_node : PennyNode

	var incoming_dialog : PennyObject = self.subject_dialog_path.evaluate(host.data_root)
	if not incoming_dialog:
		push_exception("Attempted to create dialog box for '%s', but no such object exists" % self.subject_dialog_path)
		return create_record(host)

	var incoming_dialog_node : PennyNode

	var incoming_needs_creation : bool = true
	if previous_dialog:
		previous_dialog_node = previous_dialog.local_instance
		incoming_needs_creation = previous_dialog_node == null or previous_dialog_node.appear_state >= PennyNode.AppearState.CLOSING or previous_dialog != incoming_dialog

	if incoming_needs_creation:
		incoming_dialog_node = self.instantiate_node(host, subject_dialog_path)
		incoming_dialog_node.populate(host, incoming_dialog)
		incoming_dialog_node.open_on_ready = previous_dialog_node == null
		if previous_dialog_node != null:
			previous_dialog_node.advance_on_free = false
			previous_dialog_node.tree_exited.connect(incoming_dialog_node.open)
			previous_dialog_node.close()
	else:
		incoming_dialog_node = previous_dialog_node

	var message := Message.new(raw_text, host)

	if OS.is_debug_build():
		if incoming_dialog_node is MessageHandler:
			var result := create_record(host, incoming_dialog_node.halt_on_instantiate, message)
			incoming_dialog_node.receive(result, subject_path.evaluate(host.data_root))
			return result
		elif incoming_dialog_node:
			host.cursor.create_exception("Attempted to send a message to a node, but it isn't a MessageHandler.").push()
		else:
			host.cursor.create_exception("Attempted to send a message to a node, but it wasn't created.").push()
	else:
		var result := create_record(host, incoming_dialog_node.halt_on_instantiate, message)
		incoming_dialog_node.receive(result, subject_path.evaluate(host.data_root))
		return result
	return create_record(host, false, message)


func _create_history_listing(record: Record) -> HistoryListing:
	var result := super._create_history_listing(record)
	result.label.text = str(record.attachment)
	return result
