
# Menus

```pny
prompt
	`Option 1`
		`You have chosen option 1`
	`Option 2`
		`You have chosen option 2`

### ...is a shorthand for...

option
	.able = .used				## Whether or not the option is enabled
	.show = true				## Whether or not the option is shown at all
	.used = false				## Whether or not the option has been selected.
								## Updates when chosen.
prompt
	.link = $menu_default
	.response = null			## The most recently chosen option (path). Updates when chosen.
_
	.base = prompt
	.options = [
		_0
			.base = option
			.name = `Option 1`
			`You have chosen option 1`
		_1
			.base = option
			.name = `Option 2`
			`You have chosen option 2`
	]
open prompt
match choice
	_0
		`You have chosen option 1`
	_1
		`You have chosen option 2`


### A good mix of both is the following:


_ = prompt
	_0
		.name = `Option 1`
		`You have chosen option 1`
	_1
		.name = `Option 2`
		`You have chosen option 2`


```

Options can have custom attributes, and some do certain things on their own.
`show` is a bool that will evaluate the expression when the prompt is created. If false, the option will be hidden and inaccessible.
`able` is a bool that will evaluate on creation. If false, the option will be disabled, but still visible.
`chosen` is an internal value stored by the option object. It starts as `false` and sets to `true` when this option is chosen. This can be reset by saying `option.chosen = false`
`icon` sets the icon on a button. Uses a Lookup.

```pny
choice = prompt
	too_hot
		name = `Too hot`
		able = not chosen
		show = temperature > 100
		icon = $fire

		chosen = false

		branch
			`It's too hot!`

	label farts			## Validate that only valid prompt items are stored in a prompt
	`Too cold` if temperature < 0
		`Too cold.`

match choice
	too_hot
		`It's STILL too hot!`
	_
		`Still too cold.`
```
