## GameOverState — Estado de derrota. Exibe motivo e aguarda reinício.
extends State

func enter() -> void:
	var reason = GameStateManager.game_over_reason
	match reason:
		GameStateManager.GameOverReason.MoraleDepleted:
			print("[GameOver] Derrota: Moral da tripulação chegou a 0!")
		GameStateManager.GameOverReason.Riot:
			print("[GameOver] Derrota: RIOT — A tripulação amotinou-se!")
