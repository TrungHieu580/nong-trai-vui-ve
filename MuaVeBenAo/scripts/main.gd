extends Node3D
## Scene chính: dựng thế giới, chọn mục tiêu tương tác, gửi lệnh vào GameRules,
## lưu sau mỗi thay đổi rồi cập nhật hình ảnh từ trạng thái.

const GameData = preload("res://scripts/sim/game_data.gd")
const FarmState = preload("res://scripts/sim/farm_state.gd")
const GameRules = preload("res://scripts/sim/game_rules.gd")
const SaveSystem = preload("res://scripts/sim/save_system.gd")
const Art = preload("res://scripts/world/art.gd")
const PlayerScript = preload("res://scripts/world/player.gd")
const GameUi = preload("res://scripts/ui/game_ui.gd")

const PLOT_ORIGIN := Vector3(-3.0, 0.0, -5.2)
const PLOT_SPACING := 2.1
const HOUSE_POS := Vector3(-9.5, 0.0, -8.0)
const BED_POS := Vector3(-8.0, 0.0, -3.6)
const MARKET_POS := Vector3(8.5, 0.0, 3.0)
const COOP_POS := Vector3(-7.5, 0.0, 4.5)
const POND_POS := Vector3(6.0, 0.0, -5.0)
const POND_RADIUS := 2.2
const BARN_POS := Vector3(0.5, 0.0, 6.0)
const SPAWN_POS := Vector3(-6.0, 0.0, -1.0)

var state = FarmState.new()
var saver = SaveSystem.new()
var player
var camera_rig: Node3D
var ui
var interactables: Array = []
var current_target := ""
var highlight: MeshInstance3D
var selected_seed := "seed_leafy_greens"
var busy := false
var in_game := false
var pending_id := ""  # Đối tượng được chạm, sẽ tương tác khi đi tới nơi.
var _plot_tick := 0.0

var plot_nodes: Array = []
var building_nodes := {}
var status_labels := {}
var chicken_node: Node3D
var cow_node: Node3D
var fish_root: Node3D
var ripple: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_world()
	_spawn_player()
	ui = GameUi.new()
	add_child(ui)
	ui.setup(self)
	refresh_all()
	ui.show_main_menu(saver.has_save())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and in_game:
		_save()


# ================= Input =================

func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_forward", [KEY_W, KEY_UP])
	_add_action("move_back", [KEY_S, KEY_DOWN])
	_add_action("interact", [KEY_E])
	_add_action("slot_1", [KEY_1])
	_add_action("slot_2", [KEY_2])
	_add_action("inventory", [KEY_TAB, KEY_I])
	_add_action("pause", [KEY_ESCAPE])
	_add_action("toggle_tutorial", [KEY_H])


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _unhandled_input(event: InputEvent) -> void:
	if not in_game or busy:
		return
	if ui.is_modal_open():
		if event.is_action_pressed("pause") or (event.is_action_pressed("inventory") and ui.is_inventory_open()):
			ui.close_modal()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_tap(event.position)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		interact_current()
	elif event.is_action_pressed("inventory"):
		ui.open_inventory()
	elif event.is_action_pressed("pause"):
		ui.open_pause()
	elif event.is_action_pressed("slot_1"):
		cycle_seed_by(-1)
	elif event.is_action_pressed("slot_2"):
		cycle_seed_by(1)
	elif event.is_action_pressed("toggle_tutorial"):
		state.tutorial_closed = not state.tutorial_closed
		ui.refresh()
	else:
		return
	get_viewport().set_input_as_handled()


# ================= Vòng lặp khung hình =================

func _process(delta: float) -> void:
	_time += delta
	_animate()
	if not in_game:
		player.input_enabled = false
		return
	player.input_enabled = not busy and not ui.is_modal_open()
	camera_rig.global_position = camera_rig.global_position.lerp(player.global_position, 1.0 - exp(-6.0 * delta))
	_update_target()
	if pending_id != "" and not player.has_nav:
		_do_pending()
	# Cây lớn theo đồng hồ thật: cập nhật đếm ngược và hình cây hai lần mỗi giây.
	_plot_tick += delta
	if _plot_tick >= 0.5:
		_plot_tick = 0.0
		for i in plot_nodes.size():
			_refresh_plot(i)


