
class_name StmtMessage extends Stmt

const REGEX_DEPTH_REMOVAL_PATTERN := "(?<=\\n)\\t{0,%s}"
static var REGEX_INTERPOLATION := RegEx.create_from_string("@([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)|\\[(.+)\\]")

func _get_is_halting() -> bool:
	return true

# func _get_verbosity() -> int:
# 	return -1

func _get_keyword() -> StringName:
	return 'message'

func _execute(host: PennyHost) -> Record:
	var result := super._execute(host)
	host.message_handler.receive(result)
	return result

func _message(record: Record) -> Message:
	var text : String = tokens[0].value

	var rx_whitespace = RegEx.create_from_string(REGEX_DEPTH_REMOVAL_PATTERN % depth)

	while true:
		var match := REGEX_INTERPOLATION.search(text)
		if not match : break

		var expr_string = match.get_string()
		expr_string = expr_string.substr(1, expr_string.length() - 2)

		var parser = PennyParser.new(expr_string)
		parser.parse_tokens()
		var result = record.host.evaluate_expression(parser.tokens)
		var result_string := str(result)

		text = text.substr(0, match.get_start()) + result_string + text.substr(match.get_end(), text.length() - match.get_end())

	text = rx_whitespace.sub(text, "", true)
	return Message.new(text)

func _validate() -> PennyException:
	match tokens.size():
		1:
			if tokens[0].type != Token.VALUE_STRING:
				return create_exception("Message statements must contain a string.")
		2:
			if tokens[0].type != Token.IDENTIFIER:
				return create_exception("Message statements must start with an object identifier.")
			if tokens[1].type != Token.VALUE_STRING:
				return create_exception("Message statements must contain a string.")
		_:
			return create_exception("Unexpected token '%s'" % tokens[2])
	return null
