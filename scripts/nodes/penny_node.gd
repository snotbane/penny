
## Should be the root script of any Node that Penny opens/instantiates and needs to have any control over.
class_name PennyNode extends Node

## If enabled, Penny will suspend itself when this node is placed in the scene. Imperative for things like menus.
@export var suspend_on_open : bool = false

## If enabled, Penny will resume itself when this node is freed from the scene.
@export var resume_on_close : bool = false

var host : PennyHost

## Additional data that may be submitted when this node is [member populate]d.
var attach : Variant

## Called immediately after instantiation.
func populate(_host: PennyHost, _attach: Variant = null) -> void: _populate(_host, _attach)
func _populate(_host: PennyHost, _attach: Variant = null) -> void:
	host = _host
	attach = _attach

func _ready() -> void:
	if suspend_on_open:
		host.close()
	pass
