
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
