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

They do not need to be formatted exactly like this, but this is the typical way to do so. As long as subsequent lines are one indent level higher than the quote block operator ( `>` ), they will all be considered part of the same message block. If the first translation in
the list is not specified, it will be used as a fallback for any missing translations.

#### Using Variables in Messages

You may wish for certain objects (i.e. characters) to be displayed with special attributes. You can use the `@` operator to reference these values within Messages.

```penny
def Rubin = new object
	.name => Rubin

>	Hello, @Rubin.

```

The `name` attribute is always used when referencing a `Penny.Cell` in a message. If the name has multiple translations, they will be assigned accordingly.

```penny
def Rubin = new object
	.name => Rubin
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
Rubin
>	Hello, my name is @Rubin.

>	I'm 24 years old and I'm from Mars.

## Set the new context to `~` (narrator).
~
>	Rubin looked around the room. Everyone was staring at him.
```
