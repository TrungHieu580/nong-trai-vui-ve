extends RefCounted
## Mô hình TẠM dựng từ khối cơ bản của Godot, đủ để chơi thử vòng lặp.
## Mốc Tuần 4: thay từng hàm build_* bằng cảnh .glb xuất từ Blender
## (hoặc gói CC0 như Quaternius/Kenney) mà không phải sửa logic game.

const GRASS := Color("a8cc8c")
const GRASS_DARK := Color("93bb76")
const PATH := Color("e58b6b")
const STONE := Color("c9d3d6")
const SOIL_DRY := Color("c98a68")
const SOIL_WET := Color("94593f")
const LEAF := Color("7cc35a")
const LEAF_DARK := Color("5aa244")
const CARROT := Color("f29a4a")
const STRAW := Color("ecd08a")
const WOOD := Color("c99a6a")
const WOOD_DARK := Color("8d6443")
const ROOF := Color("e46a6a")
const WALL := Color("f7ead7")
const WATER := Color("8fd3e8")
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

const SHIRT_WHITE := Color("fbf6ee")
const OVERALL := Color("6f9bd1")
const HAIR := Color("7a4a2e")

static var _mats := {}
static var _outline: StandardMaterial3D


## Viền mực kiểu tranh vẽ: vẽ lại mặt sau phình ra một chút, màu nâu đậm.
static func outline_mat() -> StandardMaterial3D:
	if _outline == null:
		_outline = StandardMaterial3D.new()
		_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline.albedo_color = Color("3b2a20")
		_outline.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline.grow = true
		_outline.grow_amount = 0.035
	return _outline


