# Penny (`.pny`) manuscript language

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

# Statements

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

**Blocking** statements must be completed before the next method can be executed, such as the `say` method.

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

### `init` Statement

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

## Invocation

In Penny, a `label` must be called from the host engine in order to begin execution:

```gd
Penny.start('label_name')
```

Alternatively, if Penny was previously exited using a `rise` or `return` statement, execution may be resumed from where it was last left off, without jumping to a specific label.

```gd
Penny.resume()
```

> [!WARNING] Jumping to Conclusions
> Keep in mind that using `Penny.resume()` at the very end of a script will immediately exit the environment and there may not be any indication of this, so make sure only to call this if you know it's safe to do so.
>
> Neither entering nor exiting the Penny environment will alter its state, but using `Penny.start()` will set the player's position and reset their depth within it.


> [!TIP] Script Length
> Penny scripts can be any length and can even loop infinitely. Best practice is to use one `.pny` file per "scene" (not engine scene, I mean more like a "chapter").

### `label` Statement

The `label` statement is simply a way of defining a destination to `jump` to or to start execution from.

###### Example

```pny
label start

`Hello, world.`
```

Contents beneath `label`s do not need to be indented. There are reasons why one may wish to do use either indented or unindented `label` contents, or both.

### `jump` Statement

The `jump` statement will move execution laterally to a specified `label`. This is the most basic form of flow control and does not increase the flow depth. This is also a simple way to create loops.

### `dive` Statement

The `dive` statement is similar to `jump`, but it will increase the flow depth by `1`. While inside the `dive`d `label`, you can then use `return` to return to the point from which the `label` was called.

> [!TIP] Project Structure
> `dive`s create an easy way to organize chapters in your project. Use a master "Table of Contents" script with multiple `dive`s for each chapter, rather than having to place at the end of each chapter script a `jump` statement to the next.

### Concurrency

