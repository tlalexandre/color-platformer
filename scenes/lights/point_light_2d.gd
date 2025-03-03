# RGB light controller
extends PointLight2D

enum LightColor {
	RED,
	GREEN,
	BLUE
}

@export var light_type: LightColor = LightColor.RED

func _ready():
	match light_type:
		LightColor.RED:
			color = Color(1, 0, 0, 1)  # Pure red
		LightColor.GREEN:
			color = Color(0, 1, 0, 1)  # Pure green
		LightColor.BLUE:
			color = Color(0, 0, 1, 1)  # Pure blue

# Function to change color at runtime if needed
func set_light_color(new_type: LightColor):
	light_type = new_type
	match light_type:
		LightColor.RED:
			color = Color(1, 0, 0, 1)
		LightColor.GREEN:
			color = Color(0, 1, 0, 1)
		LightColor.BLUE:
			color = Color(0, 0, 1, 1)
