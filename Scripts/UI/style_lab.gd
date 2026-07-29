extends CanvasLayer
## StyleLab — Options overlay.
## Default view: "More features coming soon!" message + Dev Mode unlock button.
## Dev Mode PIN (1542) unlocks all 8 deep visual customization dimensions.

signal closed

# ──────────────────────────────────────────
# Dev Mode row config — all 8 style dimensions
# ──────────────────────────────────────────
const DEV_ROWS_CONFIG: Array[Dictionary] = [
	{key = "bounce_style",    label = "BALL ANIMATION",  names_prop = "BOUNCE_NAMES"},
	{key = "text_style",      label = "TEXT STYLE",      names_prop = "TEXT_STYLE_NAMES"},
	{key = "button_shape",    label = "BUTTON SHAPE",    names_prop = "BUTTON_SHAPE_NAMES"},
	{key = "layout_style",    label = "LAYOUT",          names_prop = "LAYOUT_NAMES"},
	{key = "shader_effect",   label = "BG SHADER",       names_prop = "SHADER_NAMES"},
	{key = "pause_btn_style", label = "PAUSE BUTTON",    names_prop = "PAUSE_BTN_NAMES"},
	{key = "panel_style",     label = "MENU PANEL",      names_prop = "PANEL_NAMES"},
	{key = "anim_style",      label = "ANIMATION STYLE", names_prop = "ANIMATION_NAMES"},
]

var _row_refs: Array[Dictionary] = []
var _default_body: VBoxContainer = null # "More features coming soon" message
var _dev_section: VBoxContainer = null   # holds all dev-mode rows
var _pin_container: HBoxContainer = null # PIN entry UI
var _dev_btn: Button = null
var _dev_showing: bool = false


# ──────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	UISettingsManager.settings_changed.connect(_refresh_all)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close()


# ──────────────────────────────────────────
# UI Construction
# ──────────────────────────────────────────

func _build_ui() -> void:
	# ── Backdrop ──────────────────────────
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# ── Main floating panel ───────────────
	var panel := PanelContainer.new()
	panel.name = "LabPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -230.0
	panel.offset_top    = -340.0
	panel.offset_right  =  230.0
	panel.offset_bottom =  340.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.07, 0.13, 0.97)
	psb.set_border_width_all(2)
	psb.border_color = Color(0.0, 0.82, 1.0, 0.85)
	psb.set_corner_radius_all(20)
	psb.shadow_color = Color(0.0, 0.75, 1.0, 0.35)
	psb.shadow_size  = 22
	psb.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	# ── Margin ────────────────────────────
	var margin := MarginContainer.new()
	margin.layout_mode = 2
	for s in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 18)
	panel.add_child(margin)

	# ── Main VBox (Fills whole height) ───
	var root_vbox := VBoxContainer.new()
	root_vbox.layout_mode = 2
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	# ── Header row ───────────────────────
	var header := HBoxContainer.new()
	header.layout_mode = 2
	root_vbox.add_child(header)

	var palette_lbl := Label.new()
	palette_lbl.text = "⚙   OPTIONS"
	palette_lbl.layout_mode = 2
	palette_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_lbl.add_theme_font_size_override("font_size", 20)
	palette_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	palette_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.8, 1.0, 0.5))
	palette_lbl.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(palette_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat  = true
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.6))
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	# ── Header Divider ───────────────────
	root_vbox.add_child(_make_separator())

	# ── Scroll container (EXPANDS TO FILL WHOLE PANEL BODY) ───
	var scroll := ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.layout_mode = 2
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(content_vbox)

	# ── Default body message ("more features coming") ──────────
	_default_body = VBoxContainer.new()
	_default_body.layout_mode = 2
	_default_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_body.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_default_body.alignment = BoxContainer.ALIGNMENT_CENTER
	_default_body.add_theme_constant_override("separation", 12)
	content_vbox.add_child(_default_body)

	var msg_card := PanelContainer.new()
	msg_card.layout_mode = 2
	var msg_sb := StyleBoxFlat.new()
	msg_sb.bg_color = Color(0.08, 0.14, 0.24, 0.6)
	msg_sb.set_border_width_all(1)
	msg_sb.border_color = Color(0.0, 0.75, 1.0, 0.3)
	msg_sb.set_corner_radius_all(14)
	msg_sb.set_content_margin_all(20)
	msg_card.add_theme_stylebox_override("panel", msg_sb)
	_default_body.add_child(msg_card)

	var msg_vbox := VBoxContainer.new()
	msg_vbox.layout_mode = 2
	msg_vbox.add_theme_constant_override("separation", 8)
	msg_card.add_child(msg_vbox)

	var feat_icon := Label.new()
	feat_icon.text = "✨"
	feat_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feat_icon.add_theme_font_size_override("font_size", 32)
	msg_vbox.add_child(feat_icon)

	var feat_title := Label.new()
	feat_title.text = "More features to come for now"
	feat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feat_title.add_theme_font_size_override("font_size", 16)
	feat_title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	msg_vbox.add_child(feat_title)

	var feat_sub := Label.new()
	feat_sub.text = "Game settings & audio controls will be added in future updates."
	feat_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feat_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feat_sub.add_theme_font_size_override("font_size", 12)
	feat_sub.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 0.7))
	msg_vbox.add_child(feat_sub)

	# ── Dev Mode Button ───────────────────
	_dev_btn = Button.new()
	_dev_btn.layout_mode = 2
	_dev_btn.custom_minimum_size = Vector2(0, 42)
	_dev_btn.add_theme_font_size_override("font_size", 14)
	_dev_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if UISettingsManager.dev_mode_unlocked:
		_dev_btn.text = "🔓  Dev Mode"
		_style_dev_btn_unlocked()
	else:
		_dev_btn.text = "🔒  Dev Mode"
		_style_dev_btn_locked()

	_dev_btn.pressed.connect(_on_dev_mode_pressed)
	content_vbox.add_child(_dev_btn)

	# ── PIN entry UI (hidden by default) ──
	_pin_container = HBoxContainer.new()
	_pin_container.layout_mode = 2
	_pin_container.add_theme_constant_override("separation", 8)
	_pin_container.visible = false
	content_vbox.add_child(_pin_container)

	var pin_label := Label.new()
	pin_label.text = "Enter PIN:"
	pin_label.layout_mode = 2
	pin_label.add_theme_font_size_override("font_size", 13)
	pin_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 0.9))
	_pin_container.add_child(pin_label)

	var pin_input := LineEdit.new()
	pin_input.name = "PinInput"
	pin_input.layout_mode = 2
	pin_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pin_input.custom_minimum_size = Vector2(0, 36)
	pin_input.placeholder_text = "_ _ _ _"
	pin_input.max_length = 4
	pin_input.secret = true
	pin_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin_input.add_theme_font_size_override("font_size", 16)

	var pin_sb := StyleBoxFlat.new()
	pin_sb.bg_color = Color(0.06, 0.1, 0.18, 0.9)
	pin_sb.set_border_width_all(1)
	pin_sb.border_color = Color(0.0, 0.8, 1.0, 0.6)
	pin_sb.set_corner_radius_all(8)
	pin_input.add_theme_stylebox_override("normal", pin_sb)
	pin_input.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	pin_input.add_theme_color_override("caret_color", Color(0.0, 0.95, 1.0))
	_pin_container.add_child(pin_input)

	var submit_btn := Button.new()
	submit_btn.text = "→"
	submit_btn.custom_minimum_size = Vector2(44, 36)
	submit_btn.add_theme_font_size_override("font_size", 16)
	var sub_n := StyleBoxFlat.new()
	sub_n.bg_color = Color(0.0, 0.5, 0.7, 0.85)
	sub_n.set_corner_radius_all(8)
	submit_btn.add_theme_stylebox_override("normal", sub_n)
	var sub_h := StyleBoxFlat.new()
	sub_h.bg_color = Color(0.0, 0.7, 0.95, 1.0)
	sub_h.set_corner_radius_all(8)
	submit_btn.add_theme_stylebox_override("hover", sub_h)
	submit_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	submit_btn.add_theme_color_override("font_color", Color.WHITE)
	submit_btn.pressed.connect(func(): _try_pin(pin_input))
	pin_input.text_submitted.connect(func(_t: String): _try_pin(pin_input))
	_pin_container.add_child(submit_btn)

	# ── Dev rows container (hidden until unlocked + toggled) ──
	_dev_section = VBoxContainer.new()
	_dev_section.layout_mode = 2
	_dev_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_section.add_theme_constant_override("separation", 6)
	_dev_section.visible = false
	content_vbox.add_child(_dev_section)

	# Build all 8 customization rows inside dev section
	for cfg in DEV_ROWS_CONFIG:
		_build_row(_dev_section, cfg)

	# Reset button inside dev section
	_dev_section.add_child(_make_separator())
	var reset_btn := Button.new()
	reset_btn.text = "⟲   Reset to Defaults"
	reset_btn.layout_mode = 2
	reset_btn.custom_minimum_size = Vector2(0, 42)
	reset_btn.add_theme_font_size_override("font_size", 15)

	var r_norm := StyleBoxFlat.new()
	r_norm.bg_color = Color(0.28, 0.08, 0.1, 0.85)
	r_norm.set_border_width_all(1)
	r_norm.border_color = Color(0.85, 0.25, 0.3, 0.7)
	r_norm.set_corner_radius_all(10)
	reset_btn.add_theme_stylebox_override("normal", r_norm)

	var r_hov := StyleBoxFlat.new()
	r_hov.bg_color = Color(0.42, 0.12, 0.15, 0.95)
	r_hov.set_border_width_all(1)
	r_hov.border_color = Color(1.0, 0.35, 0.4, 0.9)
	r_hov.set_corner_radius_all(10)
	reset_btn.add_theme_stylebox_override("hover", r_hov)
	reset_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	reset_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	reset_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.7, 0.7))
	reset_btn.pressed.connect(UISettingsManager.reset_to_defaults)
	_dev_section.add_child(reset_btn)

	# ── Animate-in ───────────────────────
	var anim_params := UISettingsManager.get_animation_params()
	var dur: float = anim_params["duration"]
	var trans: int = anim_params["trans_type"]
	var eas: int   = anim_params["ease_type"]
	var init_scale: Vector2 = anim_params["initial_scale"]

	panel.pivot_offset = Vector2(230.0, 340.0)
	panel.scale  = init_scale
	panel.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, dur)
	tw.tween_property(panel, "scale", Vector2.ONE, dur).set_trans(trans).set_ease(eas)
	backdrop.modulate.a = 0.0
	tw.tween_property(backdrop, "modulate:a", 1.0, min(dur, 0.2))


