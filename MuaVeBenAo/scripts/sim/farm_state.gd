extends RefCounted
## Toàn bộ trạng thái mô phỏng của một lượt chơi. Không chứa luật chơi.

const GameData = preload("res://scripts/sim/game_data.gd")

var day: int
var coins: int
var inventory: Dictionary
var plots: Array
var buildings: Dictionary
var pond: Dictionary
var animals: Dictionary
var free_seed_day: int
var player_pos: Vector2
var tutorial_step: int
var tutorial_closed: bool


func _init() -> void:
	reset()


func reset() -> void:
	day = 1
	coins = GameData.START_COINS
	inventory = {}
	for k in GameData.START_INVENTORY:
		inventory[k] = int(GameData.START_INVENTORY[k])
	plots = []
	for i in GameData.PLOT_COUNT:
		plots.append(empty_plot())
	buildings = {}
	for b in GameData.BUILDING_ORDER:
		buildings[b] = false
	pond = empty_pond()
	animals = {}
	for a in GameData.ANIMALS:
		animals[a] = empty_animal()
	free_seed_day = 0
	player_pos = Vector2(-6.0, -1.0)
	tutorial_step = 0
	tutorial_closed = false


static func empty_plot() -> Dictionary:
	return {"crop": "", "growth": 0, "watered": false}


static func empty_pond() -> Dictionary:
	return {"stocked": false, "growth": 0, "fed": false}


static func empty_animal() -> Dictionary:
	return {"progress": 0, "fed": false, "ready": false}


# ---------- Túi đồ ----------

func count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func add_item(item_id: String, qty: int) -> void:
	inventory[item_id] = count(item_id) + qty


func remove_item(item_id: String, qty: int) -> bool:
	var have := count(item_id)
	if qty <= 0 or have < qty:
		return false
	if have == qty:
		inventory.erase(item_id)
	else:
		inventory[item_id] = have - qty
	return true


func is_inventory_empty() -> bool:
	for k in inventory:
		if int(inventory[k]) > 0:
			return false
	return true


# ---------- Sao chép / tuần tự hoá ----------

func duplicate_state():
	var copy = get_script().new()
	copy.load_dict(to_dict())
	return copy


func to_dict() -> Dictionary:
	return {
		"schemaVersion": GameData.SCHEMA_VERSION,
		"day": day,
		"coins": coins,
		"inventory": inventory.duplicate(true),
		"plots": plots.duplicate(true),
		"buildings": buildings.duplicate(true),
		"pond": pond.duplicate(true),
		"animals": animals.duplicate(true),
		"freeSeedDay": free_seed_day,
		"player": {"x": player_pos.x, "z": player_pos.y},
		"tutorialStep": tutorial_step,
		"tutorialClosed": tutorial_closed,
	}


static func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


static func _n(v, fallback: int = 0) -> int:
	if _is_num(v):
		return int(v)
	return fallback


## Nạp dữ liệu từ bản lưu. Trả về "" nếu hợp lệ, ngược lại trả về lý do lỗi
## và giữ nguyên trạng thái hiện tại.
func load_dict(d) -> String:
	if typeof(d) != TYPE_DICTIONARY:
		return "Tệp lưu không đúng định dạng."
	var ver = d.get("schemaVersion")
	if not _is_num(ver):
		return "Tệp lưu thiếu schemaVersion."
	if int(ver) != GameData.SCHEMA_VERSION:
		return "Phiên bản lưu %d chưa được hỗ trợ (cần %d)." % [int(ver), GameData.SCHEMA_VERSION]
	if not _is_num(d.get("day")) or int(d["day"]) < 1:
		return "Ngày trong tệp lưu không hợp lệ."
	if not _is_num(d.get("coins")) or int(d["coins"]) < 0:
		return "Số xu trong tệp lưu không hợp lệ."

	var inv_src = d.get("inventory")
	if typeof(inv_src) != TYPE_DICTIONARY:
		return "Túi đồ trong tệp lưu không hợp lệ."
	var new_inv := {}
	for k in inv_src:
		if not GameData.ITEMS.has(k) or not _is_num(inv_src[k]) or int(inv_src[k]) < 0:
			return "Túi đồ có vật phẩm không hợp lệ: %s." % str(k)
		if int(inv_src[k]) > 0:
			new_inv[str(k)] = int(inv_src[k])

	var plots_src = d.get("plots")
	if typeof(plots_src) != TYPE_ARRAY or plots_src.size() != GameData.PLOT_COUNT:
		return "Dữ liệu ruộng không hợp lệ."
	var new_plots := []
	for p in plots_src:
		if typeof(p) != TYPE_DICTIONARY:
			return "Dữ liệu ô ruộng không hợp lệ."
		var crop := str(p.get("crop", ""))
		if crop != "" and not GameData.CROPS.has(crop):
			return "Ô ruộng có cây lạ: %s." % crop
		new_plots.append({
			"crop": crop,
			"growth": maxi(0, _n(p.get("growth"))),
			"watered": bool(p.get("watered", false)),
		})

	var b_src = d.get("buildings")
	if typeof(b_src) != TYPE_DICTIONARY:
		return "Dữ liệu công trình không hợp lệ."
	var new_buildings := {}
	for b in GameData.BUILDING_ORDER:
		new_buildings[b] = bool(b_src.get(b, false))

	var pond_src = d.get("pond")
	if typeof(pond_src) != TYPE_DICTIONARY:
		return "Dữ liệu ao không hợp lệ."
	var new_pond := {
		"stocked": bool(pond_src.get("stocked", false)),
		"growth": maxi(0, _n(pond_src.get("growth"))),
		"fed": bool(pond_src.get("fed", false)),
	}

	var a_src = d.get("animals")
	if typeof(a_src) != TYPE_DICTIONARY:
		return "Dữ liệu vật nuôi không hợp lệ."
	var new_animals := {}
	for a in GameData.ANIMALS:
		var src = a_src.get(a, {})
		if typeof(src) != TYPE_DICTIONARY:
			return "Dữ liệu vật nuôi không hợp lệ."
		new_animals[a] = {
			"progress": maxi(0, _n(src.get("progress"))),
			"fed": bool(src.get("fed", false)),
			"ready": bool(src.get("ready", false)),
		}

	var pl = d.get("player", {})
	var pos := Vector2(-6.0, -1.0)
	if typeof(pl) == TYPE_DICTIONARY and _is_num(pl.get("x")) and _is_num(pl.get("z")):
		pos = Vector2(float(pl["x"]), float(pl["z"]))

	# Mọi thứ hợp lệ – lúc này mới ghi vào trạng thái.
	day = int(d["day"])
	coins = int(d["coins"])
	inventory = new_inv
	plots = new_plots
	buildings = new_buildings
	pond = new_pond
	animals = new_animals
	free_seed_day = _n(d.get("freeSeedDay"))
	player_pos = pos
	tutorial_step = clampi(_n(d.get("tutorialStep")), 0, GameData.TUTORIAL.size())
	tutorial_closed = bool(d.get("tutorialClosed", false))
	return ""
