## A localized representation of a script, parsed into elements the engine can understand.
@icon("res://addons/penny/icons/book_open.svg")
@tool
class_name PennyScript
extends Resource

const MessageParser := preload("res://addons/penny/script/parse/MessageParser.gd")
const PennyParser := preload("res://addons/penny/script/parse/PennyParser.gd")
const Token := preload("res://addons/penny/script/parse/Token.gd")


@export_storage
var safe_path: String

@export_storage
var label_addresses: Dictionary[StringName, Stmt]

@export_storage
var stmts: Array[Stmt] = []

@export_storage
var errors: PackedStringArray


# func _init() -> void:
# 	_ready.call_deferred()


## Called when the script is refreshed in the editor or when [Penny] is initialized.
func _ready() -> void:
	for i in stmts.size():
		stmts[i].ready(self, i)

	for label in label_addresses:
		Penny.add_label(label, self)


func _sunset() -> void:
	for label in label_addresses:
		Penny.LABEL_SCRIPTS.erase(label)


func print_labels() -> void:
	for label in label_addresses:
		print("%s :: %s" % [
			label,
			label_addresses[label],
		])


func print_errors() -> void:
	for error in errors:
		printerr(error)


func print_stmts(token_groups = []) -> void:
	for i in stmts.size():
		var is_valid := stmts[i] != null
		var print_text := str(stmts[i] if is_valid else "Stmt :: null")

		if i > 0:
			print_text += "\n{"
			for token in token_groups[i - 1]:
				print_text += "\n\t%s" % token
			print_text += "\n}"

		if is_valid:
			print(print_text)
		else:
			printerr(print_text)


func raise_error(error: String) -> void:
	errors.push_back(error)


func find_label_local(label: StringName) -> Stmt:
	return label_addresses.get(label)


func add_label(label: StringName, address: Stmt) -> void:
	if Penny.LABEL_SCRIPTS.has(label):
		raise_error("Label '%s' already exists in script '%s'." % [
			label,
			Penny.LABEL_SCRIPTS[label].resource_path,
		])

	label_addresses[label] = address
	Penny.add_label(label, self)
