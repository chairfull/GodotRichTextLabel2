# RichTextLabel2
`v0.1_unstable`

Add fonts to `res://fonts`.

For auto emojis add a font with name `emoji_font`.

# Features
- Multi bbcode tags + easy closing + auto color names: "[deep_sky_blue;b]Bold blue[] and [orange;i]Italic orange[]."
- Integer tags for absolute font size, float tags are relative font_size: "[32]Big text[] and [0.5]half text.[]"
- Auto emojis: "I'm :smile: with results you get a :+1:."
- Many effects automatically installed when you use them: "We on the [sin]sinewave[] vibe."
- Context strings: "Only $coins coins, $player.name? Travel to $location.get_name("west") for more coins."
- Font selection in inspector. `Uses res://fonts`
- Automatically sets Bold, Italic, and Bold Italic font variations if they don't exist.
- Automatic opening and closing quotes.
- Markdown symbols: `_italic_` `__bold__` `___bold italic___` `~highlight~`.
- Auto color formatting: "My [%s]colored string[] is easy." % [Color.DEEP_SKY_BLUE]
- `RichTextAnimation` for fading in and out.
	- 7 transition effects.
	- Click2Continue node that can display at the end of text.
	- `pause` `wait` `speed`
- More I can't rememember... there are a lot of features.
