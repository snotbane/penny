
@tool
class_name StmtDialog extends StmtNode_

const REGEX_DEPTH_REMOVAL_PATTERN := "(?<=\\n)\\t{0,%s}"
static var REGEX_INTERPOLATION := RegEx.create_from_string("(?<!\\\\)(@([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)|\\[(.*?)\\])")
static var REGEX_INTERJECTION := RegEx.create_from_string("(?<!\\\\)(\\{.*?\\})")
static var REGEX_DECORATION := RegEx.create_from_string("(?<!\\\\)(<.*?>)")
static var REGEX_WORD_COUNT := RegEx.create_from_string("\\b\\S+\\b")
static var REGEX_CHAR_COUNT := RegEx.create_from_string("\\S")

var dialog_node_path : Path
var raw_text : String

var text_stripped : String :
	get:
		var result : String = raw_text
		# result = REGEX_INTERPOLATION.sub(result, "$1", true)
		result = REGEX_INTERJECTION.sub(result, "", true)
		result = REGEX_DECORATION.sub(result, "", true)
		return result

var word_count : int :
	get: return REGEX_WORD_COUNT.search_all(text_stripped).size()

var char_count : int :
	get: return text_stripped.length()

var char_count_non_whitespace : int :
	get: return REGEX_CHAR_COUNT.search_all(text_stripped).size()

func _get_is_halting() -> bool:
	return true

func _get_verbosity() -> Verbosity:
	return Verbosity.MAX

func _get_keyword() -> StringName:
	return 'message'

func _execute(host: PennyHost) -> Record:
	var result := super._execute(host)
	var message_handler : Node = get_or_create_node(host, dialog_node_path)
	if message_handler is MessageHandler:
		host.is_halting = true
		message_handler.receive(result, node_path.evaluate_deep(host.data_root))
	elif message_handler:
		host.cursor.create_exception("Attempted to send a message to a node, but it isn't a MessageHandler.").push()
	else:
		host.cursor.create_exception("Attempted to send a message to a node, but it wasn't created.").push()
	return result

func _message(record: Record) -> Message:
	var text : String = raw_text

	var rx_whitespace = RegEx.create_from_string(REGEX_DEPTH_REMOVAL_PATTERN % depth)

	while true:
		var match := REGEX_INTERPOLATION.search(text)
		if not match : break

		var interp_expr_string := match.get_string(2) + match.get_string(3)	## ~= $2$3

		var parser = PennyParser.new(interp_expr_string)
		var exceptions = parser.tokenize()
		if not exceptions.is_empty():
			for i in exceptions:
				i.push()
			break

		var inter_expr := Expr.from_tokens(self, parser.tokens)
		var result = inter_expr.evaluate(record.host.data_root)
		var result_string := str(result)

		text = text.substr(0, match.get_start()) + result_string + text.substr(match.get_end(), text.length() - match.get_end())

	text = rx_whitespace.sub(text, "", true)
	return Message.new(text)

func _validate() -> PennyException:
	if tokens.back().type != Token.VALUE_STRING:
		return create_exception("The last token must be a String.")
	return null

func _setup() -> void:
	raw_text = tokens.pop_back().value
	super._setup()
	dialog_node_path = node_path.duplicate()
	dialog_node_path.ids.push_back(PennyObject.BILTIN_DIALOG_NAME)

