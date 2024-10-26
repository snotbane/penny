
## Environment for all Penny runtime data. This is a singleton and all data is static as it comes from the penny scripts. It simply represents the Penny code in workable object form.
@tool
class_name Penny extends Object

const DEFAULT_COLOR = Color.LIGHT_GRAY
const IDENTIFIER_COLOR = Color.PERU
const FUTURE_COLOR = Color.DODGER_BLUE
const HAPPY_COLOR = Color.LAWN_GREEN
const ANGRY_COLOR = Color.DEEP_PINK
const WARNING_COLOR = Color(1, 0.871, 0.4)	## Matches editor
const ERROR_COLOR = Color(1, 0.471, 0.42)	## Matches editor

static var stmt_dict : Dictionary		## StringName : Array[Stmt_]
static var labels : Dictionary			## StringName : Stmt_
static var inits : Array[StmtInit]
static var valid : bool = true
static var clean : bool = true

static var active_dock : PennyDock:
	get:
		if PennyPlugin.inst:
			return PennyPlugin.inst.dock
		return PennyDock.inst

static func clear_all() -> void:
	valid = true
	stmt_dict.clear()
	labels.clear()

static func clear(path: StringName) -> void:
	stmt_dict.erase(path)

static func import_statements(path: StringName, _statements: Array[Stmt_]) -> void:
	stmt_dict[path] = _statements

	clean = false

static func validate() -> Array[PennyException]:
	var result : Array[PennyException] = []

	labels.clear()

	var i := -1
	for path in stmt_dict.keys():
		i = -1
		for stmt in stmt_dict[path]:
			i += 1
			stmt.address = Stmt_.Address.new(path, i)
			var exception = stmt.load()
			if exception:
				result.push_back(exception)

	return result

static func load() -> void:
	inits.sort_custom(stmt_init_sort)

	for host in PennyHost.insts:
		host.reload()


static func get_stmt_from_label(label: StringName) -> Stmt_:
	if labels.has(label):
		return labels[label]
	else:
		PennyException.new("Label '%s' does not exist in the current Penny environment." % label).push()
		return null

static func log(s: String, c: Color = DEFAULT_COLOR) -> void:
	if active_dock:
		active_dock.log(s, c)

static func log_error(s: String, c: Color = ERROR_COLOR) -> void:
	Penny.log(s, c)
	push_error(s)

static func log_clear() -> void:
	if active_dock:
		active_dock.log_clear()

static func log_timed(s: String, c: Color = DEFAULT_COLOR) -> void:
	Penny.log("[%s] %s" % [get_formatted_time(), s], c)

static func log_info() -> void:
	Penny.log("%s files / %s blocks / %s words / %s chars" % get_script_info())

static func get_formatted_time() -> String:
	var time = Time.get_time_dict_from_system()
	return "%s:%s:%s" % [str(time.hour).pad_zeros(2), str(time.minute).pad_zeros(2), str(time.second).pad_zeros(2)]

static func get_script_info() -> Array:
	var files := 0
	var blocks := 0
	var words := 0
	var chars := 0
	# var non_whitespace_chars := 0
	for path in stmt_dict.keys():
		files += 1
		for i in stmt_dict[path]:
			if i is	StmtDialog:
				blocks += 1
				words += i.word_count
				chars += i.char_count
				# non_whitespace_chars += i.char_count_non_whitespace
				continue
	return [files, blocks, words, chars]

static func get_debug_string(value: Variant) -> String:
	if value is PennyObject:
		return value.name
	elif value is String:
		return "\"%s\"" % value
	return str(value)


static func stmt_init_sort(a: StmtInit, b: StmtInit) -> bool:
	return a.order >= b.order
