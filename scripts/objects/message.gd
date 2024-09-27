
## Displayable text capable of producing decorations.
class_name Message extends Object

static var RX_DEPTH_REMOVAL_PATTERN := "(?<=\\n)\\t{0,%s}"
static var RX_INTERPOLATION := RegEx.create_from_string("\\[.+\\]")

var pure : String
var text : String

func _init(from: Record) -> void:
	pure = from.statement.to_string()
	match from.statement.type:
		Statement.MESSAGE:
			text = from.statement.tokens[0].raw

			var rx_whitespace = RegEx.create_from_string(RX_DEPTH_REMOVAL_PATTERN % from.statement.depth)

			while true:
				var match := RX_INTERPOLATION.search(text)
				if not match : break

				var expr_string = match.get_string()
				expr_string = expr_string.substr(1, expr_string.length() - 2)

				var parser = PennyParser.new(expr_string)
				parser.parse_tokens()
				var result = from.host.evaluate_expression(parser.tokens)
				var result_string := convert_to_string(result)

				text = text.substr(0, match.get_start()) + result_string + text.substr(match.get_end(), text.length() - match.get_end())

			text = rx_whitespace.sub(text, "", true)
		Statement.PRINT:
			text = from.statement.tokens[0].raw
		Statement.ASSIGN:
			text = from.attachment.to_string()
		_:
			text = pure
			match from.statement.type:
				Statement.CONDITION_IF, Statement.CONDITION_ELIF, Statement.CONDITION_ELSE:
					var wrapper : String
					if from.attachment:
						wrapper = "%s (TRUE)"
					else:
						wrapper = "[s]%s (FALSE)[/s]"
					text = wrapper % text
	text = "[p align=fill jst=w,k,sl]" + text

static func convert_to_string(x: Variant) -> String:
	match x:
		null: return "NULL"
		true: return "TRUE"
		false: return "FALSE"
	return x.to_string()
