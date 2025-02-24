extends BaseBarrier
class_name DarkBarrier

func _ready() -> void:
	super._ready()  # Call base class _ready
	# Connect to filter changes
	ColorFilterManager.filter_changed.connect(_on_filter_changed)

func should_be_solid(color: Color) -> bool:
	# Get current filter
	var current_filter = ColorFilterManager.get_current_filter()
	
	# Calculate final color after filter
	var filtered_color = Color(
		color.r * current_filter.r,
		color.g * current_filter.g,
		color.b * current_filter.b,
		1.0
	)
	
	# Check if filtered color is black
	var is_black = (
		filtered_color.r <= COLOR_THRESHOLD and 
		filtered_color.g <= COLOR_THRESHOLD and 
		filtered_color.b <= COLOR_THRESHOLD
	)
	
	return is_black
