# RichTextLabel2
`v1.1`

Two Nodes:
- `RichTextLabel2`: Reduce effort needed to display state data and stylize it.
- `RichTextAnimation`: For dialogue and cinematics, animates text in and out.

| | |
|-|-|
|![](README/fromthis.png)|![](README/tothis.png)|

# Features
- Multi bbcode tags + easy closing + auto color names: `[deep_sky_blue;b]Bold blue[] and [orange;i]Italic orange[].`
- Integer tags for absolute font size, float tags are relative font_size: `[32]Big text[] and [0.5]half text.[]`
- Auto emojis: `I'm :smile: with results. You get a :+1:.`
- Effects automatically installed when you use them: `We on the [sin]sinewave[] vibe.`
	- 15 premade effects. (Some unstable/untested.)
- Context strings: `Only $coins coins, $player.name? Travel to $location.get_name("west") for more coins.`
	- Can call functions or get nested properties.
	- Niceifys integers with commas. `1234 -> 1,234`
	- Niceifys objects by calling `to_string_nice()` if it can.
	- Niceifys arrays by joining them into a comma seperated list.
- Easy font selection dropdown detects all fonts in the project.
	- Automatically creates Bold, Italic, and Bold Italic font variations if they don't exist.
	- Tweakable boldness and italic slant.
- Automatic opening and closing quotes.
- Customize how Markdown gets converted: `_italic_ -> [i]%s[] -> [i]italic[]` `*cough* -> [i]*%s*[] -> [i]*cough*[]`.
- Auto color formatting: `"My [%s]colored string[] is easy." % [Color.DEEP_SKY_BLUE]`
- `RichTextAnimation` for fading in and out.
	- 7 transition effects. (Some unstable/untested.)
	- Click2Continue node that can display at the last visible character.
	- `[hold] [h]` Tag to pause animation until user. `Wait...[h] Did you hear...[h] *Bang*!`
	- `[wait] [w]` Tag to wait in seconds. (Defaults to 1) `Let me thing.[w] Hmm...[w]...[w]...`
	- `[pace] [p]` Set pace of animations. `A slow talker [p=.1]talks like this...[p] While fast talkers [p=3]talk like this...`
- Many more I can't rememember... there are a lot of features.

> [!NOTE]
> A small cache of font paths are stored in meta_data.
> If font's aren't showing up in the dropdown, clear this meta_data.

Fonts will be discovered wherever they are.

![](README/readme1.png)
![](README/readme2.png)

# Tags

|Tag|Description|
|---|-----------|
|dim|           |
|lit|           |
|hue|           |

# RichTextAnimation

This node is meant for dialogue systems and cinematics.

[![Watch the video](https://raw.githubusercontent.com/chairfull/GodotRichTextLabel2/main/README/trans_preview.jpg)](https://raw.githubusercontent.com/chairfull/GodotRichTextLabel2/main/README/trans.mp4)

## Animation Tags

|Tag|Description|Arguments|Example|Self Closing|
|---|-----------|---------|-------|------------|
|`wait` or `w`|Waits a second.|Number of seconds.|`Wait...[w=2] Did you hear...[w] *bang*`|✅|
|`hold` or `h`|Holds until `advance()` is called.|`[h]`||✅|
|`pace` or `p`|Sets animation speed.|Scale.|`[p=2.0]Fast talker.[p=0.2]Slow talker.[p]Normal speed.`|✅|
|`skip`|Skips animation across selected items.||`They call it [skip]The Neverending Forest[].`|❌|
|`$`|Runs an expression at this spot in the animation.|Expression.|`Did you hear something...[~play_sound("gurgle")]`|✅|
|`#`|Calls `on_bookmark.emit()` with the id when reached.|Bookmark id.|`He told me [#quote]the haunted forest[#endquote] wasn't so haunted.[#end]`|✅|

If `shortcut_expression = true` you can use the `<code expression>` pattern instead of the `[!code expression]` pattern.
```
Did you hear something...[wait][~play_sound("gurgle")] Uh oh![~player.fear = 100.0] Ahh...
Did you hear something...[wait]<play_sound("gurgle")> Uh oh!<player.fear = 100.0> Ahh...
```

If `shortcut_bookmark = true` you can use the `#bookmark` pattern instead of the `[#bookmark]` pattern.
```
He told me#quote the haunted forest#endquote wasn't so haunted.#end
He told me[#quote] the haunted forest[#endquote] wasn't so haunted.[#end]
```

# Emoji Fonts
If a font has "emoji" (any case) in it's name, it will be used for emojis instead of the default font.

Emojis sometimes lag on some computers, which I get around by creating a custom FontVariant that uses the emoji font as a base and `ThemeDB.fallback_font` as a fallback font. This seems to prevent spikes.

If an emoji tag is used `:smile:` or `[:smile:]` an `emoji_font` metadata key will be created with the font.

# Changes
- 1.1
	- Added `context_state: Dictionary` for passing additional arguments available in expressions.
	- Added `{}` pattern for including complex expressions. Example: `{lerp(score, 2, 0.2) * PI}`.
	- Added `autostyle_emojis` to disable emoji detection.
	- Changed bracket escapes to be `[[]` pattern instead of `\[]` pattern.
	- Fixed `emoji_font` not loading.
	- Fixed `emoji_scale` not affecting emojis.
	- Fixed effects not animating after an emoji was used.
	- Fixed custom_effects each having text metadata.
	- Fixed Markdown detection not working when around tags.
	- Added many more comments.
	- Animation
		- Added `ctc_offset`.
		- Added `ctc_on_wait` to control whether ctc is visible while waiting for timer.
		- Added `ctc_on_finish` to control whether ctc is visible when animation finishes.
		- Added `default_wait_time` for the `[wait]` and `[w]` tags.
		- Added signals for when waiting starts and stops.
		- Added signals for when hold starts and stops.
		- Added `signal_quotes` and signals for when a "quote" starts and stops.
		- Added `signal_stars` and signals for when *stars* start and stop. 
		- Fixed expression triggers.
		- Fixed bookmark triggers.
		- Fixed tags `[wait][w][hold][h][pace][p][skip]`.
		- Fixed ctc showing up properly.
		- Renamed signals so their function is more obvious.
