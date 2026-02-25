
# Dialog

Writing human-readable, easily-localizable dialog is the core function of Penny. The Penny syntax is developed for the express purpose of making this process as simple and easy to read and write as possible, and such that function and story are comfortably connected, but not inseparably bound to each other.

## The Basics

This is how to declare a dialogue block in Penny:

```pen
>	Hello, world!
```

This will do two things:

1. Open the active **Subject**'s dialog box (if not already open).
2. Display the text `Hello, world!`

This is the most common usage of writing dialogue and will make up the majority of your narrative.

Penny takes several steps to automatically format your text. Each line will have any whitespace trimmed around the edges, and separate lines (with a higher indentation level) will be combined using a space. Generally, you should only write dialog using multiple lines if you are writing very long text or multiple translations. The following example is valid, but not good practice:

```pen
>		Hello, world!

		Goodbye, world...
```
> Hello, world! Goodbye, world...

If you need to keep them on separate lines, use an escape character (`\n`).

```pen
>	Hello, world!\n
	\n
	Goodbye, world...
```
> Hello, world!<br>
> <br>
> Goodbye, world...


> [!NOTE]
> It is common practice to use one tab to separate the dialog definition (`>`) from the dialog text (`"Hello, world!"`). This helps readability when writing different translations, but is not required.

A dialog will include all text which exists on the same or higher indentation level as the declaration.

```pen
esther
>	This text is included.
	This text is included.
		This text is included.
This text will cause an error, as it is treated as a new line.
```

Sometimes it is necessary to explicitly terminate a dialog Message, which can be done by using `;` on the same indentation as the declaration. This is typically used in menues.

```pen
menu
>	Option 1
;
	esther
	> Dialog 1

>	Option 2
	esther
	> Dialog 2
```

`Option 1` is formatted correctly; `Dialog 1` will be considered part of `Option 1`'s branch.

`Option 2` is formatted incorrectly; the option will include all following lines and read `Option 2 esther > Dialog 2` and will not have any branching statements.

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

Sometimes, you may want to separate dialog across multiple lines. This is primarily used to trigger an event in the middle of dialog or separate long chunks of text.

```pen
esther wave
>	Good morning, everybody!

esther idle
+	My name is Esther.
```
> Good morning, everybody! My name is Esther.

This will result in the above dialog to be displayed within the same dialog box, and will also trigger the flag `idle` after finishing the first dialog and before starting the second one. Unless there is an `await` statement between the two dialog declarations, they will display in order, with no delay, as if they were declared in the same block.

You can even chain appendages across multiple decision branches:

```pen
>	Which do you like better?
menu
	>	Apples
	;
		esther
		>	I like apples better.

	>	Oranges
	;
		rubin
		>	Oranges are the best.

+	But that's just my opinion!
```
> `Apples`&emsp;(Esther) I like apples better. But that's just my opinion!<br>
> `Oranges`&emsp;(Rubin) Oranges are the best. But that's just my opinion!

> [!NOTE]
> There are many things you can do in the middle of dialog using tags alone, but keep in mind that tags only apply for the translation which they are a part of. For this reason it is recommended to use tags for translation-specific text, and to append dialog when doing anything that will happen for ALL translations.

## Translations

Dialog can be easily translated per line using a special translation tag. For example, to create a Spanish translation for a single dialog:

```pen
esther
>			Good morning, everyone!
	[es]	Buenos dias a todos!
```

This will define a dialog message to print "Good morning, everyone!" as the default language, and "Buenos dias a todos!" when using Spanish (`es`). Keep in mind that the formatting does not need to be exact, but keeping each translation on the same indentation level is recommended for readability. This setup allows one to write a story with their native language as the default, and very simply add additional translations later on in development.

You can also define different dialogs for different regions using the same language:

```pen
esther
>			¡Oh, qué hermosos colores!
	[en_UK]	Oh, what beautiful colours!
	[en_US]	Oh, what beautiful colors!
```
This will define the first line for US English and the second line for UK English. If the end user's translation is English, but neither US nor UK, the first one listed that matches the language `en` will be used (or the default, if it exists).

In this example, the following translation settings will result in the following dialogs:

>`en_UK`&emsp;"Oh, what beautiful colours!"<br>
>`en_US`&emsp;"Oh, what beautiful colors!"<br>
>`en_AU`&emsp;<mark>"Oh, what beautiful colours!"</mark><br>
>`es_MX`&emsp;"¡Oh, qué hermosos colores!"<br>
>`ja_JP`&emsp;<mark>"¡Oh, qué hermosos colores!"</mark><br>

Although `en_AU` does not exist in the script, it will use the translation for `en_UK` because it still contains the language identifier `en`.
However, `ja_JP` (and any other language configuration) will use the default, which happens to be Spanish. This is the best practice so that it will be obvious if there is a dialog with a missing translation.

```pen
esther
>	[es]	¡Oh, qué hermosos colores!
	[en_UK]	Oh, what beautiful colours!
	[en_US]	Oh, what beautiful colors!
```

In this example, the following translation configurations will result in the following dialogs:

>`en_UK`&emsp;"Oh, what beautiful colours!"<br>
>`en_US`&emsp;"Oh, what beautiful colors!"<br>
>`en_AU`&emsp;"Oh, what beautiful colours!"<br>
>`es_MX`&emsp;"¡Oh, qué hermosos colores!"<br>
>`ja_JP`&emsp;<mark>*(Dialog skipped entirely)*</mark><br>

The only difference here is that there is no default translation. This statement will be omitted for any language which is not explicitly defined. This can be useful if you wish for only specific translations to have an additional dialog box. But as stated before, it's best practice to define a default translation for each dialog.

In Godot, using the function [`OS.get_locale_language()`](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-get-locale-language) will be assumed as the default language.

### Translating Object Names

Sometimes, characters may need different names for different translations. The process is identical to translating dialog boxes and uses the same logic. For example:

```pen
esther
	.name =>
				Esther
		[es]	Ester
		[jp]	エスター
```

When using the character's name in dialog, always use the code-defined identifier.

```pen
rubin
>			Good to see you, @esther.
	[es]	Qué bueno verte, @esther.
	[jp]	会えて嬉しいよ、@esther。
```
> `en_US`&emsp;Good to see you, Esther.<br>
> `es_MX`&emsp;Qué bueno verte, Ester.<br>
> `jp_JP`&emsp;会えて嬉しいよ、エスター。<br>

## String Interpretation

For Godot, strings are interpreted this way:

- 'single quotes' will create a `StringName`. Typically used as in-engine identifiers. Do not use these for dialog.
- "double quotes" will create a literal `String`. Typically used for file paths. These can be used in a `Message` but all contents will be displayed exactly as shown in the quotes.
- \`backtick quotes\` will create a literal `Message`. Use this for any localized, processed text.
- Using triple quotes of any kind will allow you to use that same type of quote within it, e.g. `"""She said "hello" to him."""`
