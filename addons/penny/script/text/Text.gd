## A single translation of text ready to be passed to a [RichTextLabel].
@tool
extends Resource

const Filter := preload("res://addons/penny/script/text/Filter.gd")
const Tag := preload("res://addons/penny/script/text/Tag.gd")

@export_storage
var text: String

## List of indeces in [member text] where we should push or pop tags.
@export_storage
var tags: Tag.Stack


func _init(__text__: String = "") -> void:
	text = __text__
	tags = Tag.Stack.new()


func _to_string() -> String:
	return text


func print_with_tags() -> void:
	var result := text
	for tag in tags:
		result += str(tag)

	print("‹ %s ›" % result)


func push_to_rich_text_label(rtl: RichTextLabel) -> void:
	var decoration_context := DecorationContext.new(self, rtl, null)
	decoration_context.process()


class DecorationContext \
extends RefCounted:
	var text : Penny.Text
	var rtl : RichTextLabel
	var all_tags: Tag.Stack
	var open_tags: Tag.Stack
	var current_tag: Tag
	var object_context

	func _init(__text__: Penny.Text, __rtl__: RichTextLabel, __object_context__) -> void:
		text = __text__
		rtl = __rtl__
		all_tags = text.tags.duplicate_deep()
		open_tags = Tag.Stack.new()
		object_context = __object_context__

		for tag in all_tags:
			for inst in tag:
				inst.owner = tag


	func process() -> void:
		preprocess()
		build()


	func preprocess() -> void:
		current_tag = null
		open_tags.clear()
		var i := 0
		while i < all_tags.size():
			current_tag = all_tags.list[i]

			match current_tag.mode:
				Tag.MODE_PUSH:
					var tag := Tag.new(current_tag.position, Tag.MODE_PUSH)
					var is_open : bool = current_tag.instances.is_empty()

					for inst in current_tag:
						if inst.template.closable:
							is_open = true
						tag.push(inst, false)
						inst.preprocess_start(self)

					if is_open:
						open_tags.push(tag)


				Tag.MODE_POP when current_tag.implicit:
					if open_tags.is_empty():
						continue

					for inst in open_tags.pop():
						inst.preprocess_end(self)


				Tag.MODE_POP:
					var popped_inst_tags : Dictionary[PennyDecorationInstance, Penny.Text.Tag] = {}

					for inst in current_tag:
						var found_popped_inst: bool = false
						for j in open_tags.size():
							for open_inst in open_tags.list[-j-1]:
								if inst.id == open_inst.id:
									popped_inst_tags[open_inst] = open_tags.list[-j-1]
									found_popped_inst = true
									break
							if found_popped_inst:
								break

					for inst in popped_inst_tags:
						popped_inst_tags[inst].instances.erase(inst)
						if popped_inst_tags[inst].instances.is_empty():
							open_tags.erase(popped_inst_tags[inst])

						inst.preprocess_end(self)


				Tag.MODE_CLEAR:
					for tag in open_tags:
						for inst in tag:
							inst.preprocess_end(self)

					open_tags.clear()

				_:
					assert(false, "Unimplemented tag mode '%s'." % current_tag.mode)

			i += 1

		current_tag = null



	func build() -> void:
		var string_idx := 0
		rtl.text = String()
		rtl.push_context()

		current_tag = null
		open_tags.clear()
		var string_position := 0
		var i := 0
		while i < all_tags.size():

			current_tag = all_tags.list[i]
			var update_rtl_context: bool = false

			if current_tag.position - string_position > 0:
				rtl.add_text(text.text.substr(string_position, current_tag.position - string_position))
			string_position = current_tag.position

			match current_tag.mode:
				Tag.MODE_PUSH:
					var tag := Tag.new(current_tag.position, Tag.MODE_PUSH)
					var is_open : bool = tag.instances.is_empty()
					for inst in current_tag:
						tag.push(inst, false)
						if inst.template.closable:
							is_open = true

						if inst.require_rtl_context:
							update_rtl_context = true

					if is_open:
						open_tags.push(tag)


				Tag.MODE_POP when current_tag.implicit:
					if open_tags.is_empty():
						continue

					for inst in open_tags.pop():
						inst.pop_to_rtl(self)
						if inst.require_rtl_context:
							update_rtl_context = true


				Tag.MODE_POP:
					var popped_inst_tags : Dictionary[PennyDecorationInstance, Penny.Text.Tag] = {}

					for inst in current_tag:
						var found_popped_inst: bool = false
						for j in open_tags.size():
							for open_inst in open_tags.list[-j-1]:
								if inst.id == open_inst.id:
									popped_inst_tags[open_inst] = open_tags.list[-j-1]
									found_popped_inst = true
									break
							if found_popped_inst:
								break

					for inst in popped_inst_tags:
						popped_inst_tags[inst].instances.erase(inst)
						if popped_inst_tags[inst].instances.is_empty():
							open_tags.erase(popped_inst_tags[inst])

						inst.pop_to_rtl(self)
						if inst.require_rtl_context:
							update_rtl_context = true


				Tag.MODE_CLEAR:
					for tag in open_tags:
						for inst in tag:
							inst.pop_to_rtl(self)
							if inst.require_rtl_context:
								update_rtl_context = true

					open_tags.clear()

				_:
					assert(false, "Unimplemented tag mode '%s'." % current_tag.mode)

			if update_rtl_context:
				rtl.pop_context()
				rtl.push_context()

			for tag in open_tags:
				for inst: PennyDecorationInstance in current_tag:
					inst.push_to_rtl(self)

			i += 1

		current_tag = null

		if string_position < text.text.length():
			rtl.add_text(text.text.substr(string_position))

		rtl.pop_context()
