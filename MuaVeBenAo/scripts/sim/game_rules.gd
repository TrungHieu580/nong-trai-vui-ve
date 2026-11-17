extends RefCounted
## Lớp luật chơi chung. Mọi thao tác kiểm tra đủ điều kiện TRƯỚC khi trừ tiền
## hoặc vật phẩm. Mỗi hàm trả về {"ok": bool, "msg": String}.

const GameData = preload("res://scripts/sim/game_data.gd")


static func _ok(msg: String) -> Dictionary:
	return {"ok": true, "msg": msg}


static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}


static func _valid_qty(qty) -> bool:
	return typeof(qty) == TYPE_INT and qty > 0


# ================= Ruộng =================

static func is_ripe(plot: Dictionary) -> bool:
	if plot["crop"] == "":
		return false
	return int(plot["growth"]) >= int(GameData.CROPS[plot["crop"]]["nights"])


static func sow(s, i: int, seed_id: String) -> Dictionary:
	if i < 0 or i >= s.plots.size():
		return _fail("Ô ruộng không hợp lệ.")
	var plot: Dictionary = s.plots[i]
	if plot["crop"] != "":
		return _fail("Ô này đã có cây.")
	if not GameData.SEED_TO_CROP.has(seed_id):
		return _fail("Đây không phải hạt giống.")
	if s.count(seed_id) <= 0:
		return _fail("Hết %s. Mua thêm ở quầy chợ." % GameData.item_name(seed_id))
	s.remove_item(seed_id, 1)
	var crop_id: String = GameData.SEED_TO_CROP[seed_id]
	plot["crop"] = crop_id
	plot["growth"] = 0
	plot["watered"] = false
	return _ok("Đã gieo %s. Nhớ tưới nhé!" % GameData.CROPS[crop_id]["name"])


static func water(s, i: int) -> Dictionary:
	if i < 0 or i >= s.plots.size():
		return _fail("Ô ruộng không hợp lệ.")
	var plot: Dictionary = s.plots[i]
	if plot["crop"] == "":
		return _fail("Ô trống, chưa cần tưới.")
	if is_ripe(plot):
		return _fail("Cây đã chín, hãy thu hoạch.")
	if plot["watered"]:
		return _fail("Ô này đã được tưới hôm nay.")
	plot["watered"] = true
	return _ok("Đã tưới %s." % GameData.CROPS[plot["crop"]]["name"])


static func harvest(s, i: int) -> Dictionary:
	if i < 0 or i >= s.plots.size():
		return _fail("Ô ruộng không hợp lệ.")
	var plot: Dictionary = s.plots[i]
	if not is_ripe(plot):
		return _fail("Cây chưa chín.")
	var def: Dictionary = GameData.CROPS[plot["crop"]]
	s.add_item(def["product"], int(def["yield"]))
	s.plots[i] = _empty_plot()
	return _ok("Thu được %d %s." % [def["yield"], GameData.item_name(def["product"]).to_lower()])


static func _empty_plot() -> Dictionary:
	return {"crop": "", "growth": 0, "watered": false}


# ================= Gà / bò =================

static func feed_animal(s, animal_id: String) -> Dictionary:
	if not GameData.ANIMALS.has(animal_id):
		return _fail("Không có vật nuôi này.")
	var def: Dictionary = GameData.ANIMALS[animal_id]
	if not s.buildings[def["building"]]:
		return _fail("Chưa có %s." % GameData.BUILDINGS[def["building"]]["name"].to_lower())
	var a: Dictionary = s.animals[animal_id]
	if a["ready"]:
		return _fail("Hãy thu %s trước." % GameData.item_name(def["product"]).to_lower())
	if a["fed"]:
		return _fail("%s đã ăn hôm nay." % def["name"])
	if s.count(def["feed"]) <= 0:
		return _fail("Hết %s. Mua ở quầy chợ." % GameData.item_name(def["feed"]))
	s.remove_item(def["feed"], 1)
	a["fed"] = true
	return _ok("Đã cho %s ăn." % def["name"].to_lower())


