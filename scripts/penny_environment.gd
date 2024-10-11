
## Environment for all Penny runtime data. This is a singleton and all data is static as it comes from the penny scripts. It simply represents the Penny code in workable object form.
@tool
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

static func get_stmt_from_label(label: StringName) -> Stmt:
	if labels.has(label):
		return labels[label].stmt
	else:
		printerr("Label '%s' does not exist in the current Penny environment." % label)
		return null

static func log(s: String) -> void:
	if PennyPlugin.inst.dock:
		PennyPlugin.inst.dock.log(s)
	else :
		print(s)

static func log_timed(s: String) -> void:
	Penny.log("[%s] %s" % [get_formatted_time(), s])

static func log_clear() -> void:
	if PennyPlugin.inst.dock:
		PennyPlugin.inst.dock.log_clear()

static func log_info() -> void:
	Penny.log("%s files | %s blocks | %s words | %s chars" % get_script_info())

static func get_formatted_time() -> String:
	var time = Time.get_time_dict_from_system()
	return "%s:%s:%s" % [str(time.hour).pad_zeros(2), str(time.minute).pad_zeros(2), str(time.second).pad_zeros(2)]

static func get_script_info() -> Array:
	var files := 0
	var blocks := 0
	var words := 0
	var chars := 0
	var non_whitespace_chars := 0
	for path in stmt_dict.keys():
		files += 1
		for i in stmt_dict[path]:
			if i is	StmtMessage:
				blocks += 1
				words += i.word_count
				chars += i.char_count
				# non_whitespace_chars += i.char_count_non_whitespace
				continue
	return [files, blocks, words, chars]
