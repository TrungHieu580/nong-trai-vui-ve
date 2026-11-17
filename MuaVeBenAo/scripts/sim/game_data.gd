extends RefCounted
## Dữ liệu cấu hình: vật phẩm, cây trồng, vật nuôi, ao, công trình, hướng dẫn.
## Cân bằng game bằng cách sửa số ở đây – không cần đụng vào logic.

const GAME_VERSION := "0.5.1"
const SCHEMA_VERSION := 3
const PADDY_COUNT := 6
const PADDY_STAGES := ["bare", "plowed", "planted", "growing", "ripe"]
## Giờ bắt đầu ngày mới (phút trong ngày): 6:00 sáng.
const MORNING := 360.0

## Mỗi ngày chợ "đang cần" một mặt hàng (trả giá cao hơn 30%), xoay vòng theo ngày.
const DEMAND_LIST := ["produce_corn", "produce_tomato", "egg", "produce_peanut", "fish_ro",
	"produce_chili", "produce_sweet_potato", "produce_cucumber", "produce_carrot", "milk",
	"produce_pumpkin", "produce_water_spinach", "produce_rice", "produce_watermelon", "produce_leafy_greens"]
const DEMAND_BONUS := 1.3
## Mỗi món đang tồn ở chợ làm giá giảm 3%, thấp nhất còn 50% giá gốc.
const STOCK_PRICE_DROP := 0.03
const MIN_PRICE_FACTOR := 0.5
const START_COINS := 40
const START_INVENTORY := {"seed_water_spinach": 3, "seed_leafy_greens": 3}
const PLOT_COUNT := 6
const FREE_SEED_COIN_LIMIT := 8
const FREE_SEED_ITEM := "seed_leafy_greens_gift"

## Cây trồng lớn theo THỜI GIAN THỰC kể từ lúc được tưới (kể cả khi tắt game).
## seconds: thời gian lớn; seed: giá hạt; yield × sell: sản lượng và giá bán mỗi món.
## shape: kiểu hình 3D / biểu tượng; color: màu nông sản.
## Cây càng lâu thì mỗi vụ càng lãi nhiều, nhưng lãi mỗi phút giảm dần.
const CROPS := {
	"water_spinach": {"name": "Rau muống", "seconds": 30, "seed": 4, "yield": 2, "sell": 5, "shape": "leafy", "color": "4f9a3a"},
	"leafy_greens": {"name": "Cải ngọt", "seconds": 60, "seed": 8, "yield": 2, "sell": 9, "shape": "leafy", "color": "7cc35a"},
	"carrot": {"name": "Cà rốt", "seconds": 120, "seed": 12, "yield": 3, "sell": 10, "shape": "root", "color": "f29a4a"},
	"cucumber": {"name": "Dưa leo", "seconds": 180, "seed": 15, "yield": 3, "sell": 12, "shape": "vine", "color": "5f9e3f"},
	"tomato": {"name": "Cà chua", "seconds": 240, "seed": 18, "yield": 4, "sell": 11, "shape": "bush", "color": "e85d4a"},
	"corn": {"name": "Ngô", "seconds": 300, "seed": 20, "yield": 3, "sell": 16, "shape": "tall", "color": "f2c94c"},
	"chili": {"name": "Ớt", "seconds": 420, "seed": 22, "yield": 5, "sell": 11, "shape": "bush", "color": "d93a2b"},
	"peanut": {"name": "Đậu phộng", "seconds": 600, "seed": 25, "yield": 4, "sell": 15, "shape": "root", "color": "c9a074"},
	"sweet_potato": {"name": "Khoai lang", "seconds": 900, "seed": 30, "yield": 3, "sell": 25, "shape": "root", "color": "a0527a"},
	"rice": {"name": "Lúa", "seconds": 1200, "seed": 35, "yield": 5, "sell": 18, "shape": "tall", "color": "e8c872"},
	"pumpkin": {"name": "Bí đỏ", "seconds": 1800, "seed": 45, "yield": 2, "sell": 60, "shape": "big", "color": "f08a24"},
	"watermelon": {"name": "Dưa hấu", "seconds": 3600, "seed": 60, "yield": 2, "sell": 100, "shape": "big", "color": "3f8a2c"},
}
## Thứ tự hiển thị ở chợ và khi đổi hạt.
const CROP_ORDER := ["water_spinach", "leafy_greens", "carrot", "cucumber", "tomato", "corn",
	"chili", "peanut", "sweet_potato", "rice", "pumpkin", "watermelon"]

