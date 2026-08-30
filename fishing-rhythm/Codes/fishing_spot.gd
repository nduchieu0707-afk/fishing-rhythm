extends Area2D

signal player_entered_spot(spot)
signal player_exited_spot(spot)

@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	add_to_group("FishingSpot")
	_setup_prompt_style()
	prompt_label.hide()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_prompt_style() -> void:
	prompt_label.text = "[ SPACE: CÂU CÁ ]"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Đặt vị trí chính giữa phía trên điểm câu
	prompt_label.custom_minimum_size = Vector2(200, 30)
	prompt_label.position = Vector2(-100, -50) # Căn giữa trục X (-100) và đẩy lên cao (Y = -50)
	prompt_label.z_index = 100 # Đảm bảo nằm đè lên mọi TileMap
	
	# Cấu hình màu sắc chữ nổi bật
	var style := LabelSettings.new()
	style.font_size = 18
	style.font_color = Color(1.0, 0.85, 0.0) # Vàng kim
	style.outline_size = 5
	style.outline_color = Color.BLACK
	prompt_label.label_settings = style

func _on_body_entered(body: Node2D) -> void:
	# Tự động kiểm tra cả Group "Player" lẫn Tên Node chứa chữ "Player"
	if body.is_in_group("Player") or body.name.to_lower().contains("player"):
		prompt_label.show()
		player_entered_spot.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name.to_lower().contains("player"):
		prompt_label.hide()
		player_exited_spot.emit(self)