Multiple Penny scripts can be run simultaneously, but all scripts share the same data. This is to allow for background objects to be scripted (see [this example from Paper Mario TTYD](https://youtu.be/-9R0PpJB9So?t=849)) or for other potential concurrent implementations.

> [!CAUTION] Concurrency Risks
> It is **extremely dangerous** to modify variables, and/or interact with objects, shared between two Penny scripts. These pose similar risks to *multithreaded* code but are not protected as such. **Most** applications will only have **one** script running at a time.

## Termination

Penny will run through its execution until one of several things happens:

- A `return` statement is encountered
- A `rise` statement is encountered at a flow depth of `0`
- The end of the script file is reached (same behavior as `rise`)
- An uncaught exception is thrown

### `rise` Statement

The `rise` statement will close the current Penny script and go up one depth level, or exit the Penny environment.

### `return` Statement

The `return` statement will immediately close the entire Penny flow tree, no matter the depth. Optionally, you may pass a value to the host engine using this statement. Additionally, you can later use `Penny.resume()` from the engine to return to this point and at the same state at which it was at when left.

```pny
return 2
```

> [!TIP] The Right Tools
> Most visual novels will almost exclusively use the `rise` statement as they will not need to exit the Penny loop at all while reading (except, e.g. to navigate the main menu).
>
> Conversely, games that use Penny for isolated dialogue integration (e.g. how most games handle dialogue) will probably make more use of the `return` statement in order to completely suspend the Penny environment while not in use.

### Uncaught Exceptions

If any uncaught exception is thrown that Penny cannot handle, the script will be immediately terminated to prevent a full game crash.

## Forks & Merges

Abstractly speaking, a **fork** is any point at which the story diverges into multiple branches. A **merge** is any point at which the story converges from a deeper branch to a shallower one.

### Conditionals

### Menus

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

# Display String

A Display String is any string that Penny writes to a `RichTextLabel` and has [Dynamic Elements](#dynamic-elements) applied to it. This can be done in a variety of ways but the two main ones are:

- [Message Block](#message-block)
- [Name Label](#name-label)

## Message Block

A **Message Block** is a single string, printed out over time, via a `RichTextLabel`, using the `say` statement. Each Block is defined by a single string. You can use `'`, `'''`, `"`, `"""`, [\`], or [\`\`\`] to indicate a Message Block (there is no difference between these, except for allowed escape characters). [\`] is my personal preference to minimize `\"` usage in `say` statements.

```pny
`Hello, my name is "Rubin."`
```

## Name Label

A **Name Label** is a short string often presented alongside a `say` statement. This text is not printed out over time, but the same dynamic applications apply to these.

## String Pipelines

Penny uses a series of processes to modify strings before they are seen by the end user. These are called **Pipelines**. Some of these pipelines can be enabled or disabled either for debugging or shipping purposes. By default, all of them are enabled.

> [!NOTE]
> This section goes into **extreme technical detail** about how strings are modified internally and is not relevant to the average user. Skip to [Dynamic Elements](#dynamic-elements) to see how to use these tools.

Consider this example for each of the Pipelines:

```pny
filter
	find = "apple"
	replace = "banana"

Player = object
	name = "Rubin"

`[Player] ate an <b, i>entire</> apple!{ log "check your console log" }`
```

### Raw Text

A **Raw String** is unmodified Penny code contained within a quote.

> \[Player\] ate an \<b, i\>entire\</\> apple!{ log "check your console log" }
```json
{
	"evals": [],
	"filters": [],
	"decors": [],
	"jects": []
}
```

### Extracting

An **Extracted String** is one that has had its Evaluations, Decorations, and Interjections "extracted" to be applied later, so that filtering won't affect them. This process involves acquiring the indeces and (if applicable) length of each dynamic element in order.

>  ate an entire apple!
```json
{
	"jects": [
		{
			"index": 21,
			"value": " log \"check your console log\" "
		}
	],
	"evals": [
		{
			"raw": {
				"index": 0,
				"value": "Player"
			},
			"final": {
				"index": 0,
				"value": null
			}
		}
	],
	"filters": [],
	"decors": [
		{
			"raw": {
				"index": 8,
				"length": 6
			},
			"final": {
				"index": 8,
				"length": 6
			},
			"tags": [
				{
					"id": "b"
				},
				{
					"id": "i"
				}
			]
		}
	]
}
```

### Evaluating

An **Evaluated String** is one that has had its Evaluations evaluated and reinserted into the string. Each evaluation will update the index and length of other dynamic elements that appear after it.

> [!NOTE]
> After evaluation, the string is actually extracted and evaluated recursively, in case any evaluations created new dynamic elements. This process is recursive until there are no further evaluations to be made.

> Rubin ate an entire apple!
```json
{
	"jects": [
		{
			"index": 26,
			"value": " log \"check your console log\" "
		}
	],
	"evals": [
		{
			"raw": {
				"index": 0,
				"value": "Player"
			},
			"final": {
				"index": 0,
				"value": "Rubin"
			}
		}
	],
	"decors": [
		{
			"raw": {
				"index": 8,
				"length": 6
			},
			"final": {
				"index": 13,
				"length": 6
			},
			"tags": [
				{
					"id": "b"
				},
				{
					"id": "i"
				}
			]
		}
	],
	"filters": []
}
```

### Filtering

A **Filtered String** is one that has had filters applied to it. This will update the lengths of decors that have been affected.

> Rubin ate an entire banana!

```json
{
	"jects": [
		{
			"index": 27,
			"value": " log \"check your console log\" "
		}
	],
	"evals": [
		{
			"raw": {
				"index": 0,
				"value": "Player"
			},
			"final": {
				"index": 0,
				"value": "Rubin"
			}
		}
	],
	"decors": [
		{
			"index": 13,
			"length": 5,
			"tags": [
				{
					"id": "b"
				},
				{
					"id": "i"
				}
			]
		}
	],
	"filters": [
		{
			"index": 20,
			"length": 5,
			"prefix": "",
			"replace": "banana",
			"suffix": "",
		}
	]
}

```

# Dynamic Elements

There are a variety of ways to alter any Display String. To achieve this, use Dynamic Elements, which are applied to the final display string in the order listed:

- [Interjections](#interjections)
- [Evaluations](#evaluations)
- [Decorations](#decorations)
- [Filters](#filters)

## Interjections

Use an **Interjection** to execute Penny code in the middle of a message block.

> [!IMPORTANT] Key Concepts
> **Interjections**:
> - May execute any host-engine **Callable**.
> - Will execute as soon as the character before it becomes visible.
> - Are best utilized inside Message Blocks, e.g. play a sound effect or animation, in the middle of a Message Block.
> - **Do not** modify the Display String text whatsoever.

###### Example 1
```pny
`Hello, my name { log "Check your console log" }is Rubin.`
`Hello, my name {
	log "Check your console log"
}is Rubin.`
```
This example demonstrates a simple logging statement to show how interjections work. Interjections can be placed inline or in block form.

###### Example 2
```pny
player_name = "Rubin"

`Hello, my name is { player_name = "Echo" }[player_name].`
`My name has now been updated to [player_name].`
```
> Hello, my name is Rubin.<br>
> My name has now been updated to Echo.

This example demonstrates that Interjections cannot modify the contents of the string which they belong in, because they are only executed once they have been reached. You *can* modify variable values inside Interjections, but this isn't really useful. It's best practice to instead keep `set`ters outside Message Blocks. The result will be identical to last time but the syntax is much more readable:

```pny
player_name = "Rubin"

`Hello, my name is [player_name].`

player_name = "Echo"

`My name has now been updated to [player_name].`
```

## Evaluations

Use an **Evaluation** to interpret an variable, expression, or function as a string using `object.to_string()`

```pny
player_name = `Rubin`
`Hello, my name is [player_name].`
```
> Hello, my name is Rubin.

## Decorations

Use a **Decoration** to modify the formatting of a Message Block or have it take on unique properties. Decorations are defined using a `<start>` tag and an `</end>` tag like so:

```pny
`Hello, my name is <i>Rubin</i>, it's nice to meet you.`
```
> Hello, my name is _Rubin_, it's nice to meet you.

Or they can be _implicitly terminated_ using an auto-terminator `</>`:

```pny
`Hello, my name is <i>Rubin</>, it's nice to meet you.`
```
> Hello, my name is _Rubin_, it's nice to meet you. _(Same result)_

An end tag is not necessary but may cause unintended side-effects (_especially_ if the decoration is part of an Eval):

```pny
`Hello, my name is <i>Rubin, it's nice to meet you.`
```

> Hello, my name is _Rubin, it's nice to meet you._

> [!NOTE]
> Some decorations can trigger an execution or act as a "pseudo-ject", such as `<va>`, which triggers a sound effect. Normally a sound is played by using a Ject like `{ sfx 'sound.ogg' }`.

> [!WARNING]
> Using a decoration that does not exist or placing parameters out of order is likely to issue a [`UndefinedDecorationWarning`](#missingdecorationwarning) or similar.

### Parameters

#### Zero-Parameter Decors

Many decors do not have any parameters. Very simple.

```pny
`Hello, my name is <i>Rubin</>, it's nice to meet you.`
```
#### Single-Parameter Decors

Many decors have exactly one attribute. These can be changed by setting them inside the start tag. Also very simple.

```pny
`Hello, my name is <color=#ff4128>Rubin</>.`
```

#### Multi-Parameter Decors

Some decorations contain multiple attributes that are set by placing whitespace in between each identifier.

```pny
`<wave a=10 p=2 s=5>Hello, world.</>`
```

#### Parameter Defaults

You can set the default values for decoration parameters. See [Custom Decorations](#custom-decorations)

### Combining Multiple Decorations

Multiple decorations may be combined into one set of tags. They'll be applied in the order listed, but this usually isn't important.

```pny
`Hello, my name is <b, i>Rubin</>, it's nice to meet you.`
```
> Hello, my name is **_Rubin_**, it's nice to meet you.

> [!TIP] Decorations Best Practice
> It is best practice to apply decorations in this way — use a single start tag to list all decors, and close it with a single auto-terminator tag.

However, multiple decorations may be applied or unapplied explicitly. Decorations may also overlap.

```pny
`<i, b>Hello, my name is Rubin,</b> it's nice to meet you.`
`<i>Hello, my name is <b>Rubin,</i> it's nice to meet you.`
`<i>Hello, my name is <b>Rubin,</i, b> it's nice to meet you.`
`<i, b>Hello, my name is <u>Rubin,</u, b> it's nice to meet you.`
```

> <i><b>Hello, my name is Rubin,</b> it's nice to meet you.</i><br>
> <i>Hello, my name is <b>Rubin,</i> it's nice to meet you.</b><br>
> <i>Hello, my name is <b>Rubin,</b></i> it's nice to meet you.<br>
> <i><b>Hello, my name is <u>Rubin,</u></b> it's nice to meet you.</i>

### Custom Decorations

You can consolidate multiple decorations into one and add custom functionality for the start and end tags.

###### Example 1

```pny
dec heavy
	b
	i
```

###### Example 2

```pny
dec highlight
	b
	color = #ffff00
	wave
```

###### Example 3

```pny
dec wave
	a = 5
	p = 2
	s = 10
```

###### Example 4

```pny
dec d
```




### Miscellaneous

#### Auto-Terminator Tag

Using an auto-terminator tag will terminate the most recent open decoration. It will unapply the decorations in reverse order.

```pny
`<i>Hello, my name is <b>Rubin,</> it's nice to meet you.`
`<i>Hello, my name is <u, b>Rubin,</> it's nice to meet you.`
```

> <i>Hello, my name is <b>Rubin,</b> it's nice to meet you.</i><br><i>Hello, my name is <b><u>Rubin,</u></b> it's nice to meet you.</i>

#### Placeholder Start Tag

Empty start tags are valid but are completely vestigial and are basically only used as placeholders:

```pny
`<i>Hello, my name is <>Rubin,</> it's nice to meet you.`
`<i>Hello, my name is Rubin,</> it's nice to meet you.`
```

> <i>Hello, my name is Rubin, it's nice to meet you.</i><br>
> <i>Hello, my name is Rubin,</i> it's nice to meet you.

#### Self-Closing Decorations

Some decorations are self-closing.

```pny
`Hello, <d=0.5/>world.`		# Valid
`Hello, <d=0.5>world.`		# Valid
`Hello, <d=0.5>world.</>`	# Issues warning for trailing end tag
```

Self-closing decorations may be combined with non-self-closing decorations (and will be treated like it closes there).

```pny
`Hello, <d=0.5, i>world.</>`
```

Non-self-closing decorations may be self-closed, but this will issue a warning.

```pny
`Hello, <d=0.5, i/>world.`	# Issues warning for self-closed `<i/>`
```

### User-Defined Decorations

#### Proxy Decorations

This kind of user-defined decoration allows one to use multiple decorations at once using the `proxy` statement. This will create a new decoration that can be accessed in any string.

```pny
dec heavy
	b
	i

`<heavy>Hello, world.</>`
```

> <b><i>Hello, world.</b></i>

One may set the default values for attributes in the decoration definition. These can then be overridden in a string later.

```pny
dec slow
	b; i; speed = 10			# Set the default value for `slow.speed`

`<slow>Hello, world.</>`
`<slow speed=2>Hello, world.</>`
```

> <b><i>Hello, world.</b></i> _(Printed at 10 chars per second)_<br><b><i>Hello, world.</b></i> _(Printed at 2 chars per second)_

```pny
dec bik = k				# Use `k` as the proxy attribute.
	b; i; k = 2.0			# Set the default for `k`

`<bik=10>Hello, world.</>`	# Setting `bik` will actually set `k`.
```

> <b><i>H e l l o , w o r l d .</b></i>

#### Custom Decorations

This kind of user-defined decoration allows one to create custom functionality. All base decorations are of this kind and must be defined with the following attributes:

```pny
dec i
	scope = 1
	init_start = 'italic_start'
	init_end = 'italic_end'
```

Decorations are defined with the following data:

-   `id : String` How to identify this decoration in a start tag.
-   `scope : int` Defines the scope.
    -   `0` self-closing. Closes in the same start tag. Trying to close one later will issue a `TrailingEndTagWarning`.
    -   `1` spanning. Closes explicitly after some length or at string end. Trying to self-close one will issue a `ZeroLengthDecorationWarning`.
    -   `2` non-warning. Can be closed anywhere, does not generate warnings.
-   `sub_decorations : Dictionary` Defines any sub decorations to use and overridden values. Custom decorations cannot have any sub decorations. Only proxy decorations can use sub decorations.
-   `init_start` Method to execute when the start (or self-closing) tag is encountered during any string evaluation.
-   `init_end` Method to execute when the end tag (or self-closing, if scope == 2) is encountered during any string evaluation.
-   `print_start` Method to execute when the start (or self-closing) tag is encountered during Message Block printout.
-   `print_end` Method to execute when the end tag (or self-closing, if scope == 2) is encountered during Message Block printout.

### Decoration List

-   `<a=string>` Anchor
-   `<alpha=float>` Opacity
-   `<alt=string>` Alt text for image
-   `<b>` Bold
-   `<color=color>` Color
-   `<d=float>` Delay (wait w/o input) (print only)
-   `<font=string>` Font Family
-   `<i>` Italic
-   `<image=string>` Image
-   `<k=float>` Kerning
-   `<next>` Auto-advance to the next statement without waiting for user input (see {nw})
-   `<raw>` Prevents string evaluation
-   `<s>` Strikethrough
-   `<size=int>` Font Size
-   `<skip>` Instantly print (print only) (see `{fast}`)
-   `<space=float>` Space
-   `<speed=float>` Characters per second (print only) (see `{cps}`)
-   `<u>` Underline
-   `<va=string>` Plays a voice acting sound and prevents text from continuing until the sound is finished (print only)
-   `<vspace=float>` New line + space
-   `<w>` Wait for input. Advancing while text is printing will stop at the next one of these to be encountered. (print only)

These decorations will be removed from Ren'Py (for now):

-   `{art}`
-   `{done}` Stop printing (for spacing parity between separate lines)
-   `{outlinecolor}`
-   `{plain}`
-   `{rb}`
-   `{rt}`
-   `{clear}`


## Filters

Filters search for [regex patterns](https://regexr.com/) and perform actions on any matching text. This can be a handy way of ensuring proper grammar after evaluation, and/or reducing clutter **for all Penny scripts** in your project.

> [!IMPORTANT] Key Concepts
> **Filters**:
> - Apply only to visible, evaluated text.
> - May add new evaluations, interjections, or decorations, which are applied after each filter. Once applied, these features cannot be removed.
> - Apply in the order which they are written.
> - **Are not** recursive, but creating multiple identical filters will cause them to apply multiple times.
> - **Do not** affect `<raw>` decorations nor text encapsulated therein.
> - Belong to a separate dictionary from objects and cannot be accessed or referenced by objects or vice versa.
> - Are interpreted at **Compile-Time** and **CANNOT BE UNREGISTERED** once the game starts!

###### Example 1

```pny
filter "apple" with "banana"

`Would you like *an* apple?`
```
> Would you like \*an\* banana?

This is a simple example to demonstrate that the text `"apple"` is replaced (substituted) with `"banana"` **without** using an [Evaluation](#evaluations). But this example is not very practical; the preceeding article doesn't even display correctly.

###### Example 2

```pny
filter "(?i)(?<=\s\W?)an\b(?=\W?\s*\w)"
	with "a"

filter "(?i)(?<=\s\W?)a\b(?=\W?\s*[aeiou])"
	with "an"

fruit_1 = "banana"
fruit_2 = "orange"

`Would you like a [fruit_1]? ...Or would you like a [fruit_2]?`
```
> Would you like a banana? ...Or would you like an orange?

The two filters in this example are much more practical! They will ensure that those pesky articles display properly, no matter what the evaluations become. This is also a situation where the ordering of the filters is crucial.

###### Example 3

```pny
filter "(?<=[^\.])_(?=[^\.]|$)"
	with "<w>"

`Hello... it is nice to see you._ You're looking so pretty today.`
```
> Hello... it is nice to see you. You're looking so pretty today.

This is a filter I like to use as a shorthand for creating a wait-for-input pause `<w>` in between long sentences simply by using an underscore.

###### Example 4

```pny
filter "\.{3,}"
	with "<speed=5>$&</><d=0.2>"

`...Hello..... world...`
```
> <u>...</u>Hello<u>.....</u> world<u>...</u>

This example is a filter to print ellipses of any length ("...") slowly (represented with underlines). Use the regex key `$&` to refer to the captured string.

###### Example 5

```pny
Rubin = object
	name = "Rubin"
	style = "<b, color=#ff4128>"

filter "\bRubin\b" with "[Rubin]"
`Nice to meet you, I'm Rubin.`
```
> Nice to meet you, I'm <b><span style="color:#ff4128">Rubin</b></span>.

This example demonstrates that you may use evaluations within filters.

###### Example 6

```pny
filter "\bR\b"
	with "<b, color=#ff4128>Rubin</>"

`Nice to meet you, I'm R.`
```
> Nice to meet you, I'm <b><span style="color:#ff4128">Rubin</b></span>.

This example shows how you might use a shorthand for a character's name (in Ren'Py style) to apply decorations and expand their name.

> [!WARNING] Filter Risks
> Filters are dangerously powerful. Using regex patterns that are too short or too inclusive may change your text in confusing ways. Make sure to test your regex thoroughly ([regexr](https://regexr.com/) is a great place to do so).
>
> Continuing from the previous example, the following is the sort of thing that might happen if you're not careful:
>
>	```pny
>	`Let's go see an R-rated movie!`
>	```
> > Let's go see an <b><span style="color:#ff4128">Rubin</b></span>-rated movie!

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

# Variables

Variables are little bits of data you can use for various purposes. They can either be stored **Globally** or **Locally** to an `object`. All variables are of the type `Godot.Variant` (but not all sub-types are supported). A Variable can be set (interchangeably) to a:
- [Attribute](#attributes)
- [Array](#arrays)
- [Object](#objects)

Most Variables are (or should be) able to be [Evaluated](#evaluations).

## Attributes

An Attribute is a simple variable that stores a single value, such as text, number, or boolean value.

```pny
player_name = "Rubin"
player_age = 28
player_dominant_right_hand = true
```

These are the variable types that Penny understands:

- `bool` — id of `true` or `false`
- `int` — numeric id without a `.`
- `float` — numeric id with a `.`
- `color` — hex id beginning with `#`, e.g. `#ff4128`
- `StringName` — string id with single quotes, e.g. `'chapter'`
- `String` — string id with double quotes, e.g. `"chapter"`
- `Text` — string id with ticks, e.g. ``` `chapter` ```
- `object` — string id with no quotes, e.g. `Rubin` or `player_name`

## Arrays

Objects can also store arrays (lists) of data.

```pny
obj Apple
	name = "apple"

obj Rubin
	name = "Rubin"
	items = ["banana", Apple, 30]

`[Rubin] has these items: [items].`
```

> Rubin has these items: banana, apple, 30.

The default method for evaluating an array is called `array_to_string()` and may be overridden in Godot. This is the default method:

```gd
func array_to_string(array: Array) -> string:
	var result := ""
	foreach i in array:
		result += i + ", "
	return result.substring(-2)		# or whatever
```

## Objects

Objects are a special kind of variable. They can be used to represent something that has a little or a lot of data.

###### Example 1

To define a new Object, use the following format:

```pny
Apple is object
```

###### Example 2

Objects can store multiple variables. These variables can then be accessed using dot notation.

```pny
Apple is object
	name = "apple"
	health = 10

`The [Apple] is healthy and will restore [Apple.health] health.`

Apple.health = 0

`The [Apple] has become rotten and will now restore [Apple.health] health.`
```
> The apple is healthy and will restore 10 health.<br>
> The apple has become rotten and will now restore 0 health.


###### Example 3

You can also set multiple properties at once using tab notation.

```pny
Apple is object					# Initial definition
	name = "apple"
	value = 10
	kind = "health"
`The "[Apple.name]" will restore [Apple.value] [Apple.kind].`

Apple							# Setting only the listed attributes
	value = 5
	kind = "stamina"
`The "[Apple.name]" will restore [Apple.value] [Apple.kind].`
```
> The "apple" will restore 10 health.<br>
> The "apple" will restore 5 stamina.

> [!NOTE]
> Some attributes, such as `name`, are used internally for things like [Evaluation](#evaluations). Please check the [Object Defaults](#object-defaults) to see a full list of internally used attribute names.

###### Example 4

> [!CAUTION] Redefining Objects
> Continuing from the previous example, redefining `Apple is object` will reset all its overridden values, resulting in data loss. This behavior is intentional.

```pny
...								# Previous example code

Apple is object					# (Accidental?) redefinition
	value = 20
	kind = "mana"
`The "[Apple.name]" will restore [Apple.value] [Apple.kind].`
```
> The "" will restore 20 mana.


### Object Referencing

Objects reference other objects when used as attributes. They do not have to be defined before they can be **set** as a reference, but they MUST be defined before they are **accessed**. (see [`UndefinedObjectKeyError`](#undefinedobjectkeyerror)).

###### Example 1

```pny
Rubin is object
	name = "Rubin"
	mother = Marigold

Marigold is object
	name = "Marigold"
	son = Rubin

`[Rubin]'s mother is [Rubin.mother].`
`[Marigold]'s son is [Marigold.son].`
```

> Rubin's mother is Marigold.<br>
> Marigold's son is Rubin.

> [!NOTE]
> For simplicity's sake, objects cannot contain sub-object dictionaries within themselves — they can only reference other global objects. See [Duplication](#duplication) to create copies of objects.

###### Example 2

```pny
Rubin is Character
	name = "Rubin"
	spouse = Echo

Echo is Character
	name = "Echo"

Rubin
	`Good day, [Rubin.spouse].

Rubin.spouse
	`Good day, [Rubin].`
```
> Good day, Echo.<br>
> Good day, Rubin.

This example shows how you can use dot notation to have characters speak even if you don't know specifically who they will be.

> [!TIP] Dot Notation vs. Tab Notation
> In Penny, you can use either kind of notation to refer to an object's attributes. Both notations are valid. Best practice is to use dot notation for a single line; tab notation for multiple lines.
>
> However, only objects accessed via dot notation can `say` anything. The reason for this is for formatting reasons; to keep `say` statements that are on the same branch at the same tab depth. Therefore the following code is not valid:
>	```pny
>	Rubin
>		`Good day, [Rubin.spouse].
>		spouse
>			`Good day, [Rubin].`
>	```

### Inheritance

Objects can inherit attributes from other objects. This is done so by using a built-in variable, `base`, to refer to the object's parent.

###### Example 1

```pny
Fruit is object
	base = object

Apple is object
	base = Fruit
```

Both of these definitions are technically valid, but also redundant, because `is` automatically sets `base`. Instead, do:

```pny
Fruit is object

Apple is Fruit
```

###### Example 2

```pny
Fruit is object
	name = "fruit"
	health = 10

Apple is Fruit
	name = "apple"

`A [Fruit] will replenish [Fruit.health] health.\n
An [Apple] will replenish [Apple.health] health as well because it is a kind of [Apple.base].`
```
> A fruit will replenish 10 health.<br>
> An apple will replenish 10 health as well because it is a kind of fruit.

###### Example 2

Inherited objects do not copy their parents' values; they reference them. Therefore, changing a parent's attributes will also change all of their childrens' attributes as well.

```pny
Fruit is object
	name = "fruit"
	health = 10

Apple is Fruit
	name = "apple"

`All [Fruit]s heal [Fruit.health], so all [Apple]s heal [Apple.health].`

Fruit.health = 20
`All [Fruit]s heal [Fruit.health], so all [Apple]s heal [Apple.health].`
```

> All fruits heal 10, so all apples heal 10.<br>
> All fruits heal 20, so all apples heal 20.

> [!WARNING]
> Circular inheritance is not valid. See [`RecursiveInheritanceError`](#recursiveinheritanceerror) for more information.

###### Example 3

An existing object may be reparented (without being redefined) by setting the built-in attribute `base`.

```pny
...

Apple.base = object

`All [Fruit]s heal [Fruit.health], so all [Apple]s heal [Apple.health].`
```
> All fruits heal 10, so all apples heal \[Apple.health\]. *(Warning issued)*

> [!CAUTION] Reparenting Objects
> This will keep overridden data, and acquire data from the new parent, but also *lose* data from the old parent. Please don't do this unless you know what you are doing.

### Duplication

Objects can be duplicated from a template object to target object (rather than being inherited). Use `=` to accomplish this (rather than using `is`). This protects the target's attributes from being modified if the template's attributes change. Creating an object in this way creates a sibling of the target object as it inherits from the same parent as the template.

```pny
obj Apple
	name = "apple"
	health = 10

obj Banana = Apple
	name = "banana"

Apple.health = 5

`The [Banana] heals [Banana.health] health.`
```
> The banana heals 10 health.

> [!WARNING]
> Objects must be defined before they can be duplicated. Because of this, circular "inheritance" is still impossible, but for different reasons than with true inheritance. Trying to do this will result in a [`UndefinedObjectKeyError`](#undefinedobjectkeyerror).


### Boilerplate Objects

Some objects already exist in a default Penny project. These can be modified if needed.

#### Base Object

These are the default values for the base `object`. When other object definitions do not use `is` for inheritance, it implies this Object is the parent. Objects can refer to anything at all, so they have very little data to start with. By default, `object`s cannot speak via message blocks nor exist in the world.

```pny
object
	name = ""
	name_prefix = "<>"
	name_suffix = "</>"
```
- `name` is a name read by the reader and is used during [Evaluation](#evaluations).
> [!TIP] Abstract "Classes"
> If you're familiar with [OOP](https://en.wikipedia.org/wiki/Object-oriented_programming), think of an `object` without a name effectively as an `abstract` class.
- `name_prefix` is prepended before `name` during [Evaluation](#evaluations).
- `name_suffix` is appended after `name` during [Evaluation](#evaluations).

#### Entity

Think of entities like "key items." They cannot speak (by default) but they are set up to have decorations added to their names to make them stand out when evaluated. They can even appear in the world using `link`.

```pny
Entity is object
	link = null
```
- `link` is a `StringName` referring to the engine PackedScene this `object` will instantiate and then control. Setting this value will not take effect until the existing node is destroyed.

#### Character

Characters are Entities that are set up to be able to speak.

```pny
Character is Entity
	message_link = "message_display_window"
	message_prefix = ""
	message_suffix = "<w>"
```
- `message_link` is a `StringName` referring to the engine PackedScene this `object` will instantiate and then control. It can only be changed while not instantiated.
- `message_prefix` is prepended before any Message Block spoken by this Character.
- `message_suffix` is appended after any Message Block spoken by this Character.

#### BackgroundCharacter

These are speaking characters that speak outside of the player's control. They auto-advance through dialogue.

```pny
 BackgroundCharacter is Character
	ignore_input = true
	message_suffix = "<d=3>"
```

# Exceptions

This is a list of warnings or errors that are thrown when certain things are invalid in Penny.

## Warnings

Warnings are messages that appear when a non-critical exception is thrown. The notify level can be adjusted for warnings. Generally it's a good idea to develop using `ignore` or `warn`, and then thoroughly test your game before shipping using the `error` level so you'll be sure to catch all exceptions.

Dynamic Elements (decors, evals, jects) that trigger warnings will make themselves visible in the text.

### `UndefinedDecorationParameterWarning`

This warning is triggered when trying to set a decoration parameter, but the parameter does not exist for that decoration.

```pny
`<wave dummy=5>Hello, world.`
```
> <wave dummy=5>Hello, world. *`UndefinedDecorationParameterWarning 'wave.dummy' not found.`*

### `UndefinedDecorationWarning`

This warning is issued when parsing a decoration. The first token in a decoration sequence refers to the decoration id. Using a decoration that doesn't exist or placing parameters before the identifier will issue this warning.

```pny
`<a=5 wave>Hello, world.`
```
> <a=5 wave>Hello, world. *`UndefinedDecorationWarning 'a' does not exist.`*

### `VestigialDecorationParameterWarning`

Many decorations do not have any parameters. Attempting to set a value for one without any parameters will issue this warning.

```pny
`Hello, <i=0.5>world</>.`
```

> Hello, <i=0.5>world</>. *`VestigialDecorationParameterWarning 'i' does not use any parameters.`*

### `TrailingEndTagWarning`

Trailing end tags are invalid and will issue both compilation and runtime warnings when encountered in Message Blocks.

```pny
`Hello, world.</i>`
```
> Hello, world.\</i\> *`TrailingEndTagWarning: '</i>' found in string.`*

### `InfiniteObjectReferenceWarning`

This warning is issued if Penny is looking for a reference via dot notation and discovers that there is a reference loop within a single object reference evaluation. This occurs by checking for repetition in any reference NOT explicitly written in the 'original' object reference evaluation.

###### Example 1

```pny
obj Rubin
	name = "Rubin"
	self = Rubin				# This is okay
	deep = Rubin.self			# This is okay
	loop = Rubin.loop			# This is NOT OKAY

`[Rubin.loop]`

# <global>.Rubin				# manually written
# Rubin.loop					# manually written			<---┐
	# <global.Rubin>			# evaluated						|
	# Rubin.loop				# evaluated; loop found!	<---┘
```
> \[Rubin.loop\]<br>
> `InfiniteObjectReferenceWarning: 'Rubin.loop' -> 'Rubin.loop' -> ... is a reference loop`

When evaluating the first `Rubin.loop`, Penny will be on the lookout for any more references to `Rubin.loop`. If it finds one, this warning will be issued.

###### Example 2

```pny
obj Rubin
	spouse = Echo
obj Echo
	spouse = Rubin
	colleague = Argo
obj Argo
	loop = Rubin.spouse.colleague.loop.unreachable

`[Echo.colleague.loop.unreachable]`

# <global>.Echo					# manually written
# Echo.colleague				# manually written
	# <global>.Argo				# evaluated
# Argo.loop						# manually written			<---┐
	# <global>.Rubin			# evaluated						|
	# Rubin.spouse				# evaluated						|
	# Echo.colleague			# evaluated						|
	# Argo.loop					# evaluated; loop found! 	<---┘
								# issue warning now!
	# loop.unreachable			# evaluated; never reached
# loop.unreachable				# manually written; never reached
```

> \[Echo.colleague.loop.unreachable\] `InfiniteObjectReferenceWarning: 'Echo.colleague.loop' -> 'Rubin.spouse.colleague.loop' -> ... is a reference loop`

###### Example 3

Just as a demonstration, this block will NOT issue this warning.

```pny
`Rubin's wife's husband's wife is [Rubin.spouse.spouse.spouse].`

# <global>.Rubin				# manually written
# Rubin.spouse					# manually written
	# <global>.Echo				# evaluated
# Echo.spouse					# manually written
	# <global>.Rubin			# evaluated
# Rubin.spouse					# manually written
	# <global>.Echo				# evaluated
```
> Rubin's wife's husband's wife is Echo.

Although there is explicitly written repetition (which *is* redundant), an evaluated reference never matches its host caller, i.e. to issue this warning the reference evaluation would need to find either `Rubin.spouse` or `Echo.spouse` and that never happens.

### `NullEvaluationWarning`

This warning is issued if at any point during an [Evaluation](#evaluations) a `null` value is found. If you're seeing this message while referencing an object, it means that the reference path is valid, but the object itself is not.

###### Example 1

```pny
player_name = null

`Hello, my name is [player_name].`
```
> Hello, my name is NULL.<br>
> `NullEvaluationWarning: 'player_name' has a null value.`

###### Example 2

```pny
obj Rubin
	name = "Rubin"
	mother = Marigold

Marigold = null

`[Rubin]'s mother is [Rubin.mother].`
```
> Rubin's mother is NULL.<br>
> `NullEvaluationWarning: 'Rubin.mother' -> 'Marigold' has a null value.`

This example is slightly misleading because `Marigold` looks like it's supposed to be an object, but it's actually just an attribute with a value of `null`.

## Errors

### `RecursiveInheritanceError`

This error is triggered if an object attempts to inherit from another previously defined object that is supposed to inherit from it.

###### Example 1

```pny
obj Apple is Fruit
obj Fruit is Apple			# Throws error
```

`Apple` is defined as a kind of `Fruit`. Therefore `Fruit` cannot be a kind of `Apple`.

###### Example 2
```pny
obj Orange is Apple
obj Banana is Orange
obj Apple is Banana			# Throws error
```
More plainly, these arrows show the inheritance structure in a loop, which explains why this is invalid.
```
Orange -> Apple -> Banana -> Orange -> ...
```

### `UndefinedObjectKeyError`

This warning is issued if Penny tries to access an `Object` but can't find one with the name provided. This can happen inside a Message Block or in regular code, perhaps during [Duplication](#duplication).

###### Example 1

```pny
`Hello, my name is [Rubin].`
```
> Hello, my name is \[Rubin\].<br>
> *`UndefinedObjectKeyError: 'Rubin' not found in dictionary`*

In this case, `Rubin` has not been defined in the global dictionary, therefore this warning must be issued.

This also occurs if trying to reference (for an object) a dictionary key that doesn't exist.

```pny
obj Rubin
	name = "Rubin"

`[Rubin] exists but [Rubin.father] does not.`
```
> Rubin exists but \[Rubin.father\] does not. *`UndefinedObjectKeyError: 'Rubin.father' not found in dictionary`*

This also occurs recursively if trying to reference an object from another object.
```pny
obj Rubin
	name = "Rubin"
	mother = Marigold

`Rubin exists but [Rubin.mother] does not.`
```
> Rubin exists but \[Rubin.mother\] does not. *`UndefinedObjectKeyError: 'Rubin.mother' -> 'Marigold' not found`*

Or...

```pny
obj Rubin
	name = "Rubin"
	mother = Marigold
	father = Marigold.husband

obj Marigold
	name = "Marigold"
	husband = Barkis

`[Rubin.mother.husband]`
`[Rubin.father]`
```
> \[Rubin.mother.husband\] `UndefinedObjectKeyError: 'Rubin.mother.husband' -> 'Barkis' not found`<br>
> \[Rubin.father\] `UndefinedObjectKeyError: 'Rubin.father' -> 'Marigold.husband' -> 'Barkis' not found`

# Localization

Currently there are no implemented localization features, however, you can create separate scripts for each translation you wish to use and manually change them per localization.

# Miscellaneous

-   Allow either tabs or spaces for indentation
-   Word count tool that counts all pure text (not evals, decors, jects) per script
-   Spell checker?
-   Proofing Mode: Goes through all written text without any flow control using only default values for evaluations
