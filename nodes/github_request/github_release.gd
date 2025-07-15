class_name GithubRelease extends RefCounted

var name : String = ""
var tag_name : String = ""
var html_url : String = "" # take user to the release page
var is_valid : bool = false

func _fetch_prop_from_data(data: Dictionary, data_path: StringName, property: StringName) -> bool:
	if data.has(data_path):
		self.set(property, data.get(data_path))
		return true
	push_warning(
		"github release data is missing '%s'. unable to set property '%s'" %
		[data_path, property])
	return false

static func from_json(data: Dictionary) -> GithubRelease:
	var rel := GithubRelease.new()
	rel.is_valid = true
	rel.is_valid = rel._fetch_prop_from_data(data, &"name", &"name") and rel.is_valid
	rel.is_valid = rel._fetch_prop_from_data(data, &"tag_name", &"tag_name") and rel.is_valid
	rel.is_valid = rel._fetch_prop_from_data(data, &"html_url", &"html_url") and rel.is_valid
	return rel

func _to_string() -> String:
	return str({
		'is_valid' : is_valid,
		'name' : name,
		'tag_name' : tag_name,
		'html_url' : html_url
	})
