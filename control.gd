extends Control

func _ready() -> void:
	# Make the control layer fill the whole viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	setup_ui()

func setup_ui() -> void:
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	# Center horizontally and stick to bottom
	hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hbox.position.y -= 50  # Offset from bottom
	
	# Add some margin and spacing
	hbox.add_theme_constant_override("separation", 10)
	hbox.set_h_size_flags(SIZE_SHRINK_CENTER)  # Center the buttons
	
	# Only create CMYW filters (no black)
	var filters = ["W", "C", "M", "Y"]
	for filter in filters:
		var button = Button.new()
		button.text = filter
		button.custom_minimum_size = Vector2(40, 40)
		button.pressed.connect(func(): ColorFilterManager.apply_filter(filter))
		hbox.add_child(button)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if Input.is_action_pressed("NoFilter"):
			ColorFilterManager.apply_filter("W")  # White/Normal
		elif Input.is_action_pressed("CyanFilter"):
			ColorFilterManager.apply_filter("C")  # Cyan
		elif Input.is_action_pressed("MagentaFilter"):
			ColorFilterManager.apply_filter("M")  # Magenta
		elif Input.is_action_pressed("YellowFilter"):
			ColorFilterManager.apply_filter("Y")  # Yellow
	elif event is InputEventJoypadButton and event.pressed:
		if Input.is_action_pressed("NoFilter"):
			ColorFilterManager.apply_filter("W")
		elif Input.is_action_pressed("CyanFilter"):
			ColorFilterManager.apply_filter("C")
		elif Input.is_action_pressed("MagentaFilter"):
			ColorFilterManager.apply_filter("M")
		elif Input.is_action_pressed("YellowFilter"):
			ColorFilterManager.apply_filter("Y")
