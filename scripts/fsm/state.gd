extends Node
class_name State

var state_machine: GameStateMachine = null

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func handle_action(action_name: String) -> void:
	pass

func transition_to(state_name: GameStateManager.GameState) -> void:
	if state_machine:
		state_machine.change_state(state_name)
