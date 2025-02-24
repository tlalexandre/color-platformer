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
	
	var base_color: Color
	if not _light_affected_objects.has(object) or _light_affected_objects[object].is_empty():
		base_color = object.platform_color
	else:
		var r = object.platform_color.r
		var g = object.platform_color.g
		var b = object.platform_color.b
		
		for light in _light_affected_objects[object]:
				r = max(r, light.color.r)
				g = max(g, light.color.g)
				b = max(b, light.color.b)

		base_color = Color(
		clamp(r, 0, 1),
		clamp(g, 0, 1),
		clamp(b, 0, 1),
		1.0
		)

	var current_filter = ColorFilterManager.get_current_filter()

	return Color(
		base_color.r * current_filter.r,
		base_color.g * current_filter.g,
		base_color.b * current_filter.b,
	)

func _find_associated_light(area: Area2D) -> Light2D:
	if area.get_parent() is PointLight2D:
		return area.get_parent()
	elif area.get_parent().get_parent() is PointLight2D:
		return area.get_parent().get_parent()
	
	for sibling in area.get_parent().get_children():
		if sibling is PointLight2D:
			return sibling
	
	return null
