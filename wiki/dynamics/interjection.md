
## Interjections

Use an **Interjection** to execute Penny code in the middle of a message block.

> [!IMPORTANT] Key Concepts
> **Interjections**:
> - May execute any host-engine **Callable**.
> - Will execute as soon as the character before it becomes visible.
> - Are best utilized inside Message Blocks, e.g. play a sound effect or animation, in the middle of a Message Block.
> - **Do not** modify the Display String text whatsoever.

###### Example 1
```pny
`Hello, my name { log "Check your console log" }is Rubin.`
`Hello, my name {
	log "Check your console log"
}is Rubin.`
```
This example demonstrates a simple logging statement to show how interjections work. Interjections can be placed inline or in block form.

###### Example 2
```pny
player_name = "Rubin"

`Hello, my name is { player_name = "Esther" }[player_name].`
`My name has now been updated to [player_name].`
```
> Hello, my name is Rubin.<br>
> My name has now been updated to Esther.

This example demonstrates that Interjections cannot modify the contents of the string which they belong in, because they are only executed once they have been reached. You *can* modify variable values inside Interjections, but this isn't really useful. It's best practice to instead keep `set`ters outside Message Blocks. The result will be identical to last time but the syntax is much more readable:

```pny
player_name = "Rubin"

`Hello, my name is [player_name].`

player_name = "Esther"

`My name has now been updated to [player_name].`
```
