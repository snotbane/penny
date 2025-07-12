extends RichTextEffect

var bbcode = "example"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color = Color.BLUE
	return true
