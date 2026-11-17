extends SceneTree
## Bộ kiểm thử mô phỏng theo tiêu chí nghiệm thu B02–B07 trong GDD.
## Chạy:  godot --headless --path . -s res://tests/run_tests.gd
## Mã thoát 0 = tất cả đạt.

const GameData = preload("res://scripts/sim/game_data.gd")
const FarmState = preload("res://scripts/sim/farm_state.gd")
const GameRules = preload("res://scripts/sim/game_rules.gd")
const SaveSystem = preload("res://scripts/sim/save_system.gd")

var _passed := 0
var _failed := 0
var _current := ""


func _init() -> void:
	var tests := [
		"test_b02_crop_cycle",
		"test_b02_carrot",
		"test_b03_market",
		"test_b03_buildings",
		"test_b04_pond",
		"test_b05_chicken",
		"test_b05_cow",
		"test_b06_sleep_does_not_mutate",
		"test_b06_save_load",
		"test_b07_scenario_day9",
		"test_b07_recovery",
		"test_free_seed_not_exploitable",
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
	s.coins = 1000
	return s


# ---------------- helpers cho kịch bản ----------------

func sow_all(s, seed_id: String) -> void:
	for i in GameData.PLOT_COUNT:
		ok(GameRules.sow(s, i, seed_id), "gieo ô %d" % i)


func water_all(s) -> void:
	for i in GameData.PLOT_COUNT:
		var p: Dictionary = s.plots[i]
		if p["crop"] != "" and not GameRules.is_ripe(p):
			ok(GameRules.water(s, i), "tưới ô %d" % i)


func harvest_all(s) -> void:
	for i in GameData.PLOT_COUNT:
		ok(GameRules.harvest(s, i), "thu ô %d" % i)


# ================= B02 =================

func test_b02_crop_cycle() -> void:
	var s = FarmState.new()
	ok(GameRules.sow(s, 0, "seed_leafy_greens"), "gieo cải")
	eq(s.count("seed_leafy_greens"), 5, "gieo trừ đúng một hạt")
	no(GameRules.sow(s, 0, "seed_leafy_greens"), "không gieo đè ô đã có cây")
	eq(s.count("seed_leafy_greens"), 5, "gieo lỗi không trừ hạt")
	no(GameRules.water(s, 1), "không tưới ô trống")

	ok(GameRules.water(s, 0), "tưới ngày gieo")
	no(GameRules.water(s, 0), "không tưới hai lần một ngày")
	s = night(s)
	eq(s.plots[0]["growth"], 1, "đêm có tưới tăng một bước")

	s = night(s)
	eq(s.plots[0]["growth"], 1, "đêm bỏ tưới không tăng bước")
	no(GameRules.harvest(s, 0), "chưa chín thì không thu")

	ok(GameRules.water(s, 0), "tưới lại")
	s = night(s)
	check(GameRules.is_ripe(s.plots[0]), "chín sau hai đêm được tưới")
	no(GameRules.water(s, 0), "cây chín không cần tưới")

	ok(GameRules.harvest(s, 0), "thu cải")
	eq(s.count("produce_leafy_greens"), 2, "thu đúng hai cải")
	no(GameRules.harvest(s, 0), "bấm thu lần hai bị chặn")
	eq(s.count("produce_leafy_greens"), 2, "bấm thu hai lần chỉ nhận một lần")
	eq(s.plots[0]["crop"], "", "ô trống sau thu")


func test_b02_carrot() -> void:
	var s = rich_state()
	ok(GameRules.buy(s, "seed_carrot", 1), "mua hạt cà rốt")
	ok(GameRules.sow(s, 2, "seed_carrot"), "gieo cà rốt")
	for d in 3:
		check(not GameRules.is_ripe(s.plots[2]), "chưa chín trước đêm %d" % (d + 1))
		ok(GameRules.water(s, 2), "tưới cà rốt")
		s = night(s)
	ok(GameRules.harvest(s, 2), "thu cà rốt")
	eq(s.count("produce_carrot"), 3, "thu đúng ba củ")


# ================= B03 =================

func test_b03_market() -> void:
	var s = FarmState.new()
	s.add_item("produce_leafy_greens", 2)
	var before: int = s.coins
	ok(GameRules.sell(s, "produce_leafy_greens", 2), "bán hai cải")
	eq(s.coins, before + 18, "bán hai cải cộng đúng 18 xu")

	var coins: int = s.coins
	var inv: Dictionary = s.inventory.duplicate(true)
	no(GameRules.buy(s, "seed_carrot", 100), "mua quá số dư")
	no(GameRules.sell(s, "seed_leafy_greens", 99), "bán quá số lượng")
	no(GameRules.sell(s, "produce_carrot", 1), "bán thứ không có")
	no(GameRules.buy(s, "seed_carrot", 0), "số lượng 0")
	no(GameRules.buy(s, "seed_carrot", -3), "số lượng âm")
	no(GameRules.buy(s, "egg", 1), "chợ không bán trứng")
	eq(s.coins, coins, "giao dịch lỗi giữ nguyên tiền")
	eq(s.inventory, inv, "giao dịch lỗi giữ nguyên túi")

	ok(GameRules.sell(s, "seed_leafy_greens", 1), "thanh lý hạt cải")
	eq(s.coins, coins + 4, "thanh lý bằng nửa giá mua")


func test_b03_buildings() -> void:
	var s = rich_state()
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


# ================= B04 =================

func test_b04_pond() -> void:
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


# ================= B05 =================

func test_b05_chicken() -> void:
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
	eq(s.count("feed_chicken"), 2, "khoá cho ăn không trừ cám")
	ok(GameRules.collect_animal(s, "chicken"), "nhặt trứng")
	eq(s.count("egg"), 1, "được một trứng")
	no(GameRules.collect_animal(s, "chicken"), "không nhặt hai lần")
	s = night(s)
	check(not s.animals["chicken"]["ready"], "đêm không cho ăn thì không có trứng")


func test_b05_cow() -> void:
	var s = rich_state()
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	ok(GameRules.buy_building(s, "pond"), "mua ao")
	ok(GameRules.buy_building(s, "barn"), "mua chuồng bò")
	ok(GameRules.buy(s, "feed_cow", 4), "mua cỏ")
	ok(GameRules.feed_animal(s, "cow"), "cho bò ăn đêm 1")
	no(GameRules.feed_animal(s, "cow"), "cho ăn lặp bị chặn")
	s = night(s)
	check(not s.animals["cow"]["ready"], "một đêm chưa có sữa")
	s = night(s)
	eq(s.animals["cow"]["progress"], 1, "bỏ ăn giữ tiến độ")
	ok(GameRules.feed_animal(s, "cow"), "cho bò ăn đêm 2")
	s = night(s)
	check(s.animals["cow"]["ready"], "hai đêm được chăm có sữa")
	ok(GameRules.collect_animal(s, "cow"), "vắt sữa")
	eq(s.count("milk"), 1, "được một sữa")
	eq(s.count("feed_cow"), 2, "trừ đúng hai cỏ")


# ================= B06 =================

func test_b06_sleep_does_not_mutate() -> void:
	var s = FarmState.new()
	ok(GameRules.sow(s, 0, "seed_leafy_greens"), "gieo")
	ok(GameRules.water(s, 0), "tưới")
	var snapshot: Dictionary = s.to_dict()
	var n = night(s)
	eq(s.to_dict(), snapshot, "ngủ không sửa trạng thái gốc")
	eq(n.day, 2, "ngày tăng đúng một")


func test_b06_save_load() -> void:
	var saver = SaveSystem.new("user://test_saves")
	saver.delete_all()
	check(not saver.has_save(), "chưa có bản lưu")
	var r0: Dictionary = saver.load_game()
	check(not r0["ok"], "không có tệp thì báo lỗi")

	var s = FarmState.new()
	s.coins = 123
	ok(GameRules.sow(s, 0, "seed_leafy_greens"), "gieo")
	ok(GameRules.water(s, 0), "tưới")
	s = night(s)
	ok(GameRules.buy_building(s, "coop"), "mua chuồng gà")
	s.player_pos = Vector2(1.5, -2.25)
	eq(saver.save(s), "", "lưu lần 1")
	var r: Dictionary = saver.load_game()
	check(r["ok"], "tải lại được")
	if r["ok"]:
		eq(r["state"].to_dict(), s.to_dict(), "tiền, túi, ngày, công trình, tiến độ giữ nguyên")

	ok(GameRules.sow(s, 1, "seed_leafy_greens"), "gieo thêm")
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
	r = saver.load_game()
	check(not r["ok"], "phiên bản không hỗ trợ bị từ chối")
	check(FileAccess.file_exists(saver.main_path), "tệp phiên bản lạ vẫn được giữ")
	saver.delete_all()


# ================= B07 =================

func test_b07_scenario_day9() -> void:
	var s = FarmState.new()
	# D1–D2: gieo 6 ô cải, tưới hai ngày.
	sow_all(s, "seed_leafy_greens")
	water_all(s)
	s = night(s)
	water_all(s)
	s = night(s)

	# D3
	eq(s.day, 3, "đến ngày 3")
	harvest_all(s)
	ok(GameRules.sell(s, "produce_leafy_greens", 12), "D3 bán 12 cải")
	eq(s.coins, 148, "D3 có 148 xu")
	ok(GameRules.buy_building(s, "coop"), "D3 mua chuồng gà")
	ok(GameRules.buy(s, "seed_carrot", 6), "D3 mua 6 hạt cà rốt")
	sow_all(s, "seed_carrot")
	water_all(s)
	ok(GameRules.buy(s, "feed_chicken", 1), "D3 mua cám gà")
	ok(GameRules.feed_animal(s, "chicken"), "D3 cho gà ăn")
	eq(s.coins, 13, "D3 còn 13 xu")
	s = night(s)

	# D4, D5
	for d in 2:
		ok(GameRules.collect_animal(s, "chicken"), "nhặt trứng")
		ok(GameRules.sell(s, "egg", 1), "bán trứng")
		ok(GameRules.buy(s, "feed_chicken", 1), "mua cám gà")
		ok(GameRules.feed_animal(s, "chicken"), "cho gà ăn")
		water_all(s)
		s = night(s)
	eq(s.coins, 25, "hết D5 có 25 xu")

	# D6
	ok(GameRules.collect_animal(s, "chicken"), "D6 nhặt trứng")
	harvest_all(s)
	ok(GameRules.sell(s, "produce_carrot", 18), "D6 bán 18 củ")
	ok(GameRules.sell(s, "egg", 1), "D6 bán trứng")
	eq(s.coins, 214, "D6 có 214 xu")
	ok(GameRules.buy_building(s, "pond"), "D6 mua ao")
	ok(GameRules.buy(s, "fish_fry", 1), "D6 mua cá giống")
	ok(GameRules.stock_pond(s), "D6 thả cá")
	ok(GameRules.buy(s, "feed_fish", 1), "D6 mua cám cá")
	ok(GameRules.feed_pond(s), "D6 cho cá ăn")
	ok(GameRules.buy(s, "feed_chicken", 1), "D6 mua cám gà")
	ok(GameRules.feed_animal(s, "chicken"), "D6 cho gà ăn")
	ok(GameRules.buy(s, "seed_leafy_greens", 6), "D6 mua 6 hạt cải")
	sow_all(s, "seed_leafy_greens")
	water_all(s)
	eq(s.coins, 45, "D6 còn 45 xu")
	s = night(s)

	# D7
	ok(GameRules.collect_animal(s, "chicken"), "D7 nhặt trứng")
	ok(GameRules.sell(s, "egg", 1), "D7 bán trứng")
	ok(GameRules.buy(s, "feed_chicken", 1), "D7 mua cám gà")
	ok(GameRules.buy(s, "feed_fish", 1), "D7 mua cám cá")
	ok(GameRules.feed_animal(s, "chicken"), "D7 cho gà ăn")
	ok(GameRules.feed_pond(s), "D7 cho cá ăn")
	water_all(s)
	eq(s.coins, 47, "D7 còn 47 xu")
	s = night(s)

	# D8
	ok(GameRules.collect_animal(s, "chicken"), "D8 nhặt trứng")
	harvest_all(s)
	ok(GameRules.sell(s, "produce_leafy_greens", 12), "D8 bán 12 cải")
	ok(GameRules.sell(s, "egg", 1), "D8 bán trứng")
	ok(GameRules.buy(s, "feed_chicken", 1), "D8 mua cám gà")
	ok(GameRules.buy(s, "feed_fish", 1), "D8 mua cám cá")
	ok(GameRules.feed_animal(s, "chicken"), "D8 cho gà ăn")
	ok(GameRules.feed_pond(s), "D8 cho cá ăn")
	eq(s.coins, 157, "D8 còn 157 xu")
	s = night(s)

	# D9
	eq(s.day, 9, "đến ngày 9")
	ok(GameRules.collect_animal(s, "chicken"), "D9 nhặt trứng")
	ok(GameRules.harvest_pond(s), "D9 thu cá")
	ok(GameRules.sell(s, "egg", 1), "D9 bán trứng")
	ok(GameRules.sell(s, "fish_ro", 3), "D9 bán 3 cá")
	eq(s.coins, 226, "D9 có 226 xu trước khi mua bò")
	ok(GameRules.buy_building(s, "barn"), "D9 mở chuồng bò")
	eq(s.coins, 86, "D9 còn 86 xu sau khi mua bò")


func test_b07_recovery() -> void:
	var s = FarmState.new()
	s.coins = 0
	s.inventory = {}
	ok(GameRules.claim_free_seed(s), "cạn vốn nhận được hạt")
	no(GameRules.claim_free_seed(s), "nhận xong thì túi không còn trống")
	ok(GameRules.sow(s, 0, "seed_leafy_greens_gift"), "gieo hạt tặng")
	ok(GameRules.water(s, 0), "tưới")
	s = night(s)
	ok(GameRules.water(s, 0), "tưới")
	s = night(s)
	ok(GameRules.harvest(s, 0), "thu")
	ok(GameRules.sell(s, "produce_leafy_greens", 2), "bán")
	eq(s.coins, 18, "có 18 xu")
	ok(GameRules.buy(s, "seed_leafy_greens", 1), "quay lại chu kỳ mua giống")


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