static func mat(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 1.0
		m.metallic_specular = 0.15
		m.next_pass = outline_mat()
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
	l.pixel_size = 0.008
	l.modulate = COLOR_INFO
	l.outline_modulate = Color(0.1, 0.07, 0.05, 0.85)
	return l


# ================= Nhân vật =================

## Nhân vật chibi: đầu to, tóc nâu búi, áo trắng, quần yếm xanh. Mặt hướng về +Z.
static func build_farmer() -> Node3D:
	var r := Node3D.new()
	# Ủng nâu
	r.add_child(box(Vector3(0.16, 0.14, 0.24), Color("8d5a3b"), Vector3(-0.1, 0.07, 0.03)))
	r.add_child(box(Vector3(0.16, 0.14, 0.24), Color("8d5a3b"), Vector3(0.1, 0.07, 0.03)))
	# Chân + quần yếm
	r.add_child(cyl(0.07, 0.07, 0.2, OVERALL, Vector3(-0.1, 0.22, 0)))
	r.add_child(cyl(0.07, 0.07, 0.2, OVERALL, Vector3(0.1, 0.22, 0)))
	r.add_child(cyl(0.2, 0.24, 0.24, OVERALL, Vector3(0, 0.42, 0)))
	# Áo trắng + yếm phía trước + quai đeo
	r.add_child(cyl(0.19, 0.22, 0.3, SHIRT_WHITE, Vector3(0, 0.66, 0)))
	r.add_child(box(Vector3(0.24, 0.22, 0.06), OVERALL, Vector3(0, 0.62, 0.19)))
	r.add_child(box(Vector3(0.05, 0.24, 0.04), OVERALL, Vector3(-0.1, 0.72, 0.18), Vector3(-10, 0, 0)))
	r.add_child(box(Vector3(0.05, 0.24, 0.04), OVERALL, Vector3(0.1, 0.72, 0.18), Vector3(-10, 0, 0)))
	r.add_child(box(Vector3(0.09, 0.07, 0.02), Color("5a82b8"), Vector3(0, 0.6, 0.225)))
	# Tay: tay áo ngắn trắng + bàn tay
	r.add_child(capsule(0.075, 0.24, SHIRT_WHITE, Vector3(-0.25, 0.7, 0), Vector3(0, 0, 18)))
	r.add_child(capsule(0.075, 0.24, SHIRT_WHITE, Vector3(0.25, 0.7, 0), Vector3(0, 0, -18)))
	r.add_child(capsule(0.06, 0.2, SKIN, Vector3(-0.3, 0.55, 0), Vector3(0, 0, 10)))
	r.add_child(capsule(0.06, 0.2, SKIN, Vector3(0.3, 0.55, 0), Vector3(0, 0, -10)))
	# Đầu to
	r.add_child(sphere(0.36, SKIN, Vector3(0, 1.17, 0)))
	# Tóc: phần sau đầu, mái phía trước, búi tóc
	r.add_child(sphere(0.38, HAIR, Vector3(0, 1.22, -0.08)))
	r.add_child(sphere(0.24, HAIR, Vector3(0, 1.4, 0.15), Vector3(1.45, 0.55, 1.0)))
	r.add_child(sphere(0.12, HAIR, Vector3(-0.27, 1.22, 0.12), Vector3(0.7, 1.2, 0.8)))
	r.add_child(sphere(0.12, HAIR, Vector3(0.27, 1.22, 0.12), Vector3(0.7, 1.2, 0.8)))
	r.add_child(sphere(0.15, HAIR, Vector3(0.16, 1.6, -0.14)))
	r.add_child(sphere(0.05, Color("f28b82"), Vector3(0.08, 1.56, -0.03)))
	# Mặt
	r.add_child(sphere(0.045, DARK, Vector3(-0.12, 1.16, 0.33), Vector3(1, 1.3, 0.6)))
	r.add_child(sphere(0.045, DARK, Vector3(0.12, 1.16, 0.33), Vector3(1, 1.3, 0.6)))
	r.add_child(sphere(0.06, PINK, Vector3(-0.2, 1.06, 0.28), Vector3(1.2, 0.6, 0.5)))
	r.add_child(sphere(0.06, PINK, Vector3(0.2, 1.06, 0.28), Vector3(1.2, 0.6, 0.5)))
	r.add_child(box(Vector3(0.08, 0.02, 0.02), Color("a0523a"), Vector3(0, 1.03, 0.35)))
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

## Dựng cây theo kiểu (shape) và màu nông sản trong GameData.CROPS.
## t: tỷ lệ lớn 0..1 (1 = chín).
static func build_crop(root: Node3D, crop_id: String, shape: String, fruit: Color, t: float) -> void:
	if t <= 0.02:
		root.add_child(sphere(0.2, SOIL_WET, Vector3(0, 0.0, 0), Vector3(1, 0.35, 1)))
		root.add_child(sphere(0.06, LEAF, Vector3(0, 0.1, 0)))
		return
	var ripe := t >= 1.0
	match shape:
		"leafy":
			_crop_leafy(root, fruit, t, ripe)
		"root":
			_crop_root(root, fruit, t, ripe)
		"bush":
			_crop_bush(root, fruit, t, ripe)
		"vine":
			_crop_vine(root, fruit, t, ripe)
		"tall":
			_crop_tall(root, fruit, t, ripe, crop_id == "rice")
		"big":
			_crop_big(root, fruit, t, ripe, crop_id == "watermelon")


static func _crop_leafy(root: Node3D, c: Color, t: float, ripe: bool) -> void:
	var r := lerpf(0.14, 0.3, t)
	var count := 5 if ripe else 3
	for k in count:
		var a := TAU * float(k) / float(count)
		var off := Vector3(cos(a), 0, sin(a)) * r * 0.7
		root.add_child(sphere(r, c if k % 2 == 0 else c.darkened(0.15), off + Vector3(0, r * 0.5, 0), Vector3(1, 0.55, 1)))
	var head := r * 0.85
	root.add_child(sphere(head, c.lightened(0.3), Vector3(0, r * 0.9, 0), Vector3(1, 0.9, 1)))
	if ripe:
		_face(root, Vector3(0, r * 0.95, head * 0.88), 0.07)


static func _leaves(root: Node3D, base_y: float, h: float, n: int) -> void:
	for k in n:
		var a := TAU * float(k) / float(n)
		root.add_child(cyl(0.015, 0.06, h, LEAF, Vector3(cos(a) * 0.06, base_y + h * 0.5, sin(a) * 0.06),
			Vector3(rad_to_deg(sin(a)) * 0.35, 0, -rad_to_deg(cos(a)) * 0.35)))


static func _crop_root(root: Node3D, c: Color, t: float, ripe: bool) -> void:
	var h := lerpf(0.2, 0.5, t)
	if ripe:
		root.add_child(sphere(0.21, c, Vector3(0, 0.16, 0), Vector3(1, 1.05, 1)))
		root.add_child(cyl(0.08, 0.0, 0.18, c, Vector3(0, -0.02, 0)))
		_leaves(root, 0.32, h, 4)
		_face(root, Vector3(0, 0.19, 0.19), 0.07)
	else:
		_leaves(root, 0.0, h, 4)


static func _crop_bush(root: Node3D, c: Color, t: float, ripe: bool) -> void:
	var s := lerpf(0.5, 1.0, t)
	root.add_child(sphere(0.3 * s, LEAF_DARK, Vector3(0, 0.3 * s, 0)))
	root.add_child(sphere(0.22 * s, LEAF, Vector3(0.12, 0.42 * s, 0.05)))
	root.add_child(sphere(0.2 * s, LEAF, Vector3(-0.13, 0.38 * s, 0.04)))
	if t > 0.6:
		var fr := 0.07 if not ripe else 0.09
		var col := c if ripe else LEAF.lightened(0.2)
		for p in [Vector3(0.18, 0.35, 0.2), Vector3(-0.17, 0.3, 0.2), Vector3(0.02, 0.5, 0.22), Vector3(0.22, 0.2, -0.1)]:
			root.add_child(sphere(fr, col, p * s + Vector3(0, 0.05, 0)))
	if ripe:
		root.add_child(sphere(0.13, c, Vector3(0, 0.3, 0.27)))
		_face(root, Vector3(0, 0.31, 0.39), 0.045)


static func _crop_vine(root: Node3D, c: Color, t: float, ripe: bool) -> void:
	var h := lerpf(0.3, 0.75, t)
	for x in [-0.25, 0.25]:
		root.add_child(cyl(0.02, 0.02, h + 0.2, WOOD, Vector3(x, (h + 0.2) * 0.5, -0.1)))
	root.add_child(box(Vector3(0.55, 0.02, 0.02), WOOD, Vector3(0, h + 0.18, -0.1)))
	for k in 4:
		var y := h * (0.25 + 0.22 * k)
		root.add_child(sphere(0.13, LEAF if k % 2 == 0 else LEAF_DARK, Vector3(-0.12 + 0.08 * k, y, -0.05), Vector3(1.2, 0.7, 0.6)))
	if ripe:
		root.add_child(capsule(0.09, 0.4, c, Vector3(0.0, 0.32, 0.12), Vector3(0, 0, 10)))
		root.add_child(capsule(0.07, 0.3, c.darkened(0.1), Vector3(0.2, 0.42, 0.05), Vector3(0, 0, -15)))
		_face(root, Vector3(0.015, 0.35, 0.21), 0.04)


static func _crop_tall(root: Node3D, c: Color, t: float, ripe: bool, is_rice: bool) -> void:
	var h := lerpf(0.3, 0.95, t)
	var stems := 6 if is_rice else 2
	for k in stems:
		var off := Vector3(-0.2 + 0.4 * float(k) / maxf(1.0, stems - 1.0), 0, 0.05 * (k % 2))
		var stalk := c if (ripe and is_rice) else LEAF
		root.add_child(cyl(0.02, 0.035, h, stalk, off + Vector3(0, h * 0.5, 0), Vector3(0, 0, 6 - 4 * k)))
		if not is_rice:
			root.add_child(box(Vector3(0.35, 0.02, 0.08), LEAF_DARK, off + Vector3(0.1, h * 0.5, 0), Vector3(0, 0, -25)))
		if ripe:
			if is_rice:
				root.add_child(capsule(0.035, 0.18, c.darkened(0.05), off + Vector3(0.04, h + 0.02, 0), Vector3(0, 0, -35)))
			else:
				root.add_child(capsule(0.07, 0.28, c, off + Vector3(0.06, h * 0.65, 0.05), Vector3(0, 0, -20)))
	if ripe and not is_rice:
		_face(root, Vector3(-0.13, h * 0.65 + 0.02, 0.13), 0.035)


static func _crop_big(root: Node3D, c: Color, t: float, ripe: bool, striped: bool) -> void:
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		root.add_child(sphere(0.16, LEAF_DARK, Vector3(cos(a) * 0.32, 0.06, sin(a) * 0.32), Vector3(1.2, 0.35, 1.2)))
	var r := lerpf(0.06, 0.32, t)
	var col := c if t > 0.5 else LEAF.lightened(0.15)
	root.add_child(sphere(r, col, Vector3(0, r * 0.85, 0.05), Vector3(1.1, 0.9, 1.0)))
	if striped and t > 0.5:
		for k in 3:
			root.add_child(box(Vector3(0.03, r * 1.5, r * 2.05), LEAF_DARK.darkened(0.2), Vector3(-r * 0.5 + r * 0.5 * k, r * 0.85, 0.05)))
	if ripe:
		root.add_child(cyl(0.02, 0.03, 0.12, WOOD_DARK, Vector3(0, r * 1.7, 0.05)))
		_face(root, Vector3(0, r * 0.9, r + 0.03), 0.09)


## Mặt cười dễ thương cho cây đã chín (nhìn về phía camera, +Z).
static func _face(root: Node3D, center: Vector3, spread: float) -> void:
	root.add_child(sphere(0.028, DARK, center + Vector3(-spread, 0.02, 0)))
	root.add_child(sphere(0.028, DARK, center + Vector3(spread, 0.02, 0)))
	root.add_child(sphere(0.03, Color("f59a9a"), center + Vector3(-spread * 1.6, -0.025, -0.01), Vector3(1.3, 0.7, 0.6)))
	root.add_child(sphere(0.03, Color("f59a9a"), center + Vector3(spread * 1.6, -0.025, -0.01), Vector3(1.3, 0.7, 0.6)))
	root.add_child(box(Vector3(0.05, 0.012, 0.02), DARK, center + Vector3(0, -0.035, 0.005)))


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


static func build_flower_patch(rng: RandomNumberGenerator) -> Node3D:
	var r := Node3D.new()
	var palette := [Color("f6a5c0"), Color("ffffff"), Color("ffd166"), Color("c3a6f0"), Color("f28b82")]
	for k in rng.randi_range(5, 8):
		var p := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.5, 0.5))
		var h := rng.randf_range(0.18, 0.32)
		r.add_child(cyl(0.012, 0.012, h, LEAF_DARK, p + Vector3(0, h * 0.5, 0)))
		var c: Color = palette[rng.randi_range(0, palette.size() - 1)]
		r.add_child(sphere(0.07, c, p + Vector3(0, h, 0), Vector3(1, 0.6, 1)))
		r.add_child(sphere(0.03, Color("ffcf4a"), p + Vector3(0, h + 0.035, 0)))
	for k in 3:
		r.add_child(sphere(0.12, LEAF, Vector3(rng.randf_range(-0.5, 0.5), 0.05, rng.randf_range(-0.4, 0.4)), Vector3(1, 0.5, 1)))
	return r


