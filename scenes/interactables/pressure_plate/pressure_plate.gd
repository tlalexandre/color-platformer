extends Area2D

signal activated
signal deactivated

@export var toggle_mode: bool = false
@export var target_light_path: NodePath

var is_active: bool = false
var target_light: PointLight2D

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	# Connect the signal to detect when player enters/exits
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Get the target light if specified
	if not target_light_path.is_empty():
		var target_light_parent = get_node_or_null(target_light_path)
		if target_light_parent:
			# Look for a PointLight2D child
			for child in target_light_parent.get_children():
				if child is PointLight2D:
					target_light = child
					print("Found target light: ", child.name)
					break
			
			if not target_light:
				push_error("No PointLight2D found as a child of " + str(target_light_path))

func _on_body_entered(body):
	# Check if it's the player (you might have a different way to identify the player)
	if body.is_in_group("player"):
		if toggle_mode:
			# If toggle mode, switch state on each entry
			if is_active:
				deactivate()
			else:
				activate()
		else:
			# If not toggle mode, just activate
			activate()

func _on_body_exited(body):
	# Check if it's the player
	if body.is_in_group("player") and not toggle_mode:
		# Only deactivate automatically if not in toggle mode
		deactivate()

func activate():
	is_active = true
	if animation_player:
		animation_player.play("press")
	
	# Control the target light using LightManager
	if target_light:
		if get_node_or_null("/root/LightManager"):
			var light_manager = get_node("/root/LightManager")
			# THIS IS THE KEY LINE: Actually call toggle_light
			light_manager.toggle_light(target_light, true)
		else:
			# Fallback if LightManager isn't available
			target_light.visible = true
			target_light.enabled = true
	
	activated.emit()

func deactivate():
	is_active = false
	if animation_player:
		animation_player.play("release")
	
	# Control the target light using LightManager
	if target_light:
		if get_node_or_null("/root/LightManager"):
			var light_manager = get_node("/root/LightManager")
			# THIS IS THE KEY LINE: Actually call toggle_light
			light_manager.toggle_light(target_light, false)
		else:
			# Fallback if LightManager isn't available
			target_light.visible = false
			target_light.enabled = false
	
	deactivated.emit()
