class_name UndoController
extends Object

signal history_changed()

class UndoOperation:
	extends Object
	
	func undo() -> bool:
		return true
		
	func redo() -> bool:
		return true
		
	func pretty_str() -> String:
		return "**pretty_str() unimplemented***"

class PropEditUndoOperation:
	extends UndoOperation
	
	var _obj : Object = null
	var _prop : StringName = &''
	var _old_value = null
	var _new_value = null
	
	func _init(obj: Object, prop: StringName, old_value, new_value):
		if obj == null:
			push_error("obj can't be null")
		if prop not in obj:
			push_error("obj %s doesn't have a property named '%s'" % [obj, prop])
		_obj = obj
		_prop = prop
		_old_value = old_value
		_new_value = new_value
	
	func undo() -> bool:
		_obj.set(_prop, _old_value)
		return true
		
	func redo() -> bool:
		_obj.set(_prop, _new_value)
		return true
		
	func pretty_str() -> String:
		return str({
			"obj" : str(_obj),
			"property" : _prop,
			"old_value" : str(_old_value),
			"new_value" : str(_new_value),
			})

class OperationBatch:
	var _ops : Array[UndoOperation] = []
	
	func push_op(op: UndoOperation) -> void:
		_ops.push_back(op)

const MAX_UNDO_REDO_HISTORY = 100
var _undo_stack : Array[OperationBatch] = []
var _redo_stack : Array[OperationBatch] = []
# flag used to block recursive operation re-adds while
# actively undo/redo and operation
var _within_a_do : bool = false

func reset() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	history_changed.emit()

func has_undo() -> bool:
	return _undo_stack.size() > 0

func has_redo() -> bool:
	return _redo_stack.size() > 0

func push_undo_op(op: UndoOperation) -> OperationBatch:
	if _within_a_do:
		return null # block recursive add while redoing
	var new_batch := OperationBatch.new()
	new_batch.push_op(op)
	_push_batch(_undo_stack, new_batch)
	_redo_stack.clear()
	history_changed.emit()
	return new_batch

func undo() -> void:
	if has_undo():
		_within_a_do = true
		var batch := _undo_stack.pop_back() as OperationBatch
		for op in batch._ops:
			op.undo()
		_push_batch(_redo_stack, batch)
		_within_a_do = false
		history_changed.emit()

func redo() -> void:
	if has_redo():
		_within_a_do = true
		var batch := _redo_stack.pop_back() as OperationBatch
		for op in batch._ops:
			op.redo()
		_push_batch(_undo_stack, batch)
		_within_a_do = false
		history_changed.emit()

static func _push_batch(stack: Array[OperationBatch], entry: OperationBatch) -> void:
	stack.push_back(entry)
	if len(stack) > MAX_UNDO_REDO_HISTORY:
		stack.pop_front()
