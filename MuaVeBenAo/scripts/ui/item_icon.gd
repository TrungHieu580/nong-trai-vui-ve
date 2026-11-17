extends Control
## Biểu tượng vẽ bằng code: vật phẩm, đồng xu, ảnh đại diện, công trình.
## Muốn đẹp hơn có thể thay bằng ảnh PNG mà không đổi chỗ gọi.

const OUT := Color("5a3a1e")

var icon_id := ""
var _s := 1.0
var _o := Vector2.ZERO


func _init(id: String = "", px: float = 64.0) -> void:
	icon_id = id
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_icon(id: String) -> void:
	icon_id = id
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	_s = side
	_o = (size - Vector2(side, side)) * 0.5
	match icon_id:
		"coin":
			_coin()
		"seed_leafy_greens":
			_packet("leafy")
		"seed_leafy_greens_gift":
			_packet("gift")
		"seed_carrot":
			_packet("carrot")
		"produce_leafy_greens":
			_cabbage()
		"produce_carrot":
			_carrot()
		"egg":
			_egg()
		"milk":
			_milk()
		"fish_ro":
			_fish(0.5, 0.52, 1.0, Color("e0973a"))
		"fish_fry":
			_fry()
		"feed_chicken":
			_sack(Color("f2c94c"))
		"feed_fish":
			_sack(Color("5bb4e5"))
		"feed_cow":
			_hay()
		"farmer":
			_farmer()
		"coop":
			_coop()
		"pond":
			_pond()
		"barn":
			_barn()
		"bag":
			_bag()
		"menu":
			_menu()


# ---------- primitives (toạ độ đơn vị 0..1) ----------

func _p(x: float, y: float) -> Vector2:
	return _o + Vector2(x, y) * _s


func _circle(x: float, y: float, r: float, c: Color) -> void:
	draw_circle(_p(x, y), r * _s, c)


func _ellipse(x: float, y: float, rx: float, ry: float, c: Color, rot: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		var v := Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)
		pts.append(_p(x + v.x, y + v.y))
	draw_colored_polygon(pts, c)


func _poly(points: Array, c: Color) -> void:
	var pts := PackedVector2Array()
	for v in points:
		pts.append(_p(v.x, v.y))
	draw_colored_polygon(pts, c)


func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(_p(x, y), Vector2(w, h) * _s), c)


func _line(x1: float, y1: float, x2: float, y2: float, c: Color, w: float) -> void:
	draw_line(_p(x1, y1), _p(x2, y2), c, maxf(1.0, w * _s), true)


# ---------- icons ----------

func _coin() -> void:
	_circle(0.5, 0.5, 0.44, Color("9a6a10"))
	_circle(0.5, 0.5, 0.39, Color("ffd23f"))
	_circle(0.5, 0.5, 0.27, Color("f2b705"))
	_rect(0.46, 0.33, 0.08, 0.34, Color("ffe98a"))
	_ellipse(0.37, 0.34, 0.08, 0.05, Color("fff6c4"), -0.6)


func _packet(mark: String) -> void:
	_poly([Vector2(0.18, 0.1), Vector2(0.82, 0.1), Vector2(0.86, 0.92), Vector2(0.14, 0.92)], OUT)
	_poly([Vector2(0.22, 0.14), Vector2(0.78, 0.14), Vector2(0.81, 0.88), Vector2(0.19, 0.88)], Color("f7e6bf"))
	_rect(0.22, 0.14, 0.56, 0.13, Color("d9a35e"))
	match mark:
		"carrot":
			_poly([Vector2(0.37, 0.47), Vector2(0.63, 0.47), Vector2(0.5, 0.82)], Color("f08a24"))
			_line(0.5, 0.47, 0.42, 0.34, Color("3f8a2c"), 0.05)
			_line(0.5, 0.47, 0.5, 0.32, Color("4caf50"), 0.05)
			_line(0.5, 0.47, 0.58, 0.34, Color("3f8a2c"), 0.05)
		_:
			_circle(0.5, 0.6, 0.19, Color("3f8a2c"))
			_circle(0.5, 0.6, 0.15, Color("63b443"))
			_circle(0.46, 0.56, 0.07, Color("9be07f"))
			if mark == "gift":
				_rect(0.46, 0.14, 0.08, 0.74, Color("e2574c"))
				_circle(0.43, 0.2, 0.06, Color("e2574c"))
				_circle(0.57, 0.2, 0.06, Color("e2574c"))


