extends Node

# Autoload singleton script for managing light interactions with barriers

var _light_affected_objects = {}  # Dictionary to store objects and their affecting lights
var initialized = false

func _ready() -> void:
	# Defer initialization to ensure all other nodes are ready
	call_deferred("_deferred_initialization")

func _deferred_initialization() -> void:
	# This will run after all _ready() functions have completed
	initialized = true
	
	# Initialize with all active lights
	var all_barriers = get_tree().get_nodes_in_group("barriers")
	var all_lights = get_tree().get_nodes_in_group("lights")
	
	# Let each active light discover affected barriers
	for light_node in all_lights:
		var light = _get_light_from_node(light_node)
		if light and light.visible and light.enabled:
			_update_barriers_affected_by_light(light)

# Process a node to extract the PointLight2D
func _get_light_from_node(node) -> PointLight2D:
	if node is PointLight2D:
		return node
	elif node.has_node("PointLight2D"):
		return node.get_node("PointLight2D")
	return null

# Called when a light enters/exits a barrier's detection area
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

# Check if lights are occluded for a specific object
func check_light_occlusion(object: Node) -> void:
	if not object.has_node("LightDetector"):
		return
		
	if not _light_affected_objects.has(object):
		_light_affected_objects[object] = []
		
	var space_state = object.get_world_2d().direct_space_state
	var lights_to_remove = []
	
	# Check existing lights for occlusion
	for light in _light_affected_objects[object]:
		# Skip inactive lights
		if not light.enabled or not light.visible:
			continue
			
		var query = PhysicsRayQueryParameters2D.create(
			light.global_position,
			object.global_position,
			4 
		)
		query.exclude = [object]
		
		var result = space_state.intersect_ray(query)
		if result:
			lights_to_remove.append(light)
	
	for light in lights_to_remove:
		_light_affected_objects[object].erase(light)
	
	# Check for lights that should be affecting this object but aren't in the list
	var light_detector = object.get_node("LightDetector")
	var overlapping_areas = light_detector.get_overlapping_areas()
	var changed = false
	
	for area in overlapping_areas:
		var light = _find_associated_light(area)
		if light and light.visible and light.enabled:
			# If this light isn't in our list already
			if not _light_affected_objects[object].has(light):
				# Check for occlusion
				var query = PhysicsRayQueryParameters2D.create(
					light.global_position,
					object.global_position,
					4   
				)
				query.exclude = [object]
				
				var result = space_state.intersect_ray(query)
				if not result: 
					_light_affected_objects[object].append(light)
					changed = true
	
	if not lights_to_remove.is_empty() or changed:
		object.update_visual_state()

# Calculate the final color of an object based on its platform color and affecting lights
func calculate_final_color(object: Node) -> Color:
	var base_color: Color
	if not _light_affected_objects.has(object) or _light_affected_objects[object].is_empty():
		base_color = object.platform_color
	else:
		# Start with the object's base color
		var r = object.platform_color.r
		var g = object.platform_color.g
		var b = object.platform_color.b
		
		var has_active_lights = false
		
		# Only consider lights that are ACTUALLY visible and enabled
		for light in _light_affected_objects[object]:
			if is_instance_valid(light) and light.visible and light.enabled:
				r = max(r, light.color.r)
				g = max(g, light.color.g)
				b = max(b, light.color.b)
				has_active_lights = true
		
		# If no active lights were found, just use the platform's color
		if not has_active_lights:
			base_color = object.platform_color
		else:
			base_color = Color(
				clamp(r, 0, 1),
				clamp(g, 0, 1),
				clamp(b, 0, 1),
				1.0
			)

	var current_filter = ColorFilterManager.get_current_filter()
	
	var final_color = Color(
		base_color.r * current_filter.r,
		base_color.g * current_filter.g,
		base_color.b * current_filter.b,
	)
	return final_color

# Toggle a light on or off
func toggle_light(light: PointLight2D, enable: bool) -> void:
	# Update light properties
	light.visible = enable
	light.enabled = enable
	
	# Find and toggle the light area
	var light_area = _find_light_area(light)
	if light_area:
		light_area.monitoring = enable
		light_area.monitorable = enable
	
	# If system isn't initialized, defer the update
	if not initialized:
		call_deferred("toggle_light", light, enable)
		return
	
	# If enabling the light, immediately find all barriers it affects
	if enable:
		# Use call_deferred to ensure physics state is up to date
		call_deferred("_update_barriers_affected_by_light", light)
	else:
		# If disabling, remove this light from all barriers
		call_deferred("_remove_light_from_all_barriers", light)

# Update all barriers that might be affected by this light
func _update_barriers_affected_by_light(light: PointLight2D) -> void:
	var barriers = get_tree().get_nodes_in_group("barriers")
	
	for barrier in barriers:
		if not barrier.has_node("LightDetector"):
			continue
			
		if _can_light_affect_barrier(light, barrier):
			# Add this light to the barrier if not already there
			if not _light_affected_objects.has(barrier):
				_light_affected_objects[barrier] = []
				
			if not _light_affected_objects[barrier].has(light):
				_light_affected_objects[barrier].append(light)
				barrier.update_visual_state()

# Remove this light from all barriers
func _remove_light_from_all_barriers(light: PointLight2D) -> void:
	for obj in _light_affected_objects.keys():
		if is_instance_valid(obj):
			var lights = _light_affected_objects[obj]
			if lights.has(light):
				lights.erase(light)
				if obj.has_method("update_visual_state"):
					obj.update_visual_state()

# Check if a light can affect a barrier (distance and occlusion check)
func _can_light_affect_barrier(light: PointLight2D, barrier: Node) -> bool:
	# Check if light is active
	if not light.enabled or not light.visible:
		return false
		
	# Calculate distance between light and barrier
	var distance = light.global_position.distance_to(barrier.global_position)
	
	# Get light radius (approximate based on texture size and scale)
	var light_radius = 0
	if light.texture:
		light_radius = max(light.texture.get_width(), light.texture.get_height()) * max(light.scale.x, light.scale.y) * 0.5
	else:
		light_radius = 300  # Default fallback radius
	
	# If barrier is outside potential light range, it can't be affected
	if distance > light_radius * 1.2:  # 1.2 is a safety margin
		return false
	
	# Check for occlusion
	var space_state = barrier.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		light.global_position,
		barrier.global_position,
		4  # Occlusion layer
	)
	query.exclude = [barrier]
	
	var result = space_state.intersect_ray(query)
	
	# If there's no occlusion, the light can affect the barrier
	return not result

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
	
# Helper function to find the light associated with an area
func _find_associated_light(area: Area2D) -> Light2D:
	if area.get_parent() is PointLight2D:
		return area.get_parent()
	elif area.get_parent().get_parent() is PointLight2D:
		return area.get_parent().get_parent()
	
	for sibling in area.get_parent().get_children():
		if sibling is PointLight2D:
			return sibling
	
	return null
