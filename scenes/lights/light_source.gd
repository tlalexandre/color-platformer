# light_source.gd
extends Node2D

@export var light_color: Color = Color.WHITE:
	set(value):
		light_color = value
		if light:
			light.color = value

@export var enabled_on_start: bool = true

@onready var light: PointLight2D = $PointLight2D
@onready var light_area: Area2D = $PointLight2D/LightArea

func _ready() -> void:
	# Set initial light color
	light.color = light_color
	
	# Set initial enabled state
	if not enabled_on_start:
		# Must call after a delay to ensure LightManager is fully loaded
		call_deferred("_disable_at_start")

func _disable_at_start() -> void:
	# Use the LightManager to properly disable the light
	if LightManager:
		LightManager.toggle_light(light, false)
	else:
		# Fallback if LightManager isn't available
		light.visible = false
		light.enabled = false
		if light_area:
			light_area.monitoring = false
			light_area.monitorable = false
