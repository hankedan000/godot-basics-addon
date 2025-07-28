class_name DictUtils
extends Object

static func get_w_default(dict: Dictionary, key: Variant, default_value=null):
	if dict.has(key):
		return dict[key]
	return default_value

static func put_enum(dict: Dictionary, key: Variant, enum_class, enum_value):
	dict[key] = EnumUtils.to_str(enum_class, enum_value)

static func get_enum_w_default(dict: Dictionary, key: Variant, enum_class, def_value):
	var enum_value_str := get_w_default(dict, key, "") as String
	return EnumUtils.from_str(enum_class, def_value, enum_value_str)
