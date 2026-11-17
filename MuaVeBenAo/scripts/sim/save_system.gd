extends RefCounted
## Lưu/tải JSON an toàn:
##   ghi save.tmp → đọc lại kiểm tra → thay save.json → sao lưu thành save.bak.
## Khi tải: thử save.json, lỗi thì thử save.bak. Không bao giờ tự xoá tệp lỗi.

const FarmState = preload("res://scripts/sim/farm_state.gd")

var dir: String
var main_path: String
var tmp_path: String
var bak_path: String


func _init(save_dir: String = "user://") -> void:
	dir = save_dir
	main_path = save_dir.path_join("save.json")
	tmp_path = save_dir.path_join("save.tmp")
	bak_path = save_dir.path_join("save.bak")


func has_save() -> bool:
	return FileAccess.file_exists(main_path) or FileAccess.file_exists(bak_path)


## Trả về "" nếu lưu thành công, ngược lại là thông báo lỗi.
func save(state) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var text := JSON.stringify(state.to_dict(), "\t")
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return "Không mở được tệp tạm (%s)." % error_string(FileAccess.get_open_error())
	f.store_string(text)
	f.close()

	var probe = FarmState.new()
	var check = read_json(tmp_path)
	var problem: String = "Tệp tạm không đọc lại được." if typeof(check) != TYPE_DICTIONARY else probe.load_dict(check)
	if problem != "":
		return "Kiểm tra tệp lưu thất bại: %s Bản lưu cũ được giữ nguyên." % problem

	var g_main := ProjectSettings.globalize_path(main_path)
	var g_tmp := ProjectSettings.globalize_path(tmp_path)
	var g_bak := ProjectSettings.globalize_path(bak_path)
	if FileAccess.file_exists(main_path):
		DirAccess.remove_absolute(g_main)
	var err := DirAccess.rename_absolute(g_tmp, g_main)
	if err != OK:
		return "Không thay được tệp lưu chính (%s)." % error_string(err)
	err = DirAccess.copy_absolute(g_main, g_bak)
	if err != OK:
		return "Đã lưu nhưng không tạo được bản sao (%s)." % error_string(err)
	return ""


## Trả về {"ok": bool, "state": FarmState hoặc null, "msg": String}.
func load_game() -> Dictionary:
	var notes: Array[String] = []
	for path in [main_path, bak_path]:
		var label := "bản chính" if path == main_path else "bản sao"
		if not FileAccess.file_exists(path):
			notes.append("%s: không có tệp" % label)
			continue
		var data = read_json(path)
		var st = FarmState.new()
		var err: String = "tệp hỏng hoặc không phải JSON" if typeof(data) != TYPE_DICTIONARY else st.load_dict(data)
		if err == "":
			var msg := ""
			if path != main_path:
				msg = "Bản lưu chính bị lỗi (%s). Đã tải bản sao gần nhất." % notes[0]
			return {"ok": true, "state": st, "msg": msg}
		notes.append("%s: %s" % [label, err])
	return {"ok": false, "state": null, "msg": "Không tải được bản lưu – " + "; ".join(notes) + ". Tệp vẫn được giữ nguyên."}


static func read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


## Chỉ dùng cho kiểm thử.
func delete_all() -> void:
	for p in [main_path, tmp_path, bak_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
