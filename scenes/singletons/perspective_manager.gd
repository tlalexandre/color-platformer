extends Node

signal vanishing_point_changed(new_point: Vector2)

var vanishing_point: Vector2:
	set(value):
		vanishing_point = value
		vanishing_point_changed.emit(value)

# List of node types that should receive perspective rendering
var perspective_node_types = [
	"BaseBarrier",
	"LightBarrier",
	"DarkBarrier",
	"LightReactiveWall"
]

func _ready() -> void:
	# Set initial vanishing point to screen center
	vanishing_point = get_viewport().get_visible_rect().size / 2
	call_deferred("add_perspective_to_scene")

func add_perspective_to_scene() -> void:
	var root = get_tree().root
	_recursively_add_perspective(root)

func _recursively_add_perspective(node: Node) -> void:
	# Check if this node should have perspective
	if _should_add_perspective(node):
		_add_perspective_to_node(node)
	
	# Check all children
	for child in node.get_children():
		_recursively_add_perspective(child)

func _should_add_perspective(node: Node) -> bool:
	# Check if node's class name is in our list
	for type in perspective_node_types:
		if node.is_class(type) or node.get_class() == type:
			return true
	return false

func _add_perspective_to_node(node: Node) -> void:
	# Skip if node already has a PerspectiveRenderer
	if node.has_node("PerspectiveRenderer"):
		return
	
	# Create and add PerspectiveRenderer
	var renderer = PerspectiveRenderer.new()
	renderer.name = "PerspectiveRenderer"
	
	# If node has a Sprite2D, hide it
	if node.has_node("Sprite2D"):
		var sprite = node.get_node("Sprite2D")
		sprite.visible = false
	
	node.add_child(renderer)
	renderer.owner = node
