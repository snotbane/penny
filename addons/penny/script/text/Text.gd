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


func push_to_rich_text_label(rtl: RichTextLabel, wait : bool = true):
	var decoration_context := DecorationContext.new(self, rtl, null)
	decoration_context.process()

	if rtl is TypewriterTextLabel:
		if wait:
			await rtl.present(self)
		else:
			rtl.present(self)


class DecorationContext \
extends RefCounted:
	var text : Penny.Text
	var rtl : RichTextLabel
	var current_tag: Tag
	var object_context

	func _init(__text__: Penny.Text, __rtl__: RichTextLabel, __object_context__) -> void:
		text = __text__
		rtl = __rtl__
		object_context = __object_context__

		for tag in text.tags:
			for inst in tag:
				inst.owner = tag


	func process() -> void:
		preprocess()
		build()


	func preprocess() -> void:
		current_tag = null
		var i := 0
		while i < text.tags.size():
			current_tag = text.tags.list[i]

			## Duplicate the instances here so that if the tag list changes, it won't lose track. This does mean that preprocessors will need to handle preprocessing any additional instances created.
			match current_tag.mode:
				Tag.MODE_PUSH:
					for inst in current_tag.instances.duplicate():
						inst.compile_env(rtl)
						inst.preprocess_start(self)

				Tag.MODE_PUSH_POP:
					for inst in current_tag.instances.duplicate():
						inst.compile_env(rtl)
						inst.preprocess_start(self)
						inst.preprocess_end(self)

				Tag.MODE_POP:
					for inst in current_tag.instances.duplicate():
						# inst.compile_env(rtl)
						inst.preprocess_end(self)

				_:
					assert(false, "Unimplemented tag mode '%s'." % current_tag.mode)

			i += 1

		current_tag = null



	func build() -> void:
		var string_idx := 0
		rtl.text = ""
		rtl.push_context()

		current_tag = null
		var open_tag : Tag = Tag.new(-1, Tag.MODE_PUSH)
		var open_insts : Array[PennyDecorationInstance] = []
		var string_position := 0
		var i := 0
		while i < text.tags.size():

			current_tag = text.tags.list[i]

			if current_tag.position - string_position > 0:
				rtl.add_text(text.text.substr(string_position, current_tag.position - string_position))
			string_position = current_tag.position

			match current_tag.mode:
				Tag.MODE_PUSH:
					for inst in current_tag:
						if inst.template.get_closable():
							open_tag.push_back(inst.duplicate())
							open_insts.push_back(inst)
						inst.build_start(self)

				Tag.MODE_PUSH_POP:
					for inst in current_tag:
						inst.build_start(self)
						inst.build_end(self)

				Tag.MODE_POP:
					var update_rtl_context: bool = false
					for inst in current_tag:
						inst.build_end(self)

						for j in open_tag.instances.size():
							if inst.is_match(open_tag.instances[-j-1]):
								open_tag.instances.remove_at(-j-1)
								break

						if not update_rtl_context and inst.require_rtl_context:
							update_rtl_context = true
							rtl.pop_context()
							rtl.push_context()

					if open_tag.instances:
						open_tag.position = current_tag.position
						text.tags.list.insert(i + 1, open_tag)
						i += 1

						for inst in open_tag:
							inst.compile_env(rtl)
							inst.build_start(self)

						open_tag = open_tag.duplicate_instances()

				_:
					assert(false, "Unimplemented tag mode '%s'." % current_tag.mode)

			i += 1

		current_tag = null

		# print("Tags ::")
		# for tag in text.tags:
		# 	print("\t%s ::" % tag.position)
		# 	for inst in tag:
		# 		print("\t\t%s :: %s :: %s" % [inst.owner.position, inst.get_instance_id(), inst])


		if string_position < text.text.length():
			rtl.add_text(text.text.substr(string_position))

		rtl.pop_context()
