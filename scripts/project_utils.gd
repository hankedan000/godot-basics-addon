class_name ProjectUtils
extends Object

static func get_app_name() -> String:
	return ProjectSettings.get_setting("application/config/name") as String

static func get_app_version() -> Version:
	var sver := ProjectSettings.get_setting("application/config/version") as String
	return Version.from_str(sver)
