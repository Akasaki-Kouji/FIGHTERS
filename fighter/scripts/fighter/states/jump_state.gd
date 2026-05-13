class_name JumpState
extends FighterState

var _launched: bool = false

func enter() -> void:
	fighter.play_anim(&"jump")
	if fighter.is_on_floor():
		fighter.velocity.y = -fighter.character_data.jump_power
		_launched = true
	else:
		_launched = false

	var x := fighter.input.axis_x()
	if absf(x) > 0.1:
		var dir := 1 if x > 0.0 else -1
		var moving_forward := dir == fighter.facing
		var spd: float = fighter.character_data.walk_f_speed if moving_forward else fighter.character_data.walk_b_speed
		fighter.velocity.x = dir * spd

func exit() -> void:
	_launched = false

func physics_update(_delta: float) -> void:
	if not _launched:
		# 空中で誤って入った場合、着地で復帰
		if fighter.is_on_floor():
			machine.change_to(&"Idle")
		return
	# ジャンプ後、降下中に着地したら Idle
	if fighter.is_on_floor() and fighter.velocity.y >= 0.0:
		machine.change_to(&"Idle")
