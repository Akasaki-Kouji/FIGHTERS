class_name StateMachine
extends Node

@export var initial_state: NodePath

var fighter: Fighter
var current: FighterState

func setup(owner_fighter: Fighter) -> void:
	fighter = owner_fighter
	for child in get_children():
		if child is FighterState:
			child.fighter = fighter
			child.machine = self
	if initial_state and has_node(initial_state):
		_change(get_node(initial_state) as FighterState)
	else:
		for child in get_children():
			if child is FighterState:
				_change(child)
				break

func physics_update(delta: float) -> void:
	if current:
		current.physics_update(delta)

func change_to(state_name: StringName) -> void:
	var target := get_node_or_null(NodePath(String(state_name)))
	if target is FighterState:
		_change(target)

func _change(next: FighterState) -> void:
	if current:
		current.exit()
	current = next
	current.enter()
