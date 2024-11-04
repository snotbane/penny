
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
heavy = decor
	b
	i
```

###### Example 2

```pny
highlight = decor
	b
	color = #ffff00
	wave
```

###### Example 3

```pny
wave = decor
	a = 5
	p = 2
	s = 10
```

###### Example 4

```pny
d = decor
	value = 0.5
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
slow = decor
	b; i; speed = 10			# Set the default value for `slow.speed`

`<slow>Hello, world.</>`
`<slow speed=2>Hello, world.</>`
```

> <b><i>Hello, world.</b></i> _(Printed at 10 chars per second)_<br>
> <b><i>Hello, world.</b></i> _(Printed at 2 chars per second)_

```pny
dec bik = k				# Use `k` as the proxy attribute.
	b; i; k = 2.0			# Set the default for `k`

`<bik=10>Hello, world.</>`	# Setting `bik` will actually set `k`.
```

> <b><i>H e l l o , w o r l d .</b></i>

#### Custom Decorations

This kind of user-defined decoration allows one to create custom functionality. This must be done in GDScript from within the engine. Use this template to begin:

```gd
extends Deco

## Used to identify the decoration, for example "<new>"
static func _get_id() -> String:
	return "new"

## Used to modify the message.
static func _modify_message(message: Message, tag: DecoInst, content: String) -> String:
	return content
```



### Decoration List

#### `a` (Anchor)

- From Ren'Py
- Creates a `[url]` bbcode tag.
- Optional string argument
- Usage:

```pny
<a>https://www.google.com/</>

<a="https://www.google.com/">Google</>
```

#### <s>`alpha` (Opacity)</s>

- From Ren'Py
- Deprecated, see [`color`](#color)

#### <s>`alt` (Alt text for image)</s>

- From Ren'Py
- Deprecated, no replacement.

#### `b` (bold, strong)

- Used in both Ren'Py and bbcode
- Creates a `[b]` bbcode tag.
- No arguments

#### `color`

- Used in both Ren'Py and bbcode
- Creates a `[color]` bbcode tag.
- Required color argument
- Usage:

```pny
<color=#ff0000>Solid red</>
<color=#ffffff80>Transparent white</>
```

#### `delay`

- Modified from Ren'Py, unique to Penny
- Creates a timed break in printing out text via typewriter
- Not affected by input (trying to advance before/during a delay will skip all the way till the next [`wait`](#wait) tag)
- Only affects typewriters
- Required float argument, time in seconds
- Usage:

```pny
String A <delay=0.5>String B
```

#### `fast`

- Used in Ren'Py
- Sets the starting point of a message to this point
- Use only one per message
- Usage:

```pny
I thought you were going to go to the party—<next>
I thought you were going to go to <fast>school...
```

#### `font`

- Used in Ren'Py and bbcode
- Creates a `[font]` bbcode tag
- Required string argument

#### `i` (Italics, emphasis)

- Used in Ren'Py and bbcode
- Creates a `[i]` bbcode tag
- No arguments

#### `if, elif, else`

- Unique to Penny
- Use these tags to create text that conditionally appears
- Required bool argument
- Usage:

```pny
seen_echo_before = false
Rubin `Hello, nice to meet you. <if=seen_echo_before>Haven't I seen you somewhere before?<else>I've never seen anyone quite like you before.</>`
```

#### `img`

- Used in Ren'Py as `image`
- Creates a `[img]` bbcode tag

#### `k` (Kerning)

- From Ren'Py
- ***Unknown implementation in bbcode***

#### `next`

- From Ren'Py as `nw`
- When encountered, instantly advance to the next statement without waiting for user input
- No arguments, no close tag
- Typically at the end of a message
- Usage:

```pny
I thought you were going to—<next>
```

#### `s` (Strikethrough)

- Used in bbcode
- Creates a `[s]` tag
- No arguments

#### `sfx`

- Unique to Penny
- Plays a sound effect when printed out
- Required link argument

#### `size`

- Used in Ren'Py and bbcode
- Creates a `[font_size]` bbcode tag
- Required int argument

#### <s>`space`</s>

- From Ren'Py
- Deprecated for now, does anyone actually use this?

#### `type_sound`

- Unique to Penny
- Sets the sound effects the typewriter uses during printout
- Required link argument
- Usage:

```pny
Normal text <typesound=$angry_text>Angry text!!!</> Normal text again.
```

#### `type_speed`

- From Ren'Py as `cps`
- Temporarily sets the typewriter's print speed in characters per second
- Required float parameter

#### `u` (Underline)

- Used in Ren'Py and bbcode
- Creates a `[u]` bbcode tag
- No arguments


#### `va` (Voice acting)

- Unique to Penny
- Plays a voice acting sound
- Prevents text from continuing until both sound and text are finished playing/displaying (unless manually interrupted) at the tag end or the next `va` tag
- Only affects typewritten text
- Required link argument
- Usage

```pny
<va=$va_going_to_store>I was just going to go to the store. <va=$va_need_some_milk>I really need some milk.
```

#### <s>`vspace`</s>

- Used in Ren'Py
- Deprecated for now

#### `wait`

- Used in Ren'Py as `w` (partially)
- Acts as a stopping point for the typewriter
- Waits for input from the user to continue printing text.
- Trying to advance while currently printing will auto complete text up to the next one of these
- Trying to advacne while stopped at one of these will begin printing again

### These decorations will be removed from Ren'Py (for now):

-   `{art}`
-   `{done}` Stop printing (for spacing parity between separate lines)
-   `{outlinecolor}`
-   `{plain}`
-   `{rb}`
-   `{rt}`
-   `{clear}`