static func build_bush(rng: RandomNumberGenerator) -> Node3D:
	var r := Node3D.new()
	var s := rng.randf_range(0.8, 1.15)
	r.add_child(sphere(0.45 * s, LEAF_DARK, Vector3(0, 0.38 * s, 0)))
	r.add_child(sphere(0.32 * s, LEAF, Vector3(0.28 * s, 0.3 * s, 0.12 * s)))
	r.add_child(sphere(0.3 * s, LEAF, Vector3(-0.26 * s, 0.28 * s, 0.1 * s)))
	for k in 4:
		var a := rng.randf() * TAU
		r.add_child(sphere(0.05, Color("fbe4ef"), Vector3(cos(a) * 0.38 * s, 0.45 * s, sin(a) * 0.38 * s)))
	return r


static var _glow: StandardMaterial3D


## Vật liệu phát sáng dùng chung cho đèn lồng và cửa sổ; main đổi độ sáng theo giờ.
static func glow_mat() -> StandardMaterial3D:
	if _glow == null:
		_glow = StandardMaterial3D.new()
		_glow.albedo_color = Color("ffe08a")
		_glow.emission_enabled = true
		_glow.emission = Color("ffcf5a")
		_glow.emission_energy_multiplier = 0.0
		_glow.next_pass = outline_mat()
	return _glow


