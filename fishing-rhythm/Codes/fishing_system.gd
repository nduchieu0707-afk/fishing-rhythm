extends Node2D

enum State { IDLE, CASTING, WAITING, BITE, REELING }
var current_state: State = State.IDLE

@export var cast_distance: float = 120.0
@export var fishing_ui_path: NodePath = "../FishingUI"

@export var spot_offset: Vector2 = Vector2(0, 16.0)
@export var spot_radius: float = 12.0

var line_2d: Line2D
var bobber: Node2D
var bite_indicator: Label
var bite_timer: Timer
var fishing_ui: CanvasLayer

var fish_visual: Node2D
var fish_shadow: Node2D
var spot_detector: Area2D

var float_tween: Tween
var bobber_target_pos: Vector2
var is_in_fishing_spot: bool = false

# ĐÃ SỬA: Sử dụng FishData thay vì Dictionary
var current_fish: FishData = null
var fish_draw_control: Control
var shadow_draw_control: Control

func _ready() -> void:
	_ensure_nodes_exist()
	_setup_visuals_and_styles()
	_connect_ui()

func _ensure_nodes_exist() -> void:
	line_2d = get_node_or_null("Line2D") as Line2D
	if not line_2d:
		line_2d = Line2D.new(); line_2d.name = "Line2D"; add_child(line_2d)

	bobber = get_node_or_null("Bobber") as Node2D
	if not bobber:
		bobber = Node2D.new(); bobber.name = "Bobber"; add_child(bobber)

	bite_indicator = get_node_or_null("BiteIndicator") as Label
	if not bite_indicator:
		bite_indicator = Label.new(); bite_indicator.name = "BiteIndicator"; bobber.add_child(bite_indicator)

	bite_timer = get_node_or_null("BiteTimer") as Timer
	if not bite_timer:
		bite_timer = Timer.new(); bite_timer.name = "BiteTimer"; add_child(bite_timer)
	bite_timer.one_shot = true
	bite_timer.timeout.connect(_on_fish_bite)

	fish_shadow = get_node_or_null("FishShadow") as Node2D
	if not fish_shadow:
		fish_shadow = Node2D.new(); fish_shadow.name = "FishShadow"; add_child(fish_shadow)

	fish_visual = get_node_or_null("FishVisual") as Node2D
	if not fish_visual:
		fish_visual = Node2D.new(); fish_visual.name = "FishVisual"; add_child(fish_visual)

	spot_detector = get_node_or_null("SpotDetector") as Area2D
	if not spot_detector:
		spot_detector = Area2D.new()
		spot_detector.name = "SpotDetector"
		add_child(spot_detector)
		
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = spot_radius
		col.shape = shape
		spot_detector.add_child(col)

		spot_detector.area_entered.connect(_on_spot_entered)
		spot_detector.area_exited.connect(_on_spot_exited)
	
	spot_detector.position = spot_offset

func _on_spot_entered(area: Area2D) -> void:
	if area.is_in_group("FishingSpot"):
		is_in_fishing_spot = true
		if fishing_ui and "label_status" in fishing_ui and current_state == State.IDLE:
			fishing_ui.label_status.text = "Đang ở bến câu! Nhấn SPACE để quăng cần."

func _on_spot_exited(area: Area2D) -> void:
	if area.is_in_group("FishingSpot"):
		is_in_fishing_spot = false
		if fishing_ui and "label_status" in fishing_ui and current_state == State.IDLE:
			fishing_ui.label_status.text = ""

func _setup_visuals_and_styles() -> void:
	line_2d.z_index = 10
	line_2d.width = 2.0
	line_2d.default_color = Color(1.0, 1.0, 1.0, 0.85)
	line_2d.antialiased = true
	line_2d.clear_points()

	bobber.z_index = 10
	var bobber_draw = bobber.get_node_or_null("Visual")
	if not bobber_draw:
		bobber_draw = Control.new(); bobber_draw.name = "Visual"; bobber.add_child(bobber_draw)
		bobber_draw.draw.connect(_draw_bobber.bind(bobber_draw))
		bobber_draw.queue_redraw()

	bite_indicator.text = "!"
	bite_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bite_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bite_indicator.custom_minimum_size = Vector2(30, 30)
	bite_indicator.position = Vector2(-15, -45)
	
	var label_style := LabelSettings.new()
	label_style.font_size = 36
	label_style.font_color = Color(1.0, 0.1, 0.1)
	label_style.outline_size = 6
	label_style.outline_color = Color.WHITE
	bite_indicator.label_settings = label_style

	fish_shadow.z_index = 9
	shadow_draw_control = Control.new()
	fish_shadow.add_child(shadow_draw_control)
	shadow_draw_control.draw.connect(_draw_fish_shadow.bind(shadow_draw_control))

	fish_visual.z_index = 11
	fish_draw_control = Control.new()
	fish_visual.add_child(fish_draw_control)
	fish_draw_control.draw.connect(_draw_fish.bind(fish_draw_control))

	bobber.hide()
	bite_indicator.hide()
	fish_shadow.hide()
	fish_visual.hide()

