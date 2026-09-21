## A written record of events that take place. This is integral to [PennyPlayer] execution, and can also be used to save and load the state of a story.
@icon("res://addons/penny/icons/notepad.svg")
extends Resource

@export_storage var call_stack: Array[Stmt]

@export_storage var records: Array

@export_storage var cursor: Penny.Record:
	set(value):
		assert(value in records, "Cannot set cursor to a record that does not exist in the ledger.")

		cursor = value


## Returns true if the cursor is at the end of the records list.
var cursor_is_tail: bool:
	get: return cursor == null or records.is_empty() or cursor == records[-1]


## Returns the most recent [Penny.Record] whose [member Penny.Record.stmt] is a [StmtSay].
var most_recent_dialog: Penny.Cell:
	get:
		for i in records.size():
			if records[-i-1].stmt is StmtSay:
				return records[-i-1].data.dialog

		return null


func add_record(record: Penny.Record) -> void:
	records.push_back(record)


func cull_records_beyond_cursor() -> void:
	pass


func clear_call_stack() -> void:
	call_stack.clear()


func push_call(stmt: Stmt) -> void:
	call_stack.push_back(stmt)


func pop_call() -> Stmt:
	return call_stack.pop_back()


## For future use in time travel.
func add_divergence_at_cursor(record: Penny.Record) -> void:
	var idx := records.find(cursor)
	records[idx] = [ records[idx], record ]


func find_recent_record_from_stmt(stmt: Stmt) -> Penny.Record:
	for i in records.size():
		if records[-i-1].stmt == stmt:
			return records[-i-1]

	return null


func find_recent_interface_from_key(key: StringName, fetch: int = 0) -> Penny.Cell:
	for i in records.size():
		if records[-i-1].stmt is not StmtNodeInterface:
			continue

		## This is another way of checking whether we're talking about StmtSay or StmtAsk, but it's a little more comprehensive in case there are any other types.
		if records[-i-1].data.interface_key != key:
			continue
			# ## This can be used to control exactly which interface is returned.
			# match fetch:
			# 	0: break
			# 	1: pass
			# 	2: continue
			# 	_:
			# 		assert(false, "Unimplemented fetch mode.")
			# 		break

		return records[-i-1].data.interface

	return null
