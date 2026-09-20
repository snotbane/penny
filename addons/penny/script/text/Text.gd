## A single translation of text ready to be passed to a [RichTextLabel].
@tool
extends Resource

const Filter := preload("res://addons/penny/script/text/Filter.gd")
const Decor := preload("res://addons/penny/script/text/Decor.gd")
const DecInst := preload("res://addons/penny/script/text/DecInst.gd")
const Tag := preload("res://addons/penny/script/text/Tag.gd")

@export_storage
var text: String

## List of indeces in [member text] where we should push or pop tags.
@export_storage
var tags: Dictionary[int, Tag]


func _init(__text__: String = "") -> void:
	text = __text__


func _to_string() -> String:
	return text


func print_with_tags() -> void:
	var result := text
	for k in tags:
		result += str(tags[k])

	print("‹ %s ›" % result)


func push_to_rich_text_label(rtl: RichTextLabel) -> void:
	rtl.clear()
	rtl.add_text(text)

	## Do this for each tag
	# rtl.push_context()
	#
	## Do this for each arg
	# rtl.push_whatever()
	#
	# rtl.pop_context()
