class_name SaveGame
## Keeps the save in browser storage, and turns it into a code the player can copy, because
## browser storage belongs to one web address and the tunnel's address changes on every restart.
## A code is the save's JSON, deflated and base64'd, behind a prefix naming the format.

const PATH := "user://save.json"
const VERSION := 1
const CODE_PREFIX := "LK1:"
const MAX_SAVE_BYTES := 1 << 20


static func write(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


static func erase() -> void:
	DirAccess.remove_absolute(PATH)


static func encode(data: Dictionary) -> String:
	var compressed := JSON.stringify(data).to_utf8_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	return CODE_PREFIX + Marshalls.raw_to_base64(compressed)


## Returns the save, or a String saying what is wrong with the code.
static func decode(code: String) -> Variant:
	code = code.strip_edges()
	if not code.begins_with(CODE_PREFIX):
		return "Save codes start with %s. This one does not." % CODE_PREFIX
	var compressed := Marshalls.base64_to_raw(code.trim_prefix(CODE_PREFIX))
	var json := compressed.decompress_dynamic(MAX_SAVE_BYTES, FileAccess.COMPRESSION_DEFLATE).get_string_from_utf8()
	var data = JSON.parse_string(json)
	if not data is Dictionary:
		return "It looks cut off or damaged. Copy the whole code and try again."
	if data.version > VERSION:
		return "It is from a newer version of the game."
	return data
