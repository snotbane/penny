
class_name Async

## Waits for ALL of the callables/signals to finish awaiting. Returns an array with the results of each one.
static func all(methods : Array) :
	return await AllListener.new(methods).completed


## Waits for the FIRST of the callables/signals to finish awaiting. Returns the result of that first method; others are never triggered.
static func any(methods : Array) :
	return await AnyListener.new(methods).completed


class AllListener extends RefCounted :
	signal completed(payload : Array[Variant])
	var payload : Array = []
	var methods_left : int

	var is_completed : bool :
		get: return methods_left == 0


	func _init(methods : Array) -> void:
		payload.resize(methods.size())
		payload.fill(null)
		methods_left = methods.size()
		for i in methods.size():
			var method = methods[i]
			self.add(i, method)


	func add(i: int, method) -> void:
		assert(not is_completed, "This listener is already completed.")
		if method is Signal:
			receive(i, await method)
		elif method is Callable:
			receive(i, await method.call())
		else:
			assert(false, "Awaitable method must be either a Signal or a Callable.")


	func receive(i : int, value : Variant = null) -> void:
		assert(not is_completed, "This listener is already completed.")
		methods_left -= 1
		payload[i] = value
		if is_completed:
			completed.emit(payload)


class AnyListener extends RefCounted :
	signal completed(payload : Variant)
	var is_completed : bool = false


	func _init(methods : Array) -> void:
		for method in methods:
			self.add(method)


	func add(method) -> void:
		assert(not is_completed, "This listener is already completed.")
		if method is Signal:
			receive(await method)
		elif method is Callable:
			receive(await method.call())
		else:
			assert(false, "Awaitable method must be either a Signal or a Callable.")


	func receive(value : Variant = null) -> void:
		assert(not is_completed, "This listener is already completed.")
		is_completed = true
		completed.emit(value)
