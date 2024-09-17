
## Environment for all Penny runtime data. This is a singleton and all data is static as it comes from the penny scripts and save files.
class_name Penny extends Object

class Address:
	var path : String

	var _index : int
	var index : int :
		get: return _index
		set (value):
			_index = max(value, 0)

	func _init(__path: String, __index: int) -> void:
		path = __path
		index = __index

	func _to_string() -> String:
		return "%s:%s" % [path, index]

static var statements : Dictionary		## String : Statement
static var labels : Dictionary			## StringName : Address
static var valid : bool = true

static func clear() -> void:
	valid = true
	statements.clear()
	labels.clear()

static func import_statements(path: String, _statements: Array[PennyParser.Statement]) -> void:
	statements[path] = _statements

	## Assign labels
	var i := -1
	for stmt in _statements:
		i += 1
		if stmt.type == PennyParser.Statement.LABEL:
			if labels.has(stmt.tokens[1].value):
				printerr("Label %s already exists (this check should be moved to the parser validations)" % stmt.tokens[1])
			labels[stmt.tokens[1].value] = Address.new(path, i)

static func get_address_from_label(label: StringName) -> Address:
	if labels.has(label):
		return labels[label]
	else:
		printerr("Label '%s' does not exist in the current Penny environment." % label)
		return null

static func get_statement_from(address: Address) -> PennyParser.Statement:
	if address.index < statements[address.path].size():
		return statements[address.path][address.index]
	return null

static func get_next_address_from(address: Address) -> PennyParser.Statement:
	return statements[address.path][address.index + 1]

# static func get_roll_back_address_from(address: Address) -> PennyParser.Statement:
