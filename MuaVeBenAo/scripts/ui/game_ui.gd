extends CanvasLayer
## Giao diện kiểu "sổ tay dễ thương": thẻ màu kem bo tròn, viền nâu đậm,
## nút vuông có biểu tượng ở các góc, chợ và túi đồ dạng lưới thẻ.
## Dùng được bằng chuột, chạm và bàn phím.

const GameData = preload("res://scripts/sim/game_data.gd")
const GameRules = preload("res://scripts/sim/game_rules.gd")
const ItemIcon = preload("res://scripts/ui/item_icon.gd")

const INK := Color("3b2a20")
const CREAM := Color("fffaf0")
const CREAM_DARK := Color("f3e6cf")
const GREEN := Color("8fcf6b")
const GREEN_HI := Color("a6dd85")
const GREEN_LO := Color("74b553")
const ORANGE := Color("f4a261")
const ORANGE_HI := Color("f7b98a")
const ROSE := Color("e98a8a")
const XP := Color("9ee6d8")
const GOOD := Color("3f7f22")
const BAD := Color("c0392b")

var main
var root: Control
var hud: Control
var day_label: Label
var day_bar: ProgressBar
var coin_label: Label
var seed_pill_icon
var seed_pill_label: Label
var seed_btn_icon
var action_btn: Button
var action_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var toast_label: Label
var _toast_tween: Tween
var tutorial_panel: PanelContainer
var tutorial_label: Label
var key_hint: Label
var fade: ColorRect

var market_wrap: Control
var market_coin_label: Label
var tab_buttons: Array = []
var market_tab := "buy"
var market_grid: GridContainer
var detail_icon
var detail_name: Label
var detail_desc: Label
var detail_price: Label
var qty_row: HBoxContainer
var qty_label: Label
var detail_total: Label
var detail_action: Button
var detail_msg: Label
var _sel_kind := ""
var _sel_id := ""
var _qty := 1

var inv_wrap: Control
var inv_grid: GridContainer
var inv_icon
var inv_name: Label
var inv_desc: Label
var inv_use: Button
var _inv_sel := ""

var summary_wrap: Control
var summary_label: Label
var summary_ok: Button
var pause_wrap: Control
var pause_first: Button
var menu_wrap: Control
var menu_new: Button
var menu_continue: Button
var menu_error: Label
var confirm_wrap: Control
var confirm_no: Button

var _modal: Control = null


func setup(main_ref) -> void:
	main = main_ref
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	_build_hud()
	_build_market()
	_build_inventory()
	_build_summary()
	_build_pause()
	_build_menu()
	_build_confirm()
	fade = ColorRect.new()
	fade.color = Color(0.08, 0.06, 0.12, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)


# ======================= Theme =======================