# ------------------------------------------------------------------------------
# HÀM VẼ PHAO & CÁ DÙNG TRỰC TIẾP DỮ LIỆU FISHDATA
# ------------------------------------------------------------------------------
func _draw_bobber(node: CanvasItem) -> void:
	node.draw_circle(Vector2.ZERO, 8.0, Color.WHITE)
	node.draw_circle(Vector2(0, -3), 6.0, Color(0.95, 0.1, 0.1))
	node.draw_arc(Vector2.ZERO, 8.0, 0, TAU, 16, Color.BLACK, 2.0)
	node.draw_circle(Vector2(0, -9), 3.0, Color.GOLD)

func _draw_fish_shadow(node: CanvasItem) -> void:
	if not current_fish: return
	var scale_factor: Vector2 = current_fish.scale_factor
	var tail_len: float = current_fish.tail_length
	
	var pts := PackedVector2Array([Vector2(-10, 0), Vector2(-tail_len, -6), Vector2(-tail_len, 6)])
	node.draw_polygon(pts, [Color(0.05, 0.1, 0.2, 0.4)])
	node.draw_set_transform(Vector2.ZERO, 0.0, scale_factor)
	node.draw_circle(Vector2.ZERO, 7.0, Color(0.05, 0.1, 0.2, 0.4))

func _draw_fish(node: CanvasItem) -> void:
	if not current_fish: return
	var b_color: Color = current_fish.body_color
	var f_color: Color = current_fish.secondary_color if "secondary_color" in current_fish else b_color.darkened(0.2)
	var scale_factor: Vector2 = current_fish.scale_factor
	var tail_len: float = current_fish.tail_length

	# Thân cá
	node.draw_set_transform(Vector2.ZERO, 0.0, scale_factor)
	node.draw_circle(Vector2.ZERO, 8.0, b_color)
	node.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0))
	
	# Đuôi cá
	var tail := PackedVector2Array([Vector2(-8, 0), Vector2(-tail_len, -8), Vector2(-tail_len, 8)])
	node.draw_polygon(tail, [b_color.darkened(0.15)])
	
	# Vây lưng
	var fin := PackedVector2Array([Vector2(-2, -7), Vector2(4, -13), Vector2(6, -6)])
	node.draw_polygon(fin, [f_color])
	
	# Mắt cá
	node.draw_circle(Vector2(6, -3), 2.5, Color.WHITE)
	node.draw_circle(Vector2(7, -3), 1.2, Color.BLACK)

# ------------------------------------------------------------------------------
# LOGIC GAME
# ------------------------------------------------------------------------------
func _connect_ui() -> void:
	if has_node(fishing_ui_path):
		fishing_ui = get_node(fishing_ui_path) as CanvasLayer
	else:
		fishing_ui = get_tree().root.find_child("FishingUI", true, false) as CanvasLayer

	if fishing_ui and fishing_ui.has_signal("fishing_finished"):
		fishing_ui.fishing_finished.connect(_on_fishing_finished)

func _process(_delta: float) -> void:
	if current_state != State.IDLE:
		line_2d.clear_points()
		line_2d.add_point(Vector2.ZERO)
		line_2d.add_point(line_2d.to_local(bobber.global_position))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		match current_state:
			State.IDLE: start_casting()
			State.WAITING: cancel_fishing("Giật cần quá sớm! Cá giật mình bơi mất.")
			State.BITE: hook_fish()

