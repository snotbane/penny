
# Dialog

Writing human-readable, easily-localizable dialog is the core function of Penny. The Penny syntax is developed for the express purpose of making this process as simple and easy to read and write as possible, and such that function and story are comfortably connected, but not inseparably bound to each other.

## The Basics

This is how to define some dialogue in Penny:

```pen
>	Hello, world!
```

This will do two things:

1. Open the most recent Subject's dialog box (if not already open).
2. Display the text "Hello, world!" for the most recent Subject.

This is the most common usage of writing dialogue and will make up the majority of your narrative.

### Whitespace

Any whitespace before or after the text will be removed. If starting a dialog with whitespace is necessary, use \`backtick quotes\`:

```pen
>	`    Hello, world!`
```
> ____Hello, world!

Furthermore, The dialog text written on separate lines is treated as being written on the same line, as long as it's on a higher tab. Separate lines will be concatenated with a single space. To keep them on separate lines, use an escape character (`\n`).

```pen
>	Hello, world!
	It's nice to see you today!
```
> Hello, world! It's nice to see you today!

```pen
>	Hello, world!\n
	It's nice to see you today!
```
> Hello, world!<br>
> It's nice to see you today!


> [!NOTE]
> It is common practice to use one tab to separate the dialog definition (`>`) from the dialog text (`"Hello, world!"`). This helps readability when writing different translations, but is not required.

A dialog will include all text which exists on the same or higher tab depth as the declaration starter (`>`), or until it encounters a declaration ender (`<`). An ender is necessary when creating rich menu options, because following branches will exist

```pen
>	This text is included.
	This text is included.
		This text is included.
This text will cause an error.

menu
>	Option 1
-
	esther
	> Dialog 1

>	Option 2
-
	esther
	> Dialog 2
```

### Closing a Dialog Box

Use the shorthand `-` to close the currently open dialog box (if there is one).

```pen
> Hello, world!
-

> It's nice to see you today!
```

This is equivalent to the following:

```pen
> Hello, world!
subject.dialog.close()

> It's nice to see you today!
```

## Subjects

Most stories require more than one character to speak. In Penny, any defined object can speak, even if it's not a character with a name and a face. Assuming that the character `esther` is already defined, this is how to define some of her dialogue:

```pen
esther
>	Good morning, everyone.
```

This will do multiple things:

1. `ln 1` Set `esther` as the most recent **Subject**
2. `ln 2` Close any currently open dialog boxes.
3. `ln 2` Open the most recent **Subject**'s (`esther`'s) dialog box (if not already open).
4. `ln 2` Display the text "Good morning, everyone." for the most recent **Subject** (`esther`).

The root `object` is the **Default Subject**. This can also be thought of as the narrator. To return to writing for the default **Default Subject**, use the shorthand `~`:

```pen
~
>	Esther sat down at her desk.
```

You can set the **Default Subject** in the root object's definition:

```pen
default_subject = esther
```

Now `esther` will be the **Default Subject**:

```pen
~
>	Good morning, everyone! My name is Esther.
```

## Referring to an Object in Dialog

Often times you'll want characters or special phrases to stand out in your text. For example, characters may have a colored name, or items might have an icon appear next to them or the icon might replace the name altogether. This can be done by altering the `name` attribute in the penny object, and using `@` to reference the object. This method is called string interpolation and it is the best way to reduce extra code and tags in your script.

```pen
esther.name => <color=#0000ff>Esther</>

esther
>	Good morning, everyone! My name is @Esther.
```
> Good morning, everyone! My name is [color=#0000ffff]Esther[/color].

One can even combine multiple interpolations together. A very typical setup where all characters have a colored name may be set up like:

```pen
object
	.name => @.prefix@.f_name</>
	.prefix => <color=@.color>

esther = new object
	.f_name => Esther
	.color = #0000ff

esther
>	Good morning, everyone! My name is @Esther.
```
> Good morning, everyone! My name is [color=#0000ffff]Esther[/color].

The resulting text is the same as before, but it allows you to set up multiple characters with the similar attributes and greatly reduces redundancy.

## Appending Dialog

Sometimes, you may want to separate dialog across multiple lines. This is primarily used to trigger an event in the middle of dialog.

```pen
esther wave
>	Good morning, everybody!

