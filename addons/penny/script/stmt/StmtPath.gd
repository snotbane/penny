## A statement that may start with a [Penny.Path], which becomes the most recent context.
@tool
class_name StmtPath
extends StmtPass

enum {
	DECLARATION_IMPLICIT,
	DECLARATION_DEF,
	DECLARATION_LET,
	DECLARATION_VAR,
}


static func get_declaration_type_from_front_keywords(keywords: Array[PennyScript.Token.Keyword]) -> int:
	if keywords.is_empty(): return DECLARATION_IMPLICIT
	match keywords[0]:
		PennyScript.Token.Keyword.DEF:
			return DECLARATION_DEF

		PennyScript.Token.Keyword.LET:
			return DECLARATION_LET

		PennyScript.Token.Keyword.VAR:
			return DECLARATION_VAR

		_:
			return DECLARATION_IMPLICIT


@export_storage
var declaration: int

@export_storage
var path: Penny.Path


func _populate_tree_item(tree: Tree, item: TreeItem) -> void:
	var dec_string : String
	var dec_tooltip : String
	match declaration:
		DECLARATION_IMPLICIT:
			dec_string = ""
			dec_tooltip = ""

		DECLARATION_LET when hoist == HOIST_EXPLICIT:
			dec_string = "def "
			dec_tooltip = "\n\t- Keyword *def* will hoist the Stmt to run on application start,\n\t\tand store this value only for the current session."

		DECLARATION_LET:
			dec_string = "let "
			dec_tooltip = "\n\t- Keyword *let* will store this value only for the current session."

		DECLARATION_VAR:
			dec_string = "var "
			dec_tooltip = "\n\t- Keyword *var* will store this value in save state."

	item.set_text(PennyDebugTree_Stmt.COLUMN_NAME, "%s%s" % [
		dec_string,
		path
	])


	item.set_tooltip_text(PennyDebugTree_Stmt.COLUMN_NAME, "StmtPath ::\n\t- Establishes a new context within the script.\n\t- This doesn't do anything during execution." + dec_tooltip)


func _init(__declaration__: int = DECLARATION_IMPLICIT) -> void:
	declaration = __declaration__

	match declaration:
		DECLARATION_DEF:
			hoist = HOIST_EXPLICIT

func _populate(tokens: Array) -> void:
	path = Penny.Path.new_from_tokens_destructive(tokens)


func _compile(script: PennyScript) -> void:
	super._compile(script)

	if path:
		context_path_from_depth = context_path_from_depth.concat(path) if path.is_relative else path
		context_path_from_recent = context_path_from_recent.concat(path) if path.is_relative else path


func _draw(player: PennyPlayer, record: Penny.Record) -> void:
	record.data = {}

	if declaration == DECLARATION_IMPLICIT: return

	record.data.storage_prior = context_storage_from_depth
	record.data.storage_after = declaration == DECLARATION_VAR


func _execute(player: PennyPlayer, record: Penny.Record):
	if declaration == DECLARATION_IMPLICIT: return

	context_storage_from_depth = record.data.storage_after


# func _undo(player: PennyPlayer, record: Penny.Record) -> void:
#	if declaration == DECLARATION_IMPLICIT or record.data.storage_prior == null: return

# 	context_storage_from_depth = record.data.storage_prior
