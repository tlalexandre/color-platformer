extends CharacterBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var body: Node2D = $Body

@export var GRAVITY: float =  700.0
@export var speed: float = 300.0
@export var jump_strength: float = -300.0
@export var body_scale: float = 0.15
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity.y += delta * GRAVITY
	handle_movement()
	move_and_slide()



func handle_movement() -> void:
	# Determine horizontal movement
	if Input.is_action_pressed("left"):
		velocity.x = -speed
		body.scale.x = -body_scale
	elif Input.is_action_pressed("right"):
		velocity.x = speed
		body.scale.x = body_scale
	else:
		velocity.x = 0
	
	# Handle jumping input
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strength
	
	# Determine which animation to play based on character state
	if not is_on_floor():
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
	
		
