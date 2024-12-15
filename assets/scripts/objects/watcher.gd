
# Class that checks to see if its children are busy
class_name Watcher extends Object

var workers : Array[Object]

var working : bool :
	get:
		for i in workers:
			if i.working:
				return true
		return false

func _init(__workers: Array[Object] = []) -> void:
	workers = __workers

func wrap_up_work() -> void:
	for i in workers:
		i.wrap_up_work()
