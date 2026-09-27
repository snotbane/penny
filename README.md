# Penny Scripting Language

Penny is a scripting language used to create dialogue sequences. This guide will show how to use it in Godot.

## Creating a Script

Create a new file somewhere in `res://` and name it something like `script.pen` . This will create a [`PennyScript`](addons/penny/script/PennyScript.gd) resource. When the game starts, it will be initialized, provided that the associated autoload Node is enabled. This will also create an implicit, but fully functional, label which is the same name as the file (e.g. `script`).

## Running a Script

In an existing scene, create a new node of type [`PennyPlayer`](addons/penny/script/PennyPlayer.gd) , either by adding it to the SceneTree in the editor, or by manually adding it via script at runtime. In its properties, you can set which label it should start at. You can then either check `autostart` and the script will run on ready, or manually call `play_from_start()` whenever you want. Alternatively, you can ignore these properties and call `play(at_label: StringName)` to specify where to start.

## Statements

This section describes different statements and how to invoke them.

### Say

This is the most common kind of statement in Penny and describes an individual dialog bubble for an object (i.e. character) to speak. The best way to invoke this is to use the quote block operator `>` .

The following statement will create a new dialog and display a [`Penny.Message`](addons/penny/script/text/Message.gd) to the user:

```penny
>	Hello, world.
```

#### Translations

You can multiple translations for a single Say statement using brackets `[]` and a language code.

```penny
>		Hello, world.
	[es]
		Hola, Mundo.
	[ja]
		こんにちは、世界。
```

They do not need to be formatted exactly like this, but this is the typical way to do so. As long as subsequent lines are one indent level higher than the quote block operator ( `>` ), they will all be considered part of the same message block. If the first translation in the list is not specified, it will be used as a fallback for any missing translations.

> [!NOTE]
> Separating translations is the first thing that happens when parsing messages. Any decorations you place in one translation will need to be repeated in others.

#### 1. Interpolating Variables

You may wish to display variables inside your text, for example, to display the player's name if they have entered it themselves. You can use the `@` operator to reference any Penny variable within Messages. This process is called **Interpolation**.

```penny
def Rubin = new object
	.text => Rubin

>	Hello, @Rubin.

```

Alternatively, you can use curly braces `{}` to interpolate an Expression. This is virtually identical to using the `@` operator, but this allows you to combine multiple symbols together.

```penny
var apple_count = 5

Rubin
>	You only got { apple_count } apples? I got { apple_count + 3 } apples!

## This will display the following:

>	You only got five apples? I got eight apples!
```

The `text` attribute is always used when referencing a `Penny.Cell` in a message. If the name has multiple translations, they will be assigned accordingly.

```penny
def Rubin = new object
	.text => Rubin
		[ru] Рубин
		[ja] ルービン
		[zh] 鱼宾

>		Hello, @Rubin.
	[es]
		Hola, @Rubin.
	[ja]
		こんにちは、@Rubin。

## This will display the following:

>		Hello, Rubin.
	[es]
		Hola, Rubin. (fallback)
	[ja]
		こんにちは、ルービン。

```

#### 2. Filters

