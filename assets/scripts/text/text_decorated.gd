
class_name DecoratedText extends Text

var decos : Array[DecoInst]

static func from_raw(raw: String, _context := Cell.ROOT) -> DecoratedText:
	return Text.new(raw)
	# var filtered := FilteredText.from_raw(raw, _context)
	# return DecoratedText.from_filtered(filtered, _context)