## Chạm/nhấp lên thế giới: chọn đối tượng gần điểm chạm, hoặc đi tới điểm đó.
func _on_tap(screen_pos: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var origin := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if dir.y > -0.01:
		return
	var hit := origin + dir * (-origin.y / dir.y)
	var best: Dictionary = {}
	var best_d := INF
	for it in interactables:
		var c: Vector3 = it["pos"]
		var edge: float = it["edge"]
		var d := Vector2(hit.x - c.x, hit.z - c.z).length()
		if d <= maxf(edge + 0.6, 1.05) and d - edge < best_d:
			best_d = d - edge
			best = it
	if best.is_empty():
		pending_id = ""
		player.go_to(hit)
		return
	pending_id = best["id"]
	var center: Vector3 = best["pos"]
	var away: Vector3 = player.global_position - center
	away.y = 0.0
	if away.length() <= float(best["reach"]) - 0.25:
		player.stop_nav()
		_do_pending()
		return
	if away.length() < 0.01:
		away = Vector3(0, 0, 1)
	player.go_to(center + away.normalized() * (float(best["edge"]) + 0.85))


func _do_pending() -> void:
	var id := pending_id
	pending_id = ""
	for it in interactables:
		if it["id"] != id:
			continue
		var c: Vector3 = it["pos"]
		var d := Vector2(player.global_position.x - c.x, player.global_position.z - c.z).length()
		if d <= float(it["reach"]):
			player.face(c)
			interact(id)
		return


## Chỉ MỘT mục tiêu được chọn: gần nhất, ưu tiên thứ đang đứng đối diện (B01).
func _update_target() -> void:
	var best := ""
	var best_score := INF
	var best_item: Dictionary = {}
	var ppos: Vector3 = player.global_position
	for it in interactables:
		var to: Vector3 = it["pos"] - ppos
		to.y = 0.0
		var dist := to.length()
		if dist > float(it["reach"]):
			continue
		var facing_bonus := 0.0
		if dist > 0.01:
			facing_bonus = player.facing.dot(to / dist)
		var score := dist - float(it["edge"]) - facing_bonus * 0.9
		if score < best_score:
			best_score = score
			best = it["id"]
			best_item = it
	current_target = best
	if best == "" or ui.is_modal_open():
		highlight.visible = false
	else:
		highlight.visible = true
		highlight.global_position = best_item["pos"] + Vector3(0, 0.08, 0)
		var s: float = best_item["ring"]
		highlight.scale = Vector3(s, 1.0, s)
		var pulse := 1.0 + sin(_time * 6.0) * 0.04
		highlight.scale *= Vector3(pulse, 1.0, pulse)
	if busy:
		ui.set_prompt("", "")
	else:
		ui.set_prompt(describe_target(best), action_verb(best))


func _animate() -> void:
	if chicken_node:
		var t := _time * 0.6
		chicken_node.position = COOP_POS + Vector3(0.5 + cos(t) * 0.8, absf(sin(_time * 7.0)) * 0.05, 0.3 + sin(t) * 0.6)
		chicken_node.rotation.y = atan2(-sin(t), cos(t))
	if cow_node:
		cow_node.rotation.z = sin(_time * 1.3) * 0.02
	if fish_root and fish_root.visible:
		fish_root.rotation.y = _time * 0.5
	if ripple and ripple.visible:
		var p := 1.0 + fmod(_time, 1.5)
		ripple.scale = Vector3(p, 1.0, p)


# ================= Dựng thế giới =================

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("bfe3f2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffffff")
	# Bản Web dùng trình kết xuất Compatibility, cảnh sáng hơn bản PC nên giảm nắng,
	# tăng ánh sáng môi trường để bóng đổ mềm kiểu tranh vẽ.
	env.ambient_light_energy = 0.25
	env.tonemap_white = 1.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 0.38
	sun.light_color = Color("ffffff")
	sun.shadow_enabled = true
	add_child(sun)


func _build_world() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024

	# Mặt đất + va chạm
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(60, 60)
	add_child(Art.mesh(ground_mesh, Art.GRASS, Vector3.ZERO))
	_add_collider(Vector3(0, -0.5, 0), Vector3(60, 1, 60))
	for wall in [[Vector3(0, 1, -12.5), Vector3(30, 2, 0.5)], [Vector3(0, 1, 13.0), Vector3(30, 2, 0.5)],
			[Vector3(-15, 1, 0), Vector3(0.5, 2, 26)], [Vector3(15, 1, 0), Vector3(0.5, 2, 26)]]:
		_add_collider(wall[0], wall[1])

	# Đường làng màu đất nung + mảng cỏ đậm
	add_child(Art.box(Vector3(22, 0.03, 1.5), Art.PATH, Vector3(0, 0.015, -0.6)))
	add_child(Art.box(Vector3(1.5, 0.03, 8), Art.PATH, Vector3(8.5, 0.015, 0.2)))
	for gp in [Vector3(-12, 0, -4), Vector3(-3, 0, 9), Vector3(12, 0, 8), Vector3(3, 0, -10), Vector3(-11, 0, 9)]:
		add_child(Art.cyl(2.2, 2.4, 0.02, Art.GRASS_DARK, gp + Vector3(0, 0.01, 0)))

	# Hàng rào gỗ bao quanh làng
	for fl in [[Vector3(0, 0, -12.5), 0.0, 30.0], [Vector3(0, 0, 13.0), 0.0, 30.0],
			[Vector3(-15.0, 0, 0.25), 90.0, 25.5], [Vector3(15.0, 0, 0.25), 90.0, 25.5]]:
		var fence := Art.build_fence_line(fl[2])
		fence.position = fl[0]
		fence.rotation_degrees.y = fl[1]
		add_child(fence)

	# Hoa, bụi cây, đèn lồng, đá lát
	for fp in [Vector3(-5.2, 0, -2.4), Vector3(3.2, 0, -2.0), Vector3(-10.5, 0, -2.3), Vector3(5.0, 0, 1.4),
			Vector3(-4.5, 0, 1.6), Vector3(11.5, 0, 0.5), Vector3(-12.5, 0, 6.0), Vector3(3.5, 0, 9.5),
			Vector3(9.5, 0, -8.8), Vector3(-6.0, 0, -10.5), Vector3(12.5, 0, 6.5), Vector3(-1.5, 0, 2.0)]:
		var fpatch := Art.build_flower_patch(rng)
		fpatch.position = fp
		add_child(fpatch)
	for bp in [Vector3(-12.8, 0, -9.0), Vector3(-6.0, 0, -11.2), Vector3(1.0, 0, -11.0), Vector3(13.0, 0, -5.0),
			Vector3(13.2, 0, 3.0), Vector3(-13.3, 0, 2.5), Vector3(-4.0, 0, 11.5), Vector3(6.5, 0, 11.3)]:
		var bush := Art.build_bush(rng)
		bush.position = bp
		add_child(bush)
	for lp in [Vector3(-2.2, 0, 0.6), Vector3(4.5, 0, -1.9), Vector3(7.2, 0, 0.8)]:
		var lantern := Art.build_lantern()
		lantern.position = lp
		add_child(lantern)
	for sp in [Vector3(-3.5, 0, 3.5), Vector3(4.5, 0, 3.8)]:
		var stones := Art.build_stepping_stones(rng, 5)
		stones.position = sp
		add_child(stones)

	# Nhà + giường
	var house := Art.build_house()
	house.position = HOUSE_POS
	add_child(house)
	_add_collider(HOUSE_POS + Vector3(0, 1.2, 0), Vector3(5, 2.4, 4))
	var bed := Art.build_bed()
	bed.position = BED_POS
	add_child(bed)
	_add_collider(BED_POS + Vector3(0, 0.25, 0), Vector3(1.1, 0.5, 2.0))
	add_child(Art.label("Giường", BED_POS + Vector3(0, 2.4, 0), 32))
	_add_interactable("bed", BED_POS, 2.0, 0.9, 1.3)

	# Sáu ô ruộng
	for i in GameData.PLOT_COUNT:
		var pos := PLOT_ORIGIN + Vector3((i % 3) * PLOT_SPACING, 0, floori(i / 3.0) * PLOT_SPACING)
		var soil_mat := StandardMaterial3D.new()
		soil_mat.albedo_color = Art.SOIL_DRY
		soil_mat.roughness = 1.0
		soil_mat.next_pass = Art.outline_mat()
		var soil_mesh := BoxMesh.new()
		soil_mesh.size = Vector3(1.6, 0.2, 1.6)
		var soil := MeshInstance3D.new()
		soil.mesh = soil_mesh
		soil.material_override = soil_mat
		soil.position = pos + Vector3(0, 0.1, 0)
		add_child(soil)
		var crop := Node3D.new()
		crop.position = pos + Vector3(0, 0.2, 0)
		add_child(crop)
		var lbl := Art.label("", pos + Vector3(0, 1.15, 0), 34)
		add_child(lbl)
		plot_nodes.append({"soil_mat": soil_mat, "crop": crop, "label": lbl})
		_add_interactable("plot:%d" % i, pos, 1.55, 0.0, 1.0)

	# Ao cá + bụi tre
	var bamboo := Art.build_bamboo(rng)
	bamboo.position = POND_POS + Vector3(3.2, 0, -2.4)
	add_child(bamboo)
	var pond := Art.build_pond()
	pond.position = POND_POS
	add_child(pond)
	fish_root = Node3D.new()
	fish_root.position = POND_POS + Vector3(0, 0.12, 0)
	add_child(fish_root)
	for k in 3:
		var fish := Art.build_fish()
		var a := TAU * k / 3.0
		fish.position = Vector3(cos(a), 0, sin(a)) * (0.8 + k * 0.35)
		fish.rotation.y = -a
		fish_root.add_child(fish)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.62
	ripple = Art.mesh(torus, Color("d6f0ff"), POND_POS + Vector3(0, 0.13, 0))
	add_child(ripple)
	var pond_shape := _add_collider(POND_POS + Vector3(0, 0.5, 0), Vector3.ZERO, POND_RADIUS)
	_register_building("pond", pond, pond_shape, POND_POS + Vector3(0, 0, 1.0))
	status_labels["pond"] = _status_label(POND_POS + Vector3(0, 1.4, 0))
	_add_interactable("pond", POND_POS, POND_RADIUS + 1.3, POND_RADIUS, 2.6)

	# Chuồng gà
	var coop := Art.build_coop()
	coop.position = COOP_POS
	add_child(coop)
	chicken_node = Art.build_chicken()
	coop.add_child(chicken_node)
	chicken_node.top_level = true
	var coop_shape := _add_collider(COOP_POS + Vector3(-1.0, 0.55, -1.0), Vector3(1.4, 1.1, 1.2))
	_register_building("coop", coop, coop_shape, COOP_POS)
	status_labels["coop"] = _status_label(COOP_POS + Vector3(0, 2.4, 0))
	_add_interactable("coop", COOP_POS, 2.8, 1.2, 1.9)

	# Chuồng bò
	var barn := Art.build_barn()
	barn.position = BARN_POS
	add_child(barn)
	cow_node = Art.build_cow()
	cow_node.position = Vector3(-0.4, 0, -0.1)
	cow_node.rotation.y = 0.3
	barn.add_child(cow_node)
	var barn_shape := _add_collider(BARN_POS + Vector3(0, 1.0, -1.3), Vector3(3.4, 2.0, 0.2))
	_register_building("barn", barn, barn_shape, BARN_POS)
	status_labels["barn"] = _status_label(BARN_POS + Vector3(0, 3.4, 0))
	_add_interactable("barn", BARN_POS + Vector3(0, 0, 0.8), 2.6, 1.0, 2.0)

	# Quầy chợ
	var market := Art.build_market()
	market.position = MARKET_POS
	add_child(market)
	_add_collider(MARKET_POS + Vector3(0, 0.5, 0), Vector3(2.8, 1.0, 1.0))
	add_child(Art.label("QUẦY CHỢ", MARKET_POS + Vector3(0, 3.1, 0), 44))
	_add_interactable("market", MARKET_POS, 2.4, 1.0, 1.9)

	# Cây cảnh viền làng
	for p in [Vector3(-14, 0, -12), Vector3(-15, 0, 2), Vector3(-13, 0, 10), Vector3(-3, 0, 12),
			Vector3(12, 0, 11), Vector3(15, 0, -2), Vector3(13, 0, -12), Vector3(-2, 0, -12), Vector3(4, 0, 12)]:
		var tree := Art.build_tree(rng)
		tree.position = p
		add_child(tree)

	# Vòng sáng đánh dấu mục tiêu
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.9
	ring_mesh.outer_radius = 1.0
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color("ffd23f")
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight = MeshInstance3D.new()
	highlight.mesh = ring_mesh
	highlight.material_override = ring_mat
	highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	highlight.visible = false
	add_child(highlight)


func _add_collider(pos: Vector3, size: Vector3, cyl_radius: float = 0.0) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	if cyl_radius > 0.0:
		var c := CylinderShape3D.new()
		c.radius = cyl_radius
		c.height = 1.0
		shape.shape = c
	else:
		var b := BoxShape3D.new()
		b.size = size
		shape.shape = b
	body.add_child(shape)
	add_child(body)
	return shape


## reach: khoảng cách tối đa tới tâm; edge: bán kính vật (để so ưu tiên); ring: cỡ vòng sáng.
func _add_interactable(id: String, pos: Vector3, reach: float, edge: float, ring: float) -> void:
	interactables.append({"id": id, "pos": pos, "reach": reach, "edge": edge, "ring": ring})


func _register_building(id: String, built: Node3D, shape: CollisionShape3D, lot_pos: Vector3) -> void:
	var def: Dictionary = GameData.BUILDINGS[id]
	var lot := Art.build_lot("Đất trống\n%s – %d xu" % [def["name"], def["price"]])
	lot.position = lot_pos
	add_child(lot)
	building_nodes[id] = {"built": built, "lot": lot, "shape": shape}


func _status_label(pos: Vector3) -> Label3D:
	var l := Art.label("", pos, 36)
	add_child(l)
	return l


func _spawn_player() -> void:
	player = PlayerScript.new()
	player.position = SPAWN_POS
	add_child(player)
	camera_rig = Node3D.new()
	camera_rig.position = SPAWN_POS
	add_child(camera_rig)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 8.0, 8.0)
	cam.rotation_degrees = Vector3(-45, 0, 0)
	cam.fov = 40.0
	camera_rig.add_child(cam)
	cam.current = true


