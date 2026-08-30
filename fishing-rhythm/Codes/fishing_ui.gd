extends CanvasLayer

signal fishing_finished(success: bool)

const ACTIONS = ["ui_up", "ui_down", "ui_left", "ui_right"]
const ARROW_ICONS = {"ui_up": "↑", "ui_down": "↓", "ui_left": "←", "ui_right": "→"}

var coins: int = 50
var bait_count: int = 5
var rod_level: int = 1

var is_fishing: bool = false
var target_sequence: Array[String] = []
var current_step: int = 0
var current_misses: int = 0
var max_misses: int = 3

# HỆ THỐNG CĂNG DÂY (TUG-OF-WAR TENSION)
var tension: float = 0.0
var max_tension: float = 100.0

var current_fish: FishData = null
var fish_db: Array[FishData] = []
var inventory: Array[FishData] = [] # Túi đồ chứa cá

@onready var hud: Control = $HUD
@onready var rhythm_panel: Panel = $RhythmPanel
@onready var shop_panel: Panel = $ShopPanel
@onready var arrow_display: RichTextLabel = $RhythmPanel/ArrowDisplay
@onready var progress_bar: ProgressBar = $RhythmPanel/ProgressBarTimer
@onready var feedback_label: Label = $RhythmPanel/FeedbackLabel
@onready var input_timer: Timer = $InputTimer

@onready var label_coins: Label = $HUD/LabelCoins
@onready var label_bait: Label = $HUD/LabelBait
@onready var label_rod: Label = $HUD/LabelRod
@onready var label_status: Label = $HUD/LabelStatus

# UI BỔ SUNG TỰ ĐỘNG BẰNG CODE
var tension_bar: ProgressBar
var fish_preview_control: Control
var inventory_panel: Panel
var inventory_grid: GridContainer

# UI MENU & HƯỚNG DẪN BỔ SUNG
var help_panel: Panel
var menu_panel: Panel

func _ready() -> void:
	init_fish_db()
	_setup_ui_layout_and_styles()
	_setup_help_and_menu_ui()
	
	rhythm_panel.hide()
	shop_panel.hide()
	inventory_panel.hide()
	help_panel.hide()
	menu_panel.hide()
	
	update_ui()
	
	input_timer.timeout.connect(_on_input_timeout)
	$ShopPanel/VBoxContainer/ButtonBuyBait.pressed.connect(_buy_bait)
	$ShopPanel/VBoxContainer/ButtonUpgradeRod.pressed.connect(_upgrade_rod)
	$ShopPanel/VBoxContainer/ButtonCloseShop.pressed.connect(func(): shop_panel.hide())

func init_fish_db() -> void:
	fish_db.clear()
	fish_db.append(FishData.new("Cá Rô Đồng", 15, 3, 1.8, Color(0.85, 0.1, 0.2), Color(0.5, 0.0, 0.1), Vector2(1.1, 0.8), 14.0))
	fish_db.append(FishData.new("Cá Chép Cam", 45, 5, 1.5, Color(0.95, 0.45, 0.1), Color(1.0, 0.7, 0.2), Vector2(1.4, 0.9), 18.0))
	fish_db.append(FishData.new("Cá Hồi Xanh", 120, 7, 1.3, Color(0.15, 0.55, 0.95), Color(0.4, 0.8, 1.0), Vector2(1.8, 0.7), 22.0))
	fish_db.append(FishData.new("Cá Rồng Vàng", 350, 9, 1.1, Color(1.0, 0.82, 0.0), Color(1.0, 0.4, 0.0), Vector2(2.1, 1.0), 26.0))

