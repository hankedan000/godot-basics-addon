class_name DictUtils
extends Object

static func get_w_default(dict: Dictionary, key: Variant, default_value=null):
	if dict.has(key):
		return dict[key]
	return default_value
