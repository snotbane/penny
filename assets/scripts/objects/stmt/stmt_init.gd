## Executes all subsequent [Stmt]s when the application is opened.
class_name StmtInit extends Stmt

var order := 0

# func _init() -> void:
# 	pass


func _get_verbosity() -> Verbosity:
	return Verbosity.FLOW_ACTIVITY

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]init %s[/color][/code]" % self.order


func _populate(tokens: Array) -> void:
	if tokens.size() == 1:
		order = int(tokens[0].value)

func _reload() -> void:
	Penny.inits.push_back(self)

# func _cleanup(record: Record, execution_response: ExecutionResponse) -> void:
# 	pass

func _undo(record: Record) -> void:
	assert(false, "Shouldn't be able to undo init statements.")

func _redo(record: Record) -> void:
	assert(false, "Shouldn't be able to redo init statements.")


static func sort(a: StmtInit, b: StmtInit) -> bool:
	return a.order < b.order
