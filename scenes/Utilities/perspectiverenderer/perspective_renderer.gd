extends Node2D
class_name PerspectiveRenderer

@export var depth: float = 0.3
@export var render_above_parent: bool = true
@export var face_color: Color = Color.WHITE:
	set(value):
		face_color = value
		queue_redraw()

var parent_size: Vector2
var last_parent_pos: Vector2
var last_parent_size: Vector2
var parent_sprite: Sprite2D
var vanishing_point_node: Node2D
var last_vanishing_pos: Vector2
var parent_perspective: IPerspective  # New variable

func _ready() -> void:
	
	setup_vanishing_point()
	setup_parent_perspective()
	update_parent_dimensions()

func setup_vanishing_point() -> void:
	var tree = get_tree()
	if tree:
		var nodes = tree.get_nodes_in_group("vanishing_point")
		if nodes.size() > 0:
			vanishing_point_node = nodes[0]
		else:
			var player = tree.get_first_node_in_group("player")
			if player and player.has_node("VanishingPoint"):
				vanishing_point_node = player.get_node("VanishingPoint")
	
	if not vanishing_point_node:
		push_error("No vanishing point node found!")

func setup_parent_perspective() -> void:
	var parent = get_parent()
	
	# First check if parent has IPerspective as a child
	for child in parent.get_children():
		if child is IPerspective:
			parent_perspective = child
			return
			
	# Then check if parent implements the methods directly
	if parent.has_method("get_render_bounds") and \
	   parent.has_method("get_render_offset") and \
	   parent.has_method("get_render_depth"):
		parent_perspective = parent

func _process(_delta: float) -> void:
	var parent = get_parent()
	# Check for parent movement
	if parent.global_position != last_parent_pos or parent_size != last_parent_size:
		queue_redraw()
		last_parent_pos = parent.global_position
		last_parent_size = parent_size
	
	# Also check vanishing point movement
	if vanishing_point_node:
		var current_vanishing_pos = vanishing_point_node.global_position
		if current_vanishing_pos != last_vanishing_pos:
			queue_redraw()
			last_vanishing_pos = current_vanishing_pos

func calculate_vertices(pos: Vector2) -> Dictionary:
	# Get parent dimensions
	var parent = get_parent()
	var half_width = parent_size.x / 2
	var half_height = parent_size.y / 2
	
	# Front vertices in local space (positioned correctly)
	var front = [
		Vector2(-half_width, -half_height),  # Top left
		Vector2(half_width, -half_height),   # Top right
		Vector2(half_width, half_height),    # Bottom right
		Vector2(-half_width, half_height)    # Bottom left
	]
	
	# Get vanishing point
	var vanishing_point_global = vanishing_point_node.global_position
	
	# Calculate back vertices with correct perspective
	var back_vertices = []
	for i in range(front.size()):
		# Convert vertex to global space
		var front_global = parent.to_global(front[i])
		
		# Calculate full direction vector to vanishing point
		var to_vanishing = vanishing_point_global - front_global
		
		# Use a ratio of the distance for proper perspective
		var perspective_depth = parent_perspective.get_render_depth() if parent_perspective else depth
		var ratio = perspective_depth / 10.0  # Smaller factor for better control
		
		# Calculate back vertex position
		var back_global = front_global + (to_vanishing * ratio)
		
		# Convert back to local space
		back_vertices.append(parent.to_local(back_global))
	
	
	# Calculate all faces
	var top = [
		front[0],  # Front top left
		front[1],  # Front top right
		back_vertices[1],  # Back top right
		back_vertices[0]   # Back top left
	]
	
	var bottom = [
		front[2],  # Front bottom right
		front[3],  # Front bottom left
		back_vertices[3],  # Back bottom left
		back_vertices[2]   # Back bottom right
	]
	
	var left = [
		front[0],  # Front top left
		front[3],  # Front bottom left
		back_vertices[3],  # Back bottom left
		back_vertices[0]   # Back top left
	]
	
	var right = [
		front[1],  # Front top right
		front[2],  # Front bottom right
		back_vertices[2],  # Back bottom right
		back_vertices[1]   # Back top right
	]
	
	return {
		"front": front,
		"top": top,
		"bottom": bottom,
		"left": left,
		"right": right
	}
	
