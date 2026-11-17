extends Node3D
## Hiển thị một dân làng: đọc trạng thái từ VillageSim mỗi khung hình,
## đặt vị trí, quay mặt, nhún khi đi, cúi khi làm việc, đổi dụng cụ cầm tay.

const Art = preload("res://scripts/world/art.gd")

var vid := ""
var display_name := ""
var model: Node3D
var label: Label3D
var tool_root: Node3D
var _tool := "?"
var _t := 0.0
var _scale := 1.0


func setup(def: Dictionary) -> void:
	vid = def["id"]
	display_name = def["name"]
	_scale = float(def.get("scale", 1.0))
	model = Art.build_person(def["look"])
	model.scale = Vector3.ONE * _scale
	add_child(model)
	tool_root = Node3D.new()
	model.add_child(tool_root)
	label = Art.label(display_name, Vector3(0, 2.0 * _scale + 0.25, 0), 28)
	add_child(label)
	_t = randf() * 10.0


func sync(v: Dictionary, delta: float) -> void:
	visible = v["visible"]
	if not visible:
		return
	var p: Vector2 = v["pos"]
	position = Vector3(p.x, 0.0, p.y)
	var f: Vector2 = v["facing"]
	model.rotation.y = lerp_angle(model.rotation.y, atan2(f.x, f.y), minf(1.0, 10.0 * delta))
	_t += delta
	if v["walking"]:
		model.position.y = absf(sin(_t * 11.0)) * 0.06
		model.rotation.x = 0.0
	elif v["tool"] in ["hoe", "sickle", "basket", "can"]:
		# Cúi lên cúi xuống khi làm việc
		model.position.y = 0.0
		model.rotation.x = maxf(0.0, sin(_t * 4.0)) * 0.22
	else:
		model.position.y = 0.0
		model.rotation.x = 0.0
	label.text = "%s\n%s" % [display_name, v["activity"]]
	var want: String = v["tool"]
	if want != _tool:
		_tool = want
		for c in tool_root.get_children():
			c.queue_free()
		if want != "":
			tool_root.add_child(Art.build_tool(want))
