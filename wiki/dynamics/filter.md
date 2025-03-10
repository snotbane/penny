
## Filters

Filters search for [regex patterns](https://regexr.com/) and perform actions on any matching text. This can be a handy way of ensuring proper grammar after evaluation, and/or reducing clutter **for all Penny scripts** in your project.

> [!IMPORTANT] Key Concepts
> **Filters**:
> - Apply only to visible, evaluated text.
> - May add new evaluations, interjections, or decorations, which are applied after each filter. Once applied, these features cannot be removed.
> - Apply in the order which they are written.
> - **Are not** recursive, but creating multiple identical filters will cause them to apply multiple times.
> - **Do not** affect `<raw>` decorations nor text encapsulated therein.
> - Belong to a separate dictionary from objects and cannot be accessed or referenced by objects or vice versa.
> - Are interpreted at **Compile-Time** and **CANNOT BE UNREGISTERED** once the game starts!

###### Example 1

```pny
filter "apple" with "banana"

`Would you like *an* apple?`
```
> Would you like \*an\* banana?

This is a simple example to demonstrate that the text `"apple"` is replaced (substituted) with `"banana"` **without** using an [Evaluation](#evaluations). But this example is not very practical; the preceeding article doesn't even display correctly.

###### Example 2

```pny
filter "(?i)(?<=\s\W?)an\b(?=\W?\s*\w)"
	with "a"

filter "(?i)(?<=\s\W?)a\b(?=\W?\s*[aeiou])"
	with "an"

fruit_1 = "banana"
fruit_2 = "orange"

`Would you like a [fruit_1]? ...Or would you like a [fruit_2]?`
```
> Would you like a banana? ...Or would you like an orange?

The two filters in this example are much more practical! They will ensure that those pesky articles display properly, no matter what the evaluations become. This is also a situation where the ordering of the filters is crucial.

###### Example 3

```pny
filter "(?<=[^\.])_(?=[^\.]|$)"
	with "<w>"

`Hello... it is nice to see you._ You're looking so pretty today.`
```
> Hello... it is nice to see you. You're looking so pretty today.

This is a filter I like to use as a shorthand for creating a wait-for-input pause `<w>` in between long sentences simply by using an underscore.

###### Example 4

```pny
filter "\.{3,}"
	with "<speed=5>$&</><d=0.2>"

`...Hello..... world...`
```
> <u>...</u>Hello<u>.....</u> world<u>...</u>

This example is a filter to print ellipses of any length ("...") slowly (represented with underlines). Use the regex key `$&` to refer to the captured string.

###### Example 5

```pny
Rubin = object
	name = "Rubin"
	style = "<b, color=#ff4128>"

filter "\bRubin\b" with "[Rubin]"
`Nice to meet you, I'm Rubin.`
```
> Nice to meet you, I'm <b><span style="color:#ff4128">Rubin</b></span>.

This example demonstrates that you may use evaluations within filters.

###### Example 6

```pny
filter "\bR\b"
	with "<b, color=#ff4128>Rubin</>"

`Nice to meet you, I'm R.`
```
> Nice to meet you, I'm <b><span style="color:#ff4128">Rubin</b></span>.

This example shows how you might use a shorthand for a character's name (in Ren'Py style) to apply decorations and expand their name.

> [!WARNING] Filter Risks
> Filters are dangerously powerful. Using regex patterns that are too short or too inclusive may change your text in confusing ways. Make sure to test your regex thoroughly ([regexr](https://regexr.com/) is a great place to do so).
>
> Continuing from the previous example, the following is the sort of thing that might happen if you're not careful:
>
>	```pny
>	`Let's go see an R-rated movie!`
>	```
> > Let's go see an <b><span style="color:#ff4128">Rubin</b></span>-rated movie!
