
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

static var scripts : Array[PennyScript]
static var labels : Dictionary			## StringName : Stmt
static var inits : Array[StmtInit]
static var valid : bool = true

static var active_dock : PennyDock:
	get:
		# if PennyPlugin.inst:
		# 	return PennyPlugin.inst.dock
		return PennyDock.inst


func _init() -> void:
	pass


static func clear_all() -> void:
	valid = true
	scripts.clear()
	labels.clear()


static func find_script_from_path(path: String) -> PennyScript:
	for i in scripts:
		if i.resource_path == path:
			return i
	return null


static func import_scripts(_scripts: Array[PennyScript]) -> void:
	scripts = _scripts


static func refresh() -> Array[PennyException]:
	var result : Array[PennyException] = []

	labels.clear()

	for script in scripts:
		result.append_array(script.parse_exceptions)
		for stmt in script.stmts:
			if stmt is StmtLabel:
				var e := Penny.register_label(stmt)
				if e: result.push_back(e)
	return result


static func register_label(stmt: StmtLabel) -> PennyException:
	if labels.has(stmt.id):
		return stmt.create_exception("Label '%s' already exists in the current Penny environment." % stmt.id)
	labels[stmt.id] = stmt
	return null


static func load() -> void:
	inits.sort_custom(stmt_init_sort)


static func find_stmt_by_hash_id(query: Stmt) -> Stmt:
	var compare_stmt := query.owning_script.stmts[query.index_in_script]
	if query.hash_id == compare_stmt.hash_id:
		return compare_stmt
	return null


static func get_stmt_from_label(label: StringName) -> Stmt:
	if labels.has(label):
		return labels[label]
	else:
		PennyException.new("Label '%s' does not exist in the current Penny environment." % label).push_error()
		return null


static func log(s: String, c: Color = DEFAULT_COLOR) -> void:
	if active_dock:
		active_dock.log(s, c)


static func log_error(s: String, c: Color = ERROR_COLOR) -> void:
	Penny.log(s, c)
	push_error(s)
	if PennyDebug.inst:
		PennyDebug.inst.visible = true


static func log_warn(s: String, c: Color = WARNING_COLOR) -> void:
	Penny.log(s, c)
	push_warning(s)


static func log_clear() -> void:
	if active_dock:
		active_dock.log_clear()


static func log_timed(s: String, c: Color = DEFAULT_COLOR) -> void:
	var full_message := "[%s] %s" % [get_formatted_time(), s]
	Penny.log(full_message, c)
	print(full_message)


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
	for scr in scripts:
		files += 1
		for stmt in scr.stmts:
			if stmt is	StmtDialog:
				blocks += 1
				words += stmt.word_count
				chars += stmt.char_count
				# non_whitespace_chars += i.char_count_non_whitespace
				continue
	return [files, blocks, words, chars]


static func get_debug_string(value: Variant) -> String:
	if value is PennyObject:
		return value.self_key
	elif value is String:
		return "\"%s\"" % value
	elif value is Color:
		return "#" + value.to_html()
	return str(value)


static func stmt_init_sort(a: StmtInit, b: StmtInit) -> bool:
	return a.order < b.order
