extends SceneTree
## Bộ kiểm thử mô phỏng.
## Chạy:  godot --headless --path . -s res://tests/run_tests.gd
## Mã thoát 0 = tất cả đạt.

const GameData = preload("res://scripts/sim/game_data.gd")
const FarmState = preload("res://scripts/sim/farm_state.gd")
const GameRules = preload("res://scripts/sim/game_rules.gd")
const SaveSystem = preload("res://scripts/sim/save_system.gd")
const VillageSim = preload("res://scripts/sim/village_sim.gd")
const VD = preload("res://scripts/sim/village_data.gd")

## Mốc thời gian giả cho kiểm thử (không phải chờ thật).
const T0 := 1_800_000_000.0

var _passed := 0
var _failed := 0
var _current := ""


func _init() -> void:
	var tests := [
		"test_crop_realtime_cycle",
		"test_all_crops_data",
		"test_all_crops_grow",
		"test_market",
		"test_buildings",
		"test_pond",
		"test_chicken",
		"test_cow",
		"test_sleep_does_not_mutate",
		"test_save_load",
		"test_migrate_v1_save",
		"test_starter_economy",
		"test_recovery",
		"test_free_seed_not_exploitable",
		"test_market_dynamic_price",
		"test_village_three_days",
		"test_village_save_roundtrip",
	]
	for t in tests:
		_current = t
		var before := _failed
		call(t)
		print(("  OK   " if _failed == before else "  LỖI ") + t)
	print("")
	print("Kết quả: %d kiểm tra đạt, %d lỗi." % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		printerr("    ✗ [%s] %s" % [_current, label])


func eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("    ✗ [%s] %s: nhận %s, mong đợi %s" % [_current, label, str(actual), str(expected)])


func ok(r: Dictionary, label: String) -> void:
	check(r["ok"], "%s (%s)" % [label, r["msg"]])


func no(r: Dictionary, label: String) -> void:
	check(not r["ok"], label)


func night(s):
	return GameRules.sleep(s)["state"]


func rich_state():
	var s = FarmState.new()
	s.coins = 100000
	return s


# ================= Trồng trọt theo thời gian thực =================

func test_crop_realtime_cycle() -> void:
	var s = FarmState.new()
	var before: int = s.count("seed_leafy_greens")
	ok(GameRules.sow(s, 0, "seed_leafy_greens"), "gieo cải")
	eq(s.count("seed_leafy_greens"), before - 1, "gieo trừ đúng một hạt")
	no(GameRules.sow(s, 0, "seed_leafy_greens"), "không gieo đè ô đã có cây")
	eq(s.count("seed_leafy_greens"), before - 1, "gieo lỗi không trừ hạt")
	no(GameRules.water(s, 1, T0), "không tưới ô trống")

	check(not GameRules.is_ripe(s.plots[0], T0 + 999999.0), "chưa tưới thì không bao giờ chín")
	ok(GameRules.water(s, 0, T0), "tưới")
	no(GameRules.water(s, 0, T0 + 5.0), "không tưới hai lần")
	check(absf(GameRules.growth_fraction(s.plots[0], T0 + 30.0) - 0.5) < 0.001, "30 giây = lớn một nửa")
	eq(int(GameRules.seconds_left(s.plots[0], T0 + 45.0)), 15, "còn 15 giây")
	check(not GameRules.is_ripe(s.plots[0], T0 + 59.0), "59 giây chưa chín")
	no(GameRules.harvest(s, 0, T0 + 59.0), "chưa chín thì không thu")
	check(GameRules.is_ripe(s.plots[0], T0 + 60.0), "60 giây thì chín")
	ok(GameRules.harvest(s, 0, T0 + 60.0), "thu cải")
	eq(s.count("produce_leafy_greens"), 2, "thu đúng hai cải")
	no(GameRules.harvest(s, 0, T0 + 61.0), "bấm thu lần hai bị chặn")
	eq(s.count("produce_leafy_greens"), 2, "thu hai lần chỉ nhận một lần")
	eq(s.plots[0]["crop"], "", "ô trống sau thu")


func test_all_crops_data() -> void:
	eq(GameData.CROPS.size(), 12, "có 12 loại cây")
	eq(GameData.CROP_ORDER.size(), GameData.CROPS.size(), "thứ tự đủ các cây")
	var last_profit := -1
	var last_seconds := 0
	for crop_id in GameData.CROP_ORDER:
		var def: Dictionary = GameData.CROPS[crop_id]
		var seed_id: String = "seed_" + crop_id
		var product: String = "produce_" + crop_id
		check(GameData.ITEMS.has(seed_id), "có hạt %s" % seed_id)
		check(GameData.ITEMS.has(product), "có nông sản %s" % product)
		eq(GameData.crop_for_seed(seed_id), crop_id, "hạt %s ra đúng cây" % seed_id)
		eq(GameData.buy_price(seed_id), int(def["seed"]), "giá hạt %s khớp bảng cây" % crop_id)
		eq(GameData.sell_price(product), int(def["sell"]), "giá bán %s khớp bảng cây" % crop_id)
		eq(GameData.sell_price(seed_id), int(def["seed"]) / 2, "thanh lý hạt %s = nửa giá" % crop_id)
		check(GameData.BUY_LIST.has(seed_id), "chợ bán hạt %s" % crop_id)
		var profit: int = int(def["yield"]) * int(def["sell"]) - int(def["seed"])
		check(profit > 0, "%s có lãi" % crop_id)
		check(profit > last_profit, "%s lâu hơn thì mỗi vụ lãi hơn" % crop_id)
		check(int(def["seconds"]) > last_seconds, "%s xếp theo thời gian tăng dần" % crop_id)
		last_profit = profit
		last_seconds = int(def["seconds"])


func test_all_crops_grow() -> void:
	var s = rich_state()
	for crop_id in GameData.CROP_ORDER:
		var def: Dictionary = GameData.CROPS[crop_id]
		var seed_id: String = "seed_" + crop_id
		var secs := float(def["seconds"])
		ok(GameRules.buy(s, seed_id, 1), "mua hạt %s" % crop_id)
		ok(GameRules.sow(s, 3, seed_id), "gieo %s" % crop_id)
		ok(GameRules.water(s, 3, T0), "tưới %s" % crop_id)
		check(not GameRules.is_ripe(s.plots[3], T0 + secs - 1.0), "%s chưa chín trước hạn" % crop_id)
		ok(GameRules.harvest(s, 3, T0 + secs), "thu %s đúng hạn" % crop_id)
		eq(s.count("produce_" + crop_id), int(def["yield"]), "%s thu đúng sản lượng" % crop_id)


# ================= Chợ / công trình =================

func test_market() -> void:
	var s = FarmState.new()
	s.add_item("produce_leafy_greens", 2)
	var before: int = s.coins
	ok(GameRules.sell(s, "produce_leafy_greens", 2), "bán hai cải")
	eq(s.coins, before + 18, "bán hai cải cộng đúng 18 xu")

	var coins: int = s.coins
	var inv: Dictionary = s.inventory.duplicate(true)
	no(GameRules.buy(s, "seed_watermelon", 100), "mua quá số dư")
	no(GameRules.sell(s, "seed_leafy_greens", 99), "bán quá số lượng")
	no(GameRules.sell(s, "produce_carrot", 1), "bán thứ không có")
	no(GameRules.buy(s, "seed_carrot", 0), "số lượng 0")
	no(GameRules.buy(s, "seed_carrot", -3), "số lượng âm")
	no(GameRules.buy(s, "egg", 1), "chợ không bán trứng")
	eq(s.coins, coins, "giao dịch lỗi giữ nguyên tiền")
	eq(s.inventory, inv, "giao dịch lỗi giữ nguyên túi")

	ok(GameRules.sell(s, "seed_leafy_greens", 1), "thanh lý hạt cải")
	eq(s.coins, coins + 4, "thanh lý bằng nửa giá mua")


func test_buildings() -> void:
	var s = FarmState.new()
	s.coins = 1000
	no(GameRules.buy_building(s, "pond"), "không mua ao trước chuồng gà")
	no(GameRules.buy_building(s, "barn"), "không mua chuồng bò trước ao")
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	no(GameRules.buy_building(s, "coop"), "không mua trùng")
	eq(s.coins, 940, "trừ đúng 60 xu")
	ok(GameRules.buy_building(s, "pond"), "mua ao")
	ok(GameRules.buy_building(s, "barn"), "mua chuồng bò")
	eq(s.coins, 710, "tổng giá công trình 290")
	check(not s.pond["stocked"], "ao mở ở trạng thái trống")

	var poor = FarmState.new()
	no(GameRules.buy_building(poor, "coop"), "40 xu chưa đủ mua chuồng gà")
	eq(poor.coins, 40, "mua lỗi giữ nguyên tiền")


# ================= Ao cá / vật nuôi (theo đêm) =================

func test_pond() -> void:
	var s = rich_state()
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	ok(GameRules.buy_building(s, "pond"), "mua ao")
	no(GameRules.feed_pond(s), "ao trống không cho ăn")
	ok(GameRules.buy(s, "fish_fry", 2), "mua giống")
	ok(GameRules.buy(s, "feed_fish", 5), "mua cám cá")
	ok(GameRules.stock_pond(s), "thả giống")
	no(GameRules.stock_pond(s), "không thả lứa thứ hai")
	eq(s.count("fish_fry"), 1, "thả lỗi không trừ giống")
	for d in 3:
		ok(GameRules.feed_pond(s), "cho cá ăn ngày %d" % (d + 1))
		no(GameRules.feed_pond(s), "cho ăn lặp bị chặn")
		s = night(s)
	eq(s.count("feed_fish"), 2, "ba đêm trừ đúng ba cám")
	no(GameRules.feed_pond(s), "cá đủ lớn thì khoá cho ăn")
	ok(GameRules.harvest_pond(s), "thu cá")
	eq(s.count("fish_ro"), 3, "thu đúng ba cá")
	no(GameRules.harvest_pond(s), "không thu hai lần")
	ok(GameRules.stock_pond(s), "thả lứa mới sau khi thu")


func test_chicken() -> void:
	var s = rich_state()
	no(GameRules.feed_animal(s, "chicken"), "chưa có chuồng gà")
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	ok(GameRules.buy(s, "feed_chicken", 3), "mua cám gà")
	ok(GameRules.feed_animal(s, "chicken"), "cho gà ăn")
	no(GameRules.feed_animal(s, "chicken"), "cho ăn lặp bị chặn")
	eq(s.count("feed_chicken"), 2, "cho ăn lặp không trừ thêm")
	s = night(s)
	check(s.animals["chicken"]["ready"], "gà có trứng sau một đêm")
	no(GameRules.feed_animal(s, "chicken"), "có trứng chờ thu thì khoá cho ăn")
	ok(GameRules.collect_animal(s, "chicken"), "nhặt trứng")
	eq(s.count("egg"), 1, "được một trứng")
	no(GameRules.collect_animal(s, "chicken"), "không nhặt hai lần")


func test_cow() -> void:
	var s = rich_state()
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	ok(GameRules.buy_building(s, "pond"), "mua ao")
	ok(GameRules.buy_building(s, "barn"), "mua chuồng bò")
	ok(GameRules.buy(s, "feed_cow", 4), "mua cỏ")
	ok(GameRules.feed_animal(s, "cow"), "cho bò ăn đêm 1")
	s = night(s)
	check(not s.animals["cow"]["ready"], "một đêm chưa có sữa")
	s = night(s)
	eq(s.animals["cow"]["progress"], 1, "bỏ ăn giữ tiến độ")
	ok(GameRules.feed_animal(s, "cow"), "cho bò ăn đêm 2")
	s = night(s)
	check(s.animals["cow"]["ready"], "hai đêm được chăm có sữa")
	ok(GameRules.collect_animal(s, "cow"), "vắt sữa")
	eq(s.count("milk"), 1, "được một sữa")


# ================= Ngủ / lưu / tải =================

func test_sleep_does_not_mutate() -> void:
	var s = FarmState.new()
	ok(GameRules.sow(s, 0, "seed_leafy_greens"), "gieo")
	ok(GameRules.water(s, 0, T0), "tưới")
	var snapshot: Dictionary = s.to_dict()
	var n = night(s)
	eq(s.to_dict(), snapshot, "ngủ không sửa trạng thái gốc")
	eq(n.day, 2, "ngày tăng đúng một")
	eq(float(n.plots[0]["watered_at"]), T0, "ngủ không làm mất tiến độ cây")


func test_save_load() -> void:
	var saver = SaveSystem.new("user://test_saves")
	saver.delete_all()
	check(not saver.has_save(), "chưa có bản lưu")
	check(not saver.load_game()["ok"], "không có tệp thì báo lỗi")

	var s = FarmState.new()
	s.coins = 123
	ok(GameRules.sow(s, 0, "seed_leafy_greens"), "gieo")
	ok(GameRules.water(s, 0, T0 + 0.25), "tưới")
	s = night(s)
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	s.player_pos = Vector2(1.5, -2.25)
	eq(saver.save(s), "", "lưu lần 1")
	var r: Dictionary = saver.load_game()
	check(r["ok"], "tải lại được")
	if r["ok"]:
		eq(r["state"].to_dict(), s.to_dict(), "tiền, túi, ngày, công trình, thời điểm tưới giữ nguyên")

	ok(GameRules.sow(s, 1, "seed_water_spinach"), "gieo thêm")
	eq(saver.save(s), "", "lưu lần 2")
	var f := FileAccess.open(saver.main_path, FileAccess.WRITE)
	f.store_string("{ hỏng")
	f.close()
	r = saver.load_game()
	check(r["ok"], "tệp chính lỗi vẫn tải được từ bản sao")
	check(r["msg"] != "", "báo cho người chơi biết đã dùng bản sao")
	if r["ok"]:
		eq(r["state"].to_dict(), s.to_dict(), "bản sao là lần lưu gần nhất")

	var bad: Dictionary = s.to_dict()
	bad["schemaVersion"] = 99
	for p in [saver.main_path, saver.bak_path]:
		var g := FileAccess.open(p, FileAccess.WRITE)
		g.store_string(JSON.stringify(bad))
		g.close()
	check(not saver.load_game()["ok"], "phiên bản không hỗ trợ bị từ chối")
	check(FileAccess.file_exists(saver.main_path), "tệp phiên bản lạ vẫn được giữ")
	saver.delete_all()


func test_migrate_v1_save() -> void:
	var plots := []
	plots.append({"crop": "leafy_greens", "growth": 1, "watered": false})
	plots.append({"crop": "carrot", "growth": 3, "watered": false})
	plots.append({"crop": "leafy_greens", "growth": 0, "watered": false})
	for i in 3:
		plots.append({"crop": "", "growth": 0, "watered": false})
	var v1 := {
		"schemaVersion": 1, "day": 5, "coins": 77,
		"inventory": {"seed_leafy_greens": 2, "produce_carrot": 3},
		"plots": plots,
		"buildings": {"coop": true, "pond": false, "barn": false},
		"pond": {"stocked": false, "growth": 0, "fed": false},
		"animals": {"chicken": {"progress": 0, "fed": true, "ready": false}, "cow": {"progress": 0, "fed": false, "ready": false}},
		"tutorialStep": 7,
	}
	var st = FarmState.new()
	eq(st.load_dict(v1), "", "đọc được bản lưu phiên bản 1")
	eq(st.coins, 77, "giữ số xu")
	eq(st.count("produce_carrot"), 3, "giữ túi đồ")
	check(st.buildings["coop"], "giữ công trình")
	var now := Time.get_unix_time_from_system()
	check(absf(GameRules.growth_fraction(st.plots[0], now) - 0.5) < 0.05, "cải 1/2 đêm thành lớn một nửa")
	check(GameRules.is_ripe(st.plots[1], now), "cà rốt đủ 3 đêm thành đã chín")
	check(not GameRules.is_watered(st.plots[2]), "cây chưa tưới vẫn chờ tưới")
	eq(st.tutorial_step, GameData.TUTORIAL.size(), "hướng dẫn đã xong vẫn là xong")


# ================= Kinh tế / phục hồi =================

func test_starter_economy() -> void:
	var s = FarmState.new()
	eq(s.coins, 40, "bắt đầu 40 xu")
	for i in 3:
		ok(GameRules.sow(s, i, "seed_water_spinach"), "gieo rau muống")
		ok(GameRules.sow(s, i + 3, "seed_leafy_greens"), "gieo cải")
	for i in GameData.PLOT_COUNT:
		ok(GameRules.water(s, i, T0), "tưới ô %d" % i)
	for i in 3:
		ok(GameRules.harvest(s, i, T0 + 30.0), "rau muống chín sau 30 giây")
		no(GameRules.harvest(s, i + 3, T0 + 30.0), "cải chưa chín sau 30 giây")
	for i in 3:
		ok(GameRules.harvest(s, i + 3, T0 + 60.0), "cải chín sau 1 phút")
	ok(GameRules.sell(s, "produce_water_spinach", 6), "bán 6 bó rau muống")
	ok(GameRules.sell(s, "produce_leafy_greens", 6), "bán 6 cây cải")
	eq(s.coins, 40 + 30 + 54, "sau 1 phút có 124 xu")
	ok(GameRules.buy_building(s, "coop"), "đủ tiền xây chuồng gà")


func test_recovery() -> void:
	var s = FarmState.new()
	s.coins = 0
	s.inventory = {}
	ok(GameRules.claim_free_seed(s), "cạn vốn nhận được hạt")
	no(GameRules.claim_free_seed(s), "nhận xong thì túi không còn trống")
	ok(GameRules.sow(s, 0, "seed_leafy_greens_gift"), "gieo hạt tặng")
	ok(GameRules.water(s, 0, T0), "tưới")
	ok(GameRules.harvest(s, 0, T0 + 60.0), "thu")
	ok(GameRules.sell(s, "produce_leafy_greens", 2), "bán")
	eq(s.coins, 18, "có 18 xu")
	ok(GameRules.buy(s, "seed_leafy_greens", 1), "quay lại chu kỳ mua giống")


func test_market_dynamic_price() -> void:
	var s = FarmState.new()
	s.day = 1
	var item := "produce_leafy_greens"
	check(GameRules.demand_item(s.day) != item, "ngày 1 chợ không cần cải (giá gốc)")
	eq(GameRules.market_price(s, item), 9, "chợ trống thì giá gốc 9")
	s.add_item(item, 10)
	ok(GameRules.sell(s, item, 10), "bán 10 cải")
	eq(s.coins, 40 + 90, "cả lô bán theo giá lúc bắt đầu bán")
	eq(int(s.market_stock.get(item, 0)), 10, "chợ tồn 10 cải")
	eq(GameRules.market_price(s, item), 6, "tồn 10 món thì giá còn 6")
	s.market_stock[item] = 1000
	eq(GameRules.market_price(s, item), 5, "giá không thấp hơn một nửa (làm tròn)")
	eq(GameRules.market_take(s, item, 999), 999, "khách mua bớt hàng")
	eq(GameRules.market_take(s, item, 5), 1, "không bán quá hàng đang có")
	eq(GameRules.market_price(s, item), 9, "hết hàng tồn thì giá hồi về gốc")
	var want := GameRules.demand_item(s.day)
	eq(GameRules.market_price(s, want), roundi(GameData.sell_price(want) * GameData.DEMAND_BONUS), "món chợ đang cần được giá cao hơn")
	eq(GameRules.market_price(s, "seed_carrot"), 6, "hạt giống không bị ảnh hưởng giá chợ")


## Chạy làng 3 ngày (mỗi bước 0,5 giây thật) và kiểm tra mọi người làm đúng việc.
func test_village_three_days() -> void:
	var s = FarmState.new()
	s.clock = 300.0
	var v = VillageSim.new(s)
	var max_rice := 0
	var night_checks := 0
	var night_ok := true
	var stall_seen := false
	var fish_seen := false
	var plow_seen := false
	var all_logs: Array = []
	var last_line := ""
	var steps := int(3 * 1440.0 / VD.MINUTES_PER_SECOND / 0.5)
	for k in steps:
		var ev: Dictionary = v.step(0.5)
		if ev["new_day"]:
			s = GameRules.sleep(s)["state"]
			v.set_state(s)
		var h: float = v.hour()
		max_rice = maxi(max_rice, int(s.market_stock.get("produce_rice", 0)))
		if h >= 2.0 and h < 4.0:
			night_checks += 1
			for p in v.villagers:
				if p["visible"] or p["block"] != "sleep":
					night_ok = false
		if h >= 9.0 and h < 10.0:
			var lan: Dictionary = v.get_villager("lan")
			if lan["pos"].distance_to(VD.SPOTS["market_stall"]) < 0.05 and lan["activity"] == "Bán hàng":
				stall_seen = true
			var tu: Dictionary = v.get_villager("tu")
			if tu["activity"] == "Câu cá" and tu["tool"] == "rod":
				fish_seen = true
		var ba: Dictionary = v.get_villager("ba")
		if ba["activity"] == "Cày ruộng":
			plow_seen = true
		# gom tin làng (sau khi sang ngày, state mới vẫn mang theo tin cũ)
		if not s.village_log.is_empty() and str(s.village_log.back()) != last_line:
			last_line = str(s.village_log.back())
			for line in s.village_log:
				if not all_logs.has(line):
					all_logs.append(line)
	eq(s.day, 4, "sau 3 ngày mô phỏng là ngày 4")
	check(night_checks > 0 and night_ok, "2–4 giờ sáng mọi người đều ở nhà ngủ")
	check(stall_seen, "9 giờ sáng Cô Lan đứng bán ở quầy chợ")
	check(fish_seen, "9 giờ sáng Chú Tư đang câu cá")
	check(plow_seen, "Bác Ba có cày ruộng")
	var text := "\n".join(all_logs)
	for kw in ["cày xong", "cấy mạ", "dẫn nước", "gặt được", "bao lúa ra chợ", "câu được", "trứng gà", "cho khách"]:
		check(text.contains(kw), "tin làng có \"%s\"" % kw)
	check(max_rice > 0, "lúa của Bác Ba có lên chợ")
	var stuck := 0
	for p in v.villagers:
		var pos: Vector2 = p["pos"]
		if absf(pos.x) > 21.0 or pos.y < -13.5 or pos.y > 13.5:
			stuck += 1
	eq(stuck, 0, "không ai đi ra ngoài hàng rào làng")


func test_village_save_roundtrip() -> void:
	var s = FarmState.new()
	s.clock = 845.5
	s.paddies[2] = {"stage": "growing", "grow": 123.0}
	GameRules.market_add(s, "produce_rice", 7)
	GameRules.add_log(s, "Thử ghi tin.")
	var t = FarmState.new()
	eq(t.load_dict(s.to_dict()), "", "đọc lại được")
	eq(t.clock, 845.5, "giữ giờ trong ngày")
	eq(t.paddies[2]["stage"], "growing", "giữ trạng thái ruộng làng")
	eq(int(t.market_stock.get("produce_rice", 0)), 7, "giữ hàng tồn ở chợ")
	eq(t.village_log.size(), 1, "giữ tin làng")
	check(str(t.village_log[0]).begins_with("14:05"), "tin làng có giờ")
	var old: Dictionary = s.to_dict()
	old.erase("clock")
	old.erase("paddies")
	old.erase("marketStock")
	old["schemaVersion"] = 2
	var u = FarmState.new()
	eq(u.load_dict(old), "", "bản lưu cũ (chưa có làng) vẫn đọc được")
	eq(u.clock, GameData.MORNING, "bản lưu cũ bắt đầu lúc 6 giờ sáng")
	eq(u.paddies.size(), GameData.PADDY_COUNT, "bản lưu cũ có đủ ruộng làng")


func test_free_seed_not_exploitable() -> void:
	var s = FarmState.new()
	s.coins = 0
	s.inventory = {}
	ok(GameRules.claim_free_seed(s), "nhận hạt")
	no(GameRules.sell(s, "seed_leafy_greens_gift", 1), "hạt tặng không bán được")
	eq(s.coins, 0, "không sinh tiền từ hạt tặng")
	s.inventory = {}
	no(GameRules.claim_free_seed(s), "mỗi ngày chỉ nhận một lần")
	var rich = FarmState.new()
	rich.inventory = {}
	no(GameRules.claim_free_seed(rich), "có từ 8 xu thì không nhận")
