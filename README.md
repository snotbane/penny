[nulture](https://nulture.carrd.co) presents...
# Penny, an Interactive Narrative Language

Penny is a coding language used to write interactive narrative content for video games. It is capable to, and appropriate for, handling any narrative demand, from short NPC dialogue, all the way up to full visual novel trees.

# Quickstart

1. Import the addon to `res://addons/penny_godot/`
2. Create an autoload Node for `res://addons/penny_godot/scripts/nodes/penny_importer.gd`
3. Modify all / create build presets in `Project > Export...`
   - Add `*.pny` to the list of exported file types in `(build preset) > Resources > Filters to export non-resource files/folders`

# Why?

Penny's purpose is to provide a dedicated environment for writers to focus on front-end visuals, audio, and (most importantly) text. Rather than being a fully-featured engine, Penny is designed to work along side a host engine. This is to separate game logic from narrative content.

## Key Features

### Regex Filtering

Writing complex text has never been simpler. One can create filters to apply to displayed text, to reduce technical clutter within the written text itself.

### Object inheritance

Data in Penny is stored in objects, which inherit attributes from other objects. One can even change an object's inheritance at any time.