# ──────────────────────────────────────────
# Dev Mode Styling
# ──────────────────────────────────────────

func _style_dev_btn_locked() -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.12, 0.18, 0.7)
	n.set_border_width_all(1)
	n.border_color = Color(0.5, 0.5, 0.65, 0.5)
	n.set_corner_radius_all(10)
	_dev_btn.add_theme_stylebox_override("normal", n)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.18, 0.18, 0.28, 0.9)
	h.set_border_width_all(1)
	h.border_color = Color(0.6, 0.6, 0.8, 0.75)
	h.set_corner_radius_all(10)
	_dev_btn.add_theme_stylebox_override("hover", h)
	_dev_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.8))
	_dev_btn.add_theme_color_override("font_hover_color", Color(0.75, 0.75, 0.85))


func _style_dev_btn_unlocked() -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.06, 0.15, 0.1, 0.8)
	n.set_border_width_all(1)
	n.border_color = Color(0.2, 0.9, 0.5, 0.7)
	n.set_corner_radius_all(10)
	_dev_btn.add_theme_stylebox_override("normal", n)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.1, 0.25, 0.16, 0.95)
	h.set_border_width_all(1)
	h.border_color = Color(0.3, 1.0, 0.6, 0.9)
	h.set_corner_radius_all(10)
	_dev_btn.add_theme_stylebox_override("hover", h)
	_dev_btn.add_theme_color_override("font_color", Color(0.3, 0.95, 0.55))
	_dev_btn.add_theme_color_override("font_hover_color", Color(0.5, 1.0, 0.7))


# ──────────────────────────────────────────
# Dev Mode Logic
# ──────────────────────────────────────────

func _on_dev_mode_pressed() -> void:
	if UISettingsManager.dev_mode_unlocked:
		_dev_showing = not _dev_showing
		_default_body.visible = not _dev_showing
		_dev_section.visible  = _dev_showing
		_dev_btn.text = "🔓  Dev Mode  ▲" if _dev_showing else "🔓  Dev Mode  ▼"
	else:
		_pin_container.visible = not _pin_container.visible
		if _pin_container.visible:
			var pin_input := _pin_container.get_node("PinInput") as LineEdit
			if pin_input:
				pin_input.text = ""
				pin_input.grab_focus()


