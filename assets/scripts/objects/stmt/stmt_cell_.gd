## Generic statement for referring to a [Cell]. Also allows one to specify flags for that [Cell].
class_name StmtCell extends Stmt

enum StorageQualifier {
	## Do not affect the storage qualification of the specified [Cell].
	NONE,
	## Set the storage qualification of the [Cell] to be stored in save data.
	STORED,
	## Set the storage qualification of the [Cell] to not be stored in save data.
	TRANSIENT
}

static var DEFAULT_CELL_REF := Path.to(Cell.OBJECT)

static func get_storage_qualifier_from_front_tokens(front_keywords: Array[PennyScript.Token]) -> StorageQualifier:
	if front_keywords.is_empty(): return StorageQualifier.NONE
	match front_keywords[0].value:
		&"let": return StorageQualifier.TRANSIENT
		&"var": return StorageQualifier.STORED
	return StorageQualifier.NONE

var _local_subject_ref : Path
var local_subject_ref : Path :
	get: return _local_subject_ref
	set(value):
		_local_subject_ref = value
		_subject_ref = context_ref.append(local_subject_ref) if _local_subject_ref.rel else _local_subject_ref


var _subject_ref : Path
var subject_ref : Path :
	get: return _subject_ref

var subject : Variant :
	get: return subject_ref.evaluate()

var subject_node : Node :
	get: return subject.instance if subject is Cell else null

var flags : PackedStringArray

var storage_qualifier : StorageQualifier

func _get_verbosity() -> Verbosity:
	return Verbosity.IGNORED

func _get_record_message(record: Record) -> String:
	return "[code][color=dim_gray]cell : %s[/color][/code]" % Penny.get_value_as_bbcode_string(subject_ref)


func _init(__storage_qualifier__ := StorageQualifier.NONE) -> void:
	storage_qualifier = __storage_qualifier__


func _populate(tokens: Array) -> void:
	var tokens_error_string := str(tokens)
	local_subject_ref = Path.new_from_tokens(tokens)
	assert(subject_ref != null, "subject_ref evaluated to null from tokens: %s" % tokens_error_string)

	if local_subject_ref.is_host_previous:
		local_subject_ref = get_prev_with_explicit_subject().local_subject_ref

	for token in tokens:
		flags.push_back(token.value)

func _prep(record: Record) -> void:
	match storage_qualifier:
		StorageQualifier.STORED:	subject_ref.set_storage_in_cell(context, true)
		StorageQualifier.TRANSIENT: subject_ref.set_storage_in_cell(context, false)

	if subject_node is SpriteActor:
		for flag in flags:
			subject_node.sprite_flags.push_flag(flag)

	record.data.merge({
		&"flags_before": [],
		&"flags_after": [],
	})

# func _cleanup(record: Record) -> void:
# 	pass

func _undo(record: Record) -> void:
	super._undo(record)
	## TODO: set flags

func _redo(record: Record) -> void:
	super._redo(record)
	## TODO: set flags


func get_prev_with_explicit_subject() -> StmtCell :
	var cursor := self
	while cursor:
		if cursor is StmtCell and not cursor.local_subject_ref.is_host_previous:
			return cursor
		cursor = self.get_prev_in_same_or_lower_depth()
	assert(false, "There is no previous StmtCell in the script with an explicit subject.")
	return null