static func collect_animal(s, animal_id: String) -> Dictionary:
	if not GameData.ANIMALS.has(animal_id):
		return _fail("Không có vật nuôi này.")
	var def: Dictionary = GameData.ANIMALS[animal_id]
	var a: Dictionary = s.animals[animal_id]
	if not s.buildings[def["building"]] or not a["ready"]:
		return _fail("Chưa có sản phẩm để thu.")
	s.add_item(def["product"], 1)
	a["ready"] = false
	a["progress"] = 0
	return _ok("Thu được 1 %s." % GameData.item_name(def["product"]).to_lower())


# ================= Ao cá =================

static func pond_ready(s) -> bool:
	return s.pond["stocked"] and int(s.pond["growth"]) >= int(GameData.POND["nights"])


static func stock_pond(s) -> Dictionary:
	if not s.buildings["pond"]:
		return _fail("Chưa có ao cá.")
	if s.pond["stocked"]:
		return _fail("Ao đang nuôi một lứa cá.")
	if s.count(GameData.POND["fry"]) <= 0:
		return _fail("Cần %s. Mua ở quầy chợ." % GameData.item_name(GameData.POND["fry"]))
	s.remove_item(GameData.POND["fry"], 1)
	s.pond["stocked"] = true
	s.pond["growth"] = 0
	s.pond["fed"] = false
	return _ok("Đã thả cá giống xuống ao.")


static func feed_pond(s) -> Dictionary:
	if not s.buildings["pond"]:
		return _fail("Chưa có ao cá.")
	if not s.pond["stocked"]:
		return _fail("Ao trống, hãy thả cá giống trước.")
	if pond_ready(s):
		return _fail("Cá đã lớn, hãy thu cá.")
	if s.pond["fed"]:
		return _fail("Cá đã ăn hôm nay.")
	if s.count(GameData.POND["feed"]) <= 0:
		return _fail("Hết %s. Mua ở quầy chợ." % GameData.item_name(GameData.POND["feed"]))
	s.remove_item(GameData.POND["feed"], 1)
	s.pond["fed"] = true
	return _ok("Đã cho cá ăn. Mặt ao gợn sóng.")


static func harvest_pond(s) -> Dictionary:
	if not pond_ready(s):
		return _fail("Cá chưa đủ lớn.")
	s.add_item(GameData.POND["product"], int(GameData.POND["yield"]))
	s.pond["stocked"] = false
	s.pond["growth"] = 0
	s.pond["fed"] = false
	return _ok("Thu được %d %s." % [GameData.POND["yield"], GameData.item_name(GameData.POND["product"]).to_lower()])


# ================= Chợ =================

static func buy(s, item_id: String, qty) -> Dictionary:
	if not _valid_qty(qty):
		return _fail("Số lượng phải là số nguyên dương.")
	var price := GameData.buy_price(item_id)
	if price <= 0:
		return _fail("Chợ không bán %s." % GameData.item_name(item_id))
	var total: int = price * qty
	if total > s.coins:
		return _fail("Không đủ xu: cần %d, đang có %d." % [total, s.coins])
	s.coins -= total
	s.add_item(item_id, qty)
	return _ok("Đã mua %d %s (−%d xu)." % [qty, GameData.item_name(item_id), total])


static func sell(s, item_id: String, qty) -> Dictionary:
	if not _valid_qty(qty):
		return _fail("Số lượng phải là số nguyên dương.")
	var price := GameData.sell_price(item_id)
	if price <= 0:
		return _fail("Chợ không mua %s." % GameData.item_name(item_id))
	if s.count(item_id) < qty:
		return _fail("Chỉ có %d %s." % [s.count(item_id), GameData.item_name(item_id)])
	var total: int = price * qty
	s.remove_item(item_id, qty)
	s.coins += total
	return _ok("Đã bán %d %s (+%d xu)." % [qty, GameData.item_name(item_id), total])


## Trả về "" nếu mua được, ngược lại là lý do.
static func building_block_reason(s, building_id: String) -> String:
	if not GameData.BUILDINGS.has(building_id):
		return "Không có công trình này."
	var def: Dictionary = GameData.BUILDINGS[building_id]
	if s.buildings[building_id]:
		return "Đã có."
	var req: String = def["requires"]
	if req != "" and not s.buildings[req]:
		return "Cần mở %s trước." % GameData.BUILDINGS[req]["name"].to_lower()
	if s.coins < int(def["price"]):
		return "Cần %d xu." % def["price"]
	return ""


