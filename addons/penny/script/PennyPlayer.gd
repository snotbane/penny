## Hosts an instance of penny for the end user to experience. Generates a [Penny.Ledger].
@icon("res://addons/penny/icons/glasses.svg")
class_name PennyPlayer
extends Node

signal drawn(record: Penny.Record)

## Emits when execution ends due to running out of [Stmt]s to travel to, or if 'exit' is called directly.
signal exited(value: Variant)

## The label to jump_label playback at.
@export
var start_label: StringName

## If enabled, playback will begin on [member ready].
@export
var autostart: bool
@export
var debug_enabled: bool = false

var hoist_mode: bool = false

func _init(__hoist_mode__: bool = false) -> void:
	ledger = Penny.Ledger.new()
	hoist_mode = __hoist_mode__


func _ready() -> void:
	if autostart:
		play_from_start.call_deferred()


func play_from_start() -> void:
	create_execute(Penny.find_label(start_label))


## Start from the specified label, or if unspecified, resume where suspended, or from [member start_label].
func play(at_label: StringName = &"") -> void:
	if at_label:
		create_execute(Penny.find_label(at_label))
	elif ledger.records[-1].next:
		create_execute(ledger.records[-1].next)
	elif ledger.call_stack:
		create_execute(ledger.pop_call())
	else:
		play_from_start()


var ledger: Penny.Ledger

## Creates a new record from the provided [Stmt] and then executes it.
func create_execute(stmt: Stmt):
	if stmt == null:
		exit()
		return

	var result: Penny.Record = stmt.draw(self)
	assert(
		result != null,
		"Stmt cannot draw a null Record."
	)
	ledger.add_record(result)
	drawn.emit(result)

	await execute(result)
	return result


func execute(record: Penny.Record):
	ledger.cursor = record

	var response: int
	if hoist_mode == (ledger.cursor.stmt.hoist != Stmt.HOIST_NONE):
		if debug_enabled and OS.is_debug_build():
			print_rich("[color=%s][lb] [color=%s]%s[/color] [rb] %s" % [
				"ffffff40",
				Color.DEEP_SKY_BLUE.to_html(false),
				name,
				record
			])
		response = await ledger.cursor.execute(self)
	else:
		response = Stmt.EXECUTE_RESPONSE_SKIPPED

	match response:
		Stmt.EXECUTE_RESPONSE_SKIPPED, \
		Stmt.EXECUTE_RESPONSE_FINISHED:
			pass

		_: return

	if false: ## force_cull_history
		ledger.cull_records_beyond_cursor()
		assert(ledger.cursor_is_tail)

	if record.stmt is StmtExit:
		exit()
		return

	if ledger.cursor_is_tail:
		record.next = record.stmt.next(self, record)
		if record.next == null:
			record.next = ledger.pop_call()

	if record.stmt is StmtSuspend:
		exit()
	else:
		create_execute(record.next)


func exit() -> void:
	_exited()
	exited.emit()

func _exited() -> void:
	pass
