extends RefCounted
## Mô phỏng xóm làng: đồng hồ, dân làng tự làm việc theo lịch, ruộng lúa làng, chợ.
## Không phụ thuộc hình ảnh – lớp 3D chỉ đọc `villagers` để vẽ, nên kiểm thử được.
##
## Mỗi dân làng là một Dictionary:
##   pos (Vector2 x,z), path (Array[Vector2]), facing (Vector2), visible, walking,
##   block (khối lịch hiện tại), activity (chữ hiển thị), tool, task, task_plot,
##   work (phút đã làm), wait, idx, carry {item: qty}, delivered, egg_day

const GameData = preload("res://scripts/sim/game_data.gd")
const GameRules = preload("res://scripts/sim/game_rules.gd")
const VD = preload("res://scripts/sim/village_data.gd")

var state
var villagers: Array = []


func _init(s) -> void:
	state = s
	for d in VD.VILLAGERS:
		villagers.append({
			"def": d, "id": d["id"], "pos": d["home"], "path": [], "facing": Vector2(0, 1),
			"visible": false, "walking": false, "block": "", "activity": "Ngủ", "tool": "",
			"task": "", "task_plot": -1, "work": 0.0, "wait": 0.0, "idx": int(d.get("play_offset", 0)),
			"carry": {}, "delivered": false, "egg_day": -1,
		})
	snap_all()


func set_state(s) -> void:
	state = s


func hour() -> float:
	return state.clock / 60.0


func get_villager(id: String) -> Dictionary:
	for v in villagers:
		if v["id"] == id:
			return v
	return {}


## Chạy mô phỏng `dt` giây thật. Trả về {"new_day": bool} khi đồng hồ qua nửa đêm
## (bên ngoài sẽ xử lý sang ngày mới cho vật nuôi rồi gọi set_state).
func step(dt: float) -> Dictionary:
	var minutes := dt * VD.MINUTES_PER_SECOND
	var new_day := false
	state.clock += minutes
	if state.clock >= 1440.0:
		state.clock -= 1440.0
		new_day = true
	_grow_paddies(minutes)
	for v in villagers:
		_update(v, dt, minutes)
	return {"new_day": new_day}


## Bỏ qua một khoảng thời gian (ví dụ khi người chơi đi ngủ): lúa vẫn lớn,
## chợ vẫn bán bớt hàng, rồi đặt mọi người về đúng chỗ theo giờ mới.
func advance_offline(minutes: float) -> void:
	_grow_paddies(minutes)
	for k in int(minutes / 90.0):
		_sell_to_customers("")
	snap_all()


## Đặt ngay mỗi người vào đúng chỗ theo lịch của giờ hiện tại (khi tải game, sau khi ngủ).
func snap_all() -> void:
	for v in villagers:
		var block := _block_for(v["def"]["role"], hour())
		v["block"] = block
		v["path"] = []
		v["task"] = ""
		v["work"] = 0.0
		v["walking"] = false
		v["visible"] = block != "sleep"
		v["pos"] = _block_spot(v, block)
		_set_idle_label(v)


# ======================= Lịch =======================

func _block_for(role: String, h: float) -> String:
	match role:
		"farmer":
			if h < 5.5 or h >= 21.0:
				return "sleep"
			if h < 6.0:
				return "home"
			if h < 11.0:
				return "field"
			if h < 13.0:
				return "home"
			if h < 17.5:
				return "field"
			if h < 19.0:
				return "market"
			return "home"
		"merchant":
			if h < 5.5 or h >= 21.5:
				return "sleep"
			if h < 6.5:
				return "home"
			if h < 11.5:
				return "stall"
			if h < 13.0:
				return "home"
			if h < 18.5:
				return "stall"
			return "home"
		"fisher":
			if h < 5.5 or h >= 21.0:
				return "sleep"
			if h < 6.0:
				return "home"
			if h < 10.5:
				return "fish"
			if h < 11.5:
				return "market"
			if h < 13.0:
				return "home"
			if h < 17.0:
				return "fish"
			if h < 18.0:
				return "market"
			return "home"
		"poultry":
			if h < 5.5 or h >= 20.5:
				return "sleep"
			if h < 6.0:
				return "home"
			if h < 8.5:
				return "yard"
			if h < 9.5:
				return "market"
			if h < 15.5:
				return "rest"
			if h < 17.0:
				return "yard"
			return "home"
		"kid":
			if h < 6.5 or h >= 20.0:
				return "sleep"
			if h < 7.5:
				return "home"
			if h < 11.0:
				return "play"
			if h < 13.0:
				return "home"
			if h < 18.0:
				return "play"
			return "home"
	return "home"


