extends RefCounted
## Mô hình TẠM dựng từ khối cơ bản của Godot, đủ để chơi thử vòng lặp.
## Mốc Tuần 4: thay từng hàm build_* bằng cảnh .glb xuất từ Blender
## (hoặc gói CC0 như Quaternius/Kenney) mà không phải sửa logic game.

const GRASS := Color("8cc152")
const PATH := Color("dcc89c")
const SOIL_DRY := Color("a8774f")
const SOIL_WET := Color("6b4630")
const LEAF := Color("63b443")
const LEAF_DARK := Color("3f8a2c")
const CARROT := Color("f08a24")
const STRAW := Color("e8c872")
const WOOD := Color("9c6b3f")
const WOOD_DARK := Color("6e4a2b")
const ROOF := Color("c0533a")
const WALL := Color("f3e3c3")
const WATER := Color("4fa3d9")
const WHITE := Color("fbfaf5")
const DARK := Color("2b2b2b")
const SKIN := Color("f6d2b0")
const SHIRT := Color("4f8fbf")
const PANTS := Color("3a5a78")
const BOOT := Color("3d3d3d")
const BAG := Color("c9a46a")
const PINK := Color("f4b6b6")
const RED := Color("e2574c")
const ORANGE := Color("f2a93b")

const COLOR_NEED := Color("ff8a7a")
const COLOR_READY := Color("ffd23f")
const COLOR_INFO := Color("ffffff")

static var _mats := {}