func _setup_ui_layout_and_styles() -> void:
	# 1. CẤU HÌNH HUD
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var label_style := LabelSettings.new()
	label_style.font_size = 18
	label_style.font_color = Color(1.0, 0.95, 0.8)
	label_style.outline_size = 4
	label_style.outline_color = Color.BLACK
	
	label_coins.label_settings = label_style
	label_bait.label_settings = label_style
	label_rod.label_settings = label_style
	
	label_coins.position = Vector2(20, 20)
	label_bait.position = Vector2(20, 48)
	label_rod.position = Vector2(20, 76)
	
	label_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label_status.offset_left = 20
	label_status.offset_right = -20
	label_status.offset_bottom = -20
	label_status.offset_top = -60
	label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var status_style := LabelSettings.new()
	status_style.font_size = 22
	status_style.font_color = Color(1.0, 0.84, 0.0)
	status_style.outline_size = 6
	status_style.outline_color = Color.BLACK
	label_status.label_settings = status_style

	# 2. RHYTHM PANEL (Khung minigame câu cá)
	rhythm_panel.set_anchors_preset(Control.PRESET_CENTER)
	rhythm_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rhythm_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	rhythm_panel.custom_minimum_size = Vector2(540, 280)
	rhythm_panel.offset_left = -270
	rhythm_panel.offset_right = 270
	rhythm_panel.offset_top = -140
	rhythm_panel.offset_bottom = 140

	var rhythm_box := StyleBoxFlat.new()
	rhythm_box.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	rhythm_box.set_corner_radius_all(16)
	rhythm_box.set_border_width_all(4)
	rhythm_box.border_color = Color(0.2, 0.7, 1.0)
	rhythm_panel.add_theme_stylebox_override("panel", rhythm_box)

	# HÌNH ẢNH CÁ HIỂN THỊ TRONG MINIGAME
	fish_preview_control = Control.new()
	fish_preview_control.custom_minimum_size = Vector2(80, 50)
	fish_preview_control.position = Vector2(230, 15)
	rhythm_panel.add_child(fish_preview_control)
	fish_preview_control.draw.connect(_draw_minigame_fish)

	arrow_display.bbcode_enabled = true
	arrow_display.set_anchors_preset(Control.PRESET_TOP_WIDE)
	arrow_display.offset_left = 10
	arrow_display.offset_right = -10
	arrow_display.offset_top = 70
	arrow_display.offset_bottom = 120
	arrow_display.add_theme_font_size_override("normal_font_size", 32)

	# THANH THỜI GIAN
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(480, 14)
	progress_bar.position = Vector2(30, 130)
	
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.12, 0.12, 0.18)
	pb_bg.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("background", pb_bg)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.2, 0.85, 0.4)
	pb_fill.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("fill", pb_fill)

	# THANH CĂNG DÂY (TENSING BAR)
	tension_bar = ProgressBar.new()
	tension_bar.show_percentage = false
	tension_bar.custom_minimum_size = Vector2(480, 18)
	tension_bar.position = Vector2(30, 155)
	rhythm_panel.add_child(tension_bar)

	var tb_bg := StyleBoxFlat.new()
	tb_bg.bg_color = Color(0.2, 0.05, 0.05)
	tb_bg.set_corner_radius_all(6)
	tension_bar.add_theme_stylebox_override("background", tb_bg)

	var tb_fill := StyleBoxFlat.new()
	tb_fill.bg_color = Color(0.9, 0.2, 0.2)
	tb_fill.set_corner_radius_all(6)
	tension_bar.add_theme_stylebox_override("fill", tb_fill)

	feedback_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	feedback_label.offset_left = 10
	feedback_label.offset_right = -10
	feedback_label.offset_bottom = -10
	feedback_label.offset_top = -50
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var fb_style := LabelSettings.new()
	fb_style.font_size = 20
	fb_style.font_color = Color(1.0, 0.35, 0.35)
	fb_style.outline_size = 4
	fb_style.outline_color = Color.BLACK
	feedback_label.label_settings = fb_style

	# 3. SHOP PANEL
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	shop_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	shop_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	shop_panel.custom_minimum_size = Vector2(380, 260)
	shop_panel.offset_left = -190
	shop_panel.offset_right = 190
	shop_panel.offset_top = -130
	shop_panel.offset_bottom = 130

	var shop_box := StyleBoxFlat.new()
	shop_box.bg_color = Color(0.1, 0.1, 0.14, 0.98)
	shop_box.set_corner_radius_all(14)
	shop_box.set_border_width_all(3)
	shop_box.border_color = Color(0.9, 0.7, 0.2)
	shop_panel.add_theme_stylebox_override("panel", shop_box)

	var vbox: VBoxContainer = $ShopPanel/VBoxContainer
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_top = 30
	vbox.offset_right = -30
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 14)

	# 4. TÚI ĐỒ (INVENTORY PANEL)
	_setup_inventory_ui()