func _block_spot(v: Dictionary, block: String) -> Vector2:
	match block:
		"field":
			return VD.SPOTS["field_idle"]
		"stall":
			return VD.SPOTS["market_stall"]
		"fish":
			return VD.SPOTS["fishing"]
		"market":
			return VD.SPOTS["market_customer"] + Vector2(0.9 * (_index_of(v) - 2), 0)
		"yard":
			return VD.SPOTS["yard"]
		"rest":
			return VD.SPOTS["well"]
		"play":
			return VD.PLAY_SPOTS[int(v["idx"]) % VD.PLAY_SPOTS.size()]
	return v["def"]["home"]


func _index_of(v: Dictionary) -> int:
	return villagers.find(v)


# ======================= Cập nhật từng người =======================

func _update(v: Dictionary, dt: float, minutes: float) -> void:
	var block := _block_for(v["def"]["role"], hour())
	if block != v["block"]:
		_enter_block(v, block)
	if not (v["path"] as Array).is_empty():
		_move(v, dt)
		return
	v["walking"] = false
	match block:
		"sleep":
			v["visible"] = false
			v["activity"] = "Ngủ"
			v["tool"] = ""
		"home":
			v["visible"] = true
			v["activity"] = "Nghỉ ở nhà"
			v["tool"] = ""
			v["facing"] = Vector2(0, float(v["def"].get("door", 1)))
		"field":
			_do_field(v, minutes)
		"stall":
			_do_stall(v, minutes)
		"fish":
			_do_fish(v, minutes)
		"market":
			_do_market(v)
		"yard":
			_do_yard(v, minutes)
		"rest":
			v["activity"] = "Hóng mát bên giếng"
			v["tool"] = ""
			v["facing"] = Vector2(0, 1)
		"play":
			_do_play(v, minutes)


func _enter_block(v: Dictionary, block: String) -> void:
	v["block"] = block
	v["work"] = 0.0
	v["wait"] = 0.0
	v["task"] = ""
	v["delivered"] = false
	v["visible"] = true
	_go(v, _block_spot(v, block))
	_set_idle_label(v)


func _set_idle_label(v: Dictionary) -> void:
	var block: String = v["block"]
	v["tool"] = ""
	match block:
		"sleep":
			v["activity"] = "Ngủ" if not v["walking"] else "Về nhà ngủ"
		"home":
			v["activity"] = "Về nhà"
		"field":
			v["activity"] = "Ra đồng"
		"stall":
			v["activity"] = "Ra chợ bán hàng"
		"fish":
			v["activity"] = "Đi câu cá"
		"market":
			v["activity"] = "Ra chợ"
		"yard":
			v["activity"] = "Ra chuồng gà"
		"rest":
			v["activity"] = "Ra giếng làng"
		"play":
			v["activity"] = "Chạy nhảy"


## Tìm đường: đi gần thì đi thẳng, đi xa thì ra đường làng rồi mới rẽ vào.
func _go(v: Dictionary, target: Vector2) -> void:
	var p: Vector2 = v["pos"]
	var path: Array = []
	if p.distance_to(target) > 5.0:
		var a := Vector2(p.x, VD.ROAD_Z)
		var b := Vector2(target.x, VD.ROAD_Z)
		if p.distance_to(a) > 0.3:
			path.append(a)
		if a.distance_to(b) > 0.3:
			path.append(b)
	if p.distance_to(target) > 0.05:
		path.append(target)
	v["path"] = path


