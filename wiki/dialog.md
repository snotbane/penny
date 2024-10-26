
# Dialogs

A.K.A. messages, text blocks, whatever. The stuff you actually READ. Super easy to write:

```pny
Rubin `Hello, world.`
```

The left expression represents the speaking object; the final string in the statement is the actual text that is sent to the dialog Node. If no speaking object is specified, the default object is used.

Everything you see in Penny is instantiated from a preexisting object in the game's data, including dialogs. These can be manually overwritten but their names are important. This is the default dialog object:

```pny
dialog = new object
	.base = object
	.link = $dialog_default
	.link_layer = 0
```

Due to inheritance, objects will all share the same dialog object, and thus the same text box, which will persist until it is manually closed. Characters that inherit their `.dialog` object from the default will all share that one (as if they are the same character.) All of this to say, this is the default behavior for Ren'Py.

If you want different characters to have *different* dialog boxes, or have the dialog boxes close between characters, you'll need to assign a new dialog object to every character. For example:

```pny
Rubin = new object
	.dialog = new dialog

Echo = new object
	.dialog = new dialog

Argo = new object
	.dialog = new dialog
```

You can mix and match them if you wish. It all depends on inheritance. For example, all characters of a certain gender may use the same type of dialogue box.

```pny
Character = new object

Male = new Character
	.dialog = new dialog
		.color = #ff0000

Female = new Character
	.dialog = new dialog
		.color = #00ffff

Rubin = new Male
	.dialog = new base.dialog

Echo = new Female
	.dialog = new base.dialog

## These two will share THE SAME dialog box, not only the same link.

System = new object
Narrator = new object
```