func _place_player(p: Vector3) -> void:
	player.global_position = p + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	camera_rig.global_position = p


# ================= Hiển thị từ trạng thái =================

func refresh_all() -> void:
	for i in plot_nodes.size():
		_refresh_plot(i)
	_refresh_buildings()
	if ui:
		ui.refresh()


## Cập nhật một ô ruộng theo đồng hồ thật. Mô hình cây chỉ dựng lại khi đổi giai đoạn
## (5 giai đoạn), còn nhãn đếm ngược cập nhật mỗi lần gọi.
func _refresh_plot(i: int) -> void:
	var node: Dictionary = plot_nodes[i]
	var plot: Dictionary = state.plots[i]
	var t := GameRules.now()
	var soil: StandardMaterial3D = node["soil_mat"]
	var watered := GameRules.is_watered(plot)
	var ripe := GameRules.is_ripe(plot, t)
	soil.albedo_color = Art.SOIL_WET if watered and not ripe else Art.SOIL_DRY
	var frac := GameRules.growth_fraction(plot, t)
	var stage := "%s:%d" % [plot["crop"], 4 if ripe else int(frac * 4.0)]
	var crop_root: Node3D = node["crop"]
	if node.get("stage", "") != stage:
		node["stage"] = stage
		for c in crop_root.get_children():
			crop_root.remove_child(c)
			c.queue_free()
		if plot["crop"] != "":
			var def: Dictionary = GameData.CROPS[plot["crop"]]
			var shown := 1.0 if ripe else minf(frac, 0.95)
			Art.build_crop(crop_root, plot["crop"], def["shape"], Color(def["color"]), shown)
	var lbl: Label3D = node["label"]
	if plot["crop"] == "":
		lbl.text = ""
		return
	var crop_name: String = GameData.CROPS[plot["crop"]]["name"]
	if ripe:
		_set_status(lbl, "★ %s chín rồi!" % crop_name, Art.COLOR_READY)
	elif not watered:
		_set_status(lbl, "● Cần tưới", Art.COLOR_NEED)
	else:
		_set_status(lbl, "%s · %s" % [crop_name, GameData.fmt_time(GameRules.seconds_left(plot, t))], Art.COLOR_INFO)


