class_name FileUtils
extends Object

static func to_json_file(obj, filepath: String, indent="  ", sort_key=true, full_precision=true) -> bool:
	var obj_str = JSON.stringify(obj, indent,  sort_key, full_precision)
	var json_file = FileAccess.open(filepath, FileAccess.WRITE)
	if json_file:
		json_file.store_string(obj_str)
		json_file.close()
	else:
		push_error("failed to save to '%s'" % [filepath])
		return false
	return true

static func from_json_file(filepath: String) -> Variant:
	var json_file = FileAccess.open(filepath, FileAccess.READ)
	if json_file == null:
		push_error("failed to open json file '%s'" % [filepath])
		return null
	var obj_str = json_file.get_as_text()
	var json = JSON.new()
	if json.parse(obj_str) == OK:
		return json.data
	push_error("failed to parse JSON object from str '%s'" % [obj_str])
	return null
