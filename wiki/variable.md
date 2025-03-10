

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
- `string` — string id with quotes, e.g. `"chapter"`
- `object` — string id with no quotes, e.g. `Rubin`. Contains any other variable type.

## Arrays

Objects can also store arrays (lists) of data.

```pny
Apple = object
	name = "apple"

Rubin = object
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
Apple = object
```

###### Example 2

Objects can store multiple variables. These variables can then be accessed using dot notation.

```pny
Apple = object
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
Apple = object					# Initial definition
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

Apple = object					# (Accidental?) redefinition
	value = 20
	kind = "mana"
`The "[Apple.name]" will restore [Apple.value] [Apple.kind].`
```
> The "" will restore 20 mana.

### Object Implication

Objects are used differently based on what is using them.

- `Object = object` : entire object
- `"@Object"` : use rich_name
- `Object.anim "walk"` : use scene

### Object Referencing

Objects reference other objects when used as attributes. They do not have to be defined before they can be **set** as a reference, but they MUST be defined before they are **accessed**. (see [`UndefinedObjectKeyError`](#undefinedobjectkeyerror)).

###### Example 1

```pny
Rubin = object
	name = "Rubin"
	mother = Marigold

Marigold = object
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
Rubin = Character
	name = "Rubin"
	spouse = Esther

Esther = Character
	name = "Esther"

Rubin
	`Good day, [Rubin.spouse].

Rubin.spouse
	`Good day, [Rubin].`
```
> Good day, Esther.<br>
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
Fruit = object
	base = object

Apple = object
	base = Fruit
```

Both of these definitions are technically valid, but also redundant, because `=` automatically sets `base`. Instead, do:

```pny
Fruit = object

Apple = Fruit
```

###### Example 2

```pny
Fruit = object
	name = "fruit"
	health = 10

Apple = Fruit
	name = "apple"

`A [Fruit] will replenish [Fruit.health] health.\n
An [Apple] will replenish [Apple.health] health as well because it is a kind of [Apple.base].`
```
> A fruit will replenish 10 health.<br>
> An apple will replenish 10 health as well because it is a kind of fruit.

###### Example 2

Inherited objects do not copy their parents' values; they reference them. Therefore, changing a parent's attributes will also change all of their childrens' attributes as well.

```pny
Fruit = object
	name = "fruit"
	health = 10

Apple = Fruit
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

Objects can be duplicated from a template object to target object (rather than being inherited). Use `clone` to accomplish this. This protects the target's attributes from being modified if the template's attributes change. Creating an object in this way creates a sibling of the target object as it inherits from the same parent as the template.

```pny
Apple = object
	name = "apple"
	health = 10

Banana = Apple clone
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

Think of entities like "key items." They cannot speak (by default) but they are set up to have decorations added to their names to make them stand out when evaluated. They can even appear in the world using `scene`.

```pny
Entity = object
	scene = null
```
- `scene` is a `StringName` referring to the engine PackedScene this `object` will instantiate and then control. Setting this value will not take effect until the existing node is destroyed.

#### Character

Characters are Entities that are set up to be able to speak.

```pny
Character = Entity
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
 BackgroundCharacter = Character
	ignore_input = true
	message_suffix = "<d=3>"
```