func _setup_inventory_ui() -> void:
	inventory_panel = Panel.new()
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	inventory_panel.custom_minimum_size = Vector2(520, 360)
	inventory_panel.offset_left = -260
	inventory_panel.offset_right = 260
	inventory_panel.offset_top = -180
	inventory_panel.offset_bottom = 180
	add_child(inventory_panel)

	var inv_box := StyleBoxFlat.new()
	inv_box.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	inv_box.set_corner_radius_all(14)
	inv_box.set_border_width_all(3)
	inv_box.border_color = Color(0.3, 0.8, 0.5)
	inventory_panel.add_theme_stylebox_override("panel", inv_box)

	var title := Label.new()
	title.text = "TÚI CÁ CỦA BẠN"
	title.position = Vector2(20, 15)
	var title_style := LabelSettings.new()
	title_style.font_size = 20
	title_style.font_color = Color(0.4, 1.0, 0.6)
	title.label_settings = title_style
	inventory_panel.add_child(title)

	var btn_close := Button.new()
	btn_close.text = "X"
	btn_close.position = Vector2(470, 10)
	btn_close.custom_minimum_size = Vector2(35, 35)
	btn_close.pressed.connect(func(): inventory_panel.hide())
	inventory_panel.add_child(btn_close)

	var btn_sell_all := Button.new()
	btn_sell_all.text = "BÁN TẤT CẢ CÁ"
	btn_sell_all.position = Vector2(320, 12)
	btn_sell_all.custom_minimum_size = Vector2(130, 32)
	btn_sell_all.pressed.connect(_sell_all_fish)
	inventory_panel.add_child(btn_sell_all)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 60)
	scroll.custom_minimum_size = Vector2(480, 280)
	inventory_panel.add_child(scroll)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 2
	inventory_grid.add_theme_constant_override("h_separation", 15)
	inventory_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(inventory_grid)