func _cabbage() -> void:
	_circle(0.5, 0.55, 0.38, Color("2f6e22"))
	_circle(0.5, 0.55, 0.34, Color("4caf50"))
	_ellipse(0.32, 0.5, 0.16, 0.24, Color("63b443"), 0.4)
	_ellipse(0.68, 0.5, 0.16, 0.24, Color("63b443"), -0.4)
	_circle(0.5, 0.55, 0.18, Color("9be07f"))
	_line(0.5, 0.4, 0.5, 0.72, Color("d7f5c8"), 0.03)


func _carrot() -> void:
	_poly([Vector2(0.26, 0.3), Vector2(0.48, 0.2), Vector2(0.84, 0.86)], OUT)
	_poly([Vector2(0.3, 0.31), Vector2(0.47, 0.24), Vector2(0.8, 0.82)], Color("f08a24"))
	_line(0.4, 0.38, 0.47, 0.35, Color("c96614"), 0.025)
	_line(0.52, 0.52, 0.58, 0.49, Color("c96614"), 0.025)
	_line(0.36, 0.26, 0.2, 0.08, Color("3f8a2c"), 0.06)
	_line(0.38, 0.25, 0.32, 0.05, Color("4caf50"), 0.06)
	_line(0.4, 0.26, 0.46, 0.08, Color("3f8a2c"), 0.06)


func _egg() -> void:
	_ellipse(0.5, 0.55, 0.31, 0.39, Color("b5a07a"))
	_ellipse(0.5, 0.55, 0.27, 0.35, Color("fff8ea"))
	_ellipse(0.41, 0.42, 0.07, 0.1, Color("ffffff"), 0.3)


func _milk() -> void:
	_rect(0.24, 0.32, 0.52, 0.6, OUT)
	_rect(0.28, 0.36, 0.44, 0.52, Color("fafafa"))
	_rect(0.36, 0.14, 0.28, 0.22, OUT)
	_rect(0.4, 0.18, 0.2, 0.2, Color("fafafa"))
	_rect(0.36, 0.08, 0.28, 0.09, Color("4f8fbf"))
	_rect(0.28, 0.52, 0.44, 0.2, Color("8fc8ee"))
	_circle(0.5, 0.62, 0.06, Color("ffffff"))


func _fish(cx: float, cy: float, k: float, c: Color) -> void:
	_poly([Vector2(cx + 0.18 * k, cy), Vector2(cx + 0.42 * k, cy - 0.17 * k), Vector2(cx + 0.42 * k, cy + 0.17 * k)], OUT)
	_poly([Vector2(cx + 0.2 * k, cy), Vector2(cx + 0.39 * k, cy - 0.13 * k), Vector2(cx + 0.39 * k, cy + 0.13 * k)], c)
	_ellipse(cx - 0.05 * k, cy, 0.3 * k, 0.17 * k, OUT)
	_ellipse(cx - 0.05 * k, cy, 0.27 * k, 0.14 * k, c)
	_ellipse(cx - 0.08 * k, cy + 0.05 * k, 0.18 * k, 0.06 * k, Color(1, 1, 1, 0.35))
	_circle(cx - 0.2 * k, cy - 0.03 * k, 0.035 * k, Color("2b2b2b"))


func _fry() -> void:
	_ellipse(0.5, 0.58, 0.36, 0.33, Color("5aa6cf"))
	_ellipse(0.5, 0.58, 0.32, 0.29, Color("bfe6fa"))
	_fish(0.43, 0.55, 0.45, Color("f2a93b"))
	_fish(0.58, 0.68, 0.38, Color("f2a93b"))
	_poly([Vector2(0.4, 0.18), Vector2(0.6, 0.18), Vector2(0.55, 0.3), Vector2(0.45, 0.3)], Color("bfe6fa"))
	_rect(0.42, 0.27, 0.16, 0.05, Color("e2574c"))


func _sack(mark: Color) -> void:
	_poly([Vector2(0.3, 0.22), Vector2(0.7, 0.22), Vector2(0.84, 0.9), Vector2(0.16, 0.9)], OUT)
	_poly([Vector2(0.33, 0.26), Vector2(0.67, 0.26), Vector2(0.8, 0.86), Vector2(0.2, 0.86)], Color("d8b07a"))
	_poly([Vector2(0.36, 0.1), Vector2(0.64, 0.1), Vector2(0.6, 0.26), Vector2(0.4, 0.26)], Color("c69c6d"))
	_rect(0.36, 0.24, 0.28, 0.05, Color("8a5a2b"))
	_circle(0.5, 0.6, 0.15, mark)
	for d in [Vector2(0.44, 0.56), Vector2(0.55, 0.58), Vector2(0.49, 0.66)]:
		_circle(d.x, d.y, 0.03, mark.darkened(0.35))


