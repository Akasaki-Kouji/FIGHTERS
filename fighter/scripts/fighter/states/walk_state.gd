class_name WalkState
extends FighterState

func enter() -> void:
	fighter.play_anim(&"walk_f")

func physics_update(_delta: float) -> void:
	if not fighter.is_on_floor():
		fighter.velocity.x = 0
		return

	var x := fighter.input.axis_x()
	var y := fighter.input.axis_y()

	if y > 0.5:
		machine.change_to(&"Crouch")
		return

	if fighter.input.is_pressed(&"up", 4):
		machine.change_to(&"Jump")
		return

	if absf(x) <= 0.1:
		machine.change_to(&"Idle")
		return

	var dir := 1 if x > 0.0 else -1
	var moving_forward := dir == fighter.facing
	if moving_forward:
		fighter.velocity.x = dir * fighter.character_data.walk_f_speed
		fighter.play_anim(&"walk_f")
	else:
		fighter.velocity.x = dir * fighter.character_data.walk_b_speed
		fighter.play_anim(&"walk_b")