func _setup_help_and_menu_ui() -> void:
	# --- 1. PANEL HƯỚNG DẪN (TUTORIAL) ---
	help_panel = Panel.new()
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	help_panel.custom_minimum_size = Vector2(500, 340)
	help_panel.offset_left = -250; help_panel.offset_right = 250
	help_panel.offset_top = -170; help_panel.offset_bottom = 170
	add_child(help_panel)

	var help_box := StyleBoxFlat.new()
	help_box.bg_color = Color(0.08, 0.1, 0.15, 0.98)
	help_box.set_corner_radius_all(14)
	help_box.set_border_width_all(3)
	help_box.border_color = Color(0.2, 0.8, 1.0)
	help_panel.add_theme_stylebox_override("panel", help_box)

	var help_text := RichTextLabel.new()
	help_text.bbcode_enabled = true
	help_text.position = Vector2(20, 20)
	help_text.size = Vector2(460, 250)
	help_text.text = "[center][b][font_size=20][color=#33ccff]HƯỚNG DẪN CÂU CÁ[/color][/font_size][/b][/center]\n\n" \
		+ "[color=#ffeb3b]1. Quăng cần:[/color] Đứng gần bến nước và nhấn phím [b]SPACE[/b].\n" \
		+ "[color=#ffeb3b]2. Giật cần:[/color] Đợi dấu [color=#ff3333]![/color] xuất hiện trên đầu rồi bấm [b]SPACE[/b] ngay.\n" \
		+ "[color=#ffeb3b]3. Nhịp phím:[/color] Nhấn chuỗi phím mũi tên [b]↑ ↓ ← →[/b] theo thứ tự hiển thị.\n" \
		+ "[color=#ffeb3b]4. Căng dây:[/color] Bấm [b]SAI[/b] hoặc [b]TRỄ[/b] làm tăng thanh đỏ. Thanh đầy = [color=#ff3333]ĐỨT DÂY[/color]!\n" \
		+ "[color=#ffeb3b]5. Phím tắt:[/color] [b]TAB[/b] (Shop) | [b]Caps Lock[/b] (Túi đồ) | [b]H[/b] (Hướng dẫn) | [b]ESC[/b] (Menu)"
	help_panel.add_child(help_text)

	var btn_close_help := Button.new()
	btn_close_help.text = "ĐÃ HIỂU"
	btn_close_help.position = Vector2(190, 285)
	btn_close_help.custom_minimum_size = Vector2(120, 36)
	btn_close_help.pressed.connect(func(): help_panel.hide())
	help_panel.add_child(btn_close_help)

	# --- 2. MENU GAME / PAUSE MENU ---
	menu_panel = Panel.new()
	menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS # Để menu hoạt động khi Pause game
	menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	menu_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu_panel.custom_minimum_size = Vector2(320, 280)
	menu_panel.offset_left = -160; menu_panel.offset_right = 160
	menu_panel.offset_top = -140; menu_panel.offset_bottom = 140
	add_child(menu_panel)

	var menu_box := StyleBoxFlat.new()
	menu_box.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	menu_box.set_corner_radius_all(14)
	menu_box.set_border_width_all(3)
	menu_box.border_color = Color(0.9, 0.7, 0.2)
	menu_panel.add_theme_stylebox_override("panel", menu_box)

	var menu_vbox := VBoxContainer.new()
	menu_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_vbox.offset_left = 30; menu_vbox.offset_right = -30
	menu_vbox.offset_top = 20; menu_vbox.offset_bottom = -20
	menu_vbox.add_theme_constant_override("separation", 10)
	menu_panel.add_child(menu_vbox)

	var menu_title := Label.new()
	menu_title.text = "MENU GAME"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_style := LabelSettings.new()
	title_style.font_size = 20
	title_style.font_color = Color.GOLD
	menu_title.label_settings = title_style
	menu_vbox.add_child(menu_title)

	var btn_resume := Button.new(); btn_resume.text = "Tiếp Tục Game"
	btn_resume.pressed.connect(_toggle_pause_menu)
	menu_vbox.add_child(btn_resume)

	var btn_help := Button.new(); btn_help.text = "Hướng Dẫn Chơi"
	btn_help.pressed.connect(func(): help_panel.show())
	menu_vbox.add_child(btn_help)

	var btn_inv := Button.new(); btn_inv.text = "Túi Cá"
	btn_inv.pressed.connect(func():
		inventory_panel.show()
		if get_tree().paused: _toggle_pause_menu()
	)
	menu_vbox.add_child(btn_inv)

	var btn_shop := Button.new(); btn_shop.text = "Cửa Hàng"
	btn_shop.pressed.connect(func():
		shop_panel.show()
		if get_tree().paused: _toggle_pause_menu()
	)
	menu_vbox.add_child(btn_shop)

	var btn_quit := Button.new(); btn_quit.text = "Thoát Game"
	btn_quit.pressed.connect(func(): get_tree().quit())
	menu_vbox.add_child(btn_quit)

func _toggle_pause_menu() -> void:
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	menu_panel.visible = is_paused

# ------------------------------------------------------------------------------
# HÌNH ẢNH CÁ TRONG RHYTHM PANEL
# ------------------------------------------------------------------------------
func _draw_minigame_fish() -> void:
	if current_fish and is_fishing:
		_draw_fish_shape(fish_preview_control, Vector2(40, 25), current_fish)