static func buy_building(s, building_id: String) -> Dictionary:
	var reason := building_block_reason(s, building_id)
	if reason != "":
		return _fail(reason)
	var def: Dictionary = GameData.BUILDINGS[building_id]
	s.coins -= int(def["price"])
	s.buildings[building_id] = true
	if building_id == "pond":
		s.pond = {"stocked": false, "growth": 0, "fed": false}
	for a in GameData.ANIMALS:
		if GameData.ANIMALS[a]["building"] == building_id:
			s.animals[a] = {"progress": 0, "fed": false, "ready": false}
	return _ok("Đã mở %s!" % def["name"].to_lower())


# ================= Phục hồi vốn =================

static func free_seed_block_reason(s) -> String:
	if s.coins >= GameData.FREE_SEED_COIN_LIMIT:
		return "Chỉ nhận khi có dưới %d xu." % GameData.FREE_SEED_COIN_LIMIT
	if not s.is_inventory_empty():
		return "Túi phải trống (có thể bán bớt đồ trước)."
	for plot in s.plots:
		if plot["crop"] != "":
			return "Ruộng phải trống."
	if pond_ready(s):
		return "Ao còn cá chờ thu."
	for a in GameData.ANIMALS:
		if s.buildings[GameData.ANIMALS[a]["building"]] and s.animals[a]["ready"]:
			return "Còn sản phẩm chờ thu ở chuồng."
	if s.free_seed_day == s.day:
		return "Hôm nay đã nhận rồi."
	return ""


static func claim_free_seed(s) -> Dictionary:
	var reason := free_seed_block_reason(s)
	if reason != "":
		return _fail(reason)
	s.add_item(GameData.FREE_SEED_ITEM, 1)
	s.free_seed_day = s.day
	return _ok("Bà bán hàng tặng bạn 1 hạt cải. Cố lên nhé!")


# ================= Chuyển ngày =================

## Tính ngày tiếp theo trên BẢN SAO. Trạng thái gốc không đổi.
## Trả về {"ok", "state": trạng thái mới, "msg": tóm tắt}.
static func sleep(s) -> Dictionary:
	var n = s.duplicate_state()
	var grown := 0
	var ripened := 0
	var products: Array[String] = []
	var cared: Array[String] = []

	for plot in n.plots:
		if plot["crop"] != "" and not is_ripe(plot) and plot["watered"]:
			plot["growth"] = int(plot["growth"]) + 1
			grown += 1
			if is_ripe(plot):
				ripened += 1
		plot["watered"] = false

	if n.buildings["pond"] and n.pond["stocked"] and n.pond["fed"] and not pond_ready(n):
		n.pond["growth"] = int(n.pond["growth"]) + 1
		cared.append(GameData.POND["name"])
		if pond_ready(n):
			products.append("%d %s" % [GameData.POND["yield"], GameData.item_name(GameData.POND["product"]).to_lower()])
	n.pond["fed"] = false

	for animal_id in GameData.ANIMALS:
		var def: Dictionary = GameData.ANIMALS[animal_id]
		var a: Dictionary = n.animals[animal_id]
		if n.buildings[def["building"]] and a["fed"] and not a["ready"]:
			a["progress"] = int(a["progress"]) + 1
			cared.append(def["name"])
			if int(a["progress"]) >= int(def["nights"]):
				a["ready"] = true
				products.append("1 " + GameData.item_name(def["product"]).to_lower())
		a["fed"] = false

	n.day += 1

	var lines: Array[String] = ["Ngày %d bắt đầu." % n.day]
	if grown > 0:
		lines.append("Cây lớn thêm: %d ô (%d ô đã chín)." % [grown, ripened])
	else:
		lines.append("Không ô ruộng nào lớn thêm – nhớ tưới trước khi ngủ.")
	if products.size() > 0:
		lines.append("Sản phẩm mới: " + ", ".join(products) + ".")
	if cared.size() > 0:
		lines.append("Đã được chăm: " + ", ".join(cared) + ".")
	return {"ok": true, "state": n, "msg": "\n".join(lines)}
