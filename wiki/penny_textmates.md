# Penny extension syntax changes

## Comments

Designated by hashtag. Block comments not supported. Partial line comments are supported.

```pny
# This is a comment
This is not commented # This is a partial comment
```

## Keywords

`pass` Indicates a placeholder execution
```pny
if true:
	pass
```

`label` Indicates a place to be jumped to
```pny
label start

# ...More instructions...
```

## Strings

Strings start with either `"`, `'`, or [\`] and end with the same. These indicate a Typewriter Block (to be printed out), spoken by the most recently selected Character.

```pny
# ...Character definition...
# ...Character selection...

"Hello, world!"
```

Strings can span multiple lines.

```pny
"Hello,
world!"
```

### String Sub-Rules

Escape characters are preceeded by a `\`.
E.g. `\n` is an escape character.

```pny
"Hello,\nworld!"
```

Tags are defined by starting with `<` or `</` and ending with `>`.
E.g. `<i>` and `</i>` are both tags:

```pny
"Hello, <i>world</i>!"
```

#### String Tag Sub-Rules

- `<`, `</`, and `>` is considered `punctuation.definition.tag`
- `,` is `punctuation`
- `=` is `operator`
- Any word is `entity.name.tag`
- Numbers are `constant.numeric`
- String constants are defined with beginning and ending with a string identifier and are simple raw strings. You can use the same kind of quotes inside tags but best practice is to use different ones.
