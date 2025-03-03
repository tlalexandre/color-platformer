extends PathFollow2D

@export var speed: float = 100.0

func _process(delta):
	progress += speed * delta  # Moves the platform along the path
