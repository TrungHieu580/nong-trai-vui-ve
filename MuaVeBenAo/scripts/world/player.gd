extends CharacterBody3D
## Nhân vật người chơi: WASD/mũi tên di chuyển, xoay theo hướng đi.

const Art = preload("res://scripts/world/art.gd")
const SPEED := 5.0
const GRAVITY := 20.0

var input_enabled := true
var facing := Vector3(0, 0, 1)
var model: Node3D
var _t := 0.0


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.5
	shape.shape = cap
	shape.position = Vector3(0, 0.75, 0)
	add_child(shape)
	model = Art.build_farmer()
	add_child(model)


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if input_enabled:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = Vector3(v.x, 0.0, v.y)
	if dir.length_squared() > 0.0001:
		facing = dir.normalized()
		model.rotation.y = lerp_angle(model.rotation.y, atan2(facing.x, facing.z), minf(1.0, 14.0 * delta))
		_t += delta
		model.position.y = absf(sin(_t * 12.0)) * 0.07
	else:
		model.position.y = lerpf(model.position.y, 0.0, minf(1.0, 10.0 * delta))
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()


## Hiệu ứng nhún ngắn khi thao tác thành công.
func play_action() -> void:
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(1.12, 0.86, 1.12), 0.08)
	tw.tween_property(model, "scale", Vector3.ONE, 0.14)