func start_casting() -> void:
	if not is_in_fishing_spot:
		if fishing_ui and "label_status" in fishing_ui:
			fishing_ui.label_status.text = "Bạn phải đứng ở bến câu mới thả mồi được!"
		return

	if fishing_ui and fishing_ui.bait_count <= 0:
		if "label_status" in fishing_ui:
			fishing_ui.label_status.text = "Hết mồi! Nhấn TAB để mở Shop mua thêm."
		return

	# ĐÃ SỬA: Lấy 1 con cá từ fish_db của FishingUI và đồng bộ sang UI luôn
	if fishing_ui and fishing_ui.fish_db.size() > 0:
		current_fish = fishing_ui.fish_db.pick_random()
		fishing_ui.current_fish = current_fish

	shadow_draw_control.queue_redraw()
	fish_draw_control.queue_redraw()

	current_state = State.CASTING
	var player = get_parent()
	if player and player.has_method("start_fishing"): player.start_fishing()

	var cast_dir := Vector2.DOWN
	if player and "last_direction" in player:
		match player.last_direction:
			"up": cast_dir = Vector2.UP
			"down": cast_dir = Vector2.DOWN
			"left": cast_dir = Vector2.LEFT
			"right": cast_dir = Vector2.RIGHT

	bobber.global_position = global_position
	bobber_target_pos = global_position + cast_dir * cast_distance
	bobber.show()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(bobber, "global_position:x", bobber_target_pos.x, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bobber, "global_position:y", bobber_target_pos.y - 40, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(bobber, "global_position:y", bobber_target_pos.y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished
	enter_waiting_state()

func enter_waiting_state() -> void:
	current_state = State.WAITING
	
	float_tween = create_tween().set_loops()
	float_tween.tween_property(bobber, "position:y", bobber.position.y - 4, 0.55).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(bobber, "position:y", bobber.position.y + 4, 0.55).set_trans(Tween.TRANS_SINE)
	
	if "label_status" in fishing_ui: fishing_ui.label_status.text = "Đang thả mồi... Đợi cá cắn!"
	bite_timer.start(randf_range(2.0, 4.5))

func _on_fish_bite() -> void:
	if current_state != State.WAITING: return
	
	current_state = State.BITE
	bite_indicator.show()
	
	fish_shadow.global_position = bobber.global_position + Vector2(25, 10)
	fish_shadow.show()
	var shadow_tween = create_tween().set_loops()
	shadow_tween.tween_property(fish_shadow, "global_position", bobber.global_position + Vector2(-15, -5), 0.4)
	shadow_tween.tween_property(fish_shadow, "global_position", bobber.global_position + Vector2(15, 8), 0.4)
	
	var player = get_parent()
	if player and player.has_method("trigger_bite"): player.trigger_bite()
	if float_tween: float_tween.kill()
	
	var shake_tween = create_tween().set_loops(4)
	shake_tween.tween_property(bobber, "position:y", bobber.position.y + 8, 0.05)
	shake_tween.tween_property(bobber, "position:y", bobber.position.y - 8, 0.05)

	await get_tree().create_timer(1.1).timeout
	if current_state == State.BITE:
		cancel_fishing("Cá ăn mất mồi rồi sổng mất!")

func hook_fish() -> void:
	current_state = State.REELING
	bite_indicator.hide()
	fish_shadow.hide()
	if float_tween: float_tween.kill()
	
	if fishing_ui and fishing_ui.has_method("start_fishing_minigame"):
		fishing_ui.start_fishing_minigame()

func animate_fish_catch() -> void:
	fish_visual.global_position = bobber.global_position
	fish_visual.rotation = 0
	fish_visual.show()

	var jump_tween = create_tween().set_parallel(true)
	jump_tween.tween_property(fish_visual, "global_position:x", global_position.x, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(fish_visual, "global_position:y", global_position.y - 60, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.chain().tween_property(fish_visual, "global_position:y", global_position.y, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	jump_tween.tween_property(fish_visual, "rotation", TAU * 2, 0.6)

	await jump_tween.finished
	fish_visual.hide()
	
	if fishing_ui and "label_status" in fishing_ui and current_fish:
		fishing_ui.label_status.text = "Bạn vừa câu được " + current_fish.name + "!"

func cancel_fishing(msg: String) -> void:
	current_state = State.IDLE
	bite_timer.stop()
	bite_indicator.hide()
	fish_shadow.hide()
	fish_visual.hide()
	if float_tween: float_tween.kill()
	
	line_2d.clear_points()
	bobber.hide()
	
	current_fish = null
	if fishing_ui: fishing_ui.current_fish = null
	
	var player = get_parent()
	if player and player.has_method("stop_fishing"): player.stop_fishing()
	if fishing_ui and "label_status" in fishing_ui and msg != "": fishing_ui.label_status.text = msg

func _on_fishing_finished(success: bool) -> void:
	if success:
		await animate_fish_catch()
		cancel_fishing("")
	else:
		cancel_fishing("Thất bại! Cá bơi mất.")
		
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("_unlock_player"):
		main_node._unlock_player()
