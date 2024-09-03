
Penny is a scripting language used to create visual novels and text cutscenes. It is very similar to [Ren'Py](https://www.renpy.org/) but there are a few key differences:

### Penny is a Format

Ren'Py is a standalone engine that can compile games on its own.

Penny is NOT an engine. It is intended to be used as a plugin for other game engines. Currently the only implementation available is for [Godot](https://godotengine.org/), but one could write their own if they so desire. It is designed to be abstract enough to be expanded in this way.

### Penny Focuses on the Text

Graphical elements like images, gui, etc. are not *defined* inside Penny scripts, but rather these things can be *referenced* and *controlled* using Penny scripts. Graphical elements should be defined inside the engine you are using and accessible via `StringName`.

### Penny is Simple and Powerful

Penny was designed with non-programmers in mind. There aren't very many concepts to learn to write basic scripts. See [Quickstart](#quickstart) for the basics.

It was also designed with hardcore, efficiency-obsessed programmers in mind. Messages (text blocks that the player will read) are designed to be heavily decorated without producing a lot of clutter. See [Filters](#filters) for examples.

# Quickstart

These are the basic concepts you need to know to get started scripting basic text right away.

### Define a Character

```pny
Rubin = Character
	name = "Rubin"
	name_prefix = "<b, color=#ff4128>"
```

### Make a Character Speak

```pny
Rubin `Hello, world`

# or

Rubin
	`Hello, world`
	`My name is [Rubin].`
```

### Give the User Choices

```pny
`Which path do you choose?`

menu
	branch `Left`
		`You choose to go left...`
	branch `Right`
		`You choose to go right...`
```

### Have the script make a choice (without notifying user)

```pny
condition = true

if condition
	`The condition is true`
else
	`The condition is false`
```
