
## Record of a statement that has occurred. Records that share the same statement are not necessarily equal as they can have occurred at different stamps (times).
class_name Record extends Object

var host : PennyHost
var stamp : int
var address : Address
var message : Message
var attachment : Variant

var statement : Statement :
	get: return Penny.get_statement_from(address)
	set (value):
		address = value.address

var verbosity : int :
	get:
		match statement.type:

			## Player Essentials
			Statement.MESSAGE, Statement.MENU: return 0

			## Debug Essentials
			Statement.ASSIGN, Statement.PRINT: return 1

			## Debug Helpers
			Statement.JUMP, Statement.RISE, Statement.DIVE, Statement.CONDITION_IF, Statement.CONDITION_ELIF, Statement.CONDITION_ELSE: return 2

			## Debug Markers
			Statement.LABEL: return 3

		return -1

func _init(__host: PennyHost, __statement: Statement, __attachment: Variant = null) -> void:
	host = __host
	stamp = host.records.size()
	statement = __statement
	attachment = __attachment
	message = Message.new(self)

func undo() -> void:
	match statement.type:
		Statement.ASSIGN:
			host.set_data(attachment.key, attachment.before)

func _to_string() -> String:
	return "Record : stamp %s, address %s" % [stamp, address]

func equals(other: Record) -> bool:
	return host == other.host and stamp == other.stamp

func get_next() -> Address:
	var result = statement.address.copy()
	match statement.type:
		Statement.CONDITION_ELSE, Statement.CONDITION_ELSE, Statement.CONDITION_IF:
			if attachment:
				result.index += 1
			else:
				result.index += 2
		_:
			result.index += 1
	return result
