
class_name Penny extends Object

static var scripts : Array[PennyScript]

static func find_script_from_path(path: String) -> PennyScript:
	for i in scripts:
		if i.resource_path == path:
			return i
	return null

static func log_timed(s: String) -> void:
	var time = Time.get_time_dict_from_system()
	var formatted_time_string := "%s:%s:%s" % [str(time.hour).pad_zeros(2), str(time.minute).pad_zeros(2), str(time.second).pad_zeros(2)]
	print("[%s] %s" % [formatted_time_string, s])
