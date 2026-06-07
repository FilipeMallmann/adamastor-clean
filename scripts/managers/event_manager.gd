## EventManager — Gere a Event Phase do Adamastor.
## 5 eventos verificados em ordem: Learn Skill, Unrest, Disease, Fatigue, Riot.
extends Node

class_name EventManager

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum EventType {
	LEARN_A_SKILL,
	UNREST_AMONG_CREW,
	DISEASE_SPREADS,
	TIRED_CREW,
	RIOT,
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal event_triggered(event_type: EventType)
signal skill_gain_available(eligible_cards: Array, motivation_count: int)
signal skill_gained(card: CardData)

# ---------------------------------------------------------------------------
# LEARN A SKILL
# ---------------------------------------------------------------------------

## Retorna as cartas elegíveis para ganhar skill dado o contexto actual.
## Considera a skill EACH_SKILL_MINUS_1_COST se activa.
func get_eligible_skills(hand: Array, gained_skills: Array, motivation_count: int) -> Array:
	var eligible: Array = []
	for card in hand:
		if not card.has_skill:
			continue
		var required = card.skill_cost
		if _has_active_skill(gained_skills, CardData.SkillType.EACH_SKILL_MINUS_1_COST):
			required = max(required - 1, 1)
		if motivation_count >= required:
			eligible.append(card)
	return eligible


## Emite skill_gain_available se existirem cartas elegíveis.
func trigger_learn_skill(hand: Array, gained_skills: Array, motivation_count: int) -> void:
	var eligible = get_eligible_skills(hand, gained_skills, motivation_count)
	if eligible.is_empty():
		return
	event_triggered.emit(EventType.LEARN_A_SKILL)
	skill_gain_available.emit(eligible, motivation_count)


## Confirma a aquisição de uma skill. Remove da mão, adiciona às skills ganhas.
func confirm_gain_skill(card: CardData, hand: Array, gained_skills: Array) -> bool:
	if card == null or not card.has_skill:
		return false
	if not hand.has(card):
		return false
	hand.erase(card)
	gained_skills.append(card)
	skill_gained.emit(card)
	return true


# ---------------------------------------------------------------------------
# Modificadores de ícones por skills activas
# ---------------------------------------------------------------------------

## Aplica modificadores às contagens de ícones com base nas skills activas.
## Corrige o bug da referência: usa chaves string, compara skill_type por enum.
func apply_skill_modifiers(icons: Dictionary, gained_skills: Array) -> Dictionary:
	var modified = icons.duplicate()
	for skill_card in gained_skills:
		match skill_card.skill_type:
			CardData.SkillType.IGNORE_1_FATIGUE_IN_PLAY:
				modified["fatigue"] = max(0, modified.get("fatigue", 0) - 1)
			CardData.SkillType.IGNORE_1_DISEASE_IN_PLAY:
				modified["disease"] = max(0, modified.get("disease", 0) - 1)
			CardData.SkillType.IGNORE_1_UNREST_IN_PLAY:
				modified["unrest"] = max(0, modified.get("unrest", 0) - 1)
			CardData.SkillType.IGNORE_1_ANY_IN_PLAY:
				var max_type = _find_max_threat_type(modified)
				if max_type != "":
					modified[max_type] = max(0, modified.get(max_type, 0) - 1)
	return modified


func _find_max_threat_type(icons: Dictionary) -> String:
	var max_val = 0
	var max_type = ""
	for key in ["unrest", "disease", "fatigue"]:
		if icons.get(key, 0) > max_val:
			max_val = icons[key]
			max_type = key
	return max_type


# ---------------------------------------------------------------------------
# Verificação dos 5 eventos (retorna true se Riot → game over)
# ---------------------------------------------------------------------------

## Verifica UNREST AMONG CREW (5+ unrest).
## Retorna a carta descartada da Adventure Row (ou null).
func check_unrest(icons: Dictionary, queue_manager: QueueManager,
		trauma_manager: TraumaManager, deck_manager: MoraleDeckManager) -> CardData:
	if icons.get("unrest", 0) < 5:
		return null
	event_triggered.emit(EventType.UNREST_AMONG_CREW)
	var lowest = queue_manager.drop_smallest()
	if lowest == null:
		return null
	if lowest.has_trauma:
		trauma_manager.add_trauma(lowest)
	else:
		deck_manager.discard(lowest)
	# Comprar nova carta para a Adventure Row
	var new_card = deck_manager.draw_top()
	if new_card:
		queue_manager.add_card(new_card)
	return lowest


## Verifica DISEASE SPREADS (5+ disease).
## Perde 1 moral por trauma de doença existente; consome esses traumas.
func check_disease(icons: Dictionary, deck_manager: MoraleDeckManager,
		trauma_manager: TraumaManager) -> void:
	if icons.get("disease", 0) < 5:
		return
	event_triggered.emit(EventType.DISEASE_SPREADS)
	var disease_count = trauma_manager.consume_disease_traumas()
	if disease_count > 0:
		deck_manager.lose_morale(disease_count)


## Verifica TIRED CREW (5+ fatigue). Perde 3 morais.
func check_fatigue(icons: Dictionary, deck_manager: MoraleDeckManager) -> void:
	if icons.get("fatigue", 0) < 5:
		return
	event_triggered.emit(EventType.TIRED_CREW)
	deck_manager.lose_morale(3)


## Verifica RIOT (3+ de cada tipo). Retorna true se derrota imediata.
func check_riot(icons: Dictionary) -> bool:
	if (icons.get("unrest", 0) >= 3 and
			icons.get("disease", 0) >= 3 and
			icons.get("fatigue", 0) >= 3):
		event_triggered.emit(EventType.RIOT)
		return true
	return false


# ---------------------------------------------------------------------------
# Utilitários
# ---------------------------------------------------------------------------

func _has_active_skill(gained_skills: Array, skill_type: CardData.SkillType) -> bool:
	for card in gained_skills:
		if card.skill_type == skill_type:
			return true
	return false


func count_active_skill(gained_skills: Array, skill_type: CardData.SkillType) -> int:
	var count = 0
	for card in gained_skills:
		if card.skill_type == skill_type:
			count += 1
	return count


func get_event_description(event_type: EventType) -> String:
	match event_type:
		EventType.LEARN_A_SKILL: return "Learn a Skill: Gain 1 skill from your hand"
		EventType.UNREST_AMONG_CREW: return "Unrest Among Crew: Discard lowest card from Adventure Row"
		EventType.DISEASE_SPREADS: return "Disease Spreads: Lose 1 morale per disease trauma"
		EventType.TIRED_CREW: return "Tired Crew: Lose 3 morale"
		EventType.RIOT: return "RIOT: Immediate game over!"
		_: return "Unknown event"
