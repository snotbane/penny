extends DialogNodeNew
class_name BubbleContainer3D

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
	child_entered_tree.connect(child_entered)
	child_order_changed.connect(refresh_deferred)

	for child in get_children():
		child_entered(child)
	refresh_deferred()


func child_entered(node: Node) -> void:
	if node is not DialogBubble3D: return
	node.visibility_changed.connect(refresh_deferred)


func refresh_deferred() -> void:
	refresh.call_deferred()
func refresh() -> void:
	var height := 0.0
	for bubble in bubble_children:
		if not bubble.visible: continue
		bubble.position = Vector3.UP * height
		height += bubble.superegg.size.y


## Receives a record and creates a bubble for it.
func receive(record: Record) :
	var bubble : DialogBubble3D = bubble_prefab.instantiate()
	add_child(bubble)
	bubble.receive.call_deferred(record)

# func receive_finish(record: Record) :


## Removes all bubbles from the container.
func flush() :
	for bubble in bubble_children:
		self.remove_child(bubble)