func _draw_fish_shape(node: CanvasItem, center: Vector2, fish: FishData) -> void:
	if not fish: return
	var body_size := 12.0 * fish.scale_factor.x
	var tail_len := fish.tail_length
	
	# 1. Đuôi cá
	var tail := PackedVector2Array([
		center + Vector2(-4, 0),
		center + Vector2(-tail_len, -8),
		center + Vector2(-tail_len, 8)
	])
	node.draw_polygon(tail, [fish.body_color.darkened(0.25)])

	# 2. Thân cá
	node.draw_circle(center, body_size * 0.6, fish.body_color)

	# 3. Mắt cá
	node.draw_circle(center + Vector2(body_size * 0.3, -3), 2.5, Color.WHITE)
	node.draw_circle(center + Vector2(body_size * 0.3 + 1.0, -3), 1.2, Color.BLACK)

func update_ui() -> void:
	label_coins.text = "Vàng: " + str(coins)
	label_bait.text = "Mồi: " + str(bait_count)
	label_rod.text = "Cần câu: Cấp " + str(rod_level)
	render_inventory()

func start_fishing_minigame() -> void:
	if bait_count <= 0:
		label_status.text = "Hết mồi! Hãy nhấn TAB để mở Cửa Hàng mua thêm."
		return
		
	bait_count -= 1
	update_ui()
	is_fishing = true
	
	if not current_fish:
		current_fish = fish_db.pick_random()
		
	current_step = 0
	current_misses = 0
	tension = 0.0
	
	tension_bar.max_value = max_tension
	tension_bar.value = tension

	feedback_label.text = ""
	
	target_sequence.clear()
	for i in range(current_fish.sequence_length):
		target_sequence.append(ACTIONS.pick_random())
		
	rhythm_panel.show()
	fish_preview_control.queue_redraw()
	label_status.text = "Đã dính " + current_fish.name + "! Bấm phím phản xạ!"
	render_arrows()
	start_step_timer()

func start_step_timer() -> void:
	var extra_time_per_arrow: float = 0.4
	var time_window: float = current_fish.input_time_window + (rod_level - 1) * 0.15 + (current_fish.sequence_length * extra_time_per_arrow)
	
	input_timer.start(time_window)
	progress_bar.max_value = time_window
	progress_bar.value = time_window

func _process(_delta: float) -> void:
	if is_fishing and not input_timer.is_stopped():
		progress_bar.value = input_timer.time_left

func _unhandled_input(event: InputEvent) -> void:
	# Tải menu Pause & Hướng dẫn bằng phím tắt
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_H and not is_fishing:
			help_panel.visible = !help_panel.visible
			get_viewport().set_input_as_handled()
			return

	if not is_fishing:
		if event.is_action_pressed("ui_focus_next"):
			shop_panel.visible = !shop_panel.visible
		elif event.is_action_pressed("ui_inventory") or (event is InputEventKey and event.pressed and (event.keycode == KEY_B or event.keycode == KEY_I)):
			inventory_panel.visible = !inventory_panel.visible
		return
		
	for action in ACTIONS:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			check_input(action)
			break

func check_input(pressed_action: String) -> void:
	if pressed_action == target_sequence[current_step]:
		feedback_label.text = "PERFECT!"
		tension = max(0.0, tension - 15.0)
		tension_bar.value = tension
		
		current_step += 1
		input_timer.stop()
		
		if current_step >= target_sequence.size():
			end_game(true)
		else:
			render_arrows()
			start_step_timer()
	else:
		handle_miss("SAI PHÍM!")

func _on_input_timeout() -> void:
	if is_fishing:
		handle_miss("TRỄ HẠN!")

