
# Display String

A Display String is any string that Penny writes to a `RichTextLabel` and has [Dynamic Elements](#dynamic-elements) applied to it. This can be done in a variety of ways but the two main ones are:

- [Message Block](#message-block)
- [Name Label](#name-label)

## Message Block

A **Message Block** is a single string, printed out over time, via a `RichTextLabel`, using the `say` statement. Each Block is defined by a single string. You can use `'`, `'''`, `"`, `"""`, [\`], or [\`\`\`] to indicate a Message Block (there is no difference between these, except for allowed escape characters). [\`] is my personal preference to minimize `\"` usage in `say` statements.

```pny
`Hello, my name is "Rubin."`
```

## Name Label

A **Name Label** is a short string often presented alongside a `say` statement. This text is not printed out over time, but the same dynamic applications apply to these.
