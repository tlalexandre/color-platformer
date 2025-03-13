extends CharacterBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var body: Node2D = $Body

@export var GRAVITY: float = 700.0
@export var speed: float = 500.0
@export var jump_strength: float = -300.0
@export var body_scale: float = 0.15

# Wall jump parameters
@export var wall_jump_strength: Vector2 = Vector2(250.0, -300.0)
@export var wall_slide_speed: float = 100.0
@export var wall_jump_time: float = 0.2  # Time before normal control returns

# Coyote time parameters
@export var coyote_time: float = 0.15  # seconds
var coyote_timer: float = 0.0
var was_on_floor: bool = false

# Jump buffering parameters
@export var jump_buffer_time: float = 0.1  # seconds
var jump_buffer_timer: float = 0.0
var buffered_jump: bool = false

# Wall jump control
var wall_jump_timer: float = 0.0
var is_wall_jumping: bool = false
var wall_normal: Vector2 = Vector2.ZERO

# Direction the player is facing
var facing_direction: int = 1  # 1 = right, -1 = left

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Update timers
	update_timers(delta)
	
	# Apply gravity
	velocity.y += delta * GRAVITY
	
	# Handle wall sliding
	handle_wall_sliding()
	
	# Handle movement
	handle_movement(delta)
	
	# Handle jumping (includes coyote time and jump buffering)
	handle_jumping()
	
	# Apply movement
	var was_on_floor_before_move = is_on_floor()
	move_and_slide()
	
	# Start coyote timer if just left the floor
	if was_on_floor_before_move and !is_on_floor():
		coyote_timer = coyote_time
	
	# Update animation state
	update_animation()

func update_timers(delta: float) -> void:
	# Update coyote timer
	if coyote_timer > 0:
		coyote_timer -= delta
	
	# Update jump buffer timer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		
	# Update wall jump timer
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
	else:
		is_wall_jumping = false

func handle_movement(delta: float) -> void:
	var horizontal_input = Input.get_axis("left", "right")
	
	# Store facing direction based on input
	if horizontal_input != 0:
		facing_direction = sign(horizontal_input)
		body.scale.x = facing_direction * body_scale
	
	# If wall jumping, reduce horizontal control
	if is_wall_jumping:
		# Apply wall jump velocity with reduced control
		velocity.x = lerp(velocity.x, horizontal_input * speed, delta * 2.0)
	else:
		# Normal movement
		velocity.x = horizontal_input * speed

func handle_wall_sliding() -> void:
	# Check if touching a wall
	if is_on_wall() and !is_on_floor():
		# Get the normal of the wall
		wall_normal = get_wall_normal()
		
		# Slow down falling when against a wall
		if velocity.y > 0:
			velocity.y = min(velocity.y, wall_slide_speed)
	else:
		wall_normal = Vector2.ZERO

func handle_jumping() -> void:
	# Check for jump input
	if Input.is_action_just_pressed("jump"):
		# Buffer the jump if not able to jump right now
		jump_buffer_timer = jump_buffer_time
		buffered_jump = true
	
	# Regular jump (with coyote time)
	if buffered_jump and (is_on_floor() or coyote_timer > 0):
		velocity.y = jump_strength
		buffered_jump = false
		jump_buffer_timer = 0
	
	# Wall jump
	elif buffered_jump and is_on_wall() and !is_on_floor():
		# Wall jump in the opposite direction of the wall
		velocity.x = wall_normal.x * wall_jump_strength.x
		velocity.y = wall_jump_strength.y
		
		# Apply wall jump control restriction
		is_wall_jumping = true
		wall_jump_timer = wall_jump_time
		
		buffered_jump = false
		jump_buffer_timer = 0
	
	# Release jump button for variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func update_animation() -> void:
	if is_on_wall() and !is_on_floor():
		# Wall sliding animation
		# Note: You'll need to create a wall_slide animation
		animation_player.play("idle")  # Replace with wall_slide when available
	elif not is_on_floor():
		if velocity.y < 0:
			# Rising/jumping
			animation_player.play("jump")
		else:
			# Falling
			animation_player.play("fall")  # Create a fall animation or use jump
	elif velocity.x != 0:
		# Walking on ground
		animation_player.play("walk")
	else:
		# Standing still
		animation_player.play("idle")