func _set_status(lbl: Label3D, text: String, color: Color) -> void:
	lbl.text = text
	lbl.modulate = color


func _refresh_buildings() -> void:
	for id in building_nodes:
		var owned: bool = state.buildings[id]
		var nodes: Dictionary = building_nodes[id]
		nodes["built"].visible = owned
		nodes["lot"].visible = not owned
		nodes["shape"].set_deferred("disabled", not owned)
		status_labels[id].visible = owned
	for animal_id in ["chicken", "cow"]:
		var def: Dictionary = GameData.ANIMALS[animal_id]
		var a: Dictionary = state.animals[animal_id]
		var lbl: Label3D = status_labels[def["building"]]
		if a["ready"]:
			_set_status(lbl, "★ Có %s!" % GameData.item_name(def["product"]).to_lower(), Art.COLOR_READY)
		elif not a["fed"]:
			_set_status(lbl, "● Đói – cần %s" % GameData.item_name(def["feed"]), Art.COLOR_NEED)
		else:
			_set_status(lbl, "%s đã ăn · %d/%d đêm" % [def["name"], a["progress"], def["nights"]], Art.COLOR_INFO)
	chicken_node.visible = state.buildings["coop"]
	var pl: Label3D = status_labels["pond"]
	var p: Dictionary = state.pond
	fish_root.visible = state.buildings["pond"] and p["stocked"]
	fish_root.scale = Vector3.ONE * (0.7 + 0.15 * int(p["growth"]))
	ripple.visible = state.buildings["pond"] and p["fed"]
	if not p["stocked"]:
		_set_status(pl, "Ao trống – thả cá giống", Art.COLOR_INFO)
	elif GameRules.pond_ready(state):
		_set_status(pl, "★ Cá đã lớn – thu cá", Art.COLOR_READY)
	elif not p["fed"]:
		_set_status(pl, "● Cá đói – cần Cám cá", Art.COLOR_NEED)
	else:
		_set_status(pl, "Cá đã ăn · %d/%d đêm" % [p["growth"], GameData.POND["nights"]], Art.COLOR_INFO)


