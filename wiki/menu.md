
# Menus

```pny
menu
	`Option 1`
		`You have chosen option 1`
	`Option 2`
		`You have chosen option 2`

### ...is a shorthand for...

_ = menu $menu_default
	_0
		.base = option
		.name = `Option 1`
		`You have chosen option 1`
	_1
		.base = option
		.name = `Option 2`
		`You have chosen option 2`


```

At its core, a menu pauses Penny activity and returns a result. Using a menu in an expression will exit the expression evaluator and simply return the result of the menu, which is always an `Option`. When we see it, it's effectively saying "HOLD UP! The player needs to make some input." You can also specify which type of menu you want to use (must be a Lookup).

A key difference (from Ren'Py) is that menus DO NOT contain any

```pny
choice = menu $default_menu
	`Option 1`
	`Option 2`
match choice
	0
		`You have chosen option 1`
	1
		`You have chosen option 2`
	_
		`Unreachable code`
```

If no menu type is used, it will simply use the default.

```pny
choice = menu
	`Option 1`
	`Option 2`
match choice
	0
		`You have chosen option 1`
	1
		`You have chosen option 2`
```

Options can have custom attributes, and some do certain things on their own.
`show` is a bool that will evaluate the expression when the menu is created. If false, the option will be hidden and inaccessible.
`able` is a bool that will evaluate on creation. If false, the option will be disabled, but still visible.
`chosen` is an internal value stored by the option object. It starts as `false` and sets to `true` when this option is chosen. This can be reset by saying `option.chosen = false`
`icon` sets the icon on a button. Uses a Lookup.

```pny
choice = menu
	too_hot
		name = `Too hot`
		able = not chosen
		show = temperature > 100
		icon = $fire

		chosen = false

		branch
			`It's too hot!`

	label farts			## Validate that only valid menu items are stored in a menu
	`Too cold` if temperature < 0
		`Too cold.`

match choice
	too_hot
		`It's STILL too hot!`
	_
		`Still too cold.`
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



