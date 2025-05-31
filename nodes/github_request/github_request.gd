class_name GithubRequest
extends Node

signal received_latest_release(rel: GithubRelease)

@onready var _http_request : HTTPRequest = $HTTPRequest

func request_latest_release(user: String, repo: String) -> bool:
	var url := "https://api.github.com/repos/%s/%s/releases/latest" % [user, repo]
	var err := _http_request.request(url)
	if err != OK:
		push_warning("release HTTP request failed! url = '%s'" % [url])
		return false
	return true

func _on_http_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_warning("github request failed! response_code = %d" % response_code)
		return
	
	var json_data := JSON.parse_string(body.get_string_from_utf8()) as Dictionary
	if json_data == null:
		push_warning("failed to parse json data form github request!")
		return
	
	var rel := GithubRelease.from_json(json_data)
	if not rel.is_valid:
		push_warning("github release data was not valid!")
		return
	
	received_latest_release.emit(rel)
