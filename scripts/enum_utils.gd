class_name EnumUtils
extends Object

static func to_str(enum_class, enum_value: Variant) -> String:
	var values := enum_class.values() as Array
	var keys := enum_class.keys() as Array
	for idx in range(values.size()):
		if values[idx] == enum_value:
			return keys[idx]
	return "**UNKNOWN**"

static func from_str(enum_class, def_value, str_value: String) -> Variant:
	var values := enum_class.values() as Array
	var keys := enum_class.keys() as Array
	for idx in range(keys.size()):
		if keys[idx] == str_value:
			return values[idx]
	return def_value
