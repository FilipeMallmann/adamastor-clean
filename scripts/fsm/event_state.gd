## EventState — Verifica os 5 eventos em ordem. Aguarda escolha do jogador para Learn a Skill.
extends State

var _waiting_for_skill: bool = false
var _icons_cache: Dictionary = {}

func enter() -> void:
	if GameStateManager.game_over_pending:
		transition_to(GameStateManager.GameState.GameOver)
		return
	if GameStateManager.game_won_pending:
		transition_to(GameStateManager.GameState.GameWon)
		return

	_waiting_for_skill = false
	var icons = GameStateManager.count_icons_in_play()
	_icons_cache = icons

	print("[Event] Ícones em jogo: %s" % str(icons))

	# 1. LEARN A SKILL
	var motivation = icons.get("motivation", 0)
	if motivation >= 2:
		var eligible = GameStateManager.event_service.get_eligible_skills(
			GameStateManager.hand_service.hand,
			GameStateManager.gained_skills,
			motivation
		)
		if not eligible.is_empty():
			_waiting_for_skill = true
			GameStateManager.event_service.skill_gain_available.emit(eligible, motivation)
			return  # Aguardar a escolha do jogador (ver confirm_skill)

	_resolve_remaining_events(icons)


## Chamado pela UI quando o jogador escolhe qual skill ganhar.
func confirm_skill(card: CardData) -> void:
	if not _waiting_for_skill:
		return
	_waiting_for_skill = false
	GameStateManager.event_service.confirm_gain_skill(
		card,
		GameStateManager.hand_service.hand,
		GameStateManager.gained_skills
	)
	_resolve_remaining_events(_icons_cache)


## Chamado pela UI se o jogador dispensar a escolha de skill.
func skip_skill() -> void:
	if not _waiting_for_skill:
		return
	_waiting_for_skill = false
	_resolve_remaining_events(_icons_cache)


func _resolve_remaining_events(icons: Dictionary) -> void:
	var ev = GameStateManager.event_service
	var deck = GameStateManager.morale_deck_service
	var queue = GameStateManager.queue_service
	var trauma = GameStateManager.trauma_service

	# 5. RIOT — verificar primeiro para sair imediatamente se for caso disso
	if ev.check_riot(icons):
		GameStateManager.trigger_game_over(GameStateManager.GameOverReason.Riot)
		transition_to(GameStateManager.GameState.GameOver)
		return

	# 2. UNREST AMONG CREW
	ev.check_unrest(icons, queue, trauma, deck)

	# 3. DISEASE SPREADS
	ev.check_disease(icons, deck, trauma)

	# 4. TIRED CREW
	ev.check_fatigue(icons, deck)

	if GameStateManager.game_over_pending:
		transition_to(GameStateManager.GameState.GameOver)
		return

	transition_to(GameStateManager.GameState.Sundown)