# ================= Lời nhắc + tương tác =================

## Hạt đang cầm. Nếu hết loại đã chọn thì tự lấy loại khác đang có trong túi.
func _seed_to_use() -> String:
	if state.count(selected_seed) > 0:
		return selected_seed
	if selected_seed == "seed_leafy_greens" and state.count(GameData.FREE_SEED_ITEM) > 0:
		return GameData.FREE_SEED_ITEM
	for seed_id in _owned_seeds():
		return seed_id
	return selected_seed


func _owned_seeds() -> Array:
	var out: Array = []
	for crop_id in GameData.CROP_ORDER:
		var seed_id: String = "seed_" + crop_id
		if state.count(seed_id) > 0:
			out.append(seed_id)
	if state.count(GameData.FREE_SEED_ITEM) > 0:
		out.append(GameData.FREE_SEED_ITEM)
	return out


func describe_target(id: String) -> String:
	if id == "":
		return ""
	if id.begins_with("plot:"):
		var plot: Dictionary = state.plots[int(id.substr(5))]
		if plot["crop"] == "":
			var seed_id := _seed_to_use()
			var n: int = state.count(seed_id)
			if n > 0:
				return "[E] Gieo %s (còn %d)" % [GameData.item_name(seed_id), n]
			return "Ô trống – hết hạt giống. Mua thêm ở quầy chợ nhé."
		var def: Dictionary = GameData.CROPS[plot["crop"]]
		var t := GameRules.now()
		if GameRules.is_ripe(plot, t):
			return "[E] Thu hoạch %s (+%d)" % [def["name"], def["yield"]]
		if not GameRules.is_watered(plot):
			return "[E] Tưới %s – chín sau %s" % [def["name"], GameData.fmt_duration(int(def["seconds"]))]
		return "%s đang lớn – còn %s" % [def["name"], GameData.fmt_time(GameRules.seconds_left(plot, t))]
	match id:
		"bed":
			return "[E] Ngủ – kết thúc ngày %d" % state.day
		"market":
			return "[E] Mở quầy chợ"
		"coop":
			return _animal_prompt("chicken")
		"barn":
			return _animal_prompt("cow")
		"pond":
			return _pond_prompt()
	return ""


