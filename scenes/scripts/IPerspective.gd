# IPerspective.gd
extends Node
class_name IPerspective

# Define the interface methods with smarter default implementations
func get_render_bounds() -> Rect2:
	var parent = get_parent()
	if not parent:
		push_error("IPerspective: No parent node found")
		return Rect2()
	
	# Try to find any collision shape in order of priority
	if parent.has_node("BackgroundSprite"):
		var sprite = parent.get_node("BackgroundSprite")
		var sprite_size = sprite.texture.get_size() * sprite.scale
		return Rect2(sprite.position, sprite_size)
	# 1. Try standard barrier collision shape

	# If we got here, we couldn't find a suitable shape
	push_error("IPerspective: Could not find a suitable collision shape for " + parent.name)
	return Rect2()

func get_render_offset() -> Vector2:
	var bounds = get_render_bounds()
	if bounds != Rect2():
		return bounds.position
	return Vector2.ZERO

func get_render_depth() -> float:
	return 0.5