static func mat(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		_mats[key] = m
	return _mats[key]


static func mesh(m: Mesh, c: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat(c)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	return mi


static func box(size: Vector3, c: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return mesh(m, c, pos, rot)


static func sphere(r: float, c: Color, pos: Vector3, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 18
	m.rings = 10
	return mesh(m, c, pos, Vector3.ZERO, scl)


static func cyl(top: float, bottom: float, h: float, c: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 18
	return mesh(m, c, pos, rot)


static func capsule(r: float, h: float, c: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	return mesh(m, c, pos, rot)


static func prism(size: Vector3, c: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := PrismMesh.new()
	m.size = size
	return mesh(m, c, pos, rot)


static func label(text: String, pos: Vector3, font_px: int = 40) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = font_px
	l.outline_size = 14
	l.pixel_size = 0.006
	l.modulate = COLOR_INFO
	l.outline_modulate = Color(0.1, 0.07, 0.05, 0.85)
	return l


# ================= Nhân vật =================

## Mặt nhân vật hướng về +Z.
static func build_farmer() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(0.17, 0.2, 0.26), BOOT, Vector3(-0.12, 0.1, 0.03)))
	r.add_child(box(Vector3(0.17, 0.2, 0.26), BOOT, Vector3(0.12, 0.1, 0.03)))
	r.add_child(cyl(0.2, 0.23, 0.3, PANTS, Vector3(0, 0.34, 0)))
	r.add_child(cyl(0.21, 0.29, 0.42, SHIRT, Vector3(0, 0.68, 0)))
	r.add_child(capsule(0.08, 0.42, SHIRT, Vector3(-0.31, 0.7, 0), Vector3(0, 0, 14)))
	r.add_child(capsule(0.08, 0.42, SHIRT, Vector3(0.31, 0.7, 0), Vector3(0, 0, -14)))
	r.add_child(sphere(0.08, SKIN, Vector3(-0.36, 0.48, 0)))
	r.add_child(sphere(0.08, SKIN, Vector3(0.36, 0.48, 0)))
	# Túi vải đeo chéo
	r.add_child(box(Vector3(0.05, 0.5, 0.04), BAG, Vector3(0, 0.72, 0.24), Vector3(0, 0, 40)))
	r.add_child(box(Vector3(0.26, 0.24, 0.12), BAG, Vector3(0.27, 0.52, 0.12)))
	# Đầu to
	r.add_child(sphere(0.36, SKIN, Vector3(0, 1.17, 0)))
	r.add_child(sphere(0.055, DARK, Vector3(-0.13, 1.2, 0.31)))
	r.add_child(sphere(0.055, DARK, Vector3(0.13, 1.2, 0.31)))
	r.add_child(sphere(0.06, PINK, Vector3(-0.21, 1.09, 0.27), Vector3(1, 0.6, 0.5)))
	r.add_child(sphere(0.06, PINK, Vector3(0.21, 1.09, 0.27), Vector3(1, 0.6, 0.5)))
	r.add_child(box(Vector3(0.1, 0.025, 0.02), Color("a0523a"), Vector3(0, 1.06, 0.345)))
	# Nón lá
	r.add_child(cyl(0.02, 0.64, 0.34, STRAW, Vector3(0, 1.58, 0)))
	r.add_child(cyl(0.6, 0.6, 0.02, Color("d9b45a"), Vector3(0, 1.43, 0)))
	return r


static func build_chicken() -> Node3D:
	var r := Node3D.new()
	r.add_child(sphere(0.26, WHITE, Vector3(0, 0.33, 0), Vector3(1, 0.9, 1.15)))
	r.add_child(box(Vector3(0.2, 0.22, 0.08), WHITE, Vector3(0, 0.45, -0.28), Vector3(-30, 0, 0)))
	r.add_child(sphere(0.16, WHITE, Vector3(0, 0.57, 0.18)))
	r.add_child(box(Vector3(0.05, 0.1, 0.14), RED, Vector3(0, 0.75, 0.18)))
	r.add_child(cyl(0.0, 0.05, 0.12, ORANGE, Vector3(0, 0.56, 0.37), Vector3(90, 0, 0)))
	r.add_child(sphere(0.025, DARK, Vector3(-0.08, 0.61, 0.3)))
	r.add_child(sphere(0.025, DARK, Vector3(0.08, 0.61, 0.3)))
	r.add_child(cyl(0.02, 0.02, 0.14, ORANGE, Vector3(-0.08, 0.07, 0)))
	r.add_child(cyl(0.02, 0.02, 0.14, ORANGE, Vector3(0.08, 0.07, 0)))
	return r


static func build_cow() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(0.8, 0.75, 1.4), WHITE, Vector3(0, 0.85, 0)))
	r.add_child(box(Vector3(0.82, 0.32, 0.4), DARK, Vector3(0, 0.95, -0.25)))
	r.add_child(box(Vector3(0.6, 0.3, 0.32), DARK, Vector3(0.11, 0.78, 0.35)))
	for x in [-0.27, 0.27]:
		for z in [-0.5, 0.5]:
			r.add_child(box(Vector3(0.18, 0.5, 0.18), WHITE, Vector3(x, 0.25, z)))
			r.add_child(box(Vector3(0.19, 0.08, 0.19), DARK, Vector3(x, 0.04, z)))
	r.add_child(box(Vector3(0.55, 0.5, 0.5), WHITE, Vector3(0, 1.15, 0.85)))
	# Mõm lớn
	r.add_child(box(Vector3(0.62, 0.3, 0.26), PINK, Vector3(0, 0.99, 1.13)))
	r.add_child(sphere(0.035, DARK, Vector3(-0.12, 1.0, 1.27)))
	r.add_child(sphere(0.035, DARK, Vector3(0.12, 1.0, 1.27)))
	r.add_child(sphere(0.045, DARK, Vector3(-0.15, 1.27, 1.1)))
	r.add_child(sphere(0.045, DARK, Vector3(0.15, 1.27, 1.1)))
	# Tai cụp
	r.add_child(box(Vector3(0.3, 0.08, 0.16), WHITE, Vector3(-0.38, 1.2, 0.8), Vector3(0, 0, 35)))
	r.add_child(box(Vector3(0.3, 0.08, 0.16), WHITE, Vector3(0.38, 1.2, 0.8), Vector3(0, 0, -35)))
	r.add_child(cyl(0.02, 0.04, 0.16, STRAW, Vector3(-0.17, 1.46, 0.8)))
	r.add_child(cyl(0.02, 0.04, 0.16, STRAW, Vector3(0.17, 1.46, 0.8)))
	r.add_child(cyl(0.025, 0.025, 0.5, WHITE, Vector3(0, 0.85, -0.78), Vector3(25, 0, 0)))
	return r


static func build_fish() -> Node3D:
	var r := Node3D.new()
	r.add_child(sphere(0.14, ORANGE, Vector3.ZERO, Vector3(0.6, 0.5, 1.4)))
	r.add_child(prism(Vector3(0.2, 0.16, 0.04), ORANGE, Vector3(0, 0, -0.24), Vector3(90, 0, 0)))
	return r


# ================= Cây trồng =================

static func build_crop(root: Node3D, crop_id: String, growth: int, nights: int) -> void:
	if growth <= 0:
		root.add_child(sphere(0.2, SOIL_WET, Vector3(0, 0.0, 0), Vector3(1, 0.35, 1)))
		root.add_child(sphere(0.06, LEAF, Vector3(0, 0.1, 0)))
		return
	var t := clampf(float(growth) / float(nights), 0.0, 1.0)
	var ripe := growth >= nights
	if crop_id == "leafy_greens":
		var r := lerpf(0.14, 0.3, t)
		var count := 5 if ripe else 3
		for k in count:
			var a := TAU * float(k) / float(count)
			var off := Vector3(cos(a), 0, sin(a)) * r * 0.7
			root.add_child(sphere(r, LEAF if k % 2 == 0 else LEAF_DARK, off + Vector3(0, r * 0.5, 0), Vector3(1, 0.55, 1)))
		root.add_child(sphere(r * 0.8, Color("8fd16a"), Vector3(0, r * 0.9, 0), Vector3(1, 0.8, 1)))
	else:
		var h := lerpf(0.2, 0.55, t)
		for k in 4:
			var a := TAU * float(k) / 4.0
			root.add_child(cyl(0.015, 0.06, h, LEAF, Vector3(cos(a) * 0.06, h * 0.5, sin(a) * 0.06),
				Vector3(rad_to_deg(sin(a)) * 0.35, 0, -rad_to_deg(cos(a)) * 0.35)))
		if ripe:
			root.add_child(cyl(0.16, 0.03, 0.32, CARROT, Vector3(0, 0.0, 0)))


# ================= Công trình =================

static func build_house() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(5, 2.4, 4), WALL, Vector3(0, 1.2, 0)))
	r.add_child(prism(Vector3(5.6, 1.6, 4.6), ROOF, Vector3(0, 3.2, 0), Vector3(0, 90, 0)))
	r.add_child(box(Vector3(0.9, 1.6, 0.08), WOOD, Vector3(1.2, 0.8, 2.02)))
	r.add_child(box(Vector3(0.8, 0.7, 0.06), Color("9fd3ea"), Vector3(-1.2, 1.45, 2.02)))
	r.add_child(box(Vector3(5.2, 0.25, 4.2), Color("c8b48c"), Vector3(0, 0.12, 0)))
	return r


static func build_bed() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(1.1, 0.35, 2.0), WOOD, Vector3(0, 0.18, 0)))
	r.add_child(box(Vector3(1.0, 0.14, 1.9), WHITE, Vector3(0, 0.42, 0)))
	r.add_child(box(Vector3(0.7, 0.14, 0.35), Color("f7e8c9"), Vector3(0, 0.55, -0.7)))
	r.add_child(box(Vector3(1.02, 0.1, 1.1), Color("d9534f"), Vector3(0, 0.5, 0.35)))
	r.add_child(box(Vector3(0.12, 0.7, 0.12), WOOD_DARK, Vector3(-0.5, 0.35, -0.95)))
	r.add_child(box(Vector3(0.12, 0.7, 0.12), WOOD_DARK, Vector3(0.5, 0.35, -0.95)))
	# Mái hiên nhỏ che giường
	for x in [-0.8, 0.8]:
		for z in [-1.1, 1.1]:
			r.add_child(cyl(0.05, 0.05, 2.0, WOOD_DARK, Vector3(x, 1.0, z)))
	r.add_child(box(Vector3(2.0, 0.1, 2.6), STRAW, Vector3(0, 2.0, 0), Vector3(8, 0, 0)))
	return r


