# Statements

## Table of Contents

- [`init`](#init)
- [`label`](#label)
- [`jump`](#jump)
- [`dive`](#dive)
- [`rise`](#rise)
- [`return`](#return)

## Overview

Each line of code in `.pny` is interpreted as a statement. These can perform a variety of tasks. These are denoted either with a keyword or sometimes special syntaxes.

```pny
Rubin							# For the object `Rubin`:
	name = "Rubin"				# Set `Rubin.name` to "Rubin"
	inst_body = "RubinNode"		# Set `Rubin.inst_body` to 'RubinNode'

label start						# Define a point `start` to jump to later

	Rubin						# For the object `Rubin`:
		idle = true				# Set `Rubin.idle` to `true`
		anim appear				# Play the `appear` animation
		`Hello, world.`			# Say this text

jump start						# Jump to the label `start`
```

### Statement Timing

**Compiled** statements occur when the game starts. These are the only compiled statements in Penny:

-   `label`
-   `menu`
-   `filter`

**Runtime** statements occur in order from start to finish while the game is running. Most statements occur in this manner.

### Statement Transmission

**Pass-Through** statements automatically advance to the next method within the same frame, such as the `set` method.

**Halting** statements must be completed before the next method can be executed, such as the `say` method.

### Statement Implication

**Explicit** statements require use of their keyword in order to be executed. Most statements are explicitly indicated.

**Implicit** statements do not require to be typed out in order to be executed. These are the only implicit statements in Penny:

-   `say` is implied using a quoted line with nothing else around, e.g. `"Hello, world."`
-   `set` is implied using an `=` in between a variable and a value, e.g. `flag = true`

# Flow Control

Flow control dictates the paths your story takes from start to finish.

## Initialization

Some actions occur only once. This includes going through every Penny script to register labels and filters. While playtesting in editor, Penny will automatically reload any detected script changes when the window is refocused, and initialization can occur multiple times per game session. However, during a production build, initialization will only occur one time.

In Godot, you will want to add `script_importer.gd` as an autoload node to handle initialization and set up Penny for use.

### `init`

Oftentimes you will want your Penny environment (i.e. story) to be initialized with some data before ever running a script, to make sure they are ready for use. Characters, logic, for example. To ensure that this data is ready right away, use an `init` block. You can place one anywhere, but it's usually best to keep init blocks in separate files.

```pny
init
	player_name = "Rubin"

	Rubin is Character
		name = player_name
```

This process is done before the saved game state is loaded, so objects with overridden values will have those reapplied afterward.

> [!NOTE]
> Only data assignment statements may be called from an `init` block.

### `label`

The `label` statement is simply a way of defining a destination to `jump` to or to start execution from.

###### Example

```pny
label start

`Hello, world.`
```

Contents beneath `label`s do not need to be indented. There are reasons why one may wish to do use either indented or unindented `label` contents, or both.

### `jump`

The `jump` statement will move execution laterally to a specified `label`. This is the most basic form of flow control and does not increase the flow depth. This is also a simple way to create loops.

### `dive`

The `dive` statement is similar to `jump`, but it will increase the flow depth by `1`. While inside the `dive`d `label`, you can then use `return` to return to the point from which the `label` was called.

> [!TIP] Project Structure
> `dive`s create an easy way to organize chapters in your project. Use a master "Table of Contents" script with multiple `dive`s for each chapter, rather than having to place at the end of each chapter script a `jump` statement to the next.
### `rise`

The `rise` statement will close the current Penny script and go up one depth level, or exit the Penny environment.

### `return`

The `return` statement will immediately close the entire Penny flow tree, no matter the depth. Optionally, you may pass a value to the host engine using this statement. Additionally, you can later use `Penny.resume()` from the engine to return to this point and at the same state at which it was at when left.

```pny
return 2
```

> [!TIP] The Right Tools
> Most visual novels will almost exclusively use the `rise` statement as they will not need to exit the Penny loop at all while reading (except, e.g. to navigate the main menu).
>
> Conversely, games that use Penny for isolated dialogue integration (e.g. how most games handle dialogue) will probably make more use of the `return` statement in order to completely suspend the Penny environment while not in use.

## Forks & Merges

Abstractly speaking, a **fork** is any point at which the story diverges into multiple branches. A **merge** is any point at which the story converges from a deeper branch to a shallower one.

### Conditionals

### `menu`

###### Example 1
```pny
`What kind of fruit would you like to eat?`

menu
	`Apple`
		`You choose to eat an apple.`
	`Banana`
		`You choose to eat a banana.`
	`Orange`
		`You choose to eat an orange.`
```

The `menu` statement indicates that the player can make a decision here and select a different path depending on what they want to do. The branch string indicates one of these paths to help them choose.

> [!NOTE]
> The `menu` statement **does not** clear the previous message block until a branch has been selected. This is to allow for the player to see the previous message (usually a question someone asks them) while making their decision. Use the `clear` statement to force a Message Block to close before prompting a menu.

> [!NOTE]
> Branch strings are not printed out and instead displayed all at once.

###### Example 2
```pny
banana_available = false

`What kind of fruit would you like to eat?`
menu
	`Banana` if banana_available
		`You choose to eat a banana.`
```

Use the `if` statement after a branch to dictate whether or not the branch appears. If the expression is `true`, the branch will appear. If the expression is `false`, the branch will not appear.

> [!NOTE]
> If no branches are open, or if the menu is otherwise interrupted, no selection will be made and the script will continue to the next statement in the same tab depth as the menu.

###### Example 3

```pny
banana_available = false
banana_unvisited = true

`What kind of fruit would you like to eat?`
menu menu_fruit
	label branch_apple
	`Apple`
		`You choose to eat an apple.`

	label branch_banana
	`Banana`
	if banana_unvisited
		banana_unvisited = false
		`You choose to eat a banana.`
```

This example shows a way of writing branches in expanded form. You may assign a label to a branch by writing the name of the label before the display text. `jump`ing to this `label` will jump to the branch as if it was selected in the menu.

> [!TIP]
> You may also assign a label to the menu, but this will not preserve the preceding text. This can be useful in certain situations, but if you wish to make sure the preceding text is always used, it is better to place a label before the text, like so:
> > ```pny
> > ...
> >
> > label menu_fruit
> >
> > `What kind of fruit would you like to eat?`
> > menu
> > 	label branch_apple
> >
> > 	...
> > ```

###### Example 4

```pny
menu
branch branch_apple
	text = `Apple`
	enable = apple_unvisited
	visible = apple_unlocked
content
	`You choose to eat an apple.`
```

Branches have some attributes that define how or if the branch is displayed. Attributes must be placed before any other statements are made.

- `text` is the string used in the menu
- `enabled` is whether or not the branch can be chosen
- `visible` is whether or not the branch is shown at all
  - A branch must be both `enabled` and `visible` in order to be selected. Both default to `true`.

# Functions

Penny does not support writing custom functions natively, but may reference functions by name in its host engine (Godot). You can write your own functions externally for Penny to reference and then execute. These functions are referenced using parentheses outside of a Message Block:

```gd
func int_to_word(x: int) -> string:
	if x < 0: return null
	match x:
		_: return "NaN"
		0: return "zero"
		1: return "one"
		...
```

```pny
`Please give me [int_to_word(10)] apples.`
`Please give me [int_to_word(-1)] apples.`
`Please give me [int_to_word("ten")] apples.`
```

> Please give me ten apples.<br>
> Please give me NULL apples. *(Issues a [`NullEvaluationWarning`](#nullevaluationwarning))*<br>
> Please give me NaN apples.
