extends CharacterBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var GRAVITY: float =  700.0
@export var speed: float = 300.0
@export var jump_strength: float = -300.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity.y += delta * GRAVITY
	handle_movement()
	move_and_slide()



func handle_movement() -> void:
	# Horizontal movement
	if Input.is_action_pressed("left"):
		velocity.x = -speed
	elif Input.is_action_pressed("right"):
		velocity.x = speed
	else:
		velocity.x = 0
	
	# Jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strength
		