[`Penny.Filter`](addons/penny/script/text/Filter.gd)s allow you to use [Regular Expressions](https://en.wikipedia.org/wiki/Regular_expression) to automatically replace certain text with new text. You can do this by setting the `filters` value of an object to an array:

```penny
def object.filters = [
	"apples" -> "oranges",
]

>	I have 10 apples.

## This will display the following:

>	I have 10 oranges.
```

> [!NOTE]
> Filtration occurs in between Interpolation and Decoration. But, because filters are often used to create Decorations, they also will not apply to any text within Decorations.

The default filters are as follows:

```penny
def object
	## This matches to the start of the string. It is listed as a separate variable so that it can be modified without having to modify the filters array.
	.filter_start = "^" -> "<dropin|dropout>"

	.filters = [
		.filter_start,

		## This is used to create a short delay after most punctuation,
		## to mimic pauses in speech.
		"(?<!(?:Mx|Mr|Dr|Prof)s?)((?:[.,?!:;](?!\S))|-{2,})+[\'\")\]]?(?!$)" -> "$0<delay>",

		## Makes ellipses print slowly.
		"\.{2,}" -> "<delay=0.2 | speed=5>$0</>",

		## Converts pipes to delays.
		"(?<!\\)\|" -> "<delay>",

		## Converts slashes to waits.
		"(?<!\\)\/" -> "<wait>",

		## Converts individual dashes to em dashes.
		"---" -> "—",
		"--" -> "–",

		## Replaces normal quotes with rich quotes
		'(\S)"' -> '$1”',
		'"' -> '“',
		"(\S)'" -> "$1’",
		"'" -> "‘",
	]


```

> [!IMPORTANT]
> Filters cannot self-recur, but they are applied to the entire message, in the order which they are provided in the array. Therefore, changing the order will change how they are applied.

The most common way to add filters is to append them to the existing array in the base object, e.g.:

```penny
def object.filters += [
	"apples" -> "oranges"
]
```

#### 3. Numeric Lingulation

In literature, it is often improper to display numerals directly. Case in point:

```penny
>	I ate three apples.

>	I ate 3 apples.
```

Penny will, by default, automatically convert any numeric values into their linguistic counterparts. Therefore, the two above messages will actually display identical text.

This can be controlled by modifying the following values (these are the defaults):

```penny
## e.g. Mach 3.4 -> Mach three-point-four
def auto_lingulate_float = false

## e.g. 3 apples -> three apples
def auto_lingulate_int = true

## e.g.
##	3:00 AM -> three o'clock a.m.
## 	17:30 -> seventeen thirty
def auto_lingulate_time = false
```

Alternatively, if you wish to define a segment of text which is affected (or not) by this, you can use the `<lingulate>` and `<digitize>` tags. This will explicitly define how the text should be lingulated (or not), regardless of any of the `auto_lingulate_` settings:

```penny
var number = 3.5

>	I saw <digitize>@number</> ships.
#	I saw 3.5 ships.

>	I saw <lingulate>@number</> ships.
#	I saw three-point-five ships.

>	I ate <lingulate=int>@number</> ships.
#	I ate four ships. -- Note that the value is rounded.

>	I was going Mach <lingulate=float>@number</>.
#	I was going Mach three-point-five.

>	I was wearing the Mark <lingulate=roman>@number</> Hazard Suit.
#	I was wearing the Mark IV Hazard Suit. -- Note that the value is rounded.
```

> [!NOTE]
> Using `<lingulate=roman>` is the only way to convert a number to roman numerals.

> [!TIP]
> If you want even more precise control over how each type is parsed, particularly if you are writing scripts which heavily rely on numeric variables, you can directly modify the following functions in the [`MessageParser`](addons/penny/script/parse/MessageParser.gd) :
>
> - `lingulate_int()`
> - `lingulate_float()`
> - `lingulate_time()`
> - `lingulate_roman()`

#### 4. Decoration

Oftentimes you'll want to spruce up your text to make it look more dynamic. This can be done with HTML-like **Decoration**s. This is functionally the same as using [BBCode tags](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html) (and all bbcode tags are supported), but Penny Decorations provide additional decorations with some extra features.

Most of these extra decorations are for use in [`TextTypewriter`](<>) s.

Unlike HTML tags, Penny tags are very dynamic. Here are a few examples:

```penny
## This is the most common way to apply a decoration; with an explicit start tag and an implicit end tag (</>).
> <b>Hello, world.</>

## You can also use explicitly defined end tags.
>	<b>Hello, world.</b>

## An unclosed tag will function as if it is closed at the end of the message.
> <b>Hello, world.

## You can apply multiple decorations within the same tag.
>	<b|i>Hello, world.</>

## You can end one or more tags explicitly as well.
>	<b|i|u>Hello,</i|u> world.</>

## You can even independently interlock tags.
>	<b>Hello, how <i>are you</b> doing today?</>

## Finally, you can use the special end all tag </*> to completely clear the tag stack.
>	<b>Hello, how <i>are you</*> doing today?
```

> [!NOTE]
> A little bit about how this works:
>
> - Using an implicit end tag (`</>`) will always end the most recently used tag.
> - Using an explicit end tag (e.g. `</b>`) will search backwards through the tag stack to find any unclosed decoration. If a decoration inside an end tag does not exist, this will do nothing. If it is unclosable, a warning will be displayed.
> - The end all tag `</*>` implicitly occurs at the end of each message translation.

##### Creating Custom Decorations

In order for a decoration to be usable in your project, it must exist inside the `res://addons/penny/decorations/` directory. Create a new PennyDecoration Resource there, and give it a **unique** id.

> [!NOTE]
> The subfolder `res://addons/penny/decorations/builtin/` is where Penny's built in decorations are located. Please do not modify these.

#### Unique Dialog Nodes

If you wish for different characters to have different dialog boxes, you can specify this by setting the `prompt_say` property:

```penny
## Define a new object called `Rubin`.
def Rubin = new object

	## Set Rubin's unique prompt_say to be a new object
	## based on `prompt_say` (a built in object).
	.prompt_say = new prompt_say

		## Set the scene of this prompt_say to a valid scene file path.
		.scene = "res://Rubin_PromptSay.tscn"


## Then specify that Rubin is speaking.
Rubin
>	Hello, world.

## Or:
Rubin > Hello, world.
```

Say statements will always use the most recent context specified, until a new one is specified.

```penny
## Set the context (speaker) to Rubin.
Rubin
>	Hello, my name is @Rubin.

## Rubin will also say this.
>	I'm 24 years old and I'm from Mars.

## Set the context (speaker) to `~` (narrator).
~
>	Rubin looked around the room. Everyone was staring at him.

## Set the context (speaker) to Esther.
Esther
>	Excuse me @Rubin, you're from MARS??
```

# Decorations

## Builtin Decorations

- `<b>` **Bold.**
- `<i>` _Italic._
- `<u>` Underline.

## Preprocessed Decorations

Preprocessed decorations perform their action before any other tag and can be used to modify the text which will be decorated. Because of this, it is best practice to give them their own tag, and to ensure that any non-preprocessed tags located between any preprocessed tags are completely self-contained and do not overlap, as this may cause issues. Unlike translations, they are not automatically separated.

### `<if>`, `<elif>`, and `<else>`

These three tags can be used to provide conditional text within a single message. `<if>` and `<elif>` each take a single boolean parameter. This functionality is primarily used to make small adjustments to a message.

```penny
var emotion = 1

>	Hello, I am feeling
		<if={ emotion == 0 }>		happy
		<elif={ emotion == 1 }>		angry
		<else>						sad
	</>today. How about you?
# Hello, I am feeling angry today. How about you?
```

> [!TIP]
> The above formatting is not necessary for the if-block to work, but it is tremendously helpful in maintaining sanity. Here's what this looks like on a single line, just for morbid curiosity's sake:
>
> ```
> Hello, I am feeling <if={ emotion == 0 }>happy<elif={ emotion == 1 }>angry<else>sad</>today.
> ```
>
> Miserable.

> [!NOTE]
> `<if>` is considered a closable decoration, while `<elif>` and `<else>` are standalone tags that rely on an `<if>` tag. You can even place if-blocks inside of each other.

### `<repeat>`

This tag can be used to repeat a span of text, including whitespace (which is normally automatically trimmed).

```penny
var times = 10

>	I'm feeling s<repeat=@times>o</> good today!
#	I'm feeling soooooooooo good today!
```

## Typewriter Decorations

These are special decorations which can only be used with a [`TypewriterTextLabel`](addons/penny/scene/typewriter/TypewriterTextLabel.gd). Any decoration which affects the timing of how characters being printed out, or audio, should be of this type.

- [`<advance/>`](#advance)
- [`<delay/>`](#delay)
- [`<dropin|dropout>`](#dropin-and-dropout)
- [`<lock>`](#lock)
- [`<pokestop/>`](#pokestop)
- [`<rate>`](#rate)
- [`<retcon>`](#retcon)
- [`<sfx>`](#sfx)
- [`<skip>`](#skip)
- [`<speed>`](#speed)
- [`<stroke>`](#stroke)
- [`<volume>`](#volume)
- [`<wait/>`](#wait)

### `<advance/>`

Automatically aborts the typewriter and emits the `advanced` signal, which, when used with Penny, continues execution.

```penny
>	I thought you were going to--<advance>
>	Shh! Not in front of mom!
```

> [!NOTE]
> This can be placed anywhere in the text, but is only really useful at the end of a message.

### `<delay/>`

Waits a constant amount of time before continuing.

```penny
>	I<delay> love<delay> you.
```

There is a default filter in place which automatically converts pipe characters `|` to the default delay. The above text can be rewritten as:

```penny
>	I| love| you.
```

You can also customize the amount of time to wait, like so:

```penny
>	I...<delay=2.5> love<delay=1> you.
```

### `<dropin>` and `<dropout>`

These are examples of decorations which allow the text to appear and disappear using a [`RichTextEffect`](<>). You may modify these to your liking or use them as a template. With decorations like this, it is most applicable to have them span the entirety of your message, and furthermore, to add them to a filter. These ones are part of the default attribute `object.filter_start`.

```penny
>	<dropin|dropout>Hello, world!</>
```

### `<lock>`

Defines a span of text during which user input to the typewriter will be disabled. The lock will always be released when the text finishes printing. This can be used to ensure the user does not accidentally advance through important text.

```penny
>	I thought you were going to be <lock>at the party.</>
```

> [!NOTE]
> This is considered a **poke stop**, meaning that if the user attempts to skip this text, the text will skip to this point and then continue as normal.

### `<pokestop/>`

Defines a poke stop. What this means is, if the user attempts to skip this text, the text will skip all the way until it reaches the first poke stop, or if there are none, to the end of the text. This is not the only tag which can create a poke stop.

```penny
>	Where are you going? <pokestop>To the supermarket? <pokestop>I thought so.
```

### `<rate>`

Defines a span of text which should print out at a specific rate. The argument passed will be a float measuring the characters per second to print out. This will override all other variables influencing typewriter speed, including user settings and `<speed>` decorations. For setting a relative print speed which factors in user settings, use [`<speed>`](#speed).

### `<retcon>`

This decoration defines a span of text which will be printed out, and then un-printed out in reverse, before continuing.

```penny
>	But... I thought you were going to <retcon>the movies</>the grocery store.
```

> [!TIP]
> Good practice to place a `<delay>` at the end of the span, so that the reader has time to read the retconned text.

### `<sfx>`

Use this to play a one-shot sound effect at this moment. If used as a span, the span of text will not advance until the audio has completed, regardless of the speed of the text. This functionality can be used to ensure that voice over audio syncs up with subtitles.

```penny
>	Look out! He's got a hammer! <sfx="bonk.ogg"/>Yeowch! He got me!
>	Look out! He's got a hammer! <sfx="bonk.ogg">Yeowch! He got me!
```

> [!NOTE]
> These two lines are different. The first one will finish playing the sound before continuing because the tag is an open-and-shut tag; whereas the second will continue printing out text with no delay because the end of the tag is implicitly at the end of the string. In this case, the text will not finish printing until the sound is finished playing, or until the user pokes the text.

There are several parameters which can be passed:

```penny
>	<
		sfx="voice_over.ogg"
		channel=0
		source=.voice
		volume=1.0
		wait=true
	>
```

- `sfx` defines the audio resource path to play. Must be a String.
- `channel` (default is `0`) Can be an `int` or `String` referring to a voice channel
- `source` (default is `.voice`) Can be a path to a `Cell` with an instance, which must be an `AudioStreamPlayer` of some kind, and tells that Node to play the audio from it. Note that the default refers to the currently speaking character's `.voice` Cell. If it is null, this will use the TypewriterTextLabel's default AudioStreamPlayer.
- `volume` is a float percentage which determines the volume of the sound.
- `wait` (default is `true`) determines if the span of text must complete before text can continue.

### `<skip>`

Defines a span of text which will instantly print out the moment it is encountered. Effectively the same thing as using `<speed=INF>`, but more direct/robust.

```penny
>	And the winner is... <skip>@Rubin!</> Congratulations!
```

### `<speed>`

Defines a span of text which should be printed at a different relative speed. The argument passed will be a percentage of the base speed. For overriding the base speed, use [`<rate>`](#rate).

### `<stroke>`

Defines a span of text which overrides the audio played when typing per character. The argument passed should evaluate to a String path which points to an `AudioStream` resource, which will be used to print out characters. Usually this is a path relative to the speaker.

```penny
>	<stroke=.sad>I thought I could trust you... <stroke=.angry>but you HURT me!
```

### `<volume>`

Defines a span of text which alters the volume of per-character audio. The argument passed should be a percentage float (0.0-1.0) representing linear volume. This does NOT affect the audio in any `<sfx>` tags.

### `<wait/>`

This tag waits for the user to **poke** (interact with) the text before continuing.

```penny
>	I never knew him.<wait> ...But I did know his father.
```

There is a default filter in place which automatically converts slash characters `/` to the default poke. The above text can be rewritten as:

```penny
>	I never knew him./ ...But I did know his father.
```

You can also pass a string argument to wait for a specific signal. This can be used to customize specific conditions, e.g. in a tutorial. The default argument is `poke`, which TypewriterTextLabels handle by default. The argument should be a path that points to a Cell, which has an instance, and a signal of that name.

```penny
>	Let's learn how to fight!<wait> First, swing your sword.<wait=player.sword_swing> Great! Now jab!
```

> [!TIP]
> The default method for sensing a poke is simply to wait for the user to click anywhere on the screen. But this can be changed to any method by connecting signals from any node to `TypewriterTextLabel.receive_poke()`. But in most cases, you'll usually want to separate stuff like this across multiple text boxes.

## Miscellaneous Decorations

### Combo Decorations

Combo Decorations can be used to combine multiple existing decorations into a single one. These are very easy to create and require zero coding!

> [!WARNING]
> Combo Decorations are preprocessed. Therefore, while it is technically possible to add other preprocessed decorations to a Combo Decoration, this is highly discouraged. However, you can add multiple ComboDecorations.

> [!NOTE]
> Arguments can be passed to a combo decoration, and each one will be propagated to all child decorations. Therefore, if two decorations share the same argument, they will both be set. As of now, there is no way to distinguish these.

### `<like>`

This special kind of **Combo Decoration** will format a span of text such that it appears like another object. This can be useful if you want one of your characters to refer to another character without using their name, but still keep that other character's formatting.

```penny
>	Hello, I'm looking for <like=Rubin>your son</>.
```

> [!IMPORTANT]
> This tag assumes that all of the following are true regarding the argument:
>
> - The argument is a **RAW** string. If you write it something like: `<like=@Rubin>`, this will trigger an **interpolation** and possibly translate the path, which is likely to result in an error.
> - The argument is a path pointing to a String attribute, or object attribute (`.text` will be used).
> - The String attribute is a raw string, or a Message containing a default translation.
> - The default translation contains one or more tags _at the very beginning_. These tags/decorations will be the ones used to decorate the span.