func _not_built_text(building_id: String) -> String:
	var def: Dictionary = GameData.BUILDINGS[building_id]
	return "Đất trống: %s – mua ở tab Công trình của quầy chợ (%d xu)" % [def["name"], def["price"]]


func _animal_prompt(animal_id: String) -> String:
	var def: Dictionary = GameData.ANIMALS[animal_id]
	if not state.buildings[def["building"]]:
		return _not_built_text(def["building"])
	var a: Dictionary = state.animals[animal_id]
	if a["ready"]:
		return "[E] Thu %s" % GameData.item_name(def["product"]).to_lower()
	if a["fed"]:
		return "%s đã ăn hôm nay (%d/%d đêm)" % [def["name"], a["progress"], def["nights"]]
	return "[E] Cho %s ăn (%s: %d)" % [def["name"].to_lower(), GameData.item_name(def["feed"]), state.count(def["feed"])]


func _pond_prompt() -> String:
	if not state.buildings["pond"]:
		return _not_built_text("pond")
	var p: Dictionary = state.pond
	if not p["stocked"]:
		return "[E] Thả cá giống (%s: %d)" % [GameData.item_name(GameData.POND["fry"]), state.count(GameData.POND["fry"])]
	if GameRules.pond_ready(state):
		return "[E] Thu cả lứa cá (+%d)" % GameData.POND["yield"]
	if p["fed"]:
		return "Cá đã ăn hôm nay (%d/%d đêm)" % [p["growth"], GameData.POND["nights"]]
	return "[E] Cho cá ăn (Cám cá: %d) – %d/%d đêm" % [state.count(GameData.POND["feed"]), p["growth"], GameData.POND["nights"]]


