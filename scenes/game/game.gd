extends Node2D
@onready var background: Sprite2D = $Background

# Add this to your game.gd script
func _ready() -> void:
	# Initial calculation
	ColorFilterManager.set_background(background)
	ColorFilterManager.calculate_filtered_background_color(background.modulate)
	
	# Connect to filter changes to update background color
	ColorFilterManager.filter_changed.connect(
		func(_new_filter): ColorFilterManager.calculate_filtered_background_color(background.modulate)
	)
