
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

static var deco_registry := preload("res://addons/penny_godot/assets/penny_decos_default.tres")
static var scripts : Array[PennyScript]
static var labels : Dictionary			## StringName : Stmt
static var inits : Array[StmtInit]
static var valid : bool = true

static var active_dock : PennyDock:
	get:
		# if PennyPlugin.inst:
		# 	return PennyPlugin.inst.dock
		return PennyDock.inst


# static func _static_init() -> void:
#	## This doesn't work because the resources need to be *pre*loaded
# 	var deco_registry_resources : Array[PennyDecoRegistry]
# 	var tres_paths := Utils.get_paths_in_project(".tres", Utils.OMIT_FILE_SEARCH_INCLUDE_ADDONS)
# 	for tres_path in tres_paths:
# 		var tres : Resource = load(tres_path)
# 		if tres is PennyDecoRegistry:
# 			deco_registry_resources.push_back(tres)


static func clear_all() -> void:
	valid = true
	scripts.clear()
	labels.clear()


static func import_scripts(_scripts: Array[PennyScript]) -> void:
	scripts = _scripts


static func validate() -> Array[PennyException]:
	var result : Array[PennyException] = []

	labels.clear()

	for script in scripts:
		for stmt in script.stmts:
			var e := stmt.validate_cross()
			if e:
				result.push_back(e)
	return result


static func load() -> void:
	inits.sort_custom(stmt_init_sort)


static func get_stmt_from_label(label: StringName) -> Stmt:
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
	if PennyDebug.inst:
		PennyDebug.inst.visible = true


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
		return value.name
	elif value is String:
		return "\"%s\"" % value
	return str(value)


static func stmt_init_sort(a: StmtInit, b: StmtInit) -> bool:
	return a.order >= b.order