static func build_market() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(2.8, 1.0, 1.0), WOOD, Vector3(0, 0.5, 0)))
	r.add_child(box(Vector3(2.9, 0.08, 1.1), WOOD_DARK, Vector3(0, 1.02, 0)))
	for x in [-1.35, 1.35]:
		for z in [-0.45, 0.45]:
			r.add_child(cyl(0.06, 0.06, 2.5, WOOD_DARK, Vector3(x, 1.25, z)))
	for k in 5:
		var c := RED if k % 2 == 0 else WHITE
		r.add_child(box(Vector3(0.6, 0.08, 1.5), c, Vector3(-1.2 + k * 0.6, 2.5, 0.1), Vector3(-10, 0, 0)))
	r.add_child(box(Vector3(0.5, 0.25, 0.4), WOOD_DARK, Vector3(-0.8, 1.17, 0)))
	r.add_child(sphere(0.12, LEAF, Vector3(-0.85, 1.35, 0)))
	r.add_child(sphere(0.12, LEAF_DARK, Vector3(-0.7, 1.35, 0.05)))
	r.add_child(box(Vector3(0.5, 0.25, 0.4), WOOD_DARK, Vector3(0.1, 1.17, 0)))
	r.add_child(cyl(0.08, 0.02, 0.25, CARROT, Vector3(0.0, 1.38, 0), Vector3(0, 0, 70)))
	r.add_child(cyl(0.08, 0.02, 0.25, CARROT, Vector3(0.2, 1.38, 0.05), Vector3(0, 0, -70)))
	r.add_child(sphere(0.09, WHITE, Vector3(0.85, 1.12, 0), Vector3(0.8, 1, 0.8)))
	r.add_child(sphere(0.09, WHITE, Vector3(1.0, 1.12, 0.05), Vector3(0.8, 1, 0.8)))
	return r


