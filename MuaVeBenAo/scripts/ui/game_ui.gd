extends CanvasLayer
## Toàn bộ giao diện: HUD, lời nhắc, hướng dẫn, chợ, túi đồ, tóm tắt cuối ngày,
## tạm dừng và menu chính. Dựng bằng code để dễ đọc và dễ sửa.

const GameData = preload("res://scripts/sim/game_data.gd")
const GameRules = preload("res://scripts/sim/game_rules.gd")

const TEXT := Color("4a3524")
const GOOD := Color("2f7d32")
const BAD := Color("c0392b")

var main
var root: Control
var hud: Control
var day_label: Label
var held_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var toast_label: Label
var _toast_tween: Tween
var tutorial_panel: PanelContainer
var tutorial_label: Label
var fade: ColorRect

var market_wrap: Control
var market_tabs: TabContainer
var market_coins: Label
var market_status: Label
var buy_list: VBoxContainer
var sell_list: VBoxContainer
var build_list: VBoxContainer
var _row_buttons := {}

var inv_wrap: Control
var inv_grid: GridContainer
var inv_desc: Label

var summary_wrap: Control
var summary_label: Label
var summary_ok: Button

var pause_wrap: Control
var pause_first: Button

var menu_wrap: Control
var menu_new: Button
var menu_continue: Button
var menu_error: Label
var confirm: ConfirmationDialog

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
	fade = ColorRect.new()
	fade.color = Color(0.05, 0.04, 0.1, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)


# ================= Theme =================

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("fff6e0")
	panel.set_corner_radius_all(14)
	panel.set_border_width_all(3)
	panel.border_color = Color("c9a46a")
	panel.set_content_margin_all(14)
	t.set_stylebox("panel", "PanelContainer", panel)
	var tab_panel := StyleBoxFlat.new()
	tab_panel.bg_color = Color("fbecc8")
	tab_panel.set_corner_radius_all(8)
	tab_panel.set_content_margin_all(10)
	t.set_stylebox("panel", "TabContainer", tab_panel)
	t.set_stylebox("tab_selected", "TabContainer", _flat(Color("6aa84f"), 8))
	t.set_stylebox("tab_unselected", "TabContainer", _flat(Color("c9a46a"), 8))
	t.set_stylebox("tab_hovered", "TabContainer", _flat(Color("8cc152"), 8))
	t.set_stylebox("tab_focus", "TabContainer", _focus_box())
	for c in ["font_selected_color", "font_unselected_color", "font_hovered_color"]:
		t.set_color(c, "TabContainer", Color.WHITE)
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("normal", "Button", _flat(Color("6aa84f"), 10))
	t.set_stylebox("hover", "Button", _flat(Color("82c065"), 10))
	t.set_stylebox("pressed", "Button", _flat(Color("4f8a37"), 10))
	t.set_stylebox("disabled", "Button", _flat(Color("b9b0a0"), 10))
	t.set_stylebox("focus", "Button", _focus_box())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.75))
	return t


