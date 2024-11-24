
# Exceptions

If any uncaught exception is thrown that Penny cannot handle, the script will be immediately terminated to prevent a full game crash.
This is a list of warnings or errors that are thrown when certain things are invalid in Penny.

## Warnings

Warnings are messages that appear when a non-critical exception is thrown. The notify level can be adjusted for warnings. Generally it's a good idea to develop using `ignore` or `warn`, and then thoroughly test your game before shipping using the `error` level so you'll be sure to catch all exceptions.

Dynamic Elements (decors, evals, jects) that trigger warnings will make themselves visible in the text.

### `UndefinedDecorationParameterWarning`

This warning is triggered when trying to set a decoration parameter, but the parameter does not exist for that decoration.

```pny
`<wave dummy=5>Hello, world.`
```
> <wave dummy=5>Hello, world. *`UndefinedDecorationParameterWarning 'wave.dummy' not found.`*

### `UndefinedDecorationWarning`

This warning is issued when parsing a decoration. The first token in a decoration sequence refers to the decoration id. Using a decoration that doesn't exist or placing parameters before the identifier will issue this warning.

```pny
`<a=5 wave>Hello, world.`
```
> <a=5 wave>Hello, world. *`UndefinedDecorationWarning 'a' does not exist.`*

### `VestigialDecorationParameterWarning`

Many decorations do not have any parameters. Attempting to set a value for one without any parameters will issue this warning.

```pny
`Hello, <i=0.5>world</>.`
```

> Hello, <i=0.5>world</>. *`VestigialDecorationParameterWarning 'i' does not use any parameters.`*

### `TrailingEndTagWarning`

Trailing end tags are invalid and will issue both compilation and runtime warnings when encountered in Message Blocks.

```pny
`Hello, world.</i>`
```
> Hello, world.\</i\> *`TrailingEndTagWarning: '</i>' found in string.`*

### `InfiniteObjectReferenceWarning`

This warning is issued if Penny is looking for a reference via dot notation and discovers that there is a reference loop within a single object reference evaluation. This occurs by checking for repetition in any reference NOT explicitly written in the 'original' object reference evaluation.

###### Example 1

```pny
obj Rubin
	name = "Rubin"
	self = Rubin				# This is okay
	deep = Rubin.self			# This is okay
	loop = Rubin.loop			# This is NOT OKAY

`[Rubin.loop]`

# <global>.Rubin				# manually written
# Rubin.loop					# manually written			<---┐
	# <global.Rubin>			# evaluated						|
	# Rubin.loop				# evaluated; loop found!	<---┘
```
> \[Rubin.loop\]<br>
> `InfiniteObjectReferenceWarning: 'Rubin.loop' -> 'Rubin.loop' -> ... is a reference loop`

When evaluating the first `Rubin.loop`, Penny will be on the lookout for any more references to `Rubin.loop`. If it finds one, this warning will be issued.

###### Example 2

```pny
obj Rubin
	spouse = Esther
obj Esther
	spouse = Rubin
	colleague = Argo
obj Argo
	loop = Rubin.spouse.colleague.loop.unreachable

`[Esther.colleague.loop.unreachable]`

# <global>.Esther					# manually written
# Esther.colleague				# manually written
	# <global>.Argo				# evaluated
# Argo.loop						# manually written			<---┐
	# <global>.Rubin			# evaluated						|
	# Rubin.spouse				# evaluated						|
	# Esther.colleague			# evaluated						|
	# Argo.loop					# evaluated; loop found! 	<---┘
								# issue warning now!
	# loop.unreachable			# evaluated; never reached
# loop.unreachable				# manually written; never reached
```

> \[Esther.colleague.loop.unreachable\] `InfiniteObjectReferenceWarning: 'Esther.colleague.loop' -> 'Rubin.spouse.colleague.loop' -> ... is a reference loop`

###### Example 3

Just as a demonstration, this block will NOT issue this warning.

```pny
`Rubin's wife's husband's wife is [Rubin.spouse.spouse.spouse].`

# <global>.Rubin				# manually written
# Rubin.spouse					# manually written
	# <global>.Esther				# evaluated
# Esther.spouse					# manually written
	# <global>.Rubin			# evaluated
# Rubin.spouse					# manually written
	# <global>.Esther				# evaluated
```
> Rubin's wife's husband's wife is Esther.

Although there is explicitly written repetition (which *is* redundant), an evaluated reference never matches its host caller, i.e. to issue this warning the reference evaluation would need to find either `Rubin.spouse` or `Esther.spouse` and that never happens.

### `NullEvaluationWarning`

This warning is issued if at any point during an [Evaluation](#evaluations) a `null` value is found. If you're seeing this message while referencing an object, it means that the reference path is valid, but the object itself is not.

###### Example 1

```pny
player_name = null

`Hello, my name is [player_name].`
```
> Hello, my name is NULL.<br>
> `NullEvaluationWarning: 'player_name' has a null value.`

###### Example 2

```pny
obj Rubin
	name = "Rubin"
	mother = Marigold

Marigold = null

`[Rubin]'s mother is [Rubin.mother].`
```
> Rubin's mother is NULL.<br>
> `NullEvaluationWarning: 'Rubin.mother' -> 'Marigold' has a null value.`

This example is slightly misleading because `Marigold` looks like it's supposed to be an object, but it's actually just an attribute with a value of `null`.

## Errors

### `RecursiveInheritanceError`

This error is triggered if an object attempts to inherit from another previously defined object that is supposed to inherit from it.

###### Example 1

```pny
obj Apple is Fruit
obj Fruit is Apple			# Throws error
```

`Apple` is defined as a kind of `Fruit`. Therefore `Fruit` cannot be a kind of `Apple`.

###### Example 2
```pny
obj Orange is Apple
obj Banana is Orange
obj Apple is Banana			# Throws error
```
More plainly, these arrows show the inheritance structure in a loop, which explains why this is invalid.
```
Orange -> Apple -> Banana -> Orange -> ...
```

### `UndefinedObjectKeyError`

This warning is issued if Penny tries to access an `Object` but can't find one with the name provided. This can happen inside a Message Block or in regular code, perhaps during [Duplication](#duplication).

###### Example 1

```pny
`Hello, my name is [Rubin].`
```
> Hello, my name is \[Rubin\].<br>
> *`UndefinedObjectKeyError: 'Rubin' not found in dictionary`*

In this case, `Rubin` has not been defined in the global dictionary, therefore this warning must be issued.

This also occurs if trying to reference (for an object) a dictionary key that doesn't exist.

```pny
obj Rubin
	name = "Rubin"

`[Rubin] exists but [Rubin.father] does not.`
```
> Rubin exists but \[Rubin.father\] does not. *`UndefinedObjectKeyError: 'Rubin.father' not found in dictionary`*

This also occurs recursively if trying to reference an object from another object.
```pny
obj Rubin
	name = "Rubin"
	mother = Marigold

`Rubin exists but [Rubin.mother] does not.`
```
> Rubin exists but \[Rubin.mother\] does not. *`UndefinedObjectKeyError: 'Rubin.mother' -> 'Marigold' not found`*

Or...

```pny
obj Rubin
	name = "Rubin"
	mother = Marigold
	father = Marigold.husband

obj Marigold
	name = "Marigold"
	husband = Barkis

`[Rubin.mother.husband]`
`[Rubin.father]`
```
> \[Rubin.mother.husband\] `UndefinedObjectKeyError: 'Rubin.mother.husband' -> 'Barkis' not found`<br>
> \[Rubin.father\] `UndefinedObjectKeyError: 'Rubin.father' -> 'Marigold.husband' -> 'Barkis' not found`
