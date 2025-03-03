# FloorPerspective.gd
extends IPerspective
class_name FloorPerspective

func get_render_bounds() -> Rect2:
	var parent = get_parent()
	if parent and parent.has_node("CollisionShape2D"):
		var collision = parent.get_node("CollisionShape2D")
		return Rect2(collision.position, collision.shape.size)
	return Rect2()

func get_render_offset() -> Vector2:
	var parent = get_parent()
	if parent and parent.has_node("CollisionShape2D"):
		return parent.get_node("CollisionShape2D").position
	return Vector2.ZERO



func get_render_depth() -> float:
	return 0.5
