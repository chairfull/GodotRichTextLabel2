@tool
class_name RTxtParserRegex extends Resource

## Optional. TODO
@export var id: StringName
## Disable to prevent parsing.
@export var enabled := true
## Pattern to search for.
@export var regex: String
## Returns something to replace the matched regex.
## Access the match with `rm`
## Example: "< %s >" % rm.strings[0]
@export_custom(PROPERTY_HINT_EXPRESSION, "") var expression: String
## Helpful hint at what is happening.
@export_multiline var comment: String

@export_group("Test", "test_")
@export_custom(PROPERTY_HINT_EXPRESSION, "") var test_input: String
@export_tool_button("Test") var test_button := func():
	var parser := RTxtParser.new()
	parser.regexes.append(self)
	test_output = parser.parse(test_input)
	
@export_custom(PROPERTY_HINT_EXPRESSION, "") var test_output: String

func _run(input: String, parser: RTxtParser) -> String:
	if not enabled or not regex or not expression:
		push_error("Skipping [%s] [%s] [%s]" % [not enabled, not regex, not expression])
		return input
	var reg := RegEx.create_from_string(regex)
	return parser._replace(input, reg, func(rm: RegExMatch):
		if expression.strip_edges().count("\n") > 0:
			var gd := GDScript.new()
			var lines := expression.split("\n")
			lines[-1] = "return " + lines[-1]
			gd.source_code = "static func _run(rm: RegExMatch):\n\t" + "\n\t".join(lines)
			var err := gd.reload()
			if err == OK:
				return str(gd.call(&"_run", rm))
			push_error("Modifier Error: ", error_string(err), expression)
			return "???"
		return parser._expression_rich("return " + expression, expression, { rm=rm }))
