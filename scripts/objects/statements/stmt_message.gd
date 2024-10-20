
@tool
class_name StmtMessage extends Stmt_

const REGEX_DEPTH_REMOVAL_PATTERN := "(?<=\\n)\\t{0,%s}"
static var REGEX_INTERPOLATION := RegEx.create_from_string("(?<!\\\\)(@([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)|\\[(.*?)\\])")
static var REGEX_INTERJECTION := RegEx.create_from_string("(?<!\\\\)(\\{.*?\\})")
static var REGEX_DECORATION := RegEx.create_from_string("(?<!\\\\)(<.*?>)")
static var REGEX_WORD_COUNT := RegEx.create_from_string("\\b\\S+\\b")
static var REGEX_CHAR_COUNT := RegEx.create_from_string("\\S")

var text_token : Token :
	get:
		return tokens[0]

var text_stripped : String :
	get:
		var result : String = text_token.value
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
	host.message_handler.receive(result)
	return result

func _message(record: Record) -> Message:
	var text : String = tokens[0].value

	var rx_whitespace = RegEx.create_from_string(REGEX_DEPTH_REMOVAL_PATTERN % depth)

	while true:
		var match := REGEX_INTERPOLATION.search(text)
		if not match : break

		var expr_string := match.get_string(2) + match.get_string(3)	## ~= $2$3

		var parser = PennyParser.new(expr_string)
		var exceptions = parser.tokenize()
		if not exceptions.is_empty():
			for i in exceptions:
				i.push()
			break

		var expr := Expr.from_tokens(self, parser.tokens)
		var result = expr.evaluate(record.host)
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
