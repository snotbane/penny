[Snotbane](https://snotbane.carrd.co) presents...
# Penny, an Interactive Narrative Language

Penny is a coding language used to write interactive narrative content for video games. It is capable of, and appropriate for, handling any narrative demand, from short NPC dialogue, all the way up to full visual novel decision trees.

# Quickstart

1. Import the addon to `res://addons/penny_godot/`

# Why?

Penny's purpose is to provide a dedicated environment for writers to focus on front-end visuals, audio, and (most importantly) text. Rather than being a fully-featured engine, Penny is designed to work along side a host engine. This is to separate visual details from narrative content.

## Key Features

### Subject Linking

When a character talks, usually they will play some sort of animation (or multiple simultaneously) while they are speaking. Penny allows you to connect an existing character (or spawn an instance of one) and control their actions via Penny script.

### Regex Filtering

Writing complex text has never been simpler. One can create filters to apply to displayed text, to reduce technical clutter within the written text itself. For example:

```pen
FANCY_DOUBLE_QUOTE_RIGHT = new filter
	.pattern = `(\S)"`
	.replace = `$1”`

FANCY_DOUBLE_QUOTE_LEFT = new filter
	.pattern = `"`
	.replace = `“`
```

These and some other filters are built into Penny by default, and can be altered based on the needs of your project.

### Object Inheritance

Data in Penny is stored in objects, which inherit attributes from other objects. One can even change an object's inheritance at any time.