func _move(v: Dictionary, dt: float) -> void:
	var speed: float = VD.KID_SPEED if v["def"]["role"] == "kid" else VD.WALK_SPEED
	var remaining := speed * dt
	var path: Array = v["path"]
	v["walking"] = true
	v["visible"] = true
	while remaining > 0.0 and not path.is_empty():
		var tgt: Vector2 = path[0]
		var d: Vector2 = tgt - v["pos"]
		var dist := d.length()
		if dist > 0.001:
			v["facing"] = d / dist
		if dist <= remaining:
			v["pos"] = tgt
			path.pop_front()
			remaining -= dist
		else:
			v["pos"] = v["pos"] + d / dist * remaining
			remaining = 0.0
	if path.is_empty():
		v["walking"] = false


func _carry_total(v: Dictionary) -> int:
	var n := 0
	for k in v["carry"]:
		n += int(v["carry"][k])
	return n


func _carry_add(v: Dictionary, item: String, qty: int) -> void:
	v["carry"][item] = int(v["carry"].get(item, 0)) + qty


## Bán hết hàng đang mang cho chợ.
func _deliver(v: Dictionary) -> void:
	var carry: Dictionary = v["carry"]
	if carry.is_empty():
		return
	var parts: Array[String] = []
	for item in carry:
		var qty := int(carry[item])
		GameRules.market_add(state, item, qty)
		parts.append("%d %s" % [qty, GameData.item_name(item).to_lower()])
	GameRules.add_log(state, "%s mang %s ra chợ bán." % [v["def"]["name"], ", ".join(parts)])
	carry.clear()


# ======================= Từng nghề =======================

## Bác Ba: cày → cấy → dẫn nước → (lúa tự lớn) → gặt → gánh ra chợ.
func _do_field(v: Dictionary, minutes: float) -> void:
	v["visible"] = true
	if v["task"] == "deliver":
		_deliver(v)
		v["task"] = ""
		return
	if v["task"] == "":
		if _carry_total(v) >= 6:
			v["task"] = "deliver"
			v["activity"] = "Gánh lúa ra chợ"
			v["tool"] = "basket"
			_go(v, VD.SPOTS["market_customer"])
			return
		var pick := _pick_paddy()
		if pick < 0:
			v["activity"] = "Thăm đồng"
			v["tool"] = ""
			v["facing"] = Vector2(0, -1)
			return
		v["task_plot"] = pick
		v["task"] = paddy_task(state.paddies[pick])
		v["work"] = 0.0
		v["activity"] = "Ra thửa ruộng %d" % (pick + 1)
		_go(v, paddy_stand(pick))
		return
	var p: Dictionary = state.paddies[v["task_plot"]]
	if paddy_task(p) != v["task"]:
		v["task"] = ""
		return
	v["work"] = float(v["work"]) + minutes
	v["activity"] = VD.TASK_LABEL[v["task"]]
	v["tool"] = VD.TASK_TOOL[v["task"]]
	v["facing"] = Vector2(0, -1)
	if float(v["work"]) >= float(VD.TASK_MINUTES[v["task"]]):
		_finish_paddy(v, p, int(v["task_plot"]))
		v["task"] = ""


static func paddy_task(p: Dictionary) -> String:
	match p["stage"]:
		"bare":
			return "plow"
		"plowed":
			return "sow"
		"planted":
			return "water"
		"ripe":
			return "harvest"
	return ""


static func paddy_stand(i: int) -> Vector2:
	return VD.PADDY_CENTERS[i] + Vector2(0, 1.35)


## Ưu tiên gặt lúa chín; nếu không thì làm tiếp thửa đầu tiên còn việc.
func _pick_paddy() -> int:
	for i in state.paddies.size():
		if state.paddies[i]["stage"] == "ripe":
			return i
	for i in state.paddies.size():
		if paddy_task(state.paddies[i]) != "":
			return i
	return -1


func _finish_paddy(v: Dictionary, p: Dictionary, i: int) -> void:
	var who: String = v["def"]["name"]
	match v["task"]:
		"plow":
			p["stage"] = "plowed"
			GameRules.add_log(state, "%s cày xong thửa ruộng %d." % [who, i + 1])
		"sow":
			p["stage"] = "planted"
			GameRules.add_log(state, "%s cấy mạ thửa %d." % [who, i + 1])
		"water":
			p["stage"] = "growing"
			p["grow"] = 0.0
			GameRules.add_log(state, "%s dẫn nước vào thửa %d." % [who, i + 1])
		"harvest":
			p["stage"] = "bare"
			p["grow"] = 0.0
			_carry_add(v, "produce_rice", VD.PADDY_YIELD)
			GameRules.add_log(state, "%s gặt được %d bao lúa." % [who, VD.PADDY_YIELD])


