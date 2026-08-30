extends Node2D

@onready var player: CharacterBody2D = $player
@onready var fishing_ui: CanvasLayer = $FishingUI
@onready var fishing_spot: Area2D = $FishingSpot
@onready var fishing_system: Node2D = $player/FishingSystem # Đường dẫn tới FishingSystem

var is_player_in_spot: bool = false

func _ready() -> void:
	fishing_spot.player_entered_spot.connect(_on_entered_spot)
	fishing_spot.player_exited_spot.connect(_on_exited_spot)
	
	player.interact_pressed.connect(_on_player_interact)
	fishing_ui.fishing_finished.connect(_on_fishing_finished)

func _on_entered_spot(_spot) -> void:
	is_player_in_spot = true
	if not fishing_ui.is_fishing:
		fishing_ui.label_status.text = "=== BẤM SPACE / ENTER ĐỂ CÂU CÁ ==="

func _on_exited_spot(_spot) -> void:
	is_player_in_spot = false
	if not fishing_ui.is_fishing:
		fishing_ui.label_status.text = ""

func _on_player_interact() -> void:
	if is_player_in_spot and not fishing_ui.is_fishing:
		player.can_move = false
		if player.has_method("start_fishing"):
			player.start_fishing()
		fishing_ui.start_fishing_minigame()

func _on_fishing_finished(success: bool) -> void:
	# ĐÃ SỬA: KHÔNG bật player.can_move ngay ở đây!
	# Đợi FishingSystem chạy xong toàn bộ animation hiệu ứng câu cá rồi mới trả lại di chuyển
	if not success:
		_unlock_player()

# Gọi từ FishingSystem sau khi animate_fish_catch() kết thúc
func _unlock_player() -> void:
	player.can_move = true
	if player.has_method("stop_fishing"):
		player.stop_fishing()
