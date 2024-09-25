
## Environment for all Penny runtime data. This is a singleton and all data is static as it comes from the penny scripts. It simply represents the Penny code in workable object form.
class_name Penny extends Object

static var statements : Dictionary		## StringName : Array[Statement]
static var labels : Dictionary			## StringName : Address
static var valid : bool = true
static var clean : bool = true

static func clear_all() -> void:
	valid = true
	statements.clear()
	labels.clear()

static func clear(path: StringName) -> void:
	statements.erase(path)

static func import_statements(path: StringName, _statements: Array[Statement]) -> void:
	statements[path] = _statements

	clean = false

static func reload_labels() -> void:
	## Assign labels
	var i := -1
	for path in statements.keys():
		for stmt in statements[path]:
			i += 1
			if stmt.type == Statement.LABEL:
				if labels.has(stmt.tokens[1].value):
					printerr("Label %s already exists (this check should be moved to the parser validations)" % stmt.tokens[1])
				labels[stmt.tokens[1].value] = Address.new(path, i)
	clean = true

static func get_address_from_label(label: StringName) -> Address:
	if labels.has(label):
		return labels[label]
	else:
		printerr("Label '%s' does not exist in the current Penny environment." % label)
		return null

static func get_statement_from(address: Address) -> Statement:
	if address.index < statements[address.path].size():
		return statements[address.path][address.index]
	return null

# static func get_roll_back_address_from(address: Address) -> Statement:
