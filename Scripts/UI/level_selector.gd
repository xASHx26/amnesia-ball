extends Control
## Stage and Level Selector controller.
## Dynamically populates 2-column grid cards for stages and levels using GameManager save data.

enum ViewState {
	STAGE_VIEW,
	LEVEL_VIEW
}

@onready var bg_rect: ColorRect = $BackgroundRect
@onready var header_title: Label = %HeaderTitle
@onready var back_btn: Button = %BackBtn

@onready var stage_container: ScrollContainer = %StageScroll
@onready var stage_grid: GridContainer = %StageGrid

@onready var level_container: ScrollContainer = %LevelScroll
@onready var level_grid: GridContainer = %LevelGrid

var current_view: ViewState = ViewState.STAGE_VIEW
var selected_stage: int = 1


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_switch_to_stage_view()


func _switch_to_stage_view() -> void:
	current_view = ViewState.STAGE_VIEW
	header_title.text = "SELECT STAGE"
	stage_container.visible = true
	level_container.visible = false
	_populate_stage_cards()


func _switch_to_level_view(stage_num: int) -> void:
	selected_stage = stage_num
	current_view = ViewState.LEVEL_VIEW
	header_title.text = "STAGE %d - LEVELS" % stage_num
	stage_container.visible = false
	level_container.visible = true
	_populate_level_cards(stage_num)


## Helper to build styled card StyleBoxes
func _create_card_stylebox(is_hover: bool = false, is_disabled: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	
	if is_disabled:
		style.bg_color = Color(0.06, 0.06, 0.12, 0.6)
		style.border_color = Color(0.3, 0.3, 0.4, 0.3)
	elif is_hover:
		style.bg_color = Color(0.14, 0.22, 0.40, 0.9)
		style.border_color = Color(0.0, 1.0, 1.0, 0.9)
	else:
		style.bg_color = Color(0.08, 0.12, 0.24, 0.75)
		style.border_color = Color(0.0, 0.8, 1.0, 0.5)
		
	return style


## Dynamically generates 2-column grid cards for stages
func _populate_stage_cards() -> void:
	for child in stage_grid.get_children():
		child.queue_free()

	var total_stages := GameManager.get_total_stages()

	for stage_num in range(1, total_stages + 1):
		var is_unlocked := GameManager.is_stage_unlocked(stage_num)
		
		# Create Tile Card Button
		var card := Button.new()
		card.custom_minimum_size = Vector2(195, 140)
		card.focus_mode = Control.FOCUS_NONE

		# Add visual theme override
		card.add_theme_stylebox_override("normal", _create_card_stylebox(false, not is_unlocked))
		card.add_theme_stylebox_override("hover", _create_card_stylebox(true, not is_unlocked))
		card.add_theme_stylebox_override("pressed", _create_card_stylebox(true, not is_unlocked))
		card.add_theme_stylebox_override("disabled", _create_card_stylebox(false, true))

		var margin := MarginContainer.new()
		margin.anchors_preset = Control.PRESET_FULL_RECT
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)

		var title := Label.new()
		title.text = "STAGE %d" % stage_num
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)

		var status := Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 13)

		if is_unlocked:
			title.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			
			# Count total stars collected in this stage
			var stars_count := 0
			var start_lvl := (stage_num - 1) * GameManager.LEVELS_PER_STAGE + 1
			for l in range(start_lvl, start_lvl + GameManager.LEVELS_PER_STAGE):
				stars_count += int(GameManager.get_level_record(l).get("stars", 0))

			var stars_label := Label.new()
			stars_label.text = "⭐ %d/9 Stars" % stars_count
			stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			stars_label.add_theme_font_size_override("font_size", 13)
			vbox.add_child(stars_label)

			status.text = "UNLOCKED"
			status.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6, 0.9))

			var current_st := stage_num
			card.pressed.connect(func(): _switch_to_level_view(current_st))
		else:
			card.disabled = true
			title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			status.text = "🔒 LOCKED"
			status.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))

		vbox.add_child(status)
		stage_grid.add_child(card)


## Dynamically generates 2-column grid cards for levels in a stage
func _populate_level_cards(stage_num: int) -> void:
	for child in level_grid.get_children():
		child.queue_free()

	var start_lvl := (stage_num - 1) * GameManager.LEVELS_PER_STAGE + 1

	for idx in range(GameManager.LEVELS_PER_STAGE):
		var level_num := start_lvl + idx
		var lvl_in_stage := idx + 1
		var record: Dictionary = GameManager.get_level_record(level_num)
		
		# Check level availability
		var is_available: bool = (lvl_in_stage == 1) or bool(GameManager.get_level_record(level_num - 1).get("completed", false)) or bool(record.get("completed", false))

		# Create Tile Card Button
		var card := Button.new()
		card.custom_minimum_size = Vector2(195, 140)
		card.focus_mode = Control.FOCUS_NONE

		card.add_theme_stylebox_override("normal", _create_card_stylebox(false, not is_available))
		card.add_theme_stylebox_override("hover", _create_card_stylebox(true, not is_available))
		card.add_theme_stylebox_override("pressed", _create_card_stylebox(true, not is_available))
		card.add_theme_stylebox_override("disabled", _create_card_stylebox(false, true))

		var margin := MarginContainer.new()
		margin.anchors_preset = Control.PRESET_FULL_RECT
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)

		var title := Label.new()
		title.text = "LEVEL %d" % level_num
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(title)

		var sub_info := Label.new()
		sub_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_info.add_theme_font_size_override("font_size", 12)

		if is_available:
			title.add_theme_color_override("font_color", Color.WHITE)

			var stars: int = int(record.get("stars", 0))
			var star_label := Label.new()
			var star_str := ""
			for s in range(3):
				star_str += "⭐" if s < stars else "☆"
			star_label.text = star_str
			star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			star_label.add_theme_font_size_override("font_size", 16)
			vbox.add_child(star_label)

			# Calculate carried jumps if played directly
			var carried_jumps: int = 0
			if lvl_in_stage > 1:
				var prev_rec: Dictionary = GameManager.get_level_record(level_num - 1)
				carried_jumps = int(prev_rec.get("saved_jumps", 0))

			if lvl_in_stage == 1:
				sub_info.text = "Base Jumps"
				sub_info.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
			else:
				sub_info.text = "+%d Saved Jumps" % carried_jumps
				sub_info.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))

			var target_lvl := level_num
			var target_jumps := carried_jumps
			card.pressed.connect(func(): GameManager.launch_level_direct(target_lvl, target_jumps))
		else:
			card.disabled = true
			title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			
			var lock_label := Label.new()
			lock_label.text = "🔒 LOCKED"
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
			lock_label.add_theme_font_size_override("font_size", 14)
			vbox.add_child(lock_label)

			sub_info.text = "Clear Level %d" % (level_num - 1)
			sub_info.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5))

		vbox.add_child(sub_info)
		level_grid.add_child(card)


func _on_back_pressed() -> void:
	if current_view == ViewState.LEVEL_VIEW:
		_switch_to_stage_view()
	else:
		GameManager.go_to_main_menu()