func determine_visible_faces(pos: Vector2, vanishing_pos: Vector2) -> Dictionary:
	# Calculate relative position to vanishing point
	var relative_pos = pos - vanishing_pos
	
	return {
		"show_top": relative_pos.y > 0,    # Show bottom face if object is below vanishing point
		"show_bottom": relative_pos.y < 0,  # Show top face if object is above vanishing point
		"show_left": relative_pos.x > 0,    # Show left face if object is to the right
		"show_right": relative_pos.x < 0    # Show right face if object is to the left
	}

func _draw() -> void:
	if not vanishing_point_node:
		return
		
	var parent = get_parent()
	var current_color = face_color
	
		# Draw debug lines directly to vanishing point
	var vanishing_global = vanishing_point_node.global_position
	var front_vertices = calculate_vertices(parent.global_position).front
	
	# Convert front vertices to global space
	var front_global = front_vertices.map(func(v): return to_global(v))
	
	## Draw lines from each vertex to vanishing point
	#for vertex in front_global:
		## Convert points to local for drawing
		#var start = to_local(vertex)
		#var end = to_local(vanishing_global)
		#draw_line(start, end, Color.RED, 1.0)
		
	if parent_sprite:
		current_color = parent_sprite.self_modulate
	elif parent.has_method("get_current_color"):
		current_color = parent.get_current_color()
	
	var vertices = calculate_vertices(parent.global_position)
	var visibility = determine_visible_faces(parent.global_position, vanishing_point_node.global_position)
	
	# Draw faces based on visibility
	if visibility.show_bottom:
		draw_colored_polygon(PackedVector2Array(vertices.bottom), current_color.darkened(0.2))
	if visibility.show_top:
		draw_colored_polygon(PackedVector2Array(vertices.top), current_color.darkened(0.2))
	if visibility.show_left:
		draw_colored_polygon(PackedVector2Array(vertices.left), current_color.darkened(0.4))
	if visibility.show_right:
		draw_colored_polygon(PackedVector2Array(vertices.right), current_color.darkened(0.4))
		
	# Always draw front face
	draw_colored_polygon(PackedVector2Array(vertices.front), current_color)
	
	# Draw edges for visible faces
	if visibility.show_bottom:
		_draw_edges(vertices.bottom)
	if visibility.show_top:
		_draw_edges(vertices.top)
	if visibility.show_left:
		_draw_edges(vertices.left)
	if visibility.show_right:
		_draw_edges(vertices.right)
	_draw_edges(vertices.front)
func _draw_edges(vertices: Array) -> void:
	var edge_color = Color.BLACK.darkened(0.5)
	for i in range(vertices.size()):
		var start = vertices[i]
		var end = vertices[(i + 1) % vertices.size()]
		draw_line(start, end, edge_color, 1.0)
		
func update_parent_dimensions() -> void:
	var parent = get_parent()
	
	if parent_perspective:
		# Use the instance methods from IPerspective
		parent_size = parent_perspective.get_render_bounds().size
		position = parent_perspective.get_render_offset()
		depth = parent_perspective.get_render_depth()
	else:
		# Your existing fallback dimension detection code
		var sprite_offset = Vector2.ZERO
		if parent_sprite:
			sprite_offset = parent_sprite.position
		
		# Calculate size and offset
		if parent is Sprite2D:
			parent_sprite = parent
			parent_size = parent_sprite.texture.get_size() * parent_sprite.scale
			position = sprite_offset
		elif parent.has_node("Sprite2D"):
			parent_sprite = parent.get_node("Sprite2D")
			parent_size = parent_sprite.texture.get_size() * parent_sprite.scale
			position = sprite_offset
		elif parent.has_node("CollisionShape2D"):
			var collision = parent.get_node("CollisionShape2D")
			if collision.shape is RectangleShape2D:
				parent_size = collision.shape.size
				position = collision.position
		else:
			parent_size = Vector2(64, 64)
			position = Vector2.ZERO
	
	# Store initial positions
	last_parent_pos = parent.global_position
	last_parent_size = parent_size
