class_name BubbleContainer3D extends DialogNode

enum EArrangeMode {
	SEQUENTIAL,
	STAGGERED,
}

var _arrange_methods := {
	EArrangeMode.SEQUENTIAL: arrange_sequential,
	EArrangeMode.STAGGERED: arrange_staggered,
}
var _arrange_method : Callable
var arrange_method : Callable :
	get: return _arrange_method
	set(value):
		if _arrange_method == value: return
		_arrange_method = value
		refresh_deferred()
var _arrange_mode := EArrangeMode.SEQUENTIAL
@export var arrange_mode := EArrangeMode.SEQUENTIAL :
	get: return _arrange_mode
	set(value):
		if _arrange_mode == value: return
		_arrange_mode = value
		arrange_method = _arrange_methods[_arrange_mode]


@export var spacing : float = 0.0

@export_subgroup("Family")

@export var bubble_prefab : PackedScene

var bubble_children : Array[DialogBubble3D] :
	get:
		var result : Array[DialogBubble3D]
		for child in get_children():
			if child is not DialogBubble3D: continue
			result.push_front(child)
		return result


func _get_typewriter() -> Typewriter:
	for i in get_child_count():
		var child := get_child(-i-1)
		if child is not DialogBubble3D: continue
		return child.typewriter
	return null


func _ready() -> void:
	arrange_method = _arrange_methods[_arrange_mode]

	child_entered_tree.connect(child_entered)
	child_order_changed.connect(refresh_deferred)

	for child in get_children(): child_entered(child)
	refresh_deferred()


func child_entered(node: Node) -> void:
	if node is not DialogBubble3D: return
	node.visibility_changed.connect(refresh_deferred)


func refresh_deferred() -> void:
	refresh.call_deferred()
func refresh() -> void:
	arrange_method.call()


## Receives a record and creates a bubble for it.
func receive(record: Record) :
	var bubble : DialogBubble3D = bubble_prefab.instantiate()
	add_child(bubble)
	bubble.receive(record)

# func receive_finish(record: Record) :


## Removes all bubbles from the container.
func flush() :
	for bubble in bubble_children:
		self.remove_child(bubble)


func arrange_sequential() -> void:
	var distance := 0.0
	var i := 0
	for bubble in bubble_children:
		if not bubble.visible: continue

		var half_superegg_height := bubble.superegg.size.y * 0.5
		if i > 0: distance += half_superegg_height

		bubble.target_progress = distance + i * spacing

		distance += half_superegg_height
		i += 1


func arrange_staggered() -> void:
	pass
