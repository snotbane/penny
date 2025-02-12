
# Path

Variable type that stores a reference to another variable. Implicitly used to indicate inheritance.

```pny
character				## retrieves a path from the root object.
character.property		## retrieves a path starting from the root object.
	.property			## retrieves a path starting from the previous less nested statement. (relative path)
						## In this example, the implied path of `\t.property` is `character.property.property`
@character				## retrieves the value at the given path. If the value is an object, it will duplicate the object. Always evaluates to a literal.
```

# Lookup

Variable type that stores a reference to a Resource stored in a LookupTable, usually a PackedScene. LookupTables can only be modified in editor. They're packed at the start into a single dictionary at the start and will issue warnings if duplicate keys are found.

```pny
Rubin
	.base = Character
	.scene = $rubin		## Packed scene to instantiate before applying any visuals to this object
	.inst = null		## Handled internally, it's the actual instantiated node itself. Don't touch.
```

# Expression

Variable type that stores multiple tokens that evaluate to a non-literal value.

```pny
hot = true					## `true` is a literal, and evaluates to a literal (true).
cold = true and false		## `true and false` is an expression, but evaluates to a literal (false). NOT an expression object.
temperature = hot and cold	## `hot and cold` is an expression, and evaluates to an expression because it contains paths.
feels_stuff = @hot or @cold ## `@hot or @cold` is an expression, but because it de-references these paths on evaluation, the result is a literal (true).
shadow = cold				## `cold` is just a path, so no expression.


```
