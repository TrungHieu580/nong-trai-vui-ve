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


# ================= Ruộng (thời gian thực) =================

static func now() -> float:
	return Time.get_unix_time_from_system()


static func is_watered(plot: Dictionary) -> bool:
	return plot["crop"] != "" and float(plot["watered_at"]) > 0.0


## Tỷ lệ lớn 0..1. Chưa tưới thì 0.
static func growth_fraction(plot: Dictionary, t: float) -> float:
	if not is_watered(plot):
		return 0.0
	var total := float(GameData.CROPS[plot["crop"]]["seconds"])
	return clampf((t - float(plot["watered_at"])) / total, 0.0, 1.0)


## Số giây còn lại tới khi chín (0 nếu đã chín hoặc chưa tưới).
static func seconds_left(plot: Dictionary, t: float) -> float:
	if not is_watered(plot):
		return 0.0
	var total := float(GameData.CROPS[plot["crop"]]["seconds"])
	return maxf(0.0, float(plot["watered_at"]) + total - t)


static func is_ripe(plot: Dictionary, t: float) -> bool:
	return is_watered(plot) and growth_fraction(plot, t) >= 1.0


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
	plot["watered_at"] = 0.0
	return _ok("Đã gieo %s. Nhớ tưới nhé!" % GameData.CROPS[crop_id]["name"])


## Tưới một lần: cây bắt đầu lớn từ thời điểm `t`.
static func water(s, i: int, t: float) -> Dictionary:
	if i < 0 or i >= s.plots.size():
		return _fail("Ô ruộng không hợp lệ.")
	var plot: Dictionary = s.plots[i]
	if plot["crop"] == "":
		return _fail("Ô trống, chưa cần tưới.")
	if is_watered(plot):
		if is_ripe(plot, t):
			return _fail("Cây đã chín, hãy thu hoạch.")
		return _fail("Đã tưới rồi, cây đang lớn.")
	plot["watered_at"] = t
	var def: Dictionary = GameData.CROPS[plot["crop"]]
	return _ok("Đã tưới %s. Chín sau %s." % [def["name"], GameData.fmt_duration(int(def["seconds"]))])


static func harvest(s, i: int, t: float) -> Dictionary:
	if i < 0 or i >= s.plots.size():
		return _fail("Ô ruộng không hợp lệ.")
	var plot: Dictionary = s.plots[i]
	if not is_ripe(plot, t):
		return _fail("Cây chưa chín.")
	var crop_id: String = plot["crop"]
	var def: Dictionary = GameData.CROPS[crop_id]
	var product := "produce_" + crop_id
	s.add_item(product, int(def["yield"]))
	s.plots[i] = _empty_plot()
	return _ok("Thu được %d %s." % [def["yield"], GameData.item_name(product).to_lower()])


static func _empty_plot() -> Dictionary:
	return {"crop": "", "watered_at": 0.0}


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


# ================= Giá chợ biến động =================

## Hàng nông sản/chăn nuôi có giá theo cung cầu; hạt giống, thức ăn thì giá cố định.
static func is_market_good(item_id: String) -> bool:
	return item_id.begins_with("produce_") or item_id in ["egg", "fish_ro", "milk"]


static func demand_item(day: int) -> String:
	return GameData.DEMAND_LIST[day % GameData.DEMAND_LIST.size()]


## Giá chợ đang trả cho một món: giảm theo hàng tồn, tăng nếu là món chợ đang cần.
static func market_price(s, item_id: String) -> int:
	var base := GameData.sell_price(item_id)
	if base <= 0 or not is_market_good(item_id):
		return base
	var stock := int(s.market_stock.get(item_id, 0))
	var f := clampf(1.0 - GameData.STOCK_PRICE_DROP * stock, GameData.MIN_PRICE_FACTOR, 1.0)
	if item_id == demand_item(s.day):
		f *= GameData.DEMAND_BONUS
	return maxi(1, roundi(base * f))


## Đưa hàng lên chợ (dân làng hoặc người chơi bán) → hàng tồn tăng, giá giảm.
static func market_add(s, item_id: String, qty: int) -> void:
	if qty > 0 and is_market_good(item_id):
		s.market_stock[item_id] = int(s.market_stock.get(item_id, 0)) + qty


## Khách mua bớt hàng ở chợ → hàng tồn giảm, giá hồi lại. Trả về số đã bán.
static func market_take(s, item_id: String, qty: int) -> int:
	var have := int(s.market_stock.get(item_id, 0))
	var n := mini(have, qty)
	if n <= 0:
		return 0
	if have - n <= 0:
		s.market_stock.erase(item_id)
	else:
		s.market_stock[item_id] = have - n
	return n


## Ghi một dòng vào bảng tin làng (giữ 30 dòng gần nhất).
static func add_log(s, text: String) -> void:
	var m := int(s.clock)
	s.village_log.append("%02d:%02d %s" % [m / 60, m % 60, text])
	while s.village_log.size() > 30:
		s.village_log.pop_front()


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
	var price := market_price(s, item_id)
	if price <= 0:
		return _fail("Chợ không mua %s." % GameData.item_name(item_id))
	if s.count(item_id) < qty:
		return _fail("Chỉ có %d %s." % [s.count(item_id), GameData.item_name(item_id)])
	var total: int = price * qty
	s.remove_item(item_id, qty)
	s.coins += total
	market_add(s, item_id, qty)
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
	var products: Array[String] = []
	var cared: Array[String] = []
	# Cây trồng lớn theo thời gian thực nên không đổi khi ngủ.

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
	if products.size() > 0:
		lines.append("Sản phẩm mới: " + ", ".join(products) + ".")
	if cared.size() > 0:
		lines.append("Đã được chăm: " + ", ".join(cared) + ".")
	if products.is_empty() and cared.is_empty():
		lines.append("Vật nuôi lớn qua đêm khi được cho ăn. Cây trồng thì lớn theo đồng hồ, không cần ngủ.")
	return {"ok": true, "state": n, "msg": "\n".join(lines)}
