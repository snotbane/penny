class_name PennyException

enum {
	PARSE_ERROR_UNCAUGHT_VALIDATION,
	PARSE_ERROR_UNEXPECTED_TOKEN,
	PARSE_ERROR_EXPECTED_EXPRESSION,
	PARSE_ERROR_EXPECTED_IDENTIFIER,
}

static var EXCEPTION_MESSAGES = {
	PARSE_ERROR_UNCAUGHT_VALIDATION: "PARSE_ERROR_UNCAUGHT_VALIDATION: In file '%s': (ln %s), the statement '%s' could not be validated.",
	PARSE_ERROR_UNEXPECTED_TOKEN: "PARSE_ERROR_UNEXPECTED_TOKEN: In file '%s': (%s, %s), an unexpected token '%s' was encountered.",
	PARSE_ERROR_EXPECTED_EXPRESSION: "PARSE_ERROR_EXPECTED_EXPRESSION: In file '%s': (%s, %s), an expression was expected for '%s' but none was found.",
	PARSE_ERROR_EXPECTED_IDENTIFIER: "PARSE_ERROR_EXPECTED_IDENTIFIER: In file '%s': (%s, %s), an identifier was expected for '%s' but none was found.",
}

static var active_file_path : String

static func push_error(code: int, clues: Array = []) -> void:
	var message : String = EXCEPTION_MESSAGES[code]

	if clues[0] is Token:
		var token : Token = clues[0]
		clues.clear()
		clues.append(token.line)
		clues.append(token.col)
		clues.append(token.value)

	if clues[0] is Statement:
		var statement : Statement = clues[0]
		clues.clear()
		clues.append(statement.line)
		clues.append(statement.to_string())

	if code < 10:
		clues.push_front(active_file_path)


	message = message % clues

	printerr(message)
	# push_error(message)
