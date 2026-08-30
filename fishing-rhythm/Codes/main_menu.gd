extends Control

# Đường dẫn đến scene thế giới game chính
@export_file("*.tscn") var main_game_scene: String = "res://Scenes/main_world.tscn"

# Các nút trên Menu chính
var btn_play: Button
var btn_help: Button
var btn_quit: Button

# Panel Hướng dẫn
var help_panel: Panel
var btn_start_game: Button
var btn_close_help: Button

func _ready() -> void:
	_setup_main_menu_ui()
	_setup_tutorial_panel()
	
	help_panel.hide()

func _setup_main_menu_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background nền
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Container trung tâm
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.custom_minimum_size = Vector2(300, 240)
	vbox.offset_left = -150
	vbox.offset_right = 150
	vbox.offset_top = -120
	vbox.offset_bottom = 120
	vbox.add_theme_constant_override("separation", 15)
	add_child(vbox)

	# Tiêu đề game
	var title := Label.new()
	title.text = "GIAO PHONG CÂU CÁ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_style := LabelSettings.new()
	title_style.font_size = 32
	title_style.font_color = Color(1.0, 0.85, 0.2)
	title_style.outline_size = 8
	title_style.outline_color = Color.BLACK
	title.label_settings = title_style
	vbox.add_child(title)

	# Các nút Menu
	btn_play = _create_menu_button("VÀO GAME")
	btn_help = _create_menu_button("HƯỚNG DẪN")
	btn_quit = _create_menu_button("THOÁT GAME")

	vbox.add_child(btn_play)
	vbox.add_child(btn_help)
	vbox.add_child(btn_quit)

	# Kết nối signal nút bấm
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_help.pressed.connect(func(): 
		btn_start_game.hide()
		btn_close_help.show()
		help_panel.show()
	)
	btn_quit.pressed.connect(func(): get_tree().quit())

func _create_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 45)
	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _setup_tutorial_panel() -> void:
	help_panel = Panel.new()
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	help_panel.custom_minimum_size = Vector2(560, 420)
	help_panel.offset_left = -280
	help_panel.offset_right = 280
	help_panel.offset_top = -210
	help_panel.offset_bottom = 210
	add_child(help_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.09, 0.13, 0.98)
	panel_style.set_corner_radius_all(14)
	panel_style.set_border_width_all(3)
	panel_style.border_color = Color(0.2, 0.7, 1.0)
	help_panel.add_theme_stylebox_override("panel", panel_style)

	# Nội dung hướng dẫn chơi chi tiết
	var help_text := RichTextLabel.new()
	help_text.bbcode_enabled = true
	help_text.position = Vector2(25, 20)
	help_text.size = Vector2(510, 330)
	help_text.text = "[center][b][font_size=22][color=#ffeb3b]HƯỚNG DẪN CƠ CHẾ & PHÍM BẤM[/color][/font_size][/b][/center]\n\n" \
		+ "[color=#33ccff][b]1. DI CHUYỂN & TƯƠNG TÁC:[/b][/color]\n" \
		+ " • Phím [b]A / S / W / D[/b] hoặc [b]Mũi tên[/b]: Di chuyển nhân vật.\n" \
		+ " • Nhấn [b]SPACE[/b] khi đứng ở bến câu để thả phao câu cá.\n\n" \
		+ "[color=#33ccff][b]2. CƠ CHẾ CÂU CÁ (MINIGAME):[/b][/color]\n" \
		+ " • Đợi dấu [color=#ff3333][b]![/b][/color] xuất hiện trên đầu phao -> Bấm [b]SPACE[/b] để giật cần.\n" \
		+ " • Bảng nhịp phím xuất hiện: Nhấn nhanh chuỗi phím mũi tên [b]↑ ↓ ← →[/b] tương ứng.\n" \
		+ " • [color=#ff9800][b]Thanh Căng Dây (Tension):[/b][/color] Bấm [b]SAI[/b] hoặc [b]QUÁ TRỄ[/b] làm tăng thanh đỏ. Thanh đầy = [color=#ff3333]ĐỨT DÂY CÂU[/color]!\n\n" \
		+ "[color=#33ccff][b]3. PHÍM TẮT TIỆN ÍCH:[/b][/color]\n" \
		+ " • [b]TAB[/b]: Mở Cửa Hàng (Mua mồi, nâng cấp cần câu).\n" \
		+ " • [b]Caps Lock[/b]: Mở Túi Cá (Xem và bán cá thu vàng).\n" \
		+ " • [b]ESC[/b]: Mở Menu Tạm Dừng / Hướng Dẫn khi đang chơi."
	help_panel.add_child(help_text)

	# Hộp chứa nút hành động phía dưới
	var btn_hbox := HBoxContainer.new()
	btn_hbox.position = Vector2(25, 360)
	btn_hbox.custom_minimum_size = Vector2(510, 40)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	help_panel.add_child(btn_hbox)

	btn_start_game = Button.new()
	btn_start_game.text = "BẮT ĐẦU CHƠI NGAY"
	btn_start_game.custom_minimum_size = Vector2(200, 40)
	btn_start_game.pressed.connect(_change_to_main_game)
	btn_hbox.add_child(btn_start_game)

	btn_close_help = Button.new()
	btn_close_help.text = "ĐÓNG"
	btn_close_help.custom_minimum_size = Vector2(120, 40)
	btn_close_help.pressed.connect(func(): help_panel.hide())
	btn_hbox.add_child(btn_close_help)

func _on_btn_play_pressed() -> void:
	btn_close_help.hide()
	btn_start_game.show()
	help_panel.show()

func _change_to_main_game() -> void:
	if main_game_scene != "":
		get_tree().change_scene_to_file(main_game_scene)
