extends CharacterBody2D

signal interact_pressed

enum State { IDLE, WALK, FISHING, BITING, ATTACK }

@export var speed: float = 150.0

var current_state: State = State.IDLE
var last_direction: String = "down" # "down", "up", "left", "right"
var can_move: bool = true

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("Player")
	anim_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float) -> void:
	# Khóa di chuyển khi ở các trạng thái đặc biệt (Tấn công / Câu cá / Cá cắn)
	if not can_move or current_state in [State.ATTACK, State.FISHING, State.BITING]:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation()
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
		update_direction(input_vector)
		current_state = State.WALK
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE

	move_and_slide()
	update_animation()

func update_direction(input: Vector2) -> void:
	if abs(input.x) > abs(input.y):
		last_direction = "right" if input.x > 0 else "left"
	else:
		last_direction = "down" if input.y > 0 else "up"

func update_animation() -> void:
	var anim_prefix := ""
	
	match current_state:
		State.IDLE:
			anim_prefix = "idle_"
		State.WALK:
			anim_prefix = "walk_"
		State.FISHING:
			anim_prefix = "fish_"
		State.BITING:
			anim_prefix = "bite_"
		State.ATTACK:
			anim_prefix = "attack_"

	var anim_name := anim_prefix + last_direction

	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		if anim_sprite.animation != anim_name:
			anim_sprite.play(anim_name)

func _unhandled_input(event: InputEvent) -> void:
	# Khi đang ở trạng thái câu cá hoặc tấn công thì bỏ qua các phím di chuyển/tương tác thường
	if not can_move or current_state in [State.ATTACK, State.FISHING, State.BITING]:
		return

	if event.is_action_pressed("ui_accept"): # Nên đổi tên action này thành "interact" để tránh đụng độ với Space ("ui_accept")
		interact_pressed.emit()
	elif event.is_action_pressed("attack"):
		start_attack()

# Các hàm điều khiển trạng thái được gọi tự động từ FishingSystem
func start_attack() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO

func start_fishing() -> void:
	current_state = State.FISHING
	velocity = Vector2.ZERO

func trigger_bite() -> void:
	current_state = State.BITING
	velocity = Vector2.ZERO

func stop_fishing() -> void:
	current_state = State.IDLE

func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		current_state = State.IDLE