func _box(bg: Color, border: Color = INK, bw: int = 3, radius: int = 18, shadow: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	if shadow > 0:
		s.shadow_color = Color(0.23, 0.16, 0.1, 0.25)
		s.shadow_offset = Vector2(0, shadow)
		s.shadow_size = 1
	s.anti_aliasing = true
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 0.45
	t.default_font = fv
	t.default_font_size = 20
	t.set_color("font_color", "Label", INK)

	var panel := _box(CREAM, INK, 4, 26, 6)
	panel.set_content_margin_all(20)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_type_variation("Pill", "PanelContainer")
	var pill := _box(CREAM, INK, 3, 40, 3)
	pill.content_margin_top = 4
	pill.content_margin_bottom = 4
	t.set_stylebox("panel", "Pill", pill)
	t.set_type_variation("Inset", "PanelContainer")
	t.set_stylebox("panel", "Inset", _box(CREAM_DARK, Color("d8c3a0"), 2, 18, 0))

	_button_styles(t, "Button", GREEN, GREEN_HI, GREEN_LO, Color.WHITE)
	t.set_type_variation("Soft", "Button")
	_button_styles(t, "Soft", CREAM, Color("fff3dc"), CREAM_DARK, INK)
	t.set_type_variation("Accent", "Button")
	_button_styles(t, "Accent", ORANGE, ORANGE_HI, Color("e08a45"), Color.WHITE)
	t.set_type_variation("Danger", "Button")
	_button_styles(t, "Danger", ROSE, Color("f0a3a3"), Color("d27070"), Color.WHITE)

	t.set_type_variation("Card", "Button")
	t.set_stylebox("normal", "Card", _box(CREAM, Color("cdb48c"), 3, 18, 3))
	t.set_stylebox("hover", "Card", _box(Color("fff3dc"), INK, 3, 18, 3))
	t.set_stylebox("pressed", "Card", _box(Color("ffe7b8"), INK, 4, 18, 1))
	t.set_stylebox("hover_pressed", "Card", _box(Color("ffe7b8"), INK, 4, 18, 1))
	t.set_stylebox("focus", "Card", _focus())
	t.set_stylebox("disabled", "Card", _box(Color("eee6d8"), Color("cdb48c"), 3, 18, 0))

	t.set_type_variation("Tab", "Button")
	t.set_stylebox("normal", "Tab", _box(CREAM_DARK, Color("cdb48c"), 3, 16, 0))
	t.set_stylebox("hover", "Tab", _box(Color("fff3dc"), INK, 3, 16, 0))
	t.set_stylebox("pressed", "Tab", _box(GREEN, INK, 3, 16, 3))
	t.set_stylebox("hover_pressed", "Tab", _box(GREEN_HI, INK, 3, 16, 3))
	t.set_stylebox("focus", "Tab", _focus())
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(c, "Tab", INK)
	t.set_color("font_pressed_color", "Tab", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Tab", Color.WHITE)

	var bar_bg := _box(Color("e9f3ef"), INK, 3, 12, 0)
	bar_bg.set_content_margin_all(0)
	var bar_fill := _box(XP, INK, 0, 10, 0)
	bar_fill.set_content_margin_all(0)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return t


func _button_styles(t: Theme, type: String, bg: Color, hi: Color, lo: Color, font: Color) -> void:
	t.set_stylebox("normal", type, _box(bg, INK, 3, 18, 5))
	t.set_stylebox("hover", type, _box(hi, INK, 3, 18, 5))
	var pressed := _box(lo, INK, 3, 18, 1)
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 4
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, pressed)
	t.set_stylebox("disabled", type, _box(Color("d9d2c5"), Color("a89c88"), 3, 18, 0))
	t.set_stylebox("focus", type, _focus())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, type, font)
	t.set_color("font_disabled_color", type, Color("8a7f6e"))


func _focus() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.set_border_width_all(4)
	s.border_color = Color("ffc93c")
	s.set_corner_radius_all(20)
	s.set_expand_margin_all(4)
	return s


# ======================= Helpers =======================