func _grow_paddies(minutes: float) -> void:
	for p in state.paddies:
		if p["stage"] == "growing":
			p["grow"] = float(p["grow"]) + minutes
			if float(p["grow"]) >= VD.PADDY_GROW_MINUTES:
				p["stage"] = "ripe"


## Cô Lan: mỗi giờ bán cho khách vài món đang tồn nhiều nhất ở chợ.
func _do_stall(v: Dictionary, minutes: float) -> void:
	v["activity"] = "Bán hàng"
	v["tool"] = "basket"
	v["facing"] = Vector2(0, 1)
	v["work"] = float(v["work"]) + minutes
	if float(v["work"]) >= 60.0:
		v["work"] = float(v["work"]) - 60.0
		_sell_to_customers(v["def"]["name"])


func _sell_to_customers(seller: String) -> void:
	var best := ""
	var best_n := 0
	for item in state.market_stock:
		var n := int(state.market_stock[item])
		if n > best_n:
			best = item
			best_n = n
	if best == "":
		return
	var want: int = 1 + (int(state.day) + int(state.clock / 60.0)) % 3
	var sold := GameRules.market_take(state, best, want)
	if sold > 0 and seller != "":
		GameRules.add_log(state, "%s bán %d %s cho khách." % [seller, sold, GameData.item_name(best).to_lower()])


## Chú Tư: ngồi câu ở ao làng, khoảng 75 phút được 1–2 con cá rô.
func _do_fish(v: Dictionary, minutes: float) -> void:
	v["activity"] = "Câu cá"
	v["tool"] = "rod"
	v["facing"] = Vector2(0, 1)
	v["work"] = float(v["work"]) + minutes
	if float(v["work"]) >= 75.0:
		v["work"] = float(v["work"]) - 75.0
		var caught: int = 1 + (int(state.day) + int(v["idx"])) % 2
		v["idx"] = int(v["idx"]) + 1
		_carry_add(v, "fish_ro", caught)
		GameRules.add_log(state, "%s câu được %d con cá rô." % [v["def"]["name"], caught])


func _do_market(v: Dictionary) -> void:
	if not v["delivered"]:
		_deliver(v)
		v["delivered"] = true
	v["activity"] = "Trò chuyện ở chợ"
	v["tool"] = ""
	v["facing"] = Vector2(0, 1)


## Bà Năm: cho gà ăn; buổi sáng nhặt trứng một lần mỗi ngày.
func _do_yard(v: Dictionary, minutes: float) -> void:
	v["activity"] = "Cho gà ăn"
	v["tool"] = "basket"
	v["facing"] = Vector2(0, 1)
	v["work"] = float(v["work"]) + minutes
	if float(v["work"]) >= 90.0 and int(v["egg_day"]) != state.day and hour() < 12.0:
		v["egg_day"] = state.day
		_carry_add(v, "egg", 3)
		GameRules.add_log(state, "%s nhặt được 3 quả trứng gà." % v["def"]["name"])


## Trẻ con: chạy từ chỗ chơi này sang chỗ khác, mỗi chỗ chơi khoảng 40 phút.
func _do_play(v: Dictionary, minutes: float) -> void:
	v["activity"] = "Chơi đùa"
	v["tool"] = ""
	v["wait"] = float(v["wait"]) + minutes
	if float(v["wait"]) >= 40.0:
		v["wait"] = 0.0
		v["idx"] = (int(v["idx"]) + 1) % VD.PLAY_SPOTS.size()
		v["activity"] = "Chạy nhảy"
		_go(v, VD.PLAY_SPOTS[v["idx"]])


## Lời chào khi người chơi bắt chuyện.
func talk(v: Dictionary) -> String:
	var role: String = v["def"]["role"]
	var lines: Array = VD.TALK.get(role, ["Chào cháu!"])
	var line: String = lines[(state.day + int(state.clock / 30.0)) % lines.size()]
	if line.contains("%s"):
		line = line % GameData.item_name(GameRules.demand_item(state.day)).to_lower()
	if v["block"] == "sleep":
		return "Khò... khò..."
	return line
