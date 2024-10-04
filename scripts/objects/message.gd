
## Displayable text capable of producing decorations.
class_name Message extends Object

const RX_DEPTH_REMOVAL_PATTERN := "(?<=\\n)\\t{0,%s}"
static var RX_INTERPOLATION := RegEx.create_from_string("\\[.+\\]")

var pure : String
var text : String

func _init(_pure: String) -> void:
	pure = _pure
	text = "[p align=fill jst=w,k,sl]" + pure
