# RichTextLabel2
`v1.3` [Demo](https://github.com/chairfull/GodotRichTextLabel2_Demo)

Two Nodes:
- `RichTextLabel2`: Reduce effort needed to display state data and stylize it.
- `RichTextAnimation`: For dialogue and cinematics, animates text in and out.


| | |
|-|-|
|![](README/fromthis.png)|![](README/tothis.png)|

https://github.com/user-attachments/assets/724558ad-f98e-40bb-8f30-dc413705c166

https://github.com/user-attachments/assets/caf703ad-44d3-43b0-b4f9-56f513ac572f

# Features
- Multi bbcode tags + easy closing + auto color names: `[deep_sky_blue;b]Bold blue[] and [orange;i]Italic orange[].`
- Integer tags for absolute font size, float tags are relative font_size: `[32]Big text[] and [0.5]half text.[]`
- Auto emojis: `I'm :smile: with results. You get a :+1:.`
- Effects automatically installed when you use them: `We on the [sin]sinewave[] vibe.`
	- Many premade effects. See Tags section below.
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
> If fonts aren't showing up in the font drop down, clear `font_cache`.
> The entire project is scanned for fonts to display in the dropdown.

![](README/readme1.png)
![](README/readme2.png)

# Tags

|Tag|Description|Example|
|:-:|-----------|:--:|
|`dim`|Dims color by 33%.||
|`lit`|Lightens color by 33%.|
|`hue`|Shifts hue. 0 or 1 = no change. 0.5 = opposite end of spectrum.|`[hue 0.25]`|
|`beat`|Pulses in size and color.||
|`curspull`|Pulls towards cursor.|`[curspull pull=-1]`|
|`cuss`|Animation to replace vowels with symbols.|`What the [cuss]heck[].`|
|`heart`|Animated love bounce. Demonstrates changing font and using emojis.||
|`jit`|||
|`jit2`|Jittering nervous animation.||
|`jump`|||
|`jump2`|||
|`l33t`|Animation to replace letters with numbers.||
|`off`|Ignore. Offsets.||
|`rain`|Simulates rain. What for? I don't know.||
|`secret`|Hidden unless mouse cursor is nearbye.||
|`sin`|Might not work as sin is now built in?||
|`sparkle`|Animation to sparkle character colors. Meant to be used with color tags.||
|`sway`|Just skews back and forth.||
|`uwu`|Converts all R's and L's to W's.||
|`wack`|Randomly animates rotation and scale for a wacky look.||
|`woo`|Animates between upper and lower case, creating a sarcastic tone.||

# RichTextAnimation

This node is meant for dialogue systems and cinematics.

## Animation Tags

|Tag|Description|Arguments|Example|Self Closing|
|:-:|-----------|---------|:-----:|:----------:|
|`wait` or `w`|Waits a second.|Number of seconds.|`Wait...[w=2] Did you hear...[w] *bang*`|✅|
|`hold` or `h`|Holds until `advance()` is called.|`[h]`||✅|
|`pace` or `p`|Sets animation speed.|Scale.|`[p=2.0]Fast talker.[p=0.2]Slow talker.[p]Normal speed.`|✅|
|`skip`|Skips animation across selected items.||`They call it [skip]The Neverending Forest[].`|❌|
|`$`|Runs an expression at this spot in the animation.|Expression.|`Did you hear something...[$play_sound("gurgle")]`|✅|
|`#`|Calls `on_bookmark.emit()` with the id when reached.|Bookmark id.|`He told me [#quote]the haunted forest[#endquote] wasn't so haunted.[#end]`|✅|

## Animations

|Tag|Description|Arguments|
|:-:|-----------|---------|
|`back`|Characters bounce back in.||
|`console`|(Broken) Simulates a computer console.||
|`fader`|Characters alpha fades in.||
|`fallin`|Characters are scaled down from a large size.||
|`focus`|Characters slide in from all random directions.||
|`fromcursor`|Characters slide in from cursor position.||
|`growin`|Characters scale up from tiny.||
|`offin`|Characters slide in from a slight offset to the left.||
|`prickle`|Character alpha fades in but with a random offset. Requires a low `fade_in_speed` to look right.||
|`redact`|(Broken) Simulates redacted text being exposed.||
|`wfc`| Characters start out as random 0's and 1's and eventually "collapse".||

If `shortcut_expression = true` you can use the `<code expression>` pattern instead of the `[!code expression]` pattern.
```
Did you hear something...[wait][$play_sound("gurgle")] Uh oh![$player.fear = 100.0] Ahh...
Did you hear something...[wait]<play_sound("gurgle")> Uh oh!<player.fear = 100.0> Ahh...
```

If `shortcut_bookmark = true` you can use the `#bookmark` pattern instead of the `[#bookmark]` pattern.
```
He told me#quote the haunted forest#endquote wasn't so haunted.#end
He told me[#quote] the haunted forest[#endquote] wasn't so haunted.[#end]
```

# Emoji Fonts
If a font has "emoji" (any case) in it's name, it will be used for emojis instead of the default font.

Emojis sometimes lag on some computers, which I get around by creating a custom FontVariant that uses the emoji font as a base and `ThemeDB.fallback_font` as a fallback font. This seems to prevent lag spikes.

If an emoji tag is used `:smile:` or `[:smile:]` an `emoji_font` metadata key will be created with the font.

# Pipes
Pipes `|` post process strings.

There are two ways to use them.
- Inside expressions `{$score+2|pipe}`
- Or as a tag `[|pipe]Text to be passed.[]`

```gd
# These are all doing the same thing.
"We'll visit {location|capitalize} tomorrow."
"We'll visit {location.capitalize()} tomorrow."
"We'll visit [|capitalize]$location[] tomorrow."

# Arguments can also be passed as a space seperated list:
# These are all the same.
"Day of week: {time.day_of_week|substr 0 3}"
"Day of week: {time.day_of_week.substr(0, 3)}"
"Day of week: [|substr 0 3]$time.day_of_week[]"
```

The real power is in adding your own. Pipes try to use a method inside the context node.
```gd
func cap(x):
	return x.capitalize()

func oooify(x):
	if cow_mode == CowMode.ACTIVATED:
		return x.replace("o", "[sin]ooo[/sin]").replace("O", "[sin]OOO[/sin]")
	else:
		return x

# Pipes can be chained.
# Location name gets capitalized, and all it's O's stretched out.
"We'll visit {location|cap|ooify}."

# Or we may want to change entire the dialogue based on state data.
[|ooify]Wow those cows were mooing.[]
```

Or maybe you want to stylize content based on the characters mood.
```gd
# If returning BBCode, it has to be old fashioned style.
func mood(s: String, npc_id: String):
	match npcs[npc_id].emotion:
		Emotion.HAPPY: return "[color=yellow]%s[/color]" % s
		Emotion.SAD: return "[color=aqua]%s[/color]" % s
		Emotion.ANGRY: return "[color=red]%s[/color]" % s
		_: return s

"Mary: [i;|mood mary]What I'm saying will be colored based on my mood.[]"
"John: [i;|mood john]What I'm saying will be colored based on my mood.[]"
```

> [!NOTE]
> The BBCode `[|pipe]` tag function must return old fashioned BBCode. 
> It doesn't support the labels features like Markdown replacement.
> Eventually I'll fix that.


# Changes
- 1.3 *BREAKING CHANGES*
	- Changed: Class name `RicherTextLabel` from `RichTextLabel2` to prevent future problems.
	- Changed: Objects can implement `to_rich_string()` instead of `to_string_nice()`.
	- Fixed scene sizes being massive by preventing auto fonts saving to disk.
	- Fixed `fit_content` not working. Now `override_fitContent` really forces `custom_minimum_size`.
	- Fixed cursor based effects being very laggy.
- 1.2
	- Added pipes `|`. See README.
	- Added auto styling of decimal numbers:
		- `autostyle_numbers_pad_decimals` Enable?
		- `autostyle_numbers_decimals` Number of decimals.
	- Added 4 new effects:
		- `[curspull]` shows how to animate based on cursor position.
		- `[wack]` randomly scales and rotates characters.
		- `[beat]` pulses it's scale and color every second.
		- `[secret]` hides characters unless cursor is nearbye.
	- Animation
		- Added 3 new animations:
			- `[fromcursor]` which transitions letters to and from cursor position.
			- `[growin]` scales characters in, overshooting, then scaling to proper size.
			- `[offin]` moves characters in from an left offset.
	- Tweaked `[cuss]` `[heart]` `[rain]` `[sway]` `[uwu]`.
	- Fixed regression in effects based on text characters.
	- Fixed Markdown symbols catching when inside `[] {} or <>`.
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