func _label(text: String, size: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	return l


func _title(text: String, size: int = 34) -> Label:
	var l := _label(text, size)
	l.add_theme_color_override("font_color", INK)
	return l


func _button(text: String, cb: Callable, variation: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.custom_minimum_size.y = 52
	b.pressed.connect(cb)
	return b


## Nút vuông kem có biểu tượng (góc màn hình).
func _icon_button(icon_id: String, caption: String, cb: Callable) -> Array:
	var b := Button.new()
	b.theme_type_variation = "Soft"
	b.custom_minimum_size = Vector2(92, 92)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	var ic = ItemIcon.new(icon_id, 52.0)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := _label(caption, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	b.add_child(v)
	return [b, ic, l]


func _outlined(l: Label) -> Label:
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 8)
	return l


func _clear(c: Node) -> void:
	for child in c.get_children():
		c.remove_child(child)
		child.queue_free()


func _modal_wrap(panel: Control, dim_alpha: float = 0.35) -> Control:
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.15, 0.1, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(center)
	center.add_child(panel)
	root.add_child(wrap)
	return wrap


func _card(icon_id: String, title: String, price_text: String, badge: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = "Card"
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(118, 132)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	var ic = ItemIcon.new(icon_id, 56.0)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var name_l := _label(title, 15)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.custom_minimum_size.x = 104
	v.add_child(name_l)
	if price_text != "":
		var pr := HBoxContainer.new()
		pr.alignment = BoxContainer.ALIGNMENT_CENTER
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pr.add_child(ItemIcon.new("coin", 20.0))
		pr.add_child(_label(price_text, 16))
		v.add_child(pr)
	b.add_child(v)
	if badge != "":
		var bl := _outlined(_label(badge, 15))
		bl.position = Vector2(8, 2)
		b.add_child(bl)
	return b


# ======================= HUD =======================

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)

	# --- Góc trên trái: ảnh đại diện + ngày ---
	var profile := HBoxContainer.new()
	profile.position = Vector2(16, 14)
	profile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile.add_theme_constant_override("separation", 8)
	var avatar := PanelContainer.new()
	avatar.add_theme_stylebox_override("panel", _box(Color("ffe3d3"), INK, 3, 18, 3))
	avatar.add_child(ItemIcon.new("farmer", 64.0))
	profile.add_child(avatar)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 4)
	var name_pill := PanelContainer.new()
	name_pill.theme_type_variation = "Pill"
	name_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	name_pill.add_child(_label("Nông trại của bạn", 16))
	pv.add_child(name_pill)
	var bar_box := Control.new()
	bar_box.custom_minimum_size = Vector2(190, 30)
	day_bar = ProgressBar.new()
	day_bar.show_percentage = false
	day_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_box.add_child(day_bar)
	day_label = _label("", 16)
	day_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_box.add_child(day_label)
	pv.add_child(bar_box)
	profile.add_child(pv)
	hud.add_child(profile)

	# --- Góc trên phải: xu + hạt đang cầm + menu ---
	var top_right := HBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top_right.offset_left = -16
	top_right.offset_right = -16
	top_right.offset_top = 16
	top_right.add_theme_constant_override("separation", 10)
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var coin_pill := PanelContainer.new()
	coin_pill.theme_type_variation = "Pill"
	var ch := HBoxContainer.new()
	coin_label = _label("0", 22)
	coin_label.custom_minimum_size.x = 64
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ch.add_child(coin_label)
	ch.add_child(ItemIcon.new("coin", 34.0))
	coin_pill.add_child(ch)
	top_right.add_child(coin_pill)
	var seed_pill := PanelContainer.new()
	seed_pill.theme_type_variation = "Pill"
	var sh := HBoxContainer.new()
	seed_pill_label = _label("", 20)
	sh.add_child(seed_pill_label)
	seed_pill_icon = ItemIcon.new("seed_leafy_greens", 34.0)
	sh.add_child(seed_pill_icon)
	seed_pill.add_child(sh)
	top_right.add_child(seed_pill)
	var menu_b := Button.new()
	menu_b.theme_type_variation = "Accent"
	menu_b.custom_minimum_size = Vector2(56, 52)
	menu_b.focus_mode = Control.FOCUS_NONE
	menu_b.pressed.connect(_on_menu_button)
	var mi = ItemIcon.new("menu", 34.0)
	mi.size = Vector2(34, 34)
	mi.position = Vector2(11, 7)
	menu_b.add_child(mi)
	top_right.add_child(menu_b)
	hud.add_child(top_right)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tutorial_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tutorial_panel.offset_left = -16
	tutorial_panel.offset_right = -16
	tutorial_panel.offset_top = 84
	tutorial_panel.custom_minimum_size = Vector2(330, 0)
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_theme_stylebox_override("panel", _box(Color("fffaf0e8"), INK, 3, 18, 3))
	tutorial_label = _label("", 16)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_panel.add_child(tutorial_label)
	hud.add_child(tutorial_panel)

	# --- Góc dưới trái: túi đồ + đổi hạt ---
	var bottom_left := VBoxContainer.new()
	bottom_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_left.offset_left = 16
	bottom_left.offset_top = -16
	bottom_left.offset_bottom = -16
	bottom_left.add_theme_constant_override("separation", 10)
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bag: Array = _icon_button("bag", "Túi đồ", _on_bag_button)
	bottom_left.add_child(bag[0])
	var seed: Array = _icon_button("seed_leafy_greens", "Đổi hạt", _on_seed_button)
	seed_btn_icon = seed[1]
	bottom_left.add_child(seed[0])
	hud.add_child(bottom_left)

	# --- Góc dưới phải: nút hành động lớn ---
	action_btn = Button.new()
	action_btn.theme_type_variation = "Accent"
	action_btn.custom_minimum_size = Vector2(118, 118)
	action_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	action_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	action_btn.offset_left = -16
	action_btn.offset_right = -16
	action_btn.offset_top = -16
	action_btn.offset_bottom = -16
	action_btn.focus_mode = Control.FOCUS_NONE
	action_btn.add_theme_stylebox_override("normal", _box(ORANGE, INK, 4, 59, 6))
	action_btn.add_theme_stylebox_override("hover", _box(ORANGE_HI, INK, 4, 59, 6))
	action_btn.add_theme_stylebox_override("pressed", _box(Color("e08a45"), INK, 4, 59, 1))
	action_btn.add_theme_stylebox_override("disabled", _box(Color("e6ddcf"), Color("a89c88"), 4, 59, 0))
	action_btn.pressed.connect(_on_action_button)
	action_label = _outlined(_label("", 22))
	action_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_btn.add_child(action_label)
	hud.add_child(action_btn)

	# --- Giữa dưới: thông báo + lời nhắc ---
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_top = -14
	bottom.offset_bottom = -14
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation", 8)
	hud.add_child(bottom)
	toast_label = _outlined(_label("", 20))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0
	bottom.add_child(toast_label)
	prompt_panel = PanelContainer.new()
	prompt_panel.theme_type_variation = "Pill"
	prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label = _label("", 18)
	prompt_panel.add_child(prompt_label)
	bottom.add_child(prompt_panel)
	key_hint = _outlined(_label("WASD/chạm để đi · E làm việc · Tab túi đồ · 1/2 chọn hạt · H hướng dẫn · Esc menu", 13))
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_hint.visible = not DisplayServer.is_touchscreen_available()
	bottom.add_child(key_hint)
	hud.visible = false


func _can_hud() -> bool:
	return main.in_game and not main.busy and not is_modal_open()


func _on_menu_button() -> void:
	if _can_hud():
		open_pause()


func _on_bag_button() -> void:
	if _can_hud():
		open_inventory()


func _on_seed_button() -> void:
	if _can_hud():
		main.cycle_seed()


func _on_action_button() -> void:
	if _can_hud():
		main.interact_current()


func refresh() -> void:
	if main == null:
		return
	var st = main.state
	day_label.text = "Ngày %d" % st.day
	day_bar.max_value = 7
	day_bar.value = ((st.day - 1) % 7) + 1
	coin_label.text = str(st.coins)
	var seed_id: String = main.seed_in_hand()
	seed_pill_icon.set_icon(seed_id)
	seed_btn_icon.set_icon(seed_id)
	seed_pill_label.text = "×%d" % st.count(seed_id)
	if st.tutorial_closed:
		tutorial_panel.visible = false
	else:
		tutorial_panel.visible = true
		if st.tutorial_step < GameData.TUTORIAL.size():
			tutorial_label.text = "Hướng dẫn %d/%d\n%s" % [
				st.tutorial_step + 1, GameData.TUTORIAL.size(), GameData.TUTORIAL[st.tutorial_step]["text"]]
		else:
			tutorial_label.text = GameData.TUTORIAL_DONE_TEXT
		if not DisplayServer.is_touchscreen_available():
			tutorial_label.text += "\n[H] Ẩn"


func set_prompt(text: String, verb: String) -> void:
	var clean := text.trim_prefix("[E] ")
	prompt_panel.visible = clean != ""
	if prompt_label.text != clean:
		prompt_label.text = clean
	action_btn.disabled = verb == ""
	action_label.text = verb if verb != "" else "…"


func toast(text: String, good: bool = true) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_outline_color", GOOD.darkened(0.3) if good else BAD.darkened(0.2))
	if _toast_tween:
		_toast_tween.kill()
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)


