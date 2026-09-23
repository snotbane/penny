## Hosts general functionality for Penny.
@icon("res://addons/penny/icons/feather.svg")
@tool
class_name Penny
extends Node

const RECOGNIZED_EXTENSIONS := [
	"pen",
	"penny",
]

const Async := preload("res://addons/penny/script/Async.gd")
const Cell := preload("res://addons/penny/script/Cell.gd")
const Evaluable := preload("res://addons/penny/script/evaluable/Evaluable.gd")
const Express := preload("res://addons/penny/script/evaluable/Express.gd")
const Ledger := preload("res://addons/penny/script/Ledger.gd")
const Path := preload("res://addons/penny/script/evaluable/Path.gd")
const Record := preload("res://addons/penny/script/Record.gd")

const Text := preload("res://addons/penny/script/text/Text.gd")
const Message := preload("res://addons/penny/script/text/Message.gd")

static var INIT_LEDGER: Penny.Ledger

static var LOADED_SCRIPTS: Array[PennyScript]

static var LABEL_SCRIPTS: Dictionary[StringName, PennyScript]


static func get_paths_in_folder(valid_exts : PackedStringArray = [], root := "res://") -> PackedStringArray:
	assert((func() -> bool:
		for ext in valid_exts:
			if ext.begins_with("."):
				return false
		return true
	).call(),
		"One or more exts contains a dot."
	)

	var dir := DirAccess.open(root)
	if not dir: return []

	var result : PackedStringArray = []
	dir.list_dir_begin()
	var file : String = dir.get_next()
	while file:
		var next := root.path_join(file)
		if dir.current_is_dir():
			result.append_array(get_paths_in_folder(valid_exts, next))
		elif valid_exts.is_empty() or next.get_extension() in valid_exts:
			result.push_back(next)
		file = dir.get_next()
	return result


static func get_git_commit_id(dir: String = "res://") -> String:
	var args := ["rev-parse", "HEAD"]
	if not dir.is_empty():
		args.insert(0, "--git-dir=" + ProjectSettings.globalize_path(dir) + ".git")

	var output := []
	var code = OS.execute("git", args, output)
	return output[0].strip_edges() if code == OK else "Unknown Commit!"


static func load_resource_editor_safe(path: String, type_hint := "") -> Resource:
	return ResourceLoader.load(path, type_hint, (
		ResourceLoader.CacheMode.CACHE_MODE_REUSE
		if OS.has_feature("template")
		else ResourceLoader.CacheMode.CACHE_MODE_REPLACE
	))


static func find_label(label: StringName) -> Stmt:
	var script := LABEL_SCRIPTS.get(label)
	if script == null: return null

	return script.find_label_local(label)


static func add_label(label: StringName, script: PennyScript) -> void:
	LABEL_SCRIPTS[label] = script


func _ready() -> void:
	for path in get_paths_in_folder(RECOGNIZED_EXTENSIONS):
		var script: PennyScript = load_resource_editor_safe(path)
		if script == null:
			printerr("Failed loading script at path: '%s'" % path)
			continue

		LOADED_SCRIPTS.push_back(script)
		script._ready()

	if Engine.is_editor_hint():
		return

	for path in get_paths_in_folder(["tres", "res"], "res://addons/penny/decorations"):
		var decoration: PennyDecoration = load_resource_editor_safe(path)
		if decoration == null:
			printerr("Failed loading decoration at path: '%s'" % path)
			continue

		PennyDecoration.add_decoration_to_registry(decoration)


	var temp_player := PennyPlayer.new(true)
	temp_player.name = "init"
	temp_player.debug_enabled = true
	add_child(temp_player)

	for script in LOADED_SCRIPTS:
		temp_player.create_execute(script.stmts[0])

	INIT_LEDGER = temp_player.ledger

	temp_player.queue_free()
