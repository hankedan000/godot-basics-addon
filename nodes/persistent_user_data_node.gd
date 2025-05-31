class_name PersistentUserDataNode
extends Node

signal restored()

var _has_edits: bool = false
var _filepath: String = ""
var _auto_save_timer:= Timer.new()
var _auto_save_thread: Thread = null

func _init(filepath: String) -> void:
	var base_dir := filepath.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(base_dir) != OK:
		push_error("failed to make dirs for path '%s'" % filepath)
		return
	
	_filepath = filepath
	if FileAccess.file_exists(_filepath):
		var data := FileUtils.from_json_file(_filepath) as Dictionary
		if data:
			print("restored persistent data from '%s'" % _filepath)
			restore_from_dict(data)
			restored.emit()

func _ready() -> void:
	add_child(_auto_save_timer)
	_auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	_auto_save_timer.start(1)

func queue_save() -> void:
	_has_edits = true

func to_dict() -> Dictionary:
	return {}

func restore_from_dict(_data: Dictionary) -> void:
	pass

func __THREADED__auto_save(data: Dictionary, filepath: String) -> void:
	FileUtils.to_json_file(data, filepath)

func _on_auto_save_timer_timeout() -> void:
	if _filepath.is_empty():
		return
	elif not _has_edits:
		return
	elif _auto_save_thread && _auto_save_thread.is_alive():
		return # still saving from last cycle
	
	if _auto_save_thread:
		_auto_save_thread.wait_to_finish() # allow thread to cleanup
	
	_auto_save_thread = Thread.new()
	_auto_save_thread.start(__THREADED__auto_save.bind(to_dict(), _filepath))
	_has_edits = false
