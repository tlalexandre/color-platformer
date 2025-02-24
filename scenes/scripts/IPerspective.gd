# IPerspective.gd
extends Node
class_name IPerspective

# Define the interface methods that classes need to implement
func get_render_bounds() -> Rect2:
	push_error("IPerspective: get_render_bounds not implemented")
	return Rect2()

func get_render_offset() -> Vector2:
	push_error("IPerspective: get_render_offset not implemented")
	return Vector2.ZERO

func get_render_depth() -> float:
	push_error("IPerspective: get_render_depth not implemented")
	return 0.5
