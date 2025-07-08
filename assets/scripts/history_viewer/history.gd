## Stores the a sequence of Penny commands. When saving a game, this also stores the state of the actors.
class_name History extends JSONResource

class HistoryOld:
	signal record_added(record : Record)
	signal record_removed(record : Record)

	var records : Array[Record]
	var max_size : int = -1

	var most_recent : Record :
		get: return records.front()


	var last_dialog : Record :
		get:
			for record in records:
				if record.stmt is StmtDialog:
					return record
			return null


	func _init(_max_size : int = -1) -> void:
		max_size = _max_size


	func add(record: Record) -> void:
		if max_size >= 0:
			while records.size() >= max_size:
				record_removed.emit(records.pop_back())

		records.push_front(record)
		record_added.emit(record)


	func reset_at(index : int) -> void:
		index += 1
		for i in index:
			record_removed.emit(records.pop_front())


	func get_roll_back_point(from: int) -> int:
		while from < records.size() - 1:
			from += 1
			if records[from].stmt.is_rollable: return from
		return -1


	func get_roll_ahead_point(from: int) -> int:
		while from > 0:
			from -= 1
			if records[from].stmt.is_rollable: return from
		return -1


	func get_reverse_index(i: int) -> int:
		return records.size() - i - 1


	func get_save_data() -> Variant:
		var copy := records.duplicate()
		copy.reverse()
		return {
			"records": Save.any(copy)
		}


	func load_data(host: PennyHost, json: Dictionary) -> void:
		records.clear()
		for record in json["records"]:
			records.push_front(Record.new(host, Penny.get_stmt_from_address(record["stmt"]["script"], record["stmt"]["index"]), Load.any(record["data"]), Record.Response.IGNORE))

var records : Array[Record]

func _get_path_ext() -> String:
	return ".sav"


func _export_json(json: Dictionary) -> void:
	json.merge({
		&"records": records.map(func(record: Record):
			return record.export_json()
			),
	})