func handle_miss(reason: String) -> void:
	current_misses += 1
	tension += 35.0
	tension_bar.value = tension
	
	feedback_label.text = reason + " - CĂNG DÂY! (" + str(current_misses) + "/" + str(max_misses) + ")"
	
	if tension >= max_tension or current_misses >= max_misses:
		end_game(false)
	else:
		current_step += 1
		if current_step >= target_sequence.size():
			end_game(false)
		else:
			render_arrows()
			start_step_timer()

func end_game(success: bool) -> void:
	is_fishing = false
	input_timer.stop()
	rhythm_panel.hide()
	
	if success:
		inventory.append(current_fish)
		label_status.text = "Bắt thành công " + current_fish.name + "! Đã bỏ cá vào túi."
	else:
		if tension >= max_tension:
			label_status.text = "ĐỨT DÂY CÂU! Cá bơi mất và tốn 1 mồi câu!"
		else:
			label_status.text = "Cá sổng mất!"
		
	update_ui()
	fishing_finished.emit(success)

func render_arrows() -> void:
	var text = "[center]"
	for i in range(target_sequence.size()):
		var icon = ARROW_ICONS[target_sequence[i]]
		if i < current_step:
			text += "[color=#4caf50]" + icon + "[/color] "
		elif i == current_step:
			text += "[color=#ffeb3b][" + icon + "][/color] "
		else:
			text += "[color=#888888]" + icon + "[/color] "
	text += "[/center]"
	arrow_display.text = text

func render_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()

	if inventory.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "Túi đồ trống..."
		inventory_grid.add_child(empty_lbl)
		return

	for idx in range(inventory.size()):
		var fish_data = inventory[idx]
		
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(220, 60)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.18, 0.24)
		style.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel", style)

		var hbox := HBoxContainer.new()
		card.add_child(hbox)

		var icon_ctrl := Control.new()
		icon_ctrl.custom_minimum_size = Vector2(50, 50)
		icon_ctrl.draw.connect(func(): _draw_fish_shape(icon_ctrl, Vector2(25, 25), fish_data))
		hbox.add_child(icon_ctrl)

		var info_vbox := VBoxContainer.new()
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(info_vbox)

		var name_lbl := Label.new()
		name_lbl.text = fish_data.name
		name_lbl.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(name_lbl)

		var val_lbl := Label.new()
		val_lbl.text = str(fish_data.value) + " Vàng"
		val_lbl.add_theme_color_override("font_color", Color.GOLD)
		val_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(val_lbl)

		var btn_sell := Button.new()
		btn_sell.text = "Bán"
		btn_sell.custom_minimum_size = Vector2(45, 30)
		btn_sell.pressed.connect(func(): _sell_single_fish(idx))
		hbox.add_child(btn_sell)

		inventory_grid.add_child(card)

func _sell_single_fish(index: int) -> void:
	if index >= 0 and index < inventory.size():
		var fish_sold = inventory[index]
		coins += fish_sold.value
		inventory.remove_at(index)
		update_ui()
		label_status.text = "Đã bán " + fish_sold.name + " được +" + str(fish_sold.value) + " vàng!"

func _sell_all_fish() -> void:
	if inventory.size() == 0: return
	var total_earned = 0
	for fish in inventory:
		total_earned += fish.value
	coins += total_earned
	inventory.clear()
	update_ui()
	label_status.text = "Đã bán sạch túi cá thu được +" + str(total_earned) + " vàng!"

func _buy_bait() -> void:
	if coins >= 10:
		coins -= 10
		bait_count += 3
		update_ui()
		label_status.text = "Đã mua 3 mồi câu!"
	else:
		label_status.text = "Không đủ vàng mua mồi!"

func _upgrade_rod() -> void:
	var cost = rod_level * 50
	if coins >= cost:
		coins -= cost
		rod_level += 1
		update_ui()
		label_status.text = "Nâng cấp cần thành công! Cấp " + str(rod_level)
	else:
		label_status.text = "Cần " + str(cost) + " vàng để nâng cấp!"