static func build_lantern() -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(0.4, 0.12, 0.4), STONE, Vector3(0, 0.06, 0)))
	r.add_child(cyl(0.05, 0.06, 0.9, DARK, Vector3(0, 0.55, 0)))
	r.add_child(box(Vector3(0.26, 0.3, 0.26), DARK, Vector3(0, 1.1, 0)))
	var glass := box(Vector3(0.2, 0.24, 0.27), Color("ffe08a"), Vector3(0, 1.1, 0))
	glass.material_override = glow_mat()
	r.add_child(glass)
	r.add_child(prism(Vector3(0.36, 0.16, 0.36), DARK, Vector3(0, 1.33, 0)))
	return r


static func build_stepping_stones(rng: RandomNumberGenerator, count: int) -> Node3D:
	var r := Node3D.new()
	for k in count:
		var p := Vector3(rng.randf_range(-0.9, 0.9), 0.02, rng.randf_range(-0.7, 0.7))
		r.add_child(cyl(0.26, 0.28, 0.05, STONE, p, Vector3(0, rng.randf() * 90.0, 0)))
	return r


# ======================= Xóm làng =======================

## Dân làng chibi, tuỳ biến bằng `look`: shirt, pants, hair, skin (mã màu) và hat
## ("non_la" nón lá, "cap" mũ lưỡi trai, "bun" búi tóc, "pigtails" tóc hai bím, "" không).
static func build_person(look: Dictionary) -> Node3D:
	var r := Node3D.new()
	var shirt := Color(look.get("shirt", "ffffff"))
	var pants := Color(look.get("pants", "4a4a6a"))
	var hair := Color(look.get("hair", "2b1d14"))
	var skin := Color(look.get("skin", "f3cfa8"))
	r.add_child(box(Vector3(0.15, 0.13, 0.22), Color("6b4a33"), Vector3(-0.1, 0.065, 0.03)))
	r.add_child(box(Vector3(0.15, 0.13, 0.22), Color("6b4a33"), Vector3(0.1, 0.065, 0.03)))
	r.add_child(cyl(0.07, 0.075, 0.24, pants, Vector3(-0.1, 0.24, 0)))
	r.add_child(cyl(0.07, 0.075, 0.24, pants, Vector3(0.1, 0.24, 0)))
	r.add_child(cyl(0.2, 0.25, 0.42, shirt, Vector3(0, 0.56, 0)))
	r.add_child(capsule(0.07, 0.34, shirt, Vector3(-0.26, 0.6, 0), Vector3(0, 0, 16)))
	r.add_child(capsule(0.07, 0.34, shirt, Vector3(0.26, 0.6, 0), Vector3(0, 0, -16)))
	r.add_child(sphere(0.065, skin, Vector3(-0.3, 0.42, 0)))
	r.add_child(sphere(0.065, skin, Vector3(0.3, 0.42, 0)))
	r.add_child(sphere(0.34, skin, Vector3(0, 1.08, 0)))
	r.add_child(sphere(0.36, hair, Vector3(0, 1.13, -0.08)))
	r.add_child(sphere(0.22, hair, Vector3(0, 1.3, 0.14), Vector3(1.45, 0.5, 1.0)))
	r.add_child(sphere(0.042, DARK, Vector3(-0.11, 1.07, 0.31), Vector3(1, 1.3, 0.6)))
	r.add_child(sphere(0.042, DARK, Vector3(0.11, 1.07, 0.31), Vector3(1, 1.3, 0.6)))
	r.add_child(sphere(0.055, PINK, Vector3(-0.19, 0.98, 0.26), Vector3(1.2, 0.6, 0.5)))
	r.add_child(sphere(0.055, PINK, Vector3(0.19, 0.98, 0.26), Vector3(1.2, 0.6, 0.5)))
	r.add_child(box(Vector3(0.07, 0.02, 0.02), Color("a0523a"), Vector3(0, 0.95, 0.33)))
	match str(look.get("hat", "")):
		"non_la":
			r.add_child(cyl(0.02, 0.6, 0.32, STRAW, Vector3(0, 1.52, 0)))
			r.add_child(cyl(0.57, 0.57, 0.02, Color("d9b45a"), Vector3(0, 1.37, 0)))
		"cap":
			r.add_child(sphere(0.33, Color("4f6d8f"), Vector3(0, 1.22, 0), Vector3(1.05, 0.7, 1.05)))
			r.add_child(box(Vector3(0.36, 0.03, 0.26), Color("3f5a78"), Vector3(0, 1.2, 0.38)))
		"bun":
			r.add_child(sphere(0.15, hair, Vector3(0, 1.5, -0.12)))
		"pigtails":
			r.add_child(sphere(0.12, hair, Vector3(-0.34, 1.12, -0.05)))
			r.add_child(sphere(0.12, hair, Vector3(0.34, 1.12, -0.05)))
			r.add_child(sphere(0.045, Color("f28b82"), Vector3(-0.3, 1.2, 0.02)))
			r.add_child(sphere(0.045, Color("f28b82"), Vector3(0.3, 1.2, 0.02)))
	return r


