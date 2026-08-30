class_name WanderNPC
extends CharacterBody2D

# --- CẤU HÌNH NPC ---
@export var move_speed: float = 35.0
@export var min_walk_time: float = 1.5
@export var max_walk_time: float = 4.0
@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0
@export var wander_radius: float = 120.0

enum State { IDLE, WANDER }
var current_state: State = State.IDLE

# Hướng nhìn hiện tại: "up", "left", "right"
var facing_direction: String = "up"

var start_position: Vector2
var move_direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	start_position = global_position
	_enter_idle_state()

func _physics_process(delta: float) -> void:
	state_timer -= delta
	
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				_enter_wander_state()
				
		State.WANDER:
			if global_position.distance_to(start_position) > wander_radius:
				move_direction = (start_position - global_position).normalized()
			
			velocity = move_direction * move_speed
			move_and_slide()
			
			if state_timer <= 0:
				_enter_idle_state()
				
	_update_3way_direction()
	_update_animation()

func _enter_idle_state() -> void:
	current_state = State.IDLE
	state_timer = randf_range(min_idle_time, max_idle_time)

func _enter_wander_state() -> void:
	current_state = State.WANDER
	state_timer = randf_range(min_walk_time, max_walk_time)
	
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	move_direction = dirs.pick_random()

func _update_3way_direction() -> void:
	if move_direction == Vector2.ZERO:
		return

	if abs(move_direction.x) > abs(move_direction.y):
		if move_direction.x > 0:
			facing_direction = "right"
		else:
			facing_direction = "left"
	else:
		# Cả đi Lên (UP) và đi Xuống (DOWN) đều dùng chung animation "walk_up"
		facing_direction = "up"

func _update_animation() -> void:
	if not animated_sprite:
		return

	var anim_name := "walk_" + facing_direction

	if current_state == State.WANDER:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
		
		# KỸ THUẬT LẬT HÌNH (FLIP): 
		# - Nếu đi Xuống (DOWN): Lật dọc ảnh (flip_v = true) từ hình "walk_up" thành đi xuống.
		# - Nếu đi Lên (UP) hoặc sang Trái/Phải: Trả về bình thường (flip_v = false).
		if move_direction == Vector2.DOWN:
			animated_sprite.flip_v = true
		else:
			animated_sprite.flip_v = false
			
		# Lật ngang trái/phải nếu cần
		if move_direction.x < 0:
			animated_sprite.flip_h = true
		elif move_direction.x > 0:
			animated_sprite.flip_h = false
	else:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.animation = anim_name
		animated_sprite.stop()
		animated_sprite.frame = 0
