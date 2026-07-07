> [!WARNING]
> This addon is still under heavy development. Language syntax may change over time. If you wish to use this addon, please follow to be notified when a stable release is available.
> If you want to go ahead and start writing a story, who is stopping you?

# Penny, a Narrative Scripting Language

Penny is a coding language used to write interactive narrative content for video games. It is capable of, and appropriate for, handling any narrative demand, from short NPC dialogue or tutorials, all the way up to full visual novel decision trees.

# Why?

Penny's purpose is to provide a dedicated environment for writers to focus on front-end visuals, audio, and (most importantly) text. It is heavily inspired by the [Ren'Py](https://www.renpy.org/) engine. However, rather than being a fully-featured engine, Penny is designed to work along side a host engine. This is to separate visual details and most typical game code from narrative content.

## Key Features

### Subject Linking

When a character talks, usually they will play some sort of animation (or multiple simultaneously) while they are speaking. Penny allows you to connect an existing character (or spawn an instance of one) and control their actions directly via Penny script. You can even call GDScript functions and update GDScript properties directly from Penny.

### Regex Filtering

Writing complex and heavily decorated text has never been simpler. One can create filters to apply to displayed text, to reduce technical clutter within the written text itself. For example:

```pen
SLOW_ELLIPSES = new filter
	.pattern = `\.{3,}` # '...' or longer
	.replace = `<speed=0.33>$1</>`

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

### Inline Translations

Projects supporting multiple translations can write them altogether in the same file, for simple expansion during development or after project publication. The end user may easily switch languages at any time.

```pen
esther
>           Good morning, everyone!
    [es]    Buenos dias a todos!
    [ja]    みなさんおはようございます！
```