## Dụng cụ cầm tay theo việc đang làm (gắn vào người, phía trước bên phải).
static func build_tool(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"hoe":
			r.add_child(cyl(0.025, 0.025, 1.0, WOOD, Vector3(0.32, 0.6, 0.18), Vector3(35, 0, 0)))
			r.add_child(box(Vector3(0.16, 0.04, 0.2), STONE.darkened(0.3), Vector3(0.32, 0.2, 0.47)))
		"basket":
			r.add_child(cyl(0.18, 0.13, 0.18, STRAW, Vector3(0.34, 0.42, 0.12)))
			r.add_child(cyl(0.15, 0.15, 0.02, LEAF, Vector3(0.34, 0.52, 0.12)))
		"can":
			r.add_child(cyl(0.11, 0.12, 0.2, Color("7fb3d5"), Vector3(0.34, 0.42, 0.14)))
			r.add_child(cyl(0.02, 0.03, 0.26, Color("7fb3d5"), Vector3(0.34, 0.47, 0.32), Vector3(70, 0, 0)))
		"sickle":
			r.add_child(cyl(0.02, 0.02, 0.22, WOOD, Vector3(0.32, 0.45, 0.16)))
			r.add_child(torus_arc(Vector3(0.32, 0.6, 0.2)))
		"rod":
			r.add_child(cyl(0.015, 0.025, 1.8, WOOD, Vector3(0.3, 1.0, 0.75), Vector3(60, 0, 0)))
			r.add_child(cyl(0.004, 0.004, 1.2, Color("f5f5f5"), Vector3(0.3, 1.05, 1.55)))
			r.add_child(sphere(0.04, Color("e2574c"), Vector3(0.3, 0.45, 1.58)))
	return r


static func torus_arc(pos: Vector3) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = 0.1
	m.outer_radius = 0.13
	return mesh(m, Color("cfd8dc"), pos, Vector3(90, 0, 0), Vector3(1, 1, 0.5))


## Nhà nhỏ của dân làng; door = +1 cửa nhìn về +Z, -1 nhìn về -Z.
static func build_small_house(walls: Color, roof: Color, door: int) -> Node3D:
	var r := Node3D.new()
	r.add_child(box(Vector3(3.6, 2.0, 3.0), walls, Vector3(0, 1.0, 0)))
	r.add_child(prism(Vector3(4.1, 1.3, 3.5), roof, Vector3(0, 2.65, 0), Vector3(0, 90, 0)))
	var z := 1.52 * door
	r.add_child(box(Vector3(0.8, 1.4, 0.06), WOOD, Vector3(0.6, 0.7, z)))
	var win := box(Vector3(0.7, 0.6, 0.06), Color("ffe08a"), Vector3(-0.8, 1.2, z))
	win.material_override = glow_mat()
	r.add_child(win)
	r.add_child(box(Vector3(3.8, 0.2, 3.2), Color("c8b48c"), Vector3(0, 0.1, 0)))
	# Lu nước và chậu cây trước nhà
	r.add_child(cyl(0.22, 0.28, 0.45, Color("a0523a"), Vector3(1.5, 0.22, z + 0.5 * door)))
	r.add_child(sphere(0.25, LEAF, Vector3(-1.5, 0.3, z + 0.4 * door)))
	return r


static func build_buffalo() -> Node3D:
	var r := Node3D.new()
	var hide := Color("5b5f66")
	r.add_child(box(Vector3(0.85, 0.75, 1.5), hide, Vector3(0, 0.85, 0)))
	for x in [-0.28, 0.28]:
		for z in [-0.5, 0.5]:
			r.add_child(box(Vector3(0.18, 0.5, 0.18), hide.darkened(0.15), Vector3(x, 0.25, z)))
	r.add_child(box(Vector3(0.55, 0.5, 0.55), hide, Vector3(0, 1.0, 0.95)))
	r.add_child(box(Vector3(0.5, 0.25, 0.22), Color("8a8f96"), Vector3(0, 0.86, 1.25)))
	r.add_child(sphere(0.045, DARK, Vector3(-0.16, 1.1, 1.22)))
	r.add_child(sphere(0.045, DARK, Vector3(0.16, 1.1, 1.22)))
	# Sừng cong lưỡi liềm đặc trưng của trâu
	r.add_child(cyl(0.03, 0.06, 0.5, Color("e8e2d0"), Vector3(-0.42, 1.3, 0.85), Vector3(0, 0, 65)))
	r.add_child(cyl(0.03, 0.06, 0.5, Color("e8e2d0"), Vector3(0.42, 1.3, 0.85), Vector3(0, 0, -65)))
	r.add_child(cyl(0.02, 0.02, 0.45, hide, Vector3(0, 0.85, -0.85), Vector3(25, 0, 0)))
	return r


static func build_well() -> Node3D:
	var r := Node3D.new()
	r.add_child(cyl(0.7, 0.75, 0.7, STONE, Vector3(0, 0.35, 0)))
	r.add_child(cyl(0.55, 0.55, 0.05, Color("4f7fa8"), Vector3(0, 0.66, 0)))
	for x in [-0.75, 0.75]:
		r.add_child(cyl(0.05, 0.05, 1.5, WOOD_DARK, Vector3(x, 1.0, 0)))
	r.add_child(prism(Vector3(1.8, 0.45, 1.2), ROOF, Vector3(0, 1.95, 0), Vector3(0, 90, 0)))
	r.add_child(cyl(0.12, 0.1, 0.18, WOOD, Vector3(0.2, 1.1, 0)))
	return r


## Một thửa ruộng lúa theo giai đoạn: bare, plowed, planted, growing, ripe.
static func build_paddy(stage: String, frac: float) -> Node3D:
	var r := Node3D.new()
	var soil := SOIL_DRY
	if stage == "plowed":
		soil = SOIL_WET
	r.add_child(box(Vector3(2.3, 0.18, 2.3), Color("8d6443"), Vector3(0, 0.09, 0)))
	r.add_child(box(Vector3(2.1, 0.2, 2.1), soil, Vector3(0, 0.1, 0)))
	if stage == "plowed":
		for k in 4:
			r.add_child(box(Vector3(1.9, 0.05, 0.08), SOIL_WET.darkened(0.3), Vector3(0, 0.21, -0.75 + k * 0.5)))
	if stage in ["planted", "growing", "ripe"]:
		r.add_child(box(Vector3(2.1, 0.03, 2.1), Color("9fd3e3"), Vector3(0, 0.215, 0)))
		var h := 0.12
		var col := Color("8fd16a")
		if stage == "growing":
			h = lerpf(0.15, 0.55, clampf(frac, 0.0, 1.0))
			col = LEAF
		elif stage == "ripe":
			h = 0.6
			col = Color("e8c872")
		for i in 3:
			for j in 3:
				var p := Vector3(-0.65 + i * 0.65, 0.22, -0.65 + j * 0.65)
				r.add_child(cyl(0.02, 0.09, h, col, p + Vector3(0, h * 0.5, 0)))
				if stage == "ripe":
					r.add_child(capsule(0.04, 0.18, Color("d9a93a"), p + Vector3(0.06, h, 0), Vector3(0, 0, -40)))
	return r


## Hàng rào gỗ thẳng dài `length` dọc trục X.
static func build_fence_line(length: float) -> Node3D:
	var r := Node3D.new()
	var x := -length * 0.5
	while x <= length * 0.5 + 0.01:
		r.add_child(box(Vector3(0.16, 0.9, 0.16), WOOD, Vector3(x, 0.45, 0)))
		r.add_child(prism(Vector3(0.16, 0.1, 0.16), WOOD_DARK, Vector3(x, 0.95, 0)))
		x += 1.4
	r.add_child(box(Vector3(length, 0.1, 0.06), WOOD, Vector3(0, 0.62, 0)))
	r.add_child(box(Vector3(length, 0.1, 0.06), WOOD, Vector3(0, 0.32, 0)))
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