func _hay() -> void:
	_rect(0.12, 0.3, 0.76, 0.5, Color("9a7a2e"))
	_rect(0.15, 0.33, 0.7, 0.44, Color("e8c872"))
	for i in 6:
		var x := 0.2 + i * 0.12
		_line(x, 0.36, x + 0.04, 0.74, Color("caa54e"), 0.02)
	_rect(0.3, 0.3, 0.06, 0.5, Color("c0533a"))
	_rect(0.64, 0.3, 0.06, 0.5, Color("c0533a"))


func _farmer() -> void:
	_circle(0.5, 0.58, 0.3, Color("c98f62"))
	_circle(0.5, 0.58, 0.27, Color("f6d2b0"))
	_circle(0.4, 0.6, 0.035, Color("2b2b2b"))
	_circle(0.6, 0.6, 0.035, Color("2b2b2b"))
	_ellipse(0.33, 0.68, 0.05, 0.03, Color("f2a0a0"))
	_ellipse(0.67, 0.68, 0.05, 0.03, Color("f2a0a0"))
	_line(0.45, 0.72, 0.55, 0.72, Color("a0523a"), 0.025)
	_poly([Vector2(0.5, 0.04), Vector2(0.96, 0.42), Vector2(0.04, 0.42)], Color("a8862e"))
	_poly([Vector2(0.5, 0.08), Vector2(0.9, 0.4), Vector2(0.1, 0.4)], Color("e8c872"))
	_line(0.3, 0.3, 0.7, 0.3, Color("caa54e"), 0.02)


func _coop() -> void:
	_rect(0.2, 0.42, 0.6, 0.46, OUT)
	_rect(0.23, 0.45, 0.54, 0.4, Color("b07a45"))
	_poly([Vector2(0.5, 0.1), Vector2(0.92, 0.46), Vector2(0.08, 0.46)], Color("a8862e"))
	_poly([Vector2(0.5, 0.15), Vector2(0.85, 0.44), Vector2(0.15, 0.44)], Color("e8c872"))
	_rect(0.42, 0.6, 0.16, 0.25, Color("6e4421"))
	_circle(0.75, 0.82, 0.12, Color("fbfaf5"))
	_rect(0.73, 0.66, 0.04, 0.06, Color("e2574c"))


func _pond() -> void:
	_ellipse(0.5, 0.58, 0.44, 0.3, Color("b59a6a"))
	_ellipse(0.5, 0.58, 0.38, 0.24, Color("4fa3d9"))
	_ellipse(0.42, 0.52, 0.16, 0.06, Color("8fd0f2"))
	_circle(0.66, 0.64, 0.08, Color("4caf50"))
	_circle(0.68, 0.62, 0.03, Color("f4b6c2"))
	_line(0.16, 0.5, 0.12, 0.18, Color("4f8a2c"), 0.04)
	_line(0.2, 0.5, 0.22, 0.14, Color("63b443"), 0.04)


func _barn() -> void:
	_rect(0.14, 0.38, 0.72, 0.52, OUT)
	_rect(0.17, 0.41, 0.66, 0.46, Color("c0533a"))
	_poly([Vector2(0.5, 0.08), Vector2(0.94, 0.42), Vector2(0.06, 0.42)], OUT)
	_poly([Vector2(0.5, 0.13), Vector2(0.86, 0.4), Vector2(0.14, 0.4)], Color("9b3a2a"))
	_rect(0.36, 0.56, 0.28, 0.31, Color("f5efe0"))
	_line(0.36, 0.56, 0.64, 0.87, Color("c0533a"), 0.04)
	_line(0.64, 0.56, 0.36, 0.87, Color("c0533a"), 0.04)


func _bag() -> void:
	_ellipse(0.5, 0.6, 0.36, 0.3, OUT)
	_ellipse(0.5, 0.6, 0.32, 0.26, Color("c9a46a"))
	_line(0.3, 0.42, 0.42, 0.12, Color("8a5a2b"), 0.06)
	_line(0.7, 0.42, 0.58, 0.12, Color("8a5a2b"), 0.06)
	_rect(0.36, 0.5, 0.28, 0.12, Color("a87f45"))
	_circle(0.5, 0.56, 0.04, Color("f2b705"))


func _menu() -> void:
	for y in [0.3, 0.5, 0.7]:
		_line(0.22, y, 0.78, y, Color("fff6e0"), 0.09)
