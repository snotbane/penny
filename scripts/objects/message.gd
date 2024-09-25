
## Displayable text capable of producing decorations.
class_name Message extends Object

static var RX_DEPTH_REMOVAL_PATTERN = "(?<=\\n)\\t{0,%s}"

var text: String

func _init(from: Statement) -> void:
	match from.type:
		Statement.MESSAGE:
			var raw = from.tokens[0].value

			var rx_whitespace = RegEx.create_from_string(RX_DEPTH_REMOVAL_PATTERN % from.depth)

			text = rx_whitespace.sub(raw, "", true)
			text = "[p align=fill jst=w,k,sl]" + text
		Statement.PRINT:
			text = from.tokens[0].value
		Statement.LABEL:
			text = "label " + from.tokens[0].value

func hash() -> int:
	return text.hash()
