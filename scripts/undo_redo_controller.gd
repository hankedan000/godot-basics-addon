class_name UndoController extends RefCounted

signal history_changed()

# a way of storing a reference to a node based on its path within the scene
class TreePathNodeRef extends RefCounted:
	var tree : SceneTree = null
	var node_path := NodePath()
	
	func _init(node: Node = null):
		if ! is_instance_valid(node):
			return
		elif ! node.is_inside_tree():
			return
		
		tree = node.get_tree()
		node_path = tree.root.get_path_to(node)
	
	func get_node() -> Node:
		if ! is_valid():
			return null
		return tree.root.get_node(node_path)
	
	func is_valid() -> bool:
		return is_instance_valid(tree) && ! node_path.is_empty()
	
	func get_node_name() -> String:
		var name_count := node_path.get_name_count()
		if name_count == 0:
			return "<null>"
		return node_path.get_name(name_count - 1)
	
	func _to_string() -> String:
		return "{tree: %s; node_path: %s}" % [tree, node_path]

class UndoOperation extends RefCounted:
	
	func undo() -> bool:
		return true
		
	func redo() -> bool:
		return true
	
	func brief_name() -> String:
		return "Base Undo Operation"
	
	func detail_summary() -> String:
		return ""

class PropEditUndoOperation extends UndoOperation:
	var _node_ref := TreePathNodeRef.new()
	var _prop : StringName = &''
	var _old_value : Variant = null
	var _new_value : Variant = null
	
	func _init(node: Node, prop: StringName, old_value: Variant, new_value: Variant):
		if ! is_instance_valid(node):
			push_error("node must be valid")
			return
		elif ! node.is_inside_tree():
			push_error("node must be inside tree")
			return
		elif prop not in node:
			push_error("node %s doesn't have a property named '%s'" % [node, prop])
			return
		_node_ref = TreePathNodeRef.new(node)
		_prop = prop
		_old_value = old_value
		_new_value = new_value
	
	func undo() -> bool:
		return _apply_prop(_old_value)
	
	func redo() -> bool:
		return _apply_prop(_new_value)
	
	func _apply_prop(value: Variant) -> bool:
		var node := _node_ref.get_node()
		if ! is_instance_valid(node):
			# get_node() pushes an error for us, so no need
			return false
		
		node.set(_prop, value)
		return true
	
	# very short 2-3 word description of the operation.
	func brief_name() -> String:
		return "Property Edit"
	
	# more detailed description of the operation, but should still be on a
	# single line.
	func detail_summary() -> String:
		return "%s:%s changed from %s to %s" % [_node_ref.get_node_name(), _prop, _old_value, _new_value]

class OperationBatch extends RefCounted:
	var _ops : Array[UndoOperation] = []
	
	func get_op_count() -> int:
		return _ops.size()
	
	func push_op(op: UndoOperation) -> void:
		_ops.push_back(op)
	
	func get_short_summary() -> String:
		if _ops.size() == 1:
			return "%s" % _ops[0].brief_name()
		elif _ops.size() > 1:
			return "Batch of %d operations" % _ops.size()
		return "No operations"

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

func get_undo_stack_summary(max_items : int = -1) -> String:
	return _get_stack_summary(_undo_stack, max_items)

func get_redo_stack_summary(max_items : int = -1) -> String:
	return _get_stack_summary(_redo_stack, max_items)

static func _get_stack_summary(stack: Array[OperationBatch], max_items : int = -1) -> String:
	var out := ""
	var idx := 0
	for batch in stack:
		if max_items >= 0 && idx >= max_items:
			break
		if idx > 0:
			out += "\n"
		out += "[%3d] - %s" % [idx, batch.get_short_summary()]
		idx += 1
	return out

static func _push_batch(stack: Array[OperationBatch], entry: OperationBatch) -> void:
	stack.push_back(entry)
	if len(stack) > MAX_UNDO_REDO_HISTORY:
		stack.pop_front()