func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished


func fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.4)
	await tw.finished


# ======================= Modal =======================

func is_modal_open() -> bool:
	return _modal != null


func is_inventory_open() -> bool:
	return _modal == inv_wrap


func _open_modal(wrap: Control, focus: Control) -> void:
	if _modal and _modal != wrap:
		_modal.visible = false
	_modal = wrap
	wrap.visible = true
	if focus:
		focus.grab_focus()


func close_modal() -> void:
	if _modal:
		_modal.visible = false
	_modal = null


func _close_button() -> Button:
	var b := _button("X", close_modal, "Danger")
	b.custom_minimum_size = Vector2(52, 52)
	return b


func _header(title: String, extra: Control) -> HBoxContainer:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var t := _title(title, 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if extra:
		head.add_child(extra)
	head.add_child(_close_button())
	return head


# ======================= Chợ =======================

func _build_market() -> void:
	var frame := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	frame.add_child(v)

	var coin_pill := PanelContainer.new()
	coin_pill.theme_type_variation = "Pill"
	var ch := HBoxContainer.new()
	market_coin_label = _label("", 22)
	ch.add_child(market_coin_label)
	ch.add_child(ItemIcon.new("coin", 30.0))
	coin_pill.add_child(ch)
	v.add_child(_header("Quầy chợ làng", coin_pill))

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var tg := ButtonGroup.new()
	for t in [["buy", "Mua"], ["sell", "Bán"], ["build", "Xây dựng"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.button_group = tg
		b.theme_type_variation = "Tab"
		b.custom_minimum_size = Vector2(140, 46)
		var key: String = t[0]
		b.pressed.connect(func(): _switch_tab(key))
		tabs.add_child(b)
		tab_buttons.append(b)
	v.add_child(tabs)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(530, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_grid = GridContainer.new()
	market_grid.columns = 4
	market_grid.add_theme_constant_override("h_separation", 10)
	market_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(market_grid)
	body.add_child(scroll)

	var det := PanelContainer.new()
	det.theme_type_variation = "Inset"
	det.custom_minimum_size = Vector2(300, 300)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	detail_icon = ItemIcon.new("", 76.0)
	detail_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dv.add_child(detail_icon)
	detail_name = _title("", 22)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(detail_name)
	detail_desc = _label("", 15)
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.custom_minimum_size.x = 268
	dv.add_child(detail_desc)
	detail_price = _label("", 17)
	dv.add_child(detail_price)
	qty_row = HBoxContainer.new()
	qty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	qty_row.add_theme_constant_override("separation", 6)
	var minus := _button("-", func(): _change_qty(-1), "Soft")
	minus.custom_minimum_size = Vector2(52, 46)
	qty_row.add_child(minus)
	qty_label = _label("1", 22)
	qty_label.custom_minimum_size.x = 54
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_row.add_child(qty_label)
	var plus := _button("+", func(): _change_qty(1), "Soft")
	plus.custom_minimum_size = Vector2(52, 46)
	qty_row.add_child(plus)
	var mx := _button("Tối đa", _max_qty, "Soft")
	mx.custom_minimum_size = Vector2(80, 46)
	qty_row.add_child(mx)
	dv.add_child(qty_row)
	detail_total = _label("", 16)
	detail_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(detail_total)
	detail_action = _button("Mua", _on_detail_action, "Accent")
	dv.add_child(detail_action)
	detail_msg = _label("", 15)
	detail_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(detail_msg)
	det.add_child(dv)
	body.add_child(det)
	v.add_child(body)
	market_wrap = _modal_wrap(frame)


func open_market() -> void:
	market_tab = "buy"
	tab_buttons[0].button_pressed = true
	detail_msg.text = ""
	_open_modal(market_wrap, null)
	_rebuild_market("")


func _switch_tab(key: String) -> void:
	market_tab = key
	detail_msg.text = ""
	_rebuild_market("")


func _rebuild_market(keep_id: String) -> void:
	var st = main.state
	market_coin_label.text = str(st.coins)
	_clear(market_grid)
	var group := ButtonGroup.new()
	var entries: Array = []
	match market_tab:
		"buy":
			entries.append(["free", "free", GameData.FREE_SEED_ITEM, "Quà của chợ", "0", ""])
			for id in GameData.BUY_LIST:
				var n: int = st.count(id)
				entries.append(["buy", id, id, GameData.item_name(id), str(GameData.buy_price(id)), ("×%d" % n) if n > 0 else ""])
		"sell":
			var keys: Array = st.inventory.keys()
			keys.sort()
			for id in keys:
				if GameData.sell_price(id) > 0:
					entries.append(["sell", id, id, GameData.item_name(id), str(GameData.sell_price(id)), "×%d" % st.count(id)])
		"build":
			for b in GameData.BUILDING_ORDER:
				var bdef: Dictionary = GameData.BUILDINGS[b]
				entries.append(["build", b, b, bdef["name"], str(bdef["price"]), "Đã có" if st.buildings[b] else ""])
	if entries.is_empty():
		var empty := _label("Túi chưa có gì để bán.\nThu hoạch rồi quay lại nhé!", 17)
		market_grid.add_child(empty)
		_sel_kind = ""
		_sel_id = ""
		_update_detail()
		return
	var first: Button = null
	var target: Button = null
	for e in entries:
		var card := _card(e[2], e[3], e[4], e[5])
		card.button_group = group
		var kind: String = e[0]
		var id: String = e[1]
		card.set_meta("kind", kind)
		card.set_meta("id", id)
		card.pressed.connect(func(): _select(kind, id))
		card.focus_entered.connect(func():
			card.button_pressed = true
			_select(kind, id))
		market_grid.add_child(card)
		if first == null:
			first = card
		if id == keep_id:
			target = card
	if target == null:
		target = first
	target.button_pressed = true
	_select(target.get_meta("kind"), target.get_meta("id"))
	target.grab_focus()


func _select(kind: String, id: String) -> void:
	if kind != _sel_kind or id != _sel_id:
		_qty = 1
		detail_msg.text = ""
	_sel_kind = kind
	_sel_id = id
	_update_detail()


func _update_detail() -> void:
	var st = main.state
	detail_total.remove_theme_color_override("font_color")
	match _sel_kind:
		"buy", "sell":
			var is_buy := _sel_kind == "buy"
			var price := GameData.buy_price(_sel_id) if is_buy else GameData.sell_price(_sel_id)
			var have: int = st.count(_sel_id)
			_qty = maxi(1, _qty) if is_buy else clampi(_qty, 1, maxi(1, have))
			detail_icon.set_icon(_sel_id)
			detail_name.text = GameData.item_name(_sel_id)
			detail_desc.text = GameData.item_desc(_sel_id) + "\nĐang có: %d" % have
			detail_price.text = "Giá: %d xu / món" % price
			qty_row.visible = true
			qty_label.text = str(_qty)
			var total := price * _qty
			var after: int = st.coins - total if is_buy else st.coins + total
			detail_total.text = "Tổng %d xu → còn %d xu" % [total, after]
			if after < 0:
				detail_total.add_theme_color_override("font_color", BAD)
			detail_action.text = "Mua" if is_buy else "Bán"
			detail_action.disabled = false
		"free":
			var reason: String = GameRules.free_seed_block_reason(st)
			detail_icon.set_icon(GameData.FREE_SEED_ITEM)
			detail_name.text = "Quà của chợ"
			detail_desc.text = "Hết vốn? Chợ tặng 1 hạt cải để làm lại từ đầu. Hạt quà không bán lại được."
			detail_price.text = "Miễn phí"
			qty_row.visible = false
			detail_total.text = reason if reason != "" else "Bạn có thể nhận ngay."
			detail_action.text = "Nhận quà"
			detail_action.disabled = reason != ""
		"build":
			var bdef: Dictionary = GameData.BUILDINGS[_sel_id]
			var reason: String = GameRules.building_block_reason(st, _sel_id)
			detail_icon.set_icon(_sel_id)
			detail_name.text = bdef["name"]
			detail_desc.text = bdef["desc"]
			detail_price.text = "Giá: %d xu" % bdef["price"]
			qty_row.visible = false
			detail_total.text = reason if reason != "" else "Đủ điều kiện xây."
			detail_action.text = "Đã xây" if st.buildings[_sel_id] else "Xây"
			detail_action.disabled = reason != ""
		_:
			detail_icon.set_icon("")
			detail_name.text = ""
			detail_desc.text = ""
			detail_price.text = ""
			qty_row.visible = false
			detail_total.text = ""
			detail_action.disabled = true


func _change_qty(d: int) -> void:
	_qty = maxi(1, _qty + d)
	_update_detail()


func _max_qty() -> void:
	var st = main.state
	if _sel_kind == "buy":
		_qty = maxi(1, int(st.coins / maxi(1, GameData.buy_price(_sel_id))))
	elif _sel_kind == "sell":
		_qty = maxi(1, st.count(_sel_id))
	_update_detail()


func _on_detail_action() -> void:
	var r: Dictionary
	match _sel_kind:
		"buy":
			r = main.market_buy(_sel_id, _qty)
		"sell":
			r = main.market_sell(_sel_id, _qty)
		"free":
			r = main.claim_free_seed()
		"build":
			r = main.market_build(_sel_id)
		_:
			return
	if r["ok"]:
		_rebuild_market(_sel_id)
	detail_msg.text = r["msg"]
	detail_msg.add_theme_color_override("font_color", GOOD if r["ok"] else BAD)


# ======================= Túi đồ =======================

func _build_inventory() -> void:
	var frame := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	frame.add_child(v)
	v.add_child(_header("Túi đồ", null))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(530, 290)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_grid = GridContainer.new()
	inv_grid.columns = 4
	inv_grid.add_theme_constant_override("h_separation", 10)
	inv_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(inv_grid)
	body.add_child(scroll)
	var det := PanelContainer.new()
	det.theme_type_variation = "Inset"
	det.custom_minimum_size = Vector2(280, 290)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 8)
	inv_icon = ItemIcon.new("", 80.0)
	inv_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dv.add_child(inv_icon)
	inv_name = _title("", 22)
	inv_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(inv_name)
	inv_desc = _label("", 15)
	inv_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_desc.custom_minimum_size.x = 250
	dv.add_child(inv_desc)
	inv_use = _button("Cầm theo", _on_inv_use, "Accent")
	dv.add_child(inv_use)
	det.add_child(dv)
	body.add_child(det)
	v.add_child(body)
	inv_wrap = _modal_wrap(frame)


func open_inventory() -> void:
	_clear(inv_grid)
	var st = main.state
	var keys: Array = st.inventory.keys()
	keys.sort()
	var group := ButtonGroup.new()
	var first: Button = null
	for id in keys:
		var card := _card(id, GameData.item_name(id), "", "×%d" % st.count(id))
		card.button_group = group
		var item_id: String = id
		card.pressed.connect(func(): _inv_select(item_id))
		card.focus_entered.connect(func():
			card.button_pressed = true
			_inv_select(item_id))
		inv_grid.add_child(card)
		if first == null:
			first = card
	if first == null:
		inv_grid.add_child(_label("Túi trống.\nRa quầy chợ mua hạt giống nhé!", 17))
		_inv_select("")
		_open_modal(inv_wrap, null)
		return
	first.button_pressed = true
	_inv_select(str(keys[0]))
	_open_modal(inv_wrap, first)


func _on_inv_use() -> void:
	main.select_seed(_inv_sel)
	close_modal()


func _inv_select(id: String) -> void:
	_inv_sel = id
	inv_icon.set_icon(id)
	inv_name.text = GameData.item_name(id) if id != "" else ""
	var desc := GameData.item_desc(id)
	if GameData.sell_price(id) > 0:
		desc += "\nGiá bán: %d xu." % GameData.sell_price(id)
	inv_desc.text = desc
	inv_use.visible = GameData.SEED_TO_CROP.has(id)


# ======================= Cuối ngày / tạm dừng / menu =======================

func _build_summary() -> void:
	var frame := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	frame.add_child(v)
	var t := _title("Một ngày mới!", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	summary_label = _label("", 18)
	summary_label.custom_minimum_size = Vector2(480, 0)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(summary_label)
	summary_ok = _button("Bắt đầu ngày mới", close_modal, "Accent")
	summary_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary_ok.custom_minimum_size.x = 260
	v.add_child(summary_ok)
	summary_wrap = _modal_wrap(frame, 0.25)


func show_summary(text: String, day: int) -> void:
	summary_label.text = text
	summary_ok.text = "Bắt đầu ngày %d" % day
	_open_modal(summary_wrap, summary_ok)


func _build_pause() -> void:
	var frame := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(320, 0)
	frame.add_child(v)
	var t := _title("Tạm nghỉ", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	pause_first = _button("Chơi tiếp", close_modal, "Accent")
	v.add_child(pause_first)
	v.add_child(_button("Bật/tắt hướng dẫn", _on_toggle_tutorial, "Soft"))
	v.add_child(_button("Lưu ngay", _on_save_now, "Soft"))
	v.add_child(_button("Về màn hình chính", _on_back_to_menu, "Soft"))
	if not OS.has_feature("web"):
		v.add_child(_button("Thoát game", _on_quit, "Danger"))
	pause_wrap = _modal_wrap(frame)


func _on_toggle_tutorial() -> void:
	main.state.tutorial_closed = not main.state.tutorial_closed
	refresh()


func _on_save_now() -> void:
	main.save_now()


func _on_back_to_menu() -> void:
	close_modal()
	main.back_to_menu()


func _on_quit() -> void:
	main.quit_game()


func open_pause() -> void:
	_open_modal(pause_wrap, pause_first)


func _build_menu() -> void:
	var frame := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(420, 0)
	frame.add_child(v)
	var logo = ItemIcon.new("farmer", 96.0)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(logo)
	var title := _title("Mùa Về Bên Ao", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := _label("Bản chơi thử %s · nông trại làng quê" % GameData.GAME_VERSION, 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	menu_continue = _button("Chơi tiếp", _on_continue, "Accent")
	v.add_child(menu_continue)
	menu_new = _button("Chơi mới", _on_new_game)
	v.add_child(menu_new)
	if not OS.has_feature("web"):
		v.add_child(_button("Thoát", _on_quit, "Soft"))
	menu_error = _label("", 15)
	menu_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_error.add_theme_color_override("font_color", BAD)
	v.add_child(menu_error)
	menu_wrap = _modal_wrap(frame, 0.3)


func _build_confirm() -> void:
	var frame := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(440, 0)
	frame.add_child(v)
	v.add_child(_title("Chơi lại từ đầu?", 28))
	var l := _label("Bạn đang có một nông trại đã lưu. Chơi mới sẽ xoá toàn bộ tiến độ đó.", 17)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	confirm_no = _button("Giữ lại", _on_confirm_no, "Soft")
	confirm_no.custom_minimum_size.x = 150
	row.add_child(confirm_no)
	var yes := _button("Chơi mới", _on_confirm_yes, "Danger")
	yes.custom_minimum_size.x = 150
	row.add_child(yes)
	v.add_child(row)
	confirm_wrap = _modal_wrap(frame, 0.3)


func _on_confirm_no() -> void:
	confirm_wrap.visible = false
	menu_new.grab_focus()


func _on_confirm_yes() -> void:
	confirm_wrap.visible = false
	main.new_game()


func show_main_menu(has_save: bool) -> void:
	close_modal()
	confirm_wrap.visible = false
	hud.visible = false
	menu_error.text = ""
	menu_continue.disabled = not has_save
	menu_wrap.visible = true
	if has_save:
		menu_continue.grab_focus()
	else:
		menu_new.grab_focus()


func enter_game() -> void:
	menu_wrap.visible = false
	confirm_wrap.visible = false
	hud.visible = true
	refresh()


func _on_new_game() -> void:
	if main.saver.has_save():
		confirm_wrap.visible = true
		confirm_no.grab_focus()
	else:
		main.new_game()


func _on_continue() -> void:
	var err: String = main.continue_game()
	if err != "":
		menu_error.text = err
