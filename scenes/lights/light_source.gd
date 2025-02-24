# light_source.gd
extends Node2D

@export var light_color: Color = Color.WHITE:
	set(value):
		light_color = value
		if light:
			light.color = value

@onready var light: PointLight2D = $PointLight2D
@onready var light_area: Area2D = $LightArea

func _ready() -> void:
	# Set initial light color
	light.color = light_color
