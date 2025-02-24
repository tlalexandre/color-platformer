extends StaticBody2D
class_name Wall

# Add IPerspective as a custom class
var perspective_handler = IPerspective.new()

func get_render_bounds() -> Rect2:
	var collision = $CollisionShape2D
	return Rect2(collision.position, collision.shape.size)

func get_render_offset() -> Vector2:
	return $CollisionShape2D.position

func get_render_depth() -> float:
	return 0.5  # Custom depth for floor
