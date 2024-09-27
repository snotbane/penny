
## Displayable text capable of producing decorations.
class_name Message extends Object

static var RX_DEPTH_REMOVAL_PATTERN = "(?<=\\n)\\t{0,%s}"

var pure : String
var text : String

func _init(from: Record) -> void:
	pure = from.statement.to_string()
	match from.statement.type:
		Statement.MESSAGE:
			var rx_whitespace = RegEx.create_from_string(RX_DEPTH_REMOVAL_PATTERN % from.statement.depth)

			text = rx_whitespace.sub(from.statement.tokens[0].raw, "", true)
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

func hash() -> int:
	return text.hash()
