
@tool extends TabContainer

var _tab_icons : Array[Texture2D] :
	get: return tab_icons
	set(value):
		tab_icons = value
		var icons : int = min(self.get_child_count(), tab_icons.size())
		for i in icons:
			var icon = tab_icons[i]
			self.set_tab_icon(i, icon)
@export var tab_icons : Array[Texture2D]

func _ready() -> void:
	_tab_icons = tab_icons
