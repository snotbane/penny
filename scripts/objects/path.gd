
class_name Path extends Evaluable

var identifiers : Array[StringName]
var relative : bool

func _init(_identifiers: Array[StringName] = [], _relative: bool = false) -> void:
	identifiers = _identifiers
	relative = _relative

static func from_tokens(tokens: Array[Token]) -> Path:
	var rel : bool = tokens[0].value == '.'
	if rel: tokens.pop_front()

	var ids : Array[StringName]
	var l = floor(tokens.size() * 0.5) + 1
	for i in l:
		ids.push_back(tokens[i * 2].value)

	return Path.new(ids, rel)

static func from_string(s: String) -> Path:
	var rel : bool = s[0] == '.'
	if rel: s = s.substr(1)

	var ids : Array[StringName]
	var split := s.split(".", false)
	for i in split:
		ids.push_back(StringName(i))
	return Path.new(ids)

func _to_string() -> String:
	var result := ""
	for i in identifiers:
		result += i + "."
	return result.substr(0, result.length() - 1)

func get_absolute_path(from: Stmt_) -> Path:
	if relative:
		var parent_stmt := from.nested_object_stmt
		if not parent_stmt:
			return null
		return parent_stmt.path.get_absolute_path(parent_stmt).combine(self)
	return self

func duplicate(deep := false) -> Path:
	return Path.new(identifiers.duplicate(deep), relative)

func _evaluate(host: PennyHost, soft: bool = false) -> Variant:
	if soft: return self
	return get_data(host)

func get_data(host: PennyHost) -> Variant:
	var mount := get_mount_point(host)
	if mount:
		return mount.get_data(identifiers.back())
	return null

func set_data(host: PennyHost, _value: Variant) -> void:
	var mount := get_mount_point(host)
	if mount:
		get_mount_point(host).set_data(identifiers.back(), _value)

func get_mount_point(host: PennyHost) -> PennyObject:
	var absolute := get_absolute_path(host.cursor)
	var result : PennyObject = host.data_root
	for i in absolute.identifiers.size() - 1:
		var id := absolute.identifiers[i]
		var next = result.get_data(id)
		if not next:
			host.cursor.create_exception("Attempted to get_mount_point object for path [%s], but identifier '%s' does not exist." % [absolute, id]).push()
			return null
		if not next is PennyObject:
			host.cursor.create_exception("Attempted to get_mount_point object for path [%s], but identifier '%s' is not an object." % [absolute, id]).push()
			return null
		result = next as PennyObject
	return result

## Creates a new object at this path.
func add_object(host: PennyHost) -> PennyObject:
	var result := PennyObject.new(host, identifiers.back(), {
		PennyObject.BASE_KEY: Path.new([PennyObject.BASE_OBJECT_NAME]),
	})
	set_data(host, result)
	return result

func combine(other: Path) -> Path:
	var result := self.duplicate()
	result.identifiers.append_array(other.identifiers)
	return result
