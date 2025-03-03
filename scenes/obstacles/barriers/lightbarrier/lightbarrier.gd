extends BaseBarrier
class_name LightBarrier

func _ready():
	super._ready()  # Important to keep base functionality
	ColorFilterManager.filter_changed.connect(_on_filter_changed)
	
	# Also connect to background color changes
	ColorFilterManager.background_color_changed.connect(_on_background_changed)
	
	# Make sure initial state is calculated
	update_collision_state()

func _physics_process(_delta: float) -> void:
	# Override the base method to ensure we also check collision state regularly
	super._physics_process(_delta)
	
	# Force update if needed (you can adjust how often this happens)
	if Engine.get_process_frames() % 10 == 0:  # Every 10 frames
		update_collision_state()

func should_be_solid(color: Color) -> bool:
	# Your existing should_be_solid implementation remains the same
	# First get the color affected by lights (from base calculation)
	var light_affected_color = LightManager.calculate_final_color(self)
	
	# Then apply filter effects
	var filtered_color = Color(
		light_affected_color.r * ColorFilterManager.get_current_filter().r,
		light_affected_color.g * ColorFilterManager.get_current_filter().g,
		light_affected_color.b * ColorFilterManager.get_current_filter().b,
		light_affected_color.a
	)
	
	# Get background color and apply current filter
	var filtered_background_color = ColorFilterManager.get_filtered_background_color()
	
	# Check conditions with final filtered color
	var is_white = (abs(filtered_color.r - 1.0) <= COLOR_THRESHOLD and
				   abs(filtered_color.g - 1.0) <= COLOR_THRESHOLD and
				   abs(filtered_color.b - 1.0) <= COLOR_THRESHOLD)
	
	var matches_background = (abs(filtered_color.r - filtered_background_color.r) <= COLOR_THRESHOLD and
							abs(filtered_color.g - filtered_background_color.g) <= COLOR_THRESHOLD and
							abs(filtered_color.b - filtered_background_color.b) <= COLOR_THRESHOLD)
	
	return not (matches_background)

func _on_filter_changed(_new_filter: Color) -> void:
	# Force update when filter changes
	update_visual_state()
	update_collision_state()

func _on_background_changed(_new_color: Color) -> void:
	# Force update when background changes
	update_visual_state()
	update_collision_state()
