extends StaticBody2D
class_name BaseBarrier

const COLOR_THRESHOLD := 0.01

var current_color: Color = Color.WHITE
@export var platform_color: Color = Color.WHITE:
	set(value):
		platform_color = value

var stored_occluder: OccluderPolygon2D
var is_solid: bool = true
var last_solid_state: bool = true
var last_position: Vector2
var players_on_platform = []

# Path Movement Properties
@export var follow_path: bool = false
@export var path_speed: float = 100.0
@export var loop_path: bool = true
@export var ping_pong: bool = false

var path_follow: PathFollow2D = null
var path_parent: Node2D = null
var path_direction: int = 1


@onready var light_occluder_2d: LightOccluder2D = $LightOccluder2D
@onready var light_detector: Area2D = $LightDetector
@onready var barrier_collision_shape: CollisionShape2D = $BarrierCollisionShape
@onready var platform_detector: Area2D = $PlatformDetector
@onready var sprite: Sprite2D = $BackgroundSprite

func _ready() -> void:
	if not sprite or not light_detector or not barrier_collision_shape or not light_occluder_2d:
		push_error("BaseBarrier: Required nodes not found!")
	
	print("Collision Layer: ", collision_layer)
	print("Collision Mask: ", collision_mask)
	print("LightDetector Layer: ", light_detector.collision_layer)
	print("LightDetector Mask: ", light_detector.collision_mask)
	print("All collision shapes:")
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			print(child.name, " - disabled: ", child.disabled)
	
	sprite.self_modulate = platform_color
	stored_occluder = light_occluder_2d.occluder
	last_position = global_position
	
	# Setup path following if needed
	if follow_path:
		var parent = get_parent()
		if parent is PathFollow2D:
			path_follow = parent
			path_follow.loop = loop_path
			path_parent = path_follow.get_parent()
	
	# Setup platform detector if it doesn't exist
	if not has_node("PlatformDetector"):
		var detector = Area2D.new()
		detector.name = "PlatformDetector"
		detector.collision_layer = 0
		detector.collision_mask = 1  # Assuming the player is on layer 1
		
		var collision_shape = CollisionShape2D.new()
		if barrier_collision_shape.shape is RectangleShape2D:
			collision_shape.shape = RectangleShape2D.new()
			collision_shape.shape.size = barrier_collision_shape.shape.size + Vector2(0, -10)
			collision_shape.position = Vector2(0, -5)
		else:
			# For other shape types, just duplicate
			collision_shape.shape = barrier_collision_shape.shape.duplicate()
		
		detector.add_child(collision_shape)
		add_child(detector)
		platform_detector = detector
	
	# Connect signals
	connect_signals()
	update_visual_state()

func _physics_process(delta: float) -> void:
	# Save previous position
	var previous_position = global_position
	
	# Handle path movement if enabled
	if follow_path and path_follow != null:
		# Calculate new progress
		var new_progress = path_follow.progress
		new_progress += path_speed * delta * path_direction
		
		# Handle ping-pong behavior
		if ping_pong:
			var path = path_parent as Path2D
			if path:
				var path_length = path.curve.get_baked_length()
				if path_direction > 0 and new_progress >= path_length:
					path_direction = -1
				elif path_direction < 0 and new_progress <= 0:
					path_direction = 1
		
		# Apply the movement
		path_follow.progress = new_progress
	
	# Calculate actual movement
	var delta_movement = global_position - previous_position
	last_position = previous_position
	
	update_visual_state()
	
	# Move any players on the platform
	for player in players_on_platform:
		if is_instance_valid(player):
			player.global_position += delta_movement
	
	# Check light occlusion
	LightManager.check_light_occlusion(self)


func connect_signals() -> void:
	light_detector.area_entered.connect(_on_light_entered)
	light_detector.area_exited.connect(_on_light_exited)
	
	if platform_detector:
		if not platform_detector.body_entered.is_connected(_on_body_entered):
			platform_detector.body_entered.connect(_on_body_entered)
		if not platform_detector.body_exited.is_connected(_on_body_exited):
			platform_detector.body_exited.connect(_on_body_exited)

func _on_light_entered(area: Area2D) -> void:
	LightManager.register_light_interaction(self, area, true)

func _on_light_exited(area: Area2D) -> void:
	LightManager.register_light_interaction(self, area, false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and not players_on_platform.has(body):
		players_on_platform.append(body)
		print("Player entered platform: ", name)

func _on_body_exited(body: Node2D) -> void:
	if players_on_platform.has(body):
		players_on_platform.erase(body)
		print("Player exited platform: ", name)

func update_visual_state() -> void:
	var new_color = LightManager.calculate_final_color(self)
	
	if new_color != current_color:
		current_color = new_color
		if has_node("PerspectiveRenderer"):
			var renderer = get_node("PerspectiveRenderer")
			renderer.face_color = current_color        
		sprite.self_modulate = current_color
		update_collision_state()

func should_be_solid(_color: Color) -> bool:
	push_error("should_be_solid must be implemented by child class")
	return true

func update_collision_state() -> void:
	var new_solid_state = should_be_solid(current_color)
	
	if new_solid_state != last_solid_state:
		if new_solid_state:
			call_deferred("_add_collision_deferred")
		else:
			call_deferred("_remove_collision_deferred")
		
		is_solid = new_solid_state
		last_solid_state = new_solid_state

# Add these helper methods
func _add_collision_deferred() -> void:
	add_child(barrier_collision_shape)
	light_occluder_2d.occluder = stored_occluder

func _remove_collision_deferred() -> void:
	remove_child(barrier_collision_shape)
	light_occluder_2d.occluder = null
		
func _on_filter_changed(new_filter: Color) -> void:
	update_visual_state()
