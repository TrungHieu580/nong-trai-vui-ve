extends RefCounted
## Dữ liệu xóm làng: đồng hồ, dân làng, địa điểm, lịch làm việc.
## Toạ độ là (x, z) trên mặt đất, cùng hệ với thế giới 3D.

## 3 phút trong game mỗi giây thật → 1 ngày ≈ 8 phút thật.
const MINUTES_PER_SECOND := 3.0
const WALK_SPEED := 2.4
const KID_SPEED := 2.9
## Đường làng chạy ngang theo trục X tại z = ROAD_Z; dân làng đi theo đường này khi đi xa.
const ROAD_Z := -0.6

## Ruộng lúa của làng (Bác Ba làm).
const PADDY_CENTERS := [Vector2(12.0, -6.6), Vector2(14.6, -6.6), Vector2(17.2, -6.6),
	Vector2(12.0, -3.9), Vector2(14.6, -3.9), Vector2(17.2, -3.9)]
const PADDY_GROW_MINUTES := 480.0
const PADDY_YIELD := 3
const TASK_MINUTES := {"plow": 40.0, "sow": 30.0, "water": 20.0, "harvest": 40.0}
const TASK_LABEL := {"plow": "Cày ruộng", "sow": "Cấy mạ", "water": "Dẫn nước", "harvest": "Gặt lúa"}
const TASK_TOOL := {"plow": "hoe", "sow": "basket", "water": "can", "harvest": "sickle"}

const SPOTS := {
	"market_customer": Vector2(8.5, 1.5),
	"market_stall": Vector2(10.5, 2.6),
	"fishing": Vector2(-12.5, 6.5),
	"yard": Vector2(-17.0, -5.6),
	"well": Vector2(5.4, 10.4),
	"pasture": Vector2(19.0, -11.4),
	"field_idle": Vector2(13.3, -1.6),
}
const PLAY_SPOTS := [Vector2(4.2, 9.0), Vector2(-3.0, 10.5), Vector2(-9.4, 8.2),
	Vector2(11.0, -1.6), Vector2(-14.0, 1.2), Vector2(2.0, 1.4)]

const VILLAGE_POND := Vector2(-12.5, 9.2)
const VILLAGE_POND_RADIUS := 2.3

## home: chỗ đứng trước cửa nhà; house: tâm ngôi nhà; door: +1 cửa nhìn về +Z, -1 nhìn về -Z.
const VILLAGERS := [
	{"id": "ba", "name": "Bác Ba", "role": "farmer", "home": Vector2(16.0, -9.0), "house": Vector2(16.0, -11.1), "door": 1,
		"scale": 1.0, "walls": "f3e3c3", "roof": "8f9a5c",
		"look": {"shirt": "a9c98a", "pants": "6b5a45", "hair": "3b3b3b", "hat": "non_la", "skin": "e2b48a"}},
	{"id": "lan", "name": "Cô Lan", "role": "merchant", "home": Vector2(15.0, 5.5), "house": Vector2(15.0, 7.6), "door": -1,
		"scale": 1.0, "walls": "fbe6e0", "roof": "e46a6a",
		"look": {"shirt": "f2a7a0", "pants": "4a4a6a", "hair": "2b1d14", "hat": "non_la", "skin": "f3cfa8"}},
	{"id": "tu", "name": "Chú Tư", "role": "fisher", "home": Vector2(-17.0, 8.3), "house": Vector2(-17.0, 10.4), "door": -1,
		"scale": 1.0, "walls": "e3eef3", "roof": "5f8fbf",
		"look": {"shirt": "8fb3d9", "pants": "5a6b7a", "hair": "2b2b2b", "hat": "cap", "skin": "d9a77c"}},
	{"id": "nam", "name": "Bà Năm", "role": "poultry", "home": Vector2(-17.0, -8.5), "house": Vector2(-17.0, -10.6), "door": 1,
		"scale": 0.95, "walls": "f1e7f7", "roof": "9b7bc0",
		"look": {"shirt": "b39ddb", "pants": "3b3b4a", "hair": "dcdcdc", "hat": "bun", "skin": "efc9a5"}},
	{"id": "bin", "name": "Bé Bin", "role": "kid", "home": Vector2(15.9, 5.5), "house": Vector2(15.0, 7.6), "door": -1,
		"scale": 0.72, "play_offset": 0,
		"look": {"shirt": "ffd166", "pants": "4f8fbf", "hair": "2b1d14", "hat": "", "skin": "f3cfa8"}},
	{"id": "na", "name": "Bé Na", "role": "kid", "home": Vector2(14.1, 5.5), "house": Vector2(15.0, 7.6), "door": -1,
		"scale": 0.72, "play_offset": 3,
		"look": {"shirt": "f6a5c0", "pants": "f6a5c0", "hair": "2b1d14", "hat": "pigtails", "skin": "f3cfa8"}},
]

## Lời thoại khi người chơi bắt chuyện, theo vai trò.
const TALK := {
	"farmer": ["Lúa năm nay trổ bông đều lắm cháu ạ!", "Con trâu là đầu cơ nghiệp mà.", "Ruộng phải dẫn nước đủ thì mạ mới lên."],
	"merchant": ["Hôm nay chợ đang cần %s, mang ra bán được giá đấy!", "Hàng về nhiều thì giá hạ, ít thì giá lên cháu nhé.", "Mua gì cứ ghé quầy cô."],
	"fisher": ["Cá rô đồng mùa này béo lắm.", "Câu cá phải kiên nhẫn, vội là cá chạy hết.", "Ao làng sáng sớm cá ăn mồi nhiều nhất."],
	"poultry": ["Gà nhà bà đẻ đều lắm.", "Trứng gà ta luộc chấm muối tiêu là nhất.", "Sáng nào bà cũng dậy sớm cho gà ăn."],
	"kid": ["Chơi trốn tìm không? Bạn đi tìm nhé!", "Lát nữa ra giếng làng chơi với tụi mình!", "Mẹ bảo chiều nay có kẹo kéo ở chợ đó!"],
}
