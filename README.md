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
def object.filters = [
	# ## Match the start of the string.
	# ## you can use this to establish decorations that apply to the entire message.
	# "^" -> "<p>\t",

	## This culls all trailing or expanded whitespace and replaces it with a single space.
	## To artifically extend whitespace, use the <char=' ' repeat=(x)> tag.
	"\s+" -> " "

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

In order for a decoration to be usable in your project, it must exist inside the `res://addons/penny/decorations/` directory. Create a new Resource there.

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
