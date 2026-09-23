## A single translation of text ready to be passed to a [RichTextLabel].
@tool
extends Resource

const Filter := preload("res://addons/penny/script/text/Filter.gd")
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


func add_tag(tag: Tag, idx: int) -> void:
	if tag == null: return

	tags[idx] = tag


func print_with_tags() -> void:
	var result := text
	for k in tags:
		result += str(tags[k])

	print("‹ %s ›" % result)


func push_to_rich_text_label(rtl: RichTextLabel) -> void:
	var decoration_context := DecorationContext.new(self, rtl)
	decoration_context.process()


class DecorationContext \
extends RefCounted:
	var text : Penny.Text
	var rtl : RichTextLabel
	var tag_stack: Array

	func _init(__text__: Penny.Text, __rtl__: RichTextLabel) -> void:
		text = __text__
		rtl = __rtl__
		tag_stack = []


	func process() -> void:
		# rtl.text = text.text
		# return

		rtl.text = String()
		rtl.push_context()

		var string_idx := 0

		# print("text.tags :: %s" % [ text.tags ])
		tag_stack.clear()
		## For each tag in the message...
		for tag_idx: int in text.tags:
			# print("\ntag_stack :: %s" % [ tag_stack ])

			## Add text from the last position, up to the current tag.
			if tag_idx - string_idx > 0:
				rtl.add_text(text.text.substr(string_idx, tag_idx - string_idx))
			string_idx = tag_idx

			var must_update_context: bool = false
			var current_tag : Tag = text.tags[tag_idx]
			# print("current_tag :: %s" % [ current_tag ])

			match current_tag.mode:
				Tag.MODE_PUSH:
					var tag := []
					tag_stack.push_back(tag)
					for inst in current_tag.instances:
						# print("pushing decoration :: <%s>" % [ inst.id ])
						tag.push_back(inst)
						if inst.require_rtl_context:
							must_update_context = true

				Tag.MODE_POP:
					## If this is an explicit end tag...
					if current_tag.instances:
						var popped_inst_tags := {}

						for inst in current_tag.instances:
							var found_popped_inst: bool = false
							var tags_to_delete := []

							for i in tag_stack.size():
								for stack_inst: PennyDecorationInstance in tag_stack[-i-1]:
									if inst.id == stack_inst.id:
										popped_inst_tags[stack_inst] = tag_stack[-i-1]
										found_popped_inst = true
										break

								if found_popped_inst:
									break

						## Pop all instances found in previous tags, and remove any tags that are now empty.
						for inst: PennyDecorationInstance in popped_inst_tags:
							# print("popping decoration :: </%s>" % [ inst.id ])
							popped_inst_tags[inst].erase(inst)
							if popped_inst_tags[inst].is_empty():
								tag_stack.erase(popped_inst_tags[inst])

							if inst.require_rtl_context:
								must_update_context = true

							inst.pop_to_rtl(rtl)

					## If this is an implicit end tag...
					else:
						if tag_stack.is_empty():
							continue

						## Pop all instances in the most recent tag. Simple.
						for inst: PennyDecorationInstance in tag_stack.pop_back():
							# print("popping decoration :: </%s>" % [ inst.id ])
							if inst.require_rtl_context:
								must_update_context = true

							inst.pop_to_rtl(rtl)

				Tag.MODE_CLEAR:
					must_update_context = true
					for tag in tag_stack:
						for inst: PennyDecorationInstance in tag:
							inst.pop_to_rtl(rtl)

					tag_stack.clear()

				_:
					assert(false, "Unimplemented Penny.Text.Tag mode '%s'." % current_tag.mode)

			if must_update_context:
				rtl.pop_context()
				rtl.push_context()

			for tag in tag_stack:
				for inst: PennyDecorationInstance in tag:
					inst.push_to_rtl(rtl)

		# print("\ntag_stack :: %s" % [ tag_stack ])

		## Add any remaining text not bound by any end tags to the string.
		if string_idx < text.text.length():
			rtl.add_text(text.text.substr(string_idx))

		rtl.pop_context()