## buy = giá mua ở chợ (0 = chợ không bán). sell = giá bán cho chợ (0 = không bán được).
## Hạt giống thanh lý = nửa giá mua, làm tròn xuống.
const ITEMS := {
	"seed_water_spinach": {"name": "Hạt rau muống", "buy": 4, "sell": 2, "desc": "Lớn trong 30 giây sau khi tưới. Thu 2 bó rau muống."},
	"seed_leafy_greens": {"name": "Hạt cải ngọt", "buy": 8, "sell": 4, "desc": "Lớn trong 1 phút sau khi tưới. Thu 2 cây cải."},
	"seed_carrot": {"name": "Hạt cà rốt", "buy": 12, "sell": 6, "desc": "Lớn trong 2 phút sau khi tưới. Thu 3 củ."},
	"seed_cucumber": {"name": "Hạt dưa leo", "buy": 15, "sell": 7, "desc": "Lớn trong 3 phút sau khi tưới. Thu 3 quả."},
	"seed_tomato": {"name": "Hạt cà chua", "buy": 18, "sell": 9, "desc": "Lớn trong 4 phút sau khi tưới. Thu 4 quả."},
	"seed_corn": {"name": "Hạt ngô", "buy": 20, "sell": 10, "desc": "Lớn trong 5 phút sau khi tưới. Thu 3 bắp."},
	"seed_chili": {"name": "Hạt ớt", "buy": 22, "sell": 11, "desc": "Lớn trong 7 phút sau khi tưới. Thu 5 quả."},
	"seed_peanut": {"name": "Hạt đậu phộng", "buy": 25, "sell": 12, "desc": "Lớn trong 10 phút sau khi tưới. Thu 4 túi."},
	"seed_sweet_potato": {"name": "Hom khoai lang", "buy": 30, "sell": 15, "desc": "Lớn trong 15 phút sau khi tưới. Thu 3 củ."},
	"seed_rice": {"name": "Thóc giống", "buy": 35, "sell": 17, "desc": "Lớn trong 20 phút sau khi tưới. Thu 5 bao lúa."},
	"seed_pumpkin": {"name": "Hạt bí đỏ", "buy": 45, "sell": 22, "desc": "Lớn trong 30 phút sau khi tưới. Thu 2 quả to."},
	"seed_watermelon": {"name": "Hạt dưa hấu", "buy": 60, "sell": 30, "desc": "Lớn trong 1 giờ sau khi tưới. Thu 2 quả to."},
	"seed_leafy_greens_gift": {"name": "Hạt cải (quà)", "buy": 0, "sell": 0,
		"desc": "Quà của chợ khi hết vốn. Gieo như hạt cải ngọt, không bán lại được."},

	"produce_water_spinach": {"name": "Rau muống", "buy": 0, "sell": 5, "desc": "Bó rau muống xanh mướt."},
	"produce_leafy_greens": {"name": "Cải ngọt", "buy": 0, "sell": 9, "desc": "Cây cải ngọt tươi."},
	"produce_carrot": {"name": "Cà rốt", "buy": 0, "sell": 10, "desc": "Củ cà rốt giòn ngọt."},
	"produce_cucumber": {"name": "Dưa leo", "buy": 0, "sell": 12, "desc": "Quả dưa leo mát lành."},
	"produce_tomato": {"name": "Cà chua", "buy": 0, "sell": 11, "desc": "Quả cà chua chín đỏ."},
	"produce_corn": {"name": "Bắp ngô", "buy": 0, "sell": 16, "desc": "Bắp ngô nếp vàng ươm."},
	"produce_chili": {"name": "Ớt", "buy": 0, "sell": 11, "desc": "Quả ớt đỏ cay nồng."},
	"produce_peanut": {"name": "Đậu phộng", "buy": 0, "sell": 15, "desc": "Túi đậu phộng (lạc) vừa nhổ."},
	"produce_sweet_potato": {"name": "Khoai lang", "buy": 0, "sell": 25, "desc": "Củ khoai lang tím bùi."},
	"produce_rice": {"name": "Bao lúa", "buy": 0, "sell": 18, "desc": "Bao lúa vàng mới gặt."},
	"produce_pumpkin": {"name": "Bí đỏ", "buy": 0, "sell": 60, "desc": "Quả bí đỏ to tròn."},
	"produce_watermelon": {"name": "Dưa hấu", "buy": 0, "sell": 100, "desc": "Quả dưa hấu ruột đỏ."},

	"feed_chicken": {"name": "Cám gà", "buy": 3, "sell": 1,
		"desc": "Mỗi ngày cho gà ăn một phần. Sau một đêm, gà đẻ một trứng."},
	"fish_fry": {"name": "Gói cá giống", "buy": 24, "sell": 12,
		"desc": "Thả vào ao trống. Cho ăn đủ 3 đêm để thu 3 cá rô."},
	"feed_fish": {"name": "Cám cá", "buy": 4, "sell": 2,
		"desc": "Mỗi ngày cho cá ăn một phần để cá lớn qua đêm."},
	"feed_cow": {"name": "Cỏ khô", "buy": 5, "sell": 2,
		"desc": "Mỗi ngày cho bò ăn một phần. Hai đêm được chăm cho một sữa."},
	"fish_ro": {"name": "Cá rô", "buy": 0, "sell": 20, "desc": "Cá rô đồng từ ao nhà. Bán ở chợ."},
	"egg": {"name": "Trứng gà", "buy": 0, "sell": 9, "desc": "Trứng gà ta. Bán ở chợ."},
	"milk": {"name": "Sữa bò", "buy": 0, "sell": 30, "desc": "Sữa bò tươi. Bán ở chợ."},
}

