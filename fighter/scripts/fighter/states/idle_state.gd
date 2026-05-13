class_name IdleState
extends FighterState

func enter() -> void:
	fighter.play_anim(&"idle")
	fighter.velocity.x = 0

func physics_update(_delta: float) -> void:
	if not fighter.is_on_floor():
		return

	var x := fighter.input.axis_x()
	var y := fighter.input.axis_y()

	if y > 0.5:
		machine.change_to(&"Crouch")
		return

	if fighter.input.is_pressed(&"up", 4):
		machine.change_to(&"Jump")
		return

	if absf(x) > 0.1:
		machine.change_to(&"Walk")
		return