func _try_pin(pin_input: LineEdit) -> void:
	if pin_input.text == UISettingsManager.DEV_PIN:
		UISettingsManager.unlock_dev_mode()
		_pin_container.visible = false
		_dev_showing = true
		_default_body.visible = false
		_dev_section.visible  = true
		_dev_btn.text = "🔓  Dev Mode  ▲"
		_style_dev_btn_unlocked()

		# Flash feedback
		_dev_btn.modulate = Color(0.3, 1.0, 0.5)
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_dev_btn, "modulate", Color.WHITE, 0.4)
	else:
		pin_input.text = ""
		pin_input.placeholder_text = "Wrong PIN"
		var orig_x: float = _pin_container.position.x
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_pin_container, "position:x", orig_x + 12.0, 0.05)
		tw.tween_property(_pin_container, "position:x", orig_x - 12.0, 0.05)
		tw.tween_property(_pin_container, "position:x", orig_x + 6.0, 0.05)
		tw.tween_property(_pin_container, "position:x", orig_x, 0.05)
		await tw.finished
		pin_input.placeholder_text = "_ _ _ _"


# ──────────────────────────────────────────
# Row Builder
# ──────────────────────────────────────────

func _build_row(parent: VBoxContainer, cfg: Dictionary) -> void:
	var key: String     = cfg["key"]
	var names: Array    = UISettingsManager.get(cfg["names_prop"])
	var cur_val: int    = UISettingsManager.get(key)

	var section := Label.new()
	section.text = cfg["label"]
	section.layout_mode = 2
	section.add_theme_font_size_override("font_size", 11)
	section.add_theme_color_override("font_color", Color(0.45, 0.65, 0.88, 0.9))
	parent.add_child(section)

	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var prev_btn := _make_arrow_btn("◀")
	row.add_child(prev_btn)

	var val_lbl := Label.new()
	val_lbl.text = names[cur_val]
	val_lbl.layout_mode = 2
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	val_lbl.custom_minimum_size   = Vector2(0, 36)
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	row.add_child(val_lbl)

	var next_btn := _make_arrow_btn("▶")
	row.add_child(next_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	parent.add_child(spacer)

	_row_refs.append({key = key, names = names, label = val_lbl})

	prev_btn.pressed.connect(func(): _cycle(key, names, val_lbl, -1))
	next_btn.pressed.connect(func(): _cycle(key, names, val_lbl,  1))


func _make_arrow_btn(txt: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(42, 36)

	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.08, 0.18, 0.32, 0.85)
	norm.set_border_width_all(1)
	norm.border_color = Color(0.0, 0.78, 1.0, 0.65)
	norm.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("normal", norm)

	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(0.12, 0.3, 0.52, 0.95)
	hov.set_border_width_all(1)
	hov.border_color = Color(0.0, 0.95, 1.0, 0.9)
	hov.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.5, 0.88, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	return btn


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.layout_mode = 2
	var sep_sb := StyleBoxFlat.new()
	sep_sb.bg_color = Color(1.0, 1.0, 1.0, 0.1)
	sep_sb.set_content_margin_all(0)
	sep.add_theme_stylebox_override("separator", sep_sb)
	return sep


# ──────────────────────────────────────────
# Logic
# ──────────────────────────────────────────

func _cycle(key: String, names: Array, label: Label, step: int) -> void:
	var count   := names.size()
	var current := int(UISettingsManager.get(key))
	var next    := ((current + step) % count + count) % count
	UISettingsManager.set_and_save(key, next)
	label.text = names[next]


func _refresh_all() -> void:
	for rd in _row_refs:
		rd["label"].text = rd["names"][int(UISettingsManager.get(rd["key"]))]


func _on_close() -> void:
	var panel := get_node_or_null("LabPanel")
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if panel:
		tw.set_parallel(true)
		tw.tween_property(panel, "modulate:a", 0.0, 0.16)
		tw.tween_property(panel, "scale", Vector2(0.88, 0.88), 0.16).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	closed.emit()
	queue_free()
