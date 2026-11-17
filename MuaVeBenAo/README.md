# Mùa Về Bên Ao – bản chơi thử

Game nông trại 3D thư giãn, làm bằng Godot 4 và GDScript, theo `Game_Nong_Trai_GDD.md` v0.1.

**Chơi ngay trên trình duyệt:** https://trunghieu580.github.io/nong-trai-vui-ve/

Mỗi lần đẩy code lên nhánh `main`, GitHub Actions tự chạy kiểm thử, xuất bản Web rồi cập nhật link trên sau khoảng 1–2 phút. Bản lỗi không được đăng. Tiến độ của mỗi người chơi được lưu trong trình duyệt của chính họ.

## Xóm làng tự vận hành

Một ngày trong game dài khoảng 8 phút thật, có sáng, trưa, chiều, tối. Ban đêm đèn lồng và cửa sổ nhà dân sáng lên. Dân làng tự làm việc theo lịch:

| Nhân vật | Công việc |
|---|---|
| Bác Ba | Ra ruộng lúa làng cùng con trâu: cày, cấy mạ, dẫn nước, gặt lúa, chiều gánh lúa ra chợ bán |
| Cô Lan | Đứng quầy chợ, mỗi giờ bán cho khách những món chợ đang tồn nhiều |
| Chú Tư | Câu cá ở ao làng, trưa và chiều mang cá ra chợ |
| Bà Năm | Cho gà ăn, sáng nhặt trứng mang ra chợ, trưa ra giếng hóng mát |
| Bé Bin, Bé Na | Chạy chơi khắp xóm: giếng làng, ao, đầu ruộng |

**Chợ có giá lên xuống**: mỗi món đang tồn ở chợ làm giá giảm 3%, thấp nhất còn một nửa giá gốc. Cô Lan bán bớt hàng thì giá hồi lại. Mỗi ngày chợ "đang cần" một mặt hàng và trả giá cao hơn 30%. Lúa của Bác Ba về chợ nhiều nên lúa thường rẻ.

Chạm vào dân làng (hoặc nhấn E khi đứng gần) để trò chuyện. Bảng **Tin làng** ở góc trái báo những việc vừa xảy ra. Giường dùng để ngủ tới 6 giờ sáng hôm sau. Nếu không đi ngủ, qua nửa đêm game vẫn tự sang ngày mới.

Logic mô phỏng nằm ở `scripts/sim/village_sim.gd` (không phụ thuộc hình ảnh). Lịch, địa điểm và lời thoại nằm ở `scripts/sim/village_data.gd`.

## Cây trồng (thời gian thực)

Gieo hạt rồi tưới một lần. Từ lúc tưới, cây lớn theo đồng hồ thật, kể cả khi đã đóng game. Cây càng lâu chín thì mỗi vụ càng lãi.

| Cây | Thời gian | Giá hạt | Thu | Giá bán | Lãi/vụ |
|---|---|---:|---|---:|---:|
| Rau muống | 30 giây | 4 | 2 bó | 5 | 6 |
| Cải ngọt | 1 phút | 8 | 2 cây | 9 | 10 |
| Cà rốt | 2 phút | 12 | 3 củ | 10 | 18 |
| Dưa leo | 3 phút | 15 | 3 quả | 12 | 21 |
| Cà chua | 4 phút | 18 | 4 quả | 11 | 26 |
| Ngô | 5 phút | 20 | 3 bắp | 16 | 28 |
| Ớt | 7 phút | 22 | 5 quả | 11 | 33 |
| Đậu phộng | 10 phút | 25 | 4 túi | 15 | 35 |
| Khoai lang | 15 phút | 30 | 3 củ | 25 | 45 |
| Lúa | 20 phút | 35 | 5 bao | 18 | 55 |
| Bí đỏ | 30 phút | 45 | 2 quả | 60 | 75 |
| Dưa hấu | 1 giờ | 60 | 2 quả | 100 | 140 |

Gà, bò và cá vẫn lớn theo đêm: cho ăn trong ngày, rồi ngủ ở giường để sang ngày mới. Số liệu nằm trong `scripts/sim/game_data.gd`.

## Chạy game

1. Cài **Godot 4.3 trở lên** (bản Standard, không cần bản .NET).
2. Mở Godot, chọn **Import** rồi chọn tệp `project.godot` trong thư mục này.
3. Nhấn **F5** để chơi.

| Phím | Tác dụng |
|---|---|
| WASD hoặc phím mũi tên | Di chuyển |
| E | Gieo, tưới, thu hoạch, cho ăn, ngủ, mở chợ (tuỳ đối tượng đang chọn) |
| 1 / 2 | Cầm hạt cải hoặc hạt cà rốt |
| Tab hoặc I | Mở túi đồ |
| H | Ẩn hoặc hiện hướng dẫn |
| Esc | Tạm dừng, hoặc đóng cửa sổ đang mở |

## Chạy kiểm thử

```
godot --headless --path . -s res://tests/run_tests.gd
```

Bộ kiểm thử chạy theo tiêu chí B02–B07 trong GDD, gồm cả kịch bản ngày 1–9 (có 226 xu và mở chuồng bò ở ngày 9). Mã thoát 0 nghĩa là tất cả đều đạt.

## Cấu trúc

```
scripts/sim/      Logic thuần, không phụ thuộc hình ảnh, kiểm thử được
  game_data.gd    Giá, chu kỳ, vật phẩm, hướng dẫn. Cân bằng game ở đây.
  farm_state.gd   Trạng thái một lượt chơi, chuyển sang JSON và đọc lại
  game_rules.gd   Luật: gieo, tưới, thu, cho ăn, mua, bán, công trình, ngủ
  save_system.gd  Lưu an toàn: tệp tạm, bản chính, bản sao
scripts/world/    Hình ảnh 3D tạm (art.gd) và nhân vật (player.gd)
scripts/ui/       HUD, chợ, túi đồ, tóm tắt cuối ngày, menu
scripts/main.gd   Ghép tất cả, chọn mục tiêu tương tác, lưu sau mỗi thao tác
tests/            Bộ kiểm thử headless
```

Bản lưu nằm ở `%APPDATA%\Godot\app_userdata\Mùa Về Bên Ao\` (gồm `save.json` và `save.bak`).

## Thay đổi so với GDD v0.1

- **Hạt quà không bán được**, và mỗi ngày chỉ nhận được một lần. Cách này chặn vòng lặp nhận hạt rồi bán lại để kiếm tiền.
- **Cám gà (3 xu) và cám cá (4 xu) là hai vật phẩm riêng.** Thức ăn của bò đặt tên là "Cỏ khô".
- Hướng dẫn có thêm bước **tưới lại rồi ngủ thêm một đêm**, vì cải cần 2 đêm mới chín.
- Phím nhanh hiện chỉ dùng **1–2** (hai loại hạt). Thao tác tưới, cho ăn và thu hoạch tự chọn theo đối tượng đang đứng gần.

## Việc tiếp theo

- **Tuần 4 – đồ hoạ**: thay các hàm `build_*` trong `scripts/world/art.gd` bằng cảnh `.glb` (tự dựng bằng Blender, hoặc dùng gói CC0 của Quaternius/Kenney).
- **Âm thanh**: chưa có. Cần thêm `AudioStreamPlayer` và thanh chỉnh âm lượng trong menu Cài đặt.
- Hiệu ứng làm mờ vật cản giữa camera và nhân vật.
- **Font tiếng Việt bo tròn** (Nunito hoặc Be Vietnam Pro): đặt vào `Theme` trong `game_ui.gd`.
- Xuất bản Windows: menu **Project → Export → Windows Desktop**.