esther idle
+	My name is Esther.
```
> Good morning, everybody! My name is Esther.

This will result in the above dialog to be displayed within the same dialog box, and will also trigger the flag `idle` after finishing the first dialog and before starting the second one.

> [!NOTE]
> There are many things you can do in the middle of dialog using tags alone, but keep in mind that tags only apply for the translation which they are a part of. For this reason it is recommended to use tags for translation-specific text, and to append dialog when doing anything that will happen for ALL translations.

## Translations

Dialog can be easily translated per line using a special translation tag. For example, to create a Spanish translation for a single dialog:

```pen
esther
>			Good morning, everyone!
	[es]	Buenos dias a todos!
```

This will define a dialog message to print "Good morning, everyone!" as the default language, and "Buenos dias a todos!" when using Spanish (`es`).

You can also define different dialogs for different regions using the same language:

```pen
esther
>			¡Oh, qué hermosos colores!
	[en_UK]	Oh, what beautiful colours!
	[en_US]	Oh, what beautiful colors!
```
This will define the first line for US English and the second line for UK English. If the end user's translation is English, but neither US nor UK, the first one listed that matches the language `en` will be used (or the default, if it exists).

In this example, the following translation settings will result in the following dialogs:

>`en_UK` > "Oh, what beautiful colours!"<br>
>`en_US` > "Oh, what beautiful colors!"<br>
>`en_AU` > <mark>"Oh, what beautiful colours!"</mark><br>
>`es_MX` > "¡Oh, qué hermosos colores!"<br>
>`ja_JP` >	<mark>"¡Oh, qué hermosos colores!"</mark><br>

Although `en_AU` does not exist in the script, it will use the translation for `en_UK` because it still contains the language identifier `en`.
However, `ja_JP` (and any other language configuration) will use the default, which happens to be Spanish. This is the best practice so that it will be obvious if there is a dialog with a missing translation.

```pen
esther
>	[es]	¡Oh, qué hermosos colores!
	[en_UK]	Oh, what beautiful colours!
	[en_US]	Oh, what beautiful colors!
```

In this example, the following translation configurations will result in the following dialogs:

>`en_UK` > "Oh, what beautiful colours!"<br>
>`en_US` > "Oh, what beautiful colors!"<br>
>`en_AU` > "Oh, what beautiful colours!"<br>
>`es_MX` > "¡Oh, qué hermosos colores!"<br>
>`ja_JP` >	<mark>*(Dialog skipped entirely)*</mark><br>

The only difference here is that there is no default translation. This statement will be omitted for any language which is not explicitly defined. This can be useful if you wish for only specific translations to have an additional dialog box. But as stated before, it's best practice to define a default translation for each dialog.

In Godot, using the function [`OS.get_locale_language()`](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-get-locale-language) will be assumed as the default language.

> [!NOTE]
> You can write multiple translations on the same line, e.g.
> ```pen
>>	Hello! [es] ¡Hola! [jp] こんにちは！
> ```
> ...but that is considered bad formatting. Instead, write it like this:
> ```pen
>>			Hello!
>	[es]	¡Hola!
>	[jp]	こんにちは！
> ```
> Doesn't that look so much nicer?

### Translating Object Names

Sometimes, characters may need different names for different translations. The process is identical to translating dialog boxes and uses the same logic. For example:

```pen
Esther
	.name =>
				Esther
		[es]	Ester
		[jp]	エスター
```

When using the character's name in dialog, always use the code-defined identifier.

```pen
Rubin
>			Good to see you, @Esther.
	[es]	Qué bueno verte, @Esther.
	[jp]	会えて嬉しいよ、@Esther。
```
> `en` "Good to see you, Esther."<br>
> `es` "Qué bueno verte, Ester."<br>
> `jp` "会えて嬉しいよ、エスター。"<br>

## String Interpretation

For Godot, strings are interpreted this way:

- 'single quotes' will create a `StringName`. Typically used as in-engine identifiers. Do not use these for dialog.
- "double quotes" will create a literal `String`. Typically used for file paths. These can be used in a `Message` but all contents will be displayed exactly as shown in the quotes.
- \`backtick quotes\` will create a literal `Message`. Use this for any localized, processed text.
- Using triple quotes of any kind will allow you to use that same type of quote within it, e.g. `"""She said "hello" to him."""`
