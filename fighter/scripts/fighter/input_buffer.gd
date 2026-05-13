class_name InputBuffer
extends Node

const BUFFER_SIZE: int = 60

var _player_id: int = 0
var _press_age: Dictionary = {}

const ACTIONS: Array[StringName] = [
	&"left", &"right", &"up", &"down",
	&"attack_a", &"attack_b", &"attack_c", &"attack_d",
]

func setup(player_id: int) -> void:
	_player_id = player_id
	for a in ACTIONS:
		_press_age[a] = -1

func tick() -> void:
	for a in ACTIONS:
		var action := _scoped(a)
		if Input.is_action_just_pressed(action):
			_press_age[a] = 0
		elif _press_age[a] >= 0 and _press_age[a] < BUFFER_SIZE:
			_press_age[a] += 1
		elif _press_age[a] >= BUFFER_SIZE:
			_press_age[a] = -1

func is_held(action: StringName) -> bool:
	return Input.is_action_pressed(_scoped(action))

func is_pressed(action: StringName, within: int = 8) -> bool:
	var age: int = _press_age.get(action, -1)
	if age < 0:
		return false
	if age <= within:
		_press_age[action] = -1
		return true
	return false

func axis_x() -> float:
	return Input.get_axis(_scoped(&"left"), _scoped(&"right"))

func axis_y() -> float:
	return Input.get_axis(_scoped(&"up"), _scoped(&"down"))

func _scoped(action: StringName) -> StringName:
	return StringName("p%d_%s" % [_player_id, action])