## Động từ ngắn cho nút hành động lớn; "" nghĩa là chưa làm gì được.
func action_verb(id: String) -> String:
	if id == "":
		return ""
	if id.begins_with("plot:"):
		var plot: Dictionary = state.plots[int(id.substr(5))]
		if plot["crop"] == "":
			return "Gieo" if state.count(_seed_to_use()) > 0 else ""
		if GameRules.is_ripe(plot, GameRules.now()):
			return "Thu"
		return "Tưới" if not GameRules.is_watered(plot) else ""
	match id:
		"bed":
			return "Ngủ"
		"market":
			return "Chợ"
		"coop", "barn":
			var animal_id := "chicken" if id == "coop" else "cow"
			if not state.buildings[id]:
				return ""
			var a: Dictionary = state.animals[animal_id]
			if a["ready"]:
				return "Thu"
			return "" if a["fed"] else "Cho ăn"
		"pond":
			if not state.buildings["pond"]:
				return ""
			if not state.pond["stocked"]:
				return "Thả cá"
			if GameRules.pond_ready(state):
				return "Thu cá"
			return "" if state.pond["fed"] else "Cho ăn"
	return ""


func interact_current() -> void:
	interact(current_target)


func interact(id: String) -> void:
	if id == "" or busy:
		return
	if id.begins_with("plot:"):
		var i := int(id.substr(5))
		var plot: Dictionary = state.plots[i]
		if plot["crop"] == "":
			_apply(GameRules.sow(state, i, _seed_to_use()), "sow")
		elif GameRules.is_ripe(plot, GameRules.now()):
			_apply(GameRules.harvest(state, i, GameRules.now()), "harvest")
		else:
			_apply(GameRules.water(state, i, GameRules.now()), "water")
		return
	match id:
		"bed":
			start_sleep()
		"market":
			ui.open_market()
		"coop":
			_interact_animal("chicken")
		"barn":
			_interact_animal("cow")
		"pond":
			_interact_pond()


func _interact_animal(animal_id: String) -> void:
	var def: Dictionary = GameData.ANIMALS[animal_id]
	if not state.buildings[def["building"]]:
		ui.toast(_not_built_text(def["building"]), false)
		return
	if state.animals[animal_id]["ready"]:
		_apply(GameRules.collect_animal(state, animal_id), "collect")
	else:
		_apply(GameRules.feed_animal(state, animal_id), "feed")


