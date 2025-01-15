
## Decorations

Use a **Decoration** to modify the formatting of a Message Block or have it take on unique properties. Decorations are defined using a `<start>` tag and an `</>` tag like so:

```pny
`Hello, my name is <i>Rubin</>, it's nice to meet you.`
```
> Hello, my name is _Rubin_, it's nice to meet you.

> [!WARNING]
> Decorations must be closed with a generic auto-terminator. They cannot be closed with an explicit terminator (e.g. `</i>`). They CAN be left unclosed (closed by the end of the string)

### Combining Multiple Decorations

Multiple decorations may be combined into one set of tags. They'll be applied in the order listed, but this usually isn't important.

```pny
`Hello, my name is <b, i>Rubin</>, it's nice to meet you.`
```
> Hello, my name is **_Rubin_**, it's nice to meet you.

> [!TIP] Decorations Best Practice
> It is best practice to apply decorations in this way — use a single start tag to list all decors, and close it with a single auto-terminator tag.

<!-- However, multiple decorations may be applied or unapplied explicitly. Decorations may also overlap.

```pny
`<i, b>Hello, my name is Rubin,</b> it's nice to meet you.`
`<i>Hello, my name is <b>Rubin,</i> it's nice to meet you.`
`<i>Hello, my name is <b>Rubin,</i, b> it's nice to meet you.`
`<i, b>Hello, my name is <u>Rubin,</u, b> it's nice to meet you.`
```

> <i><b>Hello, my name is Rubin,</b> it's nice to meet you.</i><br>
> <i>Hello, my name is <b>Rubin,</i> it's nice to meet you.</b><br>
> <i>Hello, my name is <b>Rubin,</b></i> it's nice to meet you.<br>
> <i><b>Hello, my name is <u>Rubin,</u></b> it's nice to meet you.</i> -->

<!-- ### Custom Decorations

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
``` -->

### Custom Decorations

This kind of user-defined decoration allows one to create custom functionality. This must be done in GDScript from within the engine. Use this template to begin:

```gd
extends Deco

func _get_penny_tag_id() -> StringName:
	return &""

func _get_bbcode_tag_id() -> StringName:
	return super._get_bbcode_tag_id()

func _invoke(message: Message, tag: DecoInst) -> void:
	pass
```



### Miscellaneous

#### Auto-Terminator Tag

Using an auto-terminator tag will terminate the most recent open decoration. It will unapply the decorations in reverse order.

```pny
`<i>Hello, my name is <b>Rubin,</> it's nice to meet you.</>`
`<i>Hello, my name is <u, b>Rubin,</> it's nice to meet you.</>`
```

> <i>Hello, my name is <b>Rubin,</b> it's nice to meet you.</i><br><i>Hello, my name is <b><u>Rubin,</u></b> it's nice to meet you.</i>

#### Placeholder Start Tag

Empty start tags are valid but are completely vestigial and are basically only used as placeholders:

```pny
`<i>Hello, my name is <>Rubin,</> it's nice to meet you.</>`
```

> <i>Hello, my name is Rubin, it's nice to meet you.</i>

#### Self-Closing Decorations

Some decorations are self-closing.

```pny
`Hello, <delay seconds=0.5>world.`
```

Self-closing decorations may be combined with non-self-closing decorations (and will be treated like it closes there).

```pny
`Hello, <d=0.5, i>world.</>`
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

#### `kern` (Kerning)

- From Ren'Py as `k`
- ***Unknown implementation in bbcode***

#### `lock`

- Unique to Penny
- Prevents skipping dialogue / prodding the typewriter, except during `wait`
- Use for very important pieces of dialogue
- Dialogue can still be skipped entirely if holding skip
- No arguments
- Usage:

```pny
I never thought <lock>you would actually believe me...</>
```

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

# Troubleshooting

Decorations work well but are strange to set up. When creating a new deco script, ensure the following:

- The new script calls `Deco.register_instance(DecoNew.new())` in its `_static_init()` method
- The new script belongs to a `PennyDecoRegistry` resource somewhere in the FileSystem
- The `PennyDecoRegistry` exists as metadata somewhere in a scene in the project.

All of this is to ensure that the scripts get loaded properly when packaged.

I have experienced an issue where a new deco script will not appear after following the above steps. My observations are that somehow it is getting statically initialized before the base `Deco` class does, which clears `Deco.MASTER_REGISTRY`. To fix, I removed the new script from the project, ran the game, then placed the script back in. That's all I needed to do.