func _flat(c: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _focus_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.set_border_width_all(3)
	s.border_color = Color("f2b705")
	s.set_corner_radius_all(10)
	s.set_expand_margin_all(2)
	return s


# ================= Helpers =================

func _label(text: String, size: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


func _outlined(l: Label) -> Label:
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	return l


func _clear(c: Node) -> void:
	for child in c.get_children():
		c.remove_child(child)
		child.queue_free()


## Khung hộp thoại giữa màn hình với nền tối mờ.
func _modal_wrap(panel: Control, dim_alpha: float = 0.45) -> Control:
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.05, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(center)
	center.add_child(panel)
	root.add_child(wrap)
	return wrap


# ================= HUD =================

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)

	var top := PanelContainer.new()
	top.position = Vector2(16, 16)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tv := VBoxContainer.new()
	day_label = _label("", 22)
	held_label = _label("")
	tv.add_child(day_label)
	tv.add_child(held_label)
	top.add_child(tv)
	hud.add_child(top)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tutorial_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tutorial_panel.offset_left = -16
	tutorial_panel.offset_right = -16
	tutorial_panel.offset_top = 16
	tutorial_panel.custom_minimum_size = Vector2(380, 0)
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_label = _label("")
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_panel.add_child(tutorial_label)
	hud.add_child(tutorial_panel)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
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
	prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label = _label("", 20)
	prompt_panel.add_child(prompt_label)
	bottom.add_child(prompt_panel)

	var hint := _outlined(_label("WASD di chuyển · E tương tác · 1/2 chọn hạt · Tab túi đồ · H hướng dẫn · Esc tạm dừng", 15))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(hint)
	hud.visible = false


func refresh() -> void:
	if main == null:
		return
	var st = main.state
	day_label.text = "Ngày %d   ·   %d xu" % [st.day, st.coins]
	held_label.text = "Đang cầm: %s   (1: Hạt cải · 2: Hạt cà rốt)" % main.held_text()
	if st.tutorial_closed:
		tutorial_panel.visible = false
	else:
		tutorial_panel.visible = true
		if st.tutorial_step < GameData.TUTORIAL.size():
			tutorial_label.text = "Hướng dẫn %d/%d\n%s\n\n[H] Ẩn hướng dẫn" % [
				st.tutorial_step + 1, GameData.TUTORIAL.size(), GameData.TUTORIAL[st.tutorial_step]["text"]]
		else:
			tutorial_label.text = GameData.TUTORIAL_DONE_TEXT + "\n\n[H] Ẩn hướng dẫn"


func set_prompt(text: String) -> void:
	prompt_panel.visible = text != ""
	if prompt_label.text != text:
		prompt_label.text = text


func toast(text: String, good: bool = true) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", Color("e9ffd9") if good else Color("ffd2c9"))
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


# ================= Modal chung =================

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


# ================= Chợ =================

func _build_market() -> void:
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var title := _label("Quầy chợ làng", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	market_coins = _label("", 22)
	head.add_child(market_coins)
	v.add_child(head)

	market_tabs = TabContainer.new()
	market_tabs.custom_minimum_size = Vector2(960, 380)
	v.add_child(market_tabs)
	buy_list = _tab_list("Mua")
	sell_list = _tab_list("Bán")
	build_list = _tab_list("Công trình")
	market_tabs.tab_changed.connect(func(_i): _focus_first_in_tab())

	market_status = _label("")
	market_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(market_status)
	var close := _button("Đóng (Esc)", close_modal)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(close)
	market_wrap = _modal_wrap(panel)


func _tab_list(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_tabs.add_child(scroll)
	market_tabs.set_tab_title(market_tabs.get_tab_count() - 1, title)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


func open_market() -> void:
	market_status.text = "Dùng Tab/mũi tên để chọn, Enter để xác nhận. Đổi tab bằng Ctrl+Tab."
	market_status.add_theme_color_override("font_color", TEXT)
	_open_modal(market_wrap, null)
	_refresh_market("")


func _refresh_market(focus_key: String) -> void:
	var st = main.state
	market_coins.text = "Số dư: %d xu" % st.coins
	_row_buttons.clear()

	_clear(buy_list)
	var reason: String = GameRules.free_seed_block_reason(st)
	var free_row := HBoxContainer.new()
	var free_btn := _button("Nhận 1 hạt cải miễn phí", func(): _after_trade("free", main.claim_free_seed(), null))
	free_btn.disabled = reason != ""
	free_row.add_child(free_btn)
	var free_note := _label("  " + (reason if reason != "" else "Dành cho lúc hết vốn – hạt quà không bán lại được."))
	free_note.add_theme_font_size_override("font_size", 15)
	free_row.add_child(free_note)
	buy_list.add_child(free_row)
	_row_buttons["free"] = free_btn
	for item_id in GameData.BUY_LIST:
		buy_list.add_child(_trade_row(item_id, true))

	_clear(sell_list)
	var keys: Array = st.inventory.keys()
	keys.sort()
	var any := false
	for item_id in keys:
		if GameData.sell_price(item_id) > 0:
			sell_list.add_child(_trade_row(item_id, false))
			any = true
	if not any:
		sell_list.add_child(_label("Túi chưa có gì để bán."))

	_clear(build_list)
	for b in GameData.BUILDING_ORDER:
		build_list.add_child(_building_row(b))

	if focus_key != "" and _row_buttons.has(focus_key):
		var btn: Button = _row_buttons[focus_key]
		if btn.is_visible_in_tree():
			btn.grab_focus()
			return
	_focus_first_in_tab()


func _focus_first_in_tab() -> void:
	var lists := [buy_list, sell_list, build_list]
	var list: Node = lists[market_tabs.current_tab]
	var first := _find_focusable(list)
	if first:
		first.grab_focus()
	else:
		market_tabs.get_tab_bar().grab_focus()


func _find_focusable(n: Node) -> Control:
	for c in n.get_children():
		if c is Button and c.focus_mode != Control.FOCUS_NONE:
			return c
		var deeper := _find_focusable(c)
		if deeper:
			return deeper
	return null


func _trade_row(item_id: String, is_buy: bool) -> HBoxContainer:
	var st = main.state
	var price := GameData.buy_price(item_id) if is_buy else GameData.sell_price(item_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_l := _label(GameData.item_name(item_id))
	name_l.custom_minimum_size.x = 170
	name_l.tooltip_text = GameData.item_desc(item_id)
	name_l.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name_l)
	var price_l := _label("%d xu" % price)
	price_l.custom_minimum_size.x = 70
	row.add_child(price_l)
	var have_l := _label("Có: %d" % st.count(item_id))
	have_l.custom_minimum_size.x = 80
	row.add_child(have_l)
	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = 999 if is_buy else maxi(1, st.count(item_id))
	qty.value = 1
	qty.rounded = true
	qty.custom_minimum_size.x = 110
	row.add_child(qty)
	var total_l := _label("")
	total_l.custom_minimum_size.x = 300
	row.add_child(total_l)
	var update := func():
		var n := int(qty.value)
		var sum := n * price
		var after: int = st.coins - sum if is_buy else st.coins + sum
		total_l.text = "Tổng %d xu → số dư %d xu" % [sum, after]
		total_l.add_theme_color_override("font_color", BAD if after < 0 else TEXT)
	qty.value_changed.connect(func(_v): update.call())
	update.call()
	var key := ("buy:" if is_buy else "sell:") + item_id
	var btn := _button("Mua" if is_buy else "Bán", func():
		var r: Dictionary = main.market_buy(item_id, int(qty.value)) if is_buy else main.market_sell(item_id, int(qty.value))
		_after_trade(key, r, total_l))
	btn.custom_minimum_size.x = 80
	row.add_child(btn)
	_row_buttons[key] = btn
	return row


func _building_row(building_id: String) -> HBoxContainer:
	var st = main.state
	var def: Dictionary = GameData.BUILDINGS[building_id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_l := _label(def["name"])
	name_l.custom_minimum_size.x = 140
	row.add_child(name_l)
	var price_l := _label("%d xu" % def["price"])
	price_l.custom_minimum_size.x = 80
	row.add_child(price_l)
	var reason: String = GameRules.building_block_reason(st, building_id)
	var note := _label(def["desc"] + ("" if reason == "" else "  (" + reason + ")"))
	note.custom_minimum_size.x = 520
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(note)
	var owned: bool = st.buildings[building_id]
	var key := "build:" + building_id
	var btn := _button("Đã có" if owned else "Mua", func(): _after_trade(key, main.market_build(building_id), note))
	btn.disabled = reason != ""
	btn.custom_minimum_size.x = 90
	row.add_child(btn)
	_row_buttons[key] = btn
	return row


func _after_trade(key: String, r: Dictionary, row_label: Label) -> void:
	market_status.text = r["msg"]
	market_status.add_theme_color_override("font_color", GOOD if r["ok"] else BAD)
	if r["ok"]:
		_refresh_market(key)
	elif row_label:
		row_label.text = r["msg"]
		row_label.add_theme_color_override("font_color", BAD)


# ================= Túi đồ =================

func _build_inventory() -> void:
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(_label("Túi đồ", 26))
	inv_grid = GridContainer.new()
	inv_grid.columns = 4
	inv_grid.add_theme_constant_override("h_separation", 10)
	inv_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(inv_grid)
	inv_desc = _label("")
	inv_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_desc.custom_minimum_size = Vector2(640, 60)
	v.add_child(inv_desc)
	v.add_child(_label("Chọn hạt giống để cầm theo. Esc hoặc Tab để đóng.", 15))
	inv_wrap = _modal_wrap(panel)


func open_inventory() -> void:
	_clear(inv_grid)
	var st = main.state
	var keys: Array = st.inventory.keys()
	keys.sort()
	var first: Button = null
	for item_id in keys:
		var b := Button.new()
		b.text = "%s\n×%d" % [GameData.item_name(item_id), st.count(item_id)]
		b.custom_minimum_size = Vector2(150, 70)
		var desc := "%s – %s" % [GameData.item_name(item_id), GameData.item_desc(item_id)]
		if GameData.sell_price(item_id) > 0:
			desc += " Giá bán: %d xu." % GameData.sell_price(item_id)
		b.focus_entered.connect(func(): inv_desc.text = desc)
		b.mouse_entered.connect(func(): inv_desc.text = desc)
		var id: String = item_id
		b.pressed.connect(func():
			if GameData.SEED_TO_CROP.has(id):
				main.select_seed(id)
				close_modal())
		inv_grid.add_child(b)
		if first == null:
			first = b
	if keys.is_empty():
		inv_desc.text = "Túi trống. Ra quầy chợ để mua hạt giống."
	else:
		inv_desc.text = ""
	_open_modal(inv_wrap, first)


# ================= Tóm tắt cuối ngày =================

func _build_summary() -> void:
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(_label("Một ngày mới!", 28))
	summary_label = _label("")
	summary_label.custom_minimum_size = Vector2(520, 0)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(summary_label)
	summary_ok = _button("Bắt đầu ngày mới", close_modal)
	summary_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(summary_ok)
	summary_wrap = _modal_wrap(panel, 0.3)


func show_summary(text: String, day: int) -> void:
	summary_label.text = text
	summary_ok.text = "Bắt đầu ngày %d" % day
	_open_modal(summary_wrap, summary_ok)


# ================= Tạm dừng =================

func _build_pause() -> void:
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(320, 0)
	panel.add_child(v)
	var t := _label("Tạm dừng", 28)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	pause_first = _button("Tiếp tục", close_modal)
	v.add_child(pause_first)
	v.add_child(_button("Lưu ngay", func(): main.save_now()))
	v.add_child(_button("Về menu chính", func():
		close_modal()
		main.back_to_menu()))
	if not OS.has_feature("web"):
		v.add_child(_button("Thoát game", func(): main.quit_game()))
	pause_wrap = _modal_wrap(panel)


func open_pause() -> void:
	_open_modal(pause_wrap, pause_first)


# ================= Menu chính =================

func _build_menu() -> void:
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(440, 0)
	panel.add_child(v)
	var title := _label("Mùa Về Bên Ao", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := _label("Bản chơi thử %s – nông trại làng quê" % GameData.GAME_VERSION, 18)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	menu_continue = _button("Tiếp tục", _on_continue)
	v.add_child(menu_continue)
	menu_new = _button("Chơi mới", _on_new_game)
	v.add_child(menu_new)
	if not OS.has_feature("web"):
		v.add_child(_button("Thoát", func(): main.quit_game()))
	menu_error = _label("")
	menu_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_error.add_theme_color_override("font_color", BAD)
	v.add_child(menu_error)
	var help := _label("WASD di chuyển · E tương tác · Tab túi đồ · Esc tạm dừng", 15)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(help)
	menu_wrap = _modal_wrap(panel, 0.55)

	confirm = ConfirmationDialog.new()
	confirm.title = "Xác nhận"
	confirm.dialog_text = "Đã có bản lưu. Chơi mới sẽ ghi đè toàn bộ tiến độ hiện tại.\nBạn có chắc không?"
	confirm.ok_button_text = "Ghi đè và chơi mới"
	confirm.cancel_button_text = "Huỷ"
	confirm.confirmed.connect(func(): main.new_game())
	add_child(confirm)


func show_main_menu(has_save: bool) -> void:
	close_modal()
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
	hud.visible = true
	refresh()


func _on_new_game() -> void:
	if main.saver.has_save():
		confirm.popup_centered()
	else:
		main.new_game()


func _on_continue() -> void:
	var err: String = main.continue_game()
	if err != "":
		menu_error.text = err