static func build_coop() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(1.4, 1.1, 1.2), WOOD, Vector3(-1.0, 0.55, -1.0)))
	r.add_child(prism(Vector3(1.7, 0.7, 1.5), STRAW, Vector3(-1.0, 1.45, -1.0)))
	r.add_child(box(Vector3(0.4, 0.5, 0.05), WOOD_DARK, Vector3(-1.0, 0.3, -0.38)))
	_fence(r, 3.6, 3.0)
	return r


static func build_barn() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(3.4, 2.0, 0.2), WOOD, Vector3(0, 1.0, -1.3)))
	r.add_child(box(Vector3(0.2, 2.0, 2.6), WOOD, Vector3(-1.6, 1.0, 0)))
	r.add_child(box(Vector3(0.2, 2.0, 2.6), WOOD, Vector3(1.6, 1.0, 0)))
	r.add_child(prism(Vector3(3.8, 1.1, 3.0), ROOF, Vector3(0, 2.55, 0)))
	r.add_child(box(Vector3(1.2, 0.35, 0.4), WOOD_DARK, Vector3(0.8, 0.18, 1.0)))
	r.add_child(box(Vector3(1.1, 0.1, 0.32), STRAW, Vector3(0.8, 0.36, 1.0)))
	return r


static func build_pond() -> Node3D:
	var r := Node3D.new()
	r.add_child(cyl(2.5, 2.5, 0.1, Color("c9b38a"), Vector3(0, 0.03, 0)))
	r.add_child(cyl(2.2, 2.2, 0.1, WATER, Vector3(0, 0.06, 0)))
	for k in 6:
		var a := TAU * float(k) / 6.0 + 0.3
		r.add_child(sphere(0.18, Color("9a9a8f"), Vector3(cos(a) * 2.45, 0.08, sin(a) * 2.45), Vector3(1, 0.6, 1)))
	return r


static func build_lot(text: String) -> Node3D:
	var r := Node3D.new()
	r.add_child(cyl(0.06, 0.06, 1.1, WOOD_DARK, Vector3(0, 0.55, 0)))
	r.add_child(box(Vector3(1.0, 0.5, 0.06), WOOD, Vector3(0, 1.0, 0.05)))
	var l := label(text, Vector3(0, 1.7, 0), 34)
	r.add_child(l)
	return r


static func build_bamboo(rng: RandomNumberGenerator) -> Node3D:
	var r := Node3D.new()
	for k in 9:
		var h := rng.randf_range(3.0, 4.6)
		var p := Vector3(rng.randf_range(-1.0, 1.0), h * 0.5, rng.randf_range(-1.0, 1.0))
		r.add_child(cyl(0.07, 0.08, h, Color("7fb24a"), p, Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6))))
		r.add_child(sphere(0.45, LEAF_DARK, Vector3(p.x, h, p.z), Vector3(1, 0.6, 1)))
	return r


static func build_tree(rng: RandomNumberGenerator) -> Node3D:
	var r := Node3D.new()
	var s := rng.randf_range(0.8, 1.3)
	r.add_child(cyl(0.15 * s, 0.2 * s, 1.4 * s, WOOD_DARK, Vector3(0, 0.7 * s, 0)))
	r.add_child(sphere(0.9 * s, LEAF_DARK, Vector3(0, 1.9 * s, 0)))
	r.add_child(sphere(0.6 * s, LEAF, Vector3(0.35 * s, 2.3 * s, 0.2 * s)))
	return r


static func _fence(r: Node3D, w: float, d: float) -> void:
	var hw := w * 0.5
	var hd := d * 0.5
	var step := 0.6
	var x := -hw
	while x <= hw + 0.01:
		r.add_child(box(Vector3(0.08, 0.6, 0.08), WOOD_DARK, Vector3(x, 0.3, -hd)))
		r.add_child(box(Vector3(0.08, 0.6, 0.08), WOOD_DARK, Vector3(x, 0.3, hd)))
		x += step
	var z := -hd
	while z <= hd + 0.01:
		r.add_child(box(Vector3(0.08, 0.6, 0.08), WOOD_DARK, Vector3(-hw, 0.3, z)))
		r.add_child(box(Vector3(0.08, 0.6, 0.08), WOOD_DARK, Vector3(hw, 0.3, z)))
		z += step
	for y in [0.2, 0.45]:
		r.add_child(box(Vector3(w, 0.06, 0.04), WOOD, Vector3(0, y, -hd)))
		r.add_child(box(Vector3(w, 0.06, 0.04), WOOD, Vector3(0, y, hd)))
		r.add_child(box(Vector3(0.04, 0.06, d), WOOD, Vector3(-hw, y, 0)))
		r.add_child(box(Vector3(0.04, 0.06, d), WOOD, Vector3(hw, y, 0)))
