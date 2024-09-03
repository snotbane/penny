
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

