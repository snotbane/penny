
# Menus

```pny
menu
	`Option 1`
		`You have chosen option 1`
	`Option 2`
		`You have chosen option 2`
```

You can store the result of the menu as an integer.

```pny
choice = menu
	`Option 1`
	`Option 2`

match choice
	0
		`You have chosen option 1`
	1
		`You have chosen option 2`
	_
		`Impossible selection`
```

You may specify a specific scene to instantiate for the menu. Can be a "string" or $link value.

Entering a menu will temporarily hold all Penny activity. In order to return to Penny, you must either queue_free() the scene node, or call Penny.resume() from within the scene.

```pny


menu "res://scenes/menu.tscn"			## Load using string literal

menu $default							## Load using key "default" in host settings

## Be careful you don't do this:

default = "res://scenes/wrong.tscn"
menu default
menu $default							## Two different things!! (Probably)

```