const BUY_LIST := ["seed_water_spinach", "seed_leafy_greens", "seed_carrot", "seed_cucumber", "seed_tomato",
	"seed_corn", "seed_chili", "seed_peanut", "seed_sweet_potato", "seed_rice", "seed_pumpkin",
	"seed_watermelon", "feed_chicken", "fish_fry", "feed_fish", "feed_cow"]

const SEED_TO_CROP := {
	"seed_water_spinach": "water_spinach",
	"seed_leafy_greens": "leafy_greens",
	"seed_leafy_greens_gift": "leafy_greens",
	"seed_carrot": "carrot",
	"seed_cucumber": "cucumber",
	"seed_tomato": "tomato",
	"seed_corn": "corn",
	"seed_chili": "chili",
	"seed_peanut": "peanut",
	"seed_sweet_potato": "sweet_potato",
	"seed_rice": "rice",
	"seed_pumpkin": "pumpkin",
	"seed_watermelon": "watermelon",
}

const ANIMALS := {
	"chicken": {"name": "Gà", "building": "coop", "feed": "feed_chicken", "product": "egg", "nights": 1},
	"cow": {"name": "Bò", "building": "barn", "feed": "feed_cow", "product": "milk", "nights": 2},
}

const POND := {"name": "Cá", "fry": "fish_fry", "feed": "feed_fish", "product": "fish_ro", "nights": 3, "yield": 3}

const BUILDINGS := {
	"coop": {"name": "Chuồng gà", "price": 60, "requires": "", "desc": "Kèm một con gà trưởng thành."},
	"pond": {"name": "Ao cá", "price": 90, "requires": "coop", "desc": "Ao trống, thả cá giống để nuôi."},
	"barn": {"name": "Chuồng bò", "price": 140, "requires": "pond", "desc": "Kèm một con bò trưởng thành."},
}
const BUILDING_ORDER := ["coop", "pond", "barn"]

const TUTORIAL := [
	{"action": "sow", "text": "Chạm vào một ô ruộng (hoặc đi tới và nhấn E) để gieo hạt."},
	{"action": "water", "text": "Tưới ô vừa gieo. Cây chỉ bắt đầu lớn sau khi được tưới."},
	{"action": "harvest", "text": "Cây lớn theo thời gian thực, kể cả khi tắt game. Chờ chín rồi thu hoạch nhé!"},
	{"action": "sell", "text": "Mang nông sản ra quầy chợ, mở tab Bán để bán lấy xu."},
]
const TUTORIAL_DONE_TEXT := "Xong hướng dẫn! Thử các loại hạt khác ở chợ. Cây càng lâu chín, mỗi vụ càng lãi. Gom 60 xu để xây chuồng gà."


static func crop_for_seed(seed_id: String) -> String:
	return SEED_TO_CROP.get(seed_id, "")


static func item_name(id: String) -> String:
	if ITEMS.has(id):
		return ITEMS[id]["name"]
	return id


static func item_desc(id: String) -> String:
	if ITEMS.has(id):
		return ITEMS[id]["desc"]
	return ""


static func buy_price(id: String) -> int:
	if ITEMS.has(id):
		return int(ITEMS[id]["buy"])
	return 0


static func sell_price(id: String) -> int:
	if ITEMS.has(id):
		return int(ITEMS[id]["sell"])
	return 0


## 75 → "1:15", 3600 → "1:00:00"
static func fmt_time(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


## 30 → "30 giây", 120 → "2 phút", 3600 → "1 giờ"
static func fmt_duration(seconds: int) -> String:
	if seconds < 60:
		return "%d giây" % seconds
	if seconds < 3600:
		return "%d phút" % (seconds / 60)
	return "%d giờ" % (seconds / 3600)
