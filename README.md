# RicherTextLabel v2.0
Rewritten from scratch.

Main Changes:
	
- Simpler to write: 
	- Can close with a single `]`: `[red;b]Bold red] text and [green;i]italic green] text.`
	- Interactive [objects](#objects) as simple as: `bbcode = "Was it %s, or %s?" % [self, get_node("first_char")]`
	- Interactive text using `=` prefix: `[=start]Start Game]\n[=set]Settings]\n[=q]Quit]`
	- [Emojis and images](#emojis-and-images) share simple pattern: `Eating an ~apple ~smile. Icon: ~icon`.
- Single node `RicherTextLabel`. Can take [modifiers](#modifiers) like:
	- [`Animation`](#animation) for animating by character, world, or line.
	- [`Scatter`](#scatter) for displaying each line at a different position on screen.
	- [`Curve`](#curve) for aligning text to a `Path2D`.
	- [`Ticker`](#ticker) for creating news tickers that pan across the screen.
- Hover animations, sounds, tooltips and more for clickable text.
	- Animate text on hover, unhover, click, and right_click.
	- Sounds play on hover, unhover, click, and right_click.
- Optionally remove tags the old way: `[b;blue]Name[/blue] Description.`
- [`Parser`](#parser) resource makes it easier for all labels in a project to share settings.
- Uses `@` instead of `$` for getting [context properties](#context), since `$` is commonly used for dialogue.
- Potentially faster as it no longer uses `push_` `pop()` calls. (Haven't actually tested.)
- Images `[img]` can finally have their color/alpha animated by effects, making them usable in transition animations.
- `bbcode_head` that always get's prefixed when you call `bbcode = "text"`.
- `[sin]` has applies a skew, for added juiciness.

# Parser
The `Parser` `Resource` makes reusing settings across `RicherTextLabel`s far easier.

## Context
A Node that will be used when replacing `@context_vars` or calling `@context_functions(true)`.

- `context_allow_autoloads` enables autload nodes `Let's invite @Global.get_group(&"chars") to the party!`
- `context_allow_global_classes` enables your own named scripts `Items: @MyUtils.list_items(true)`
- `context_allow_engine_singletons` enables [Godots built in classes](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html) `Our @OS.get_name() computer runs nice.`
- `context_allow` list of names to allow in expressions. Leave blank to allow everything.
- `context_block` list of names to block in expressions. Leave black to block nothing.

## Link
Links can be animated on hover & click events with the `link_effect` tooltip.

They play sounds with `link_audio_path_*` fields.

## Tooltip
Links that don't call a function are treated as tooltips, and will display the help cursor.
Set `tooltip_cursor` to change it.

When creating a link with `[=link]Text]` pattern, a tooltip can follow `?`: `[=link?Text to display]Text]`.
A problem with way is it doesn't allow for richtext. For that, you should be passing objects that implement `to_richtext()`

# BBCode Patterns

## Multiple Tags

- Tags go in `[]`
- Include multiple tags by dividing with a `;`
- All tags will auto close when there is an empty tag `[]` or `]`.
- Optionally you can close a tag by prefixing an `/`: `[b;red]apple[/red]`

```
Want an [red;b;!clicked_item apple]apple] or a [yellow;b;!clicked_item pear]pear]?
```

Will be turned into.

```
Want an [color=#ff0000][b][url=clicked_item("apple")]apple[/url][/b][/color] or a [color=#ffff00][b][url=clicked_item("pear")]pear[/url][/b][color]?
```

## Clickable Functions
TODO: Should use @ symbol to stay consistent.
- `[!method_name]Click Me]`
- `[!method_name arg1 arg2]Click Me]`

## Colors
- `[(1.0,1.0,0.0,1.0)]` useful for quick formatting: `"My [%s]colored] text." % [Color.YELLOW_GREEN]`
- `[red]`
- `[red green]` 1st is font_color, 2nd is font_outline_color.

## Fonts
Simply enter the font name `[font1]Font 1 text] and [font2]font 2 text].`

Use the `RicherTextParser` resource to setup fonts. It can scan `res://` and find them all.

## Sizes
Tags with a `float` will be treated as relative adjustment `My [2.0]big text] and [.5]small text].`

Tags with an `int` will be added/subtracted from the font size `My [2]slightly larger text] and [-2]slightly smaller text].`

## Emojis And Images
The `~pattern` is used for quickly showing an emoji or image. Images are automatically scaled to `font_size`.
Will look for images in `emoji_images_dir`.

## Objects
Turning `Nodes` & `Resources` into clickable text is as easy as: `bbcode = str(my_object)`.

Or: `bbcode = "Chars: %s, %s, and %s." % [bob, jan, sue]`
Each character can implement the methods below to be clickable, or show a unique tooltip.

### Methods
Your `Node`s & `Resource`s should implement some of these methods.
If `to_richtext()` isn't implemented the `name` property or `to_string()` method will be used.

- `func to_richtext() -> String:` Like `to_string()` but expects bbcode.
- `func _richtext_clicked() -> void:` If exists, called when object's text is clicked in label.
- `func _richtext_hovered() -> void:` If exists, called when object's text is hovered in label.
- `func _richtext_unhovered() -> void:` If exists, called when object's text is hovered in label.

### Tooltip
If there is a `tooltip_text` property on the object, it will be used for a `[hint]`.

# Modifiers
The `modifiers` are used to do more advanced manipulation, like animation and positioning.

## Animation
The animation system allows you to fade in text by:
- `CHAR`
- `WORD`
- `LINE`

### Indicator
The indicator communicates to the user that they can press a key to advance the animation.
There are signals that will fire when the animation has `paused` or `continued`.

If you set a node it will automatically be aligned to the last visible character.

## Scatter
Each line of the `RicherTextLabel` will be aligned to a node. This lets a single label be treated as multiple.
Good for:
- Multiple characters having text over their individual heads.
- Comic books style Boom! Pow! Pop! effects.
	- Enable `copy_rotation` and `copy_scale` for maximum effect.
- Intro cinematics, where you want a caption above and below.

Nodes can be 3D and their position will be projected to 2D viewport space.

There is `viewport_clamp` and `viewport_margin` to make sure labels stay in bounds.

If only one line of text and `repeat_input` > 0, it will repeat your input for multiple lines. Good for a kind of "Hah-Hah-Hah" effect, or a "You Died" animation... 

## Curve
Aligns characters along a `Path2D`.

Set `clip_children = false` for best effect.

## Ticker
Like you see in news stations.
It treats each new line as a story, places them all on the same line with a divider, and just endlessly scrolls.

The `divider` key can be any kind of unicode or emoji to divide stories.

Set `clip_children = true` for best effect.

## Link List
Treats each new line as a link.

Connect to `link_clicked` `link_right_clicked` `link_hovered` `link_unhovered`.

String will come back in kebab case: `Start Game` = `start-game`.

You can set `tooltip_text` by adding it after a `|`.

```gdscript
New Game|Start a new game
Load|Continue from previous game
Settings|Adjust the visuals and audio
Quit|Don't ever click this
```
