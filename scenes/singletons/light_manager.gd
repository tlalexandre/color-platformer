extends Node

# Autoload singleton script

var _light_affected_objects = {}  # Dictionary to store objects and their affecting lights

func register_light_interaction(object: Node, area: Area2D, is_entering: bool) -> void:
	var light = _find_associated_light(area)
	if not light:
		return
		
	if not _light_affected_objects.has(object):
		_light_affected_objects[object] = []
		
	var lights = _light_affected_objects[object]
	
	if is_entering and not lights.has(light):
		lights.append(light)
	elif not is_entering and lights.has(light):
		lights.erase(light)
		
	object.update_visual_state()

func check_light_occlusion(object: Node) -> void:
	if not _light_affected_objects.has(object):
		return
		
	var space_state = object.get_world_2d().direct_space_state
	var lights_to_remove = []
	
	for light in _light_affected_objects[object]:
		var query = PhysicsRayQueryParameters2D.create(
			light.global_position,
			object.global_position,
			4  # Layer 2 (LightOcclusion)
		)
		query.exclude = [object]
		
		var result = space_state.intersect_ray(query)
		if result:
			lights_to_remove.append(light)
	
	for light in lights_to_remove:
		_light_affected_objects[object].erase(light)
	
	if not lights_to_remove.is_empty():
		object.update_visual_state()

func calculate_final_color(object: Node) -> Color:
	print("DEEP DEBUG: Calculating color for ", object.name)
	
	var base_color: Color
	if not _light_affected_objects.has(object) or _light_affected_objects[object].is_empty():
		print("DEEP DEBUG: No lights affecting object, using platform_color: ", object.platform_color)
		base_color = object.platform_color
	else:
		print("DEEP DEBUG: Object has ", _light_affected_objects[object].size(), " lights in list")
		
		# Start with the object's base color
		var r = object.platform_color.r
		var g = object.platform_color.g
		var b = object.platform_color.b
		
		var has_active_lights = false
		
		# Only consider lights that are ACTUALLY visible and enabled
		for light in _light_affected_objects[object]:
			if is_instance_valid(light) and light.visible and light.enabled:
				print("DEEP DEBUG: Active light found: ", light.name, " color: ", light.color)
				r = max(r, light.color.r)
				g = max(g, light.color.g)
				b = max(b, light.color.b)
				has_active_lights = true
			else:
				print("DEEP DEBUG: Inactive/invalid light found, ignoring")
		
		# If no active lights were found, just use the platform's color
		if not has_active_lights:
			print("DEEP DEBUG: No ACTIVE lights found, using platform_color: ", object.platform_color)
			base_color = object.platform_color
		else:
			base_color = Color(
				clamp(r, 0, 1),
				clamp(g, 0, 1),
				clamp(b, 0, 1),
				1.0
			)
			print("DEEP DEBUG: Combined light color: ", base_color)

	var current_filter = ColorFilterManager.get_current_filter()
	
	var final_color = Color(
		base_color.r * current_filter.r,
		base_color.g * current_filter.g,
		base_color.b * current_filter.b,
	)
	print("DEEP DEBUG: Final filtered color: ", final_color)
	return final_color

func _find_associated_light(area: Area2D) -> Light2D:
	if area.get_parent() is PointLight2D:
		return area.get_parent()
	elif area.get_parent().get_parent() is PointLight2D:
		return area.get_parent().get_parent()
	
	for sibling in area.get_parent().get_children():
		if sibling is PointLight2D:
			return sibling
	
	return null

func toggle_light(light: PointLight2D, enable: bool) -> void:
	# Enable or disable the light
	light.visible = enable
	light.enabled = enable
	
	# Find and toggle the light area
	var light_area = _find_light_area(light)
	if light_area:
		light_area.monitoring = enable
		light_area.monitorable = enable
	
	# If disabling, we need to remove this light from all affected objects
	if not enable:
		for obj in _light_affected_objects.keys():
			if is_instance_valid(obj):
				var lights = _light_affected_objects[obj]
				# If this object was affected by our light, remove it
				if lights.has(light):
					lights.erase(light)
					print("LightManager: Removed light ", light.name, " from ", obj.name)
					# Update the object's visual state
					if obj.has_method("update_visual_state"):
						obj.update_visual_state()
	
	# Always update ALL barriers in the scene
	var barriers = get_tree().get_nodes_in_group("barriers")
	for barrier in barriers:
		if barrier.has_method("update_visual_state"):
			barrier.update_visual_state()
	
	print("LightManager: Light ", light.name, " toggled ", "ON" if enable else "OFF")

# Helper function to find a light's Area2D
func _find_light_area(light: PointLight2D) -> Area2D:
	# Check if the area is a child of the light
	for child in light.get_children():
		if child is Area2D:
			return child
	
	# Check if the area is a sibling of the light
	var parent = light.get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling is Area2D:
				return sibling
	
	return null
