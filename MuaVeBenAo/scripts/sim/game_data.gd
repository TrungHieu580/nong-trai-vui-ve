extends RefCounted
## Dữ liệu cấu hình: vật phẩm, cây trồng, vật nuôi, ao, công trình, hướng dẫn.
## Cân bằng game bằng cách sửa số ở đây – không cần đụng vào logic.

const GAME_VERSION := "0.1.3"
const SCHEMA_VERSION := 1
const START_COINS := 40
const START_INVENTORY := {"seed_leafy_greens": 6}
const PLOT_COUNT := 6
const FREE_SEED_COIN_LIMIT := 8
const FREE_SEED_ITEM := "seed_leafy_greens_gift"

## buy = giá mua ở chợ (0 = chợ không bán).
## sell = giá bán cho chợ (0 = không bán được). Vật tư thanh lý = nửa giá mua, làm tròn xuống.
const ITEMS := {
	"seed_leafy_greens": {"name": "Hạt cải", "buy": 8, "sell": 4,
		"desc": "Gieo lên ô trống. Chín sau 2 đêm được tưới, thu 2 cải."},
	"seed_leafy_greens_gift": {"name": "Hạt cải (quà)", "buy": 0, "sell": 0,
		"desc": "Quà của chợ khi hết vốn. Gieo như hạt cải thường, không bán lại được."},
	"seed_carrot": {"name": "Hạt cà rốt", "buy": 12, "sell": 6,
		"desc": "Gieo lên ô trống. Chín sau 3 đêm được tưới, thu 3 củ."},
	"feed_chicken": {"name": "Cám gà", "buy": 3, "sell": 1,
		"desc": "Mỗi ngày cho gà ăn một phần. Sau một đêm, gà đẻ một trứng."},
	"fish_fry": {"name": "Gói cá giống", "buy": 24, "sell": 12,
		"desc": "Thả vào ao trống. Cho ăn đủ 3 đêm để thu 3 cá rô."},
	"feed_fish": {"name": "Cám cá", "buy": 4, "sell": 2,
		"desc": "Mỗi ngày cho cá ăn một phần để cá lớn qua đêm."},
	"feed_cow": {"name": "Cỏ khô", "buy": 5, "sell": 2,
		"desc": "Mỗi ngày cho bò ăn một phần. Hai đêm được chăm cho một sữa."},
	"produce_leafy_greens": {"name": "Cải", "buy": 0, "sell": 9,
		"desc": "Rau cải tươi. Bán ở chợ."},
	"produce_carrot": {"name": "Cà rốt", "buy": 0, "sell": 10,
		"desc": "Củ cà rốt. Bán ở chợ."},
	"fish_ro": {"name": "Cá rô", "buy": 0, "sell": 20,
		"desc": "Cá rô đồng từ ao nhà. Bán ở chợ."},
	"egg": {"name": "Trứng gà", "buy": 0, "sell": 9,
		"desc": "Trứng gà ta. Bán ở chợ."},
	"milk": {"name": "Sữa bò", "buy": 0, "sell": 30,
		"desc": "Sữa bò tươi. Bán ở chợ."},
}

const BUY_LIST := ["seed_leafy_greens", "seed_carrot", "feed_chicken", "fish_fry", "feed_fish", "feed_cow"]

const CROPS := {
	"leafy_greens": {"name": "Cải", "product": "produce_leafy_greens", "nights": 2, "yield": 2},
	"carrot": {"name": "Cà rốt", "product": "produce_carrot", "nights": 3, "yield": 3},
}

const SEED_TO_CROP := {
	"seed_leafy_greens": "leafy_greens",
	"seed_leafy_greens_gift": "leafy_greens",
	"seed_carrot": "carrot",
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
	{"action": "sow", "text": "Đi tới ô ruộng (WASD) và nhấn E để gieo hạt cải."},
	{"action": "water", "text": "Nhấn E lần nữa để tưới ô vừa gieo. Ô nào có cây cũng cần tưới mỗi ngày."},
	{"action": "sleep", "text": "Về giường trước hiên nhà và nhấn E để ngủ. Cây chỉ lớn qua đêm nếu đã được tưới."},
	{"action": "water", "text": "Cải cần 2 đêm. Hôm nay hãy tưới lại các ô đã gieo."},
	{"action": "sleep", "text": "Ngủ thêm một đêm nữa."},
	{"action": "harvest", "text": "Cải đã chín! Nhấn E tại ô ruộng để thu hoạch."},
	{"action": "sell", "text": "Mang cải ra quầy chợ, mở tab Bán để bán lấy xu."},
]
const TUTORIAL_DONE_TEXT := "Xong hướng dẫn! Gom đủ 60 xu rồi mở chuồng gà ở tab Công trình của quầy chợ."


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