func _interact_pond() -> void:
	if not state.buildings["pond"]:
		ui.toast(_not_built_text("pond"), false)
		return
	if not state.pond["stocked"]:
		_apply(GameRules.stock_pond(state), "stock")
	elif GameRules.pond_ready(state):
		_apply(GameRules.harvest_pond(state), "collect")
	else:
		_apply(GameRules.feed_pond(state), "feed")


## Áp dụng kết quả lệnh: thành công thì lưu + cập nhật hình ảnh.
func _apply(r: Dictionary, action: String) -> Dictionary:
	if r["ok"]:
		_advance_tutorial(action)
		refresh_all()
		player.play_action()
		ui.toast(r["msg"], true)
		_save()  # Gọi sau toast để thông báo lỗi lưu (nếu có) không bị che.
	else:
		ui.toast(r["msg"], false)
	return r


func _advance_tutorial(action: String) -> void:
	if state.tutorial_step < GameData.TUTORIAL.size() and GameData.TUTORIAL[state.tutorial_step]["action"] == action:
		state.tutorial_step += 1


func _save() -> void:
	state.player_pos = Vector2(player.global_position.x, player.global_position.z)
	var err: String = saver.save(state)
	if err != "":
		ui.toast("Lưu thất bại: %s Thao tác tiếp theo sẽ thử lưu lại." % err, false)


func start_sleep() -> void:
	if busy:
		return
	busy = true
	pending_id = ""
	ui.set_prompt("", "")
	await ui.fade_out()
	var r: Dictionary = GameRules.sleep(state)
	state = r["state"]
	_advance_tutorial("sleep")
	_save()
	refresh_all()
	await ui.fade_in()
	ui.show_summary(r["msg"], state.day)
	busy = false


# ================= API cho giao diện =================

func market_buy(item_id: String, qty: int) -> Dictionary:
	return _apply(GameRules.buy(state, item_id, qty), "buy")


func market_sell(item_id: String, qty: int) -> Dictionary:
	return _apply(GameRules.sell(state, item_id, qty), "sell")


func market_build(building_id: String) -> Dictionary:
	return _apply(GameRules.buy_building(state, building_id), "build")


func claim_free_seed() -> Dictionary:
	return _apply(GameRules.claim_free_seed(state), "free_seed")


func select_seed(item_id: String) -> void:
	if item_id == GameData.FREE_SEED_ITEM:
		item_id = "seed_leafy_greens"
	if not GameData.SEED_TO_CROP.has(item_id):
		return
	selected_seed = item_id
	ui.refresh()
	ui.toast("Đang cầm: %s" % GameData.item_name(item_id), true)


func seed_in_hand() -> String:
	return _seed_to_use()


func cycle_seed() -> void:
	cycle_seed_by(1)


## Đổi sang loại hạt kế tiếp đang có trong túi.
func cycle_seed_by(step: int) -> void:
	var owned := _owned_seeds()
	owned.erase(GameData.FREE_SEED_ITEM)
	if owned.is_empty():
		ui.toast("Túi chưa có hạt giống. Ra quầy chợ mua nhé!", false)
		return
	var i := owned.find(_seed_to_use())
	select_seed(owned[(i + step + owned.size()) % owned.size()])


func new_game() -> void:
	state = FarmState.new()
	selected_seed = "seed_leafy_greens"
	_place_player(SPAWN_POS)
	in_game = true
	_save()
	refresh_all()
	ui.enter_game()


## Trả về "" nếu tải được, ngược lại là thông báo lỗi.
func continue_game() -> String:
	var r: Dictionary = saver.load_game()
	if not r["ok"]:
		return r["msg"]
	state = r["state"]
	selected_seed = "seed_leafy_greens"
	_place_player(Vector3(state.player_pos.x, 0.0, state.player_pos.y))
	in_game = true
	refresh_all()
	ui.enter_game()
	if r["msg"] != "":
		ui.toast(r["msg"], false)
	return ""


func save_now() -> void:
	_save()
	ui.toast("Đã lưu.", true)


func back_to_menu() -> void:
	_save()
	in_game = false
	ui.show_main_menu(saver.has_save())


func quit_game() -> void:
	if in_game:
		_save()
	get_tree().quit()
