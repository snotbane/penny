[Snotbane](https://snotbane.carrd.co) presents...
# Penny, an Interactive Narrative Language

Penny is a coding language used to write interactive narrative content for video games. It is capable of, and appropriate for, handling any narrative demand, from short NPC dialogue, all the way up to full visual novel decision trees.

# Quickstart

1. Import the addon to `res://addons/penny_godot/`

# Why?

Penny's purpose is to provide a dedicated environment for writers to focus on front-end visuals, audio, and (most importantly) text. Rather than being a fully-featured engine, Penny is designed to work along side a host engine. This is to separate visual details from narrative content.

## Key Features

### Subject Linking

When a character talks, usually they will play some sort of animation (or multiple simultaneously) while they are speaking. Penny allows you to connect an existing character (or spawn an instance of one) and control their actions via Penny script.

### Regex Filtering

Writing complex text has never been simpler. One can create filters to apply to displayed text, to reduce technical clutter within the written text itself. For example:

```pen
FANCY_DOUBLE_QUOTE_RIGHT = new filter
	.pattern = `(\S)"`
	.replace = `$1”`

FANCY_DOUBLE_QUOTE_LEFT = new filter
	.pattern = `"`
	.replace = `“`
```

These and some other filters are built into Penny by default, and can be altered based on the needs of your project.

### Object Inheritance

Data in Penny is stored in objects, which inherit attributes from other objects. One can even change an object's inheritance at any time.


# How To

## Menus

Menus are used for the player to control where they wish to go. There are multiple ways to define menus in Penny, each with their own uses.

#### Explicit Menu

The simplest way to define a menu is by creating an Explicit Menu. This will automatically create option objects based on the raw text provided.

```pen
menu
	`Option 1`
		`You chose option 1`
	`Option 2`
	`Option 3`
		`You chose option 3`
```

#### Dynamic Menu

A dynamic menu requires you to define its options prior to calling it. This allows you to define object specifications and conditions for each individual option.

```pen
has_key = false

option1 = new option
	.text = `Option 1`
option2 = new option
	.text = `Option 2`
option3 = new option
	.text = `Option 3`
	.$visible = { has_key }

menu
	option1
		`You chose option 1`
	option2
	option3
		`You chose option 3`
```

#### Stored Menu

A stored menu is like a dynamic menu, but you must also define the menu object. This will call the menu and simply store the result of the menu in its `response` value. These are almost always paired with a match statement and are generally used when you wish to run some other statement(s) in between the asking of the menu and the results of the menu.

```pen
has_key = false

option1 = new option
	.text = `Option 1`
option2 = new option
	.text = `Option 2`
option3 = new option
	.text = `Option 3`
	.$visible = { has_key }

test_menu = new prompt
	.options = [ option1, option2, option3 ]

menu test_menu

`Do something else here before manifesting the result of the menu...`

match test_menu.response
	option1
		`You chose option 1`
	option2
	option3
		`You chose option 3`
```
