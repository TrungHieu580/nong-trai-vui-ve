# Mùa Về Bên Ao – bản chơi thử

Game nông trại 3D thư giãn, làm bằng Godot 4 và GDScript, theo `Game_Nong_Trai_GDD.md` v0.1.

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
