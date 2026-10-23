class_name PixelFont
## A 3x5 capitals font drawn with rectangles, so text is crisp at any whole-number scale.

const ADVANCE := 4
const LINE_HEIGHT := 7

const GLYPHS := {
	"A": ".#. #.# ### #.# #.#",
	"B": "##. #.# ##. #.# ##.",
	"C": ".## #.. #.. #.. .##",
	"D": "##. #.# #.# #.# ##.",
	"E": "### #.. ##. #.. ###",
	"F": "### #.. ##. #.. #..",
	"G": ".## #.. #.# #.# .##",
	"H": "#.# #.# ### #.# #.#",
	"I": "### .#. .#. .#. ###",
	"J": "..# ..# ..# #.# .#.",
	"K": "#.# #.# ##. #.# #.#",
	"L": "#.. #.. #.. #.. ###",
	"M": "#.# ### ### #.# #.#",
	"N": "##. #.# #.# #.# #.#",
	"O": ".#. #.# #.# #.# .#.",
	"P": "##. #.# ##. #.. #..",
	"Q": ".#. #.# #.# ##. .##",
	"R": "##. #.# ##. #.# #.#",
	"S": ".## #.. .#. ..# ##.",
	"T": "### .#. .#. .#. .#.",
	"U": "#.# #.# #.# #.# ###",
	"V": "#.# #.# #.# #.# .#.",
	"W": "#.# #.# ### ### #.#",
	"X": "#.# #.# .#. #.# #.#",
	"Y": "#.# #.# .#. .#. .#.",
	"Z": "### ..# .#. #.. ###",
	"0": "### #.# #.# #.# ###",
	"1": ".#. ##. .#. .#. ###",
	"2": "##. ..# .#. #.. ###",
	"3": "##. ..# .#. ..# ##.",
	"4": "#.# #.# ### ..# ..#",
	"5": "### #.. ##. ..# ##.",
	"6": ".## #.. ### #.# ###",
	"7": "### ..# .#. .#. .#.",
	"8": "### #.# ### #.# ###",
	"9": "### #.# ### ..# ##.",
	".": "... ... ... ... .#.",
	",": "... ... ... .#. #..",
	"'": ".#. .#. ... ... ...",
	"!": ".#. .#. .#. ... .#.",
	"?": "##. ..# .#. ... .#.",
	":": "... .#. ... .#. ...",
	"-": "... ... ### ... ...",
	"+": "... .#. ### .#. ...",
	"/": "..# ..# .#. #.. #..",
	"%": "#.# ..# .#. #.. #.#",
	"(": ".#. #.. #.. #.. .#.",
	")": ".#. ..# ..# ..# .#.",
	" ": "... ... ... ... ...",
}

static var _pixels := {}


static func draw(canvas: CanvasItem, position: Vector2, text: String, color: Color, scale := 1) -> void:
	var x := position.x
	for character in text.to_upper():
		for pixel: Vector2i in _glyph_pixels(character):
			canvas.draw_rect(Rect2(x + pixel.x * scale, position.y + pixel.y * scale, scale, scale), color)
		x += ADVANCE * scale


static func width(text: String, scale := 1) -> int:
	return (text.length() * ADVANCE - 1) * scale


## Breaks text into lines of at most `max_characters`, keeping the text's own line breaks.
static func wrap(text: String, max_characters: int) -> PackedStringArray:
	var lines := PackedStringArray()
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" "):
			if line != "" and line.length() + 1 + word.length() > max_characters:
				lines.append(line)
				line = word
			else:
				line = word if line == "" else line + " " + word
		lines.append(line)
	return lines


static func _glyph_pixels(character: String) -> Array:
	if not _pixels.has(character):
		var rows: PackedStringArray = GLYPHS[character].split(" ")
		var pixels := []
		for y in rows.size():
			for x in rows[y].length():
				if rows[y][x] == "#":
					pixels.append(Vector2i(x, y))
		_pixels[character] = pixels
	return _pixels[character]
