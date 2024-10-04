
## Environment for all Penny runtime data. This is a singleton and all data is static as it comes from the penny scripts. It simply represents the Penny code in workable object form.
class_name Penny extends Object

static var stmt_dict : Dictionary		## StringName : Array[Stmt]
static var labels : Dictionary			## StringName : Address
static var valid : bool = true
static var clean : bool = true

static func clear_all() -> void:
	valid = true
	stmt_dict.clear()
	labels.clear()

static func clear(path: StringName) -> void:
	stmt_dict.erase(path)

static func import_statements(path: StringName, _statements: Array[Stmt]) -> void:
	stmt_dict[path] = _statements

	clean = false

static func load() -> void:
	if not valid:
		printerr("Penny.valid == false; aborting Penny.load()")
		return

	labels.clear()

	var i := -1
	for path in stmt_dict.keys():
		i = -1
		for stmt in stmt_dict[path]:
			i += 1
			stmt.address = Address.new(path, i)
			stmt._load()

static func get_address_from_label(label: StringName) -> Address:
	if labels.has(label):
		return labels[label]
	else:
		printerr("Label '%s' does not exist in the current Penny environment." % label)
		return null

static func get_statement_from(address: Address) -> Stmt:
	if address.index < stmt_dict[address.path].size():
		return stmt_dict[address.path][address.index]
	return null
