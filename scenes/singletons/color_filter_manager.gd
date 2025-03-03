extends Node

signal filter_changed(new_filter: Color)
signal background_color_changed(new_color:Color)

# CMYK represented as RGB filters
var cyan_filter := Color(0, 1, 1, 1)    # Removes Red
var magenta_filter := Color(1, 0, 1, 1)  # Removes Green
var yellow_filter := Color(1, 1, 0, 1)   # Removes Blue
var white_filter := Color(1, 1, 1, 1)    # Shows all colors

var _filtered_background_color: Color = Color.WHITE  # Default value
var background: Node = null
var current_filter := white_filter

var filter_overlay: ColorRect

func _ready() -> void:
	setup_filter_overlay()

func setup_filter_overlay() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128  # High layer number to be on top
	
	filter_overlay = ColorRect.new()
	filter_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	filter_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Load and set shader
	var shader = load("res://assets/shaders/color_filter_shader.gdshader")  # Adjust path as needed
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("filter_color", current_filter)
	filter_overlay.material = material
	
	canvas_layer.add_child(filter_overlay)
	add_child(canvas_layer)

func apply_filter(filter_type: String) -> void:
	var new_filter: Color
	
	match filter_type:
		"C": new_filter = cyan_filter
		"M": new_filter = magenta_filter
		"Y": new_filter = yellow_filter
		"W": new_filter = white_filter
		_: 
			push_error("Invalid filter type: " + filter_type)
			return
	
	current_filter = new_filter
	filter_overlay.material.set_shader_parameter("filter_color", current_filter)
	filter_changed.emit(current_filter)

func get_current_filter() -> Color:
	return current_filter

func combine_filters(filters: Array) -> void:
	var combined = Color(1, 1, 1, 1)
	for filter in filters:
		combined.r = min(combined.r, filter.r)
		combined.g = min(combined.g, filter.g)
		combined.b = min(combined.b, filter.b)
	
	current_filter = combined
	filter_overlay.material.set_shader_parameter("filter_color", current_filter)
	filter_changed.emit(current_filter)

func calculate_filtered_background_color(base_background_color: Color) -> void:
	_filtered_background_color = Color(
		base_background_color.r * current_filter.r,
		base_background_color.g * current_filter.g,
		base_background_color.b * current_filter.b,
		base_background_color.a
	)
	background_color_changed.emit(_filtered_background_color)

func set_background(bg_node: Node) -> void:
	background = bg_node
	# Recalculate filtered background when setting a new background
	if background:
		calculate_filtered_background_color(background.modulate)

func get_filtered_background_color() -> Color:
	if background:
		return _filtered_background_color
	return Color.WHITE  # Default fallback
