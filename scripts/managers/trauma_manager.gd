## TraumaManager — Gere os traumas permanentes acumulados pela tripulação.
## Traumas são cartas colocadas de lado (rodadas 90°), visível só o ícone de trauma.
## Usa CardData.ThreatIcon como tipo canónico de trauma.
extends Node

class_name TraumaManager

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var permanent_traumas: Array = []  # Array[CardData] — cartas de trauma acumuladas

# ---------------------------------------------------------------------------
# Operações
# ---------------------------------------------------------------------------

func add_trauma(card: CardData) -> void:
	if card == null or not card.has_trauma:
		return
	permanent_traumas.append(card)


## Remove 1 trauma do tipo especificado. Retorna a carta removida ou null.
func remove_trauma(trauma_type: CardData.ThreatIcon) -> CardData:
	for i in permanent_traumas.size():
		if permanent_traumas[i].trauma_type == trauma_type:
			return permanent_traumas.pop_at(i)
	return null


## Remove 1 trauma de qualquer tipo. Retorna a carta removida ou null.
func remove_any_trauma() -> CardData:
	if permanent_traumas.is_empty():
		return null
	return permanent_traumas.pop_back()


func clear_traumas() -> void:
	permanent_traumas.clear()


# ---------------------------------------------------------------------------
# Contagem de ícones de trauma em jogo
# ---------------------------------------------------------------------------

func count_unrest() -> int:
	var total = 0
	for card in permanent_traumas:
		if card.trauma_type == CardData.ThreatIcon.UNREST:
			total += 1
	return total


func count_disease() -> int:
	var total = 0
	for card in permanent_traumas:
		if card.trauma_type == CardData.ThreatIcon.DISEASE:
			total += 1
	return total


func count_fatigue() -> int:
	var total = 0
	for card in permanent_traumas:
		if card.trauma_type == CardData.ThreatIcon.FATIGUE:
			total += 1
	return total


## Retorna a contagem de traumas de doença e remove-os (consumidos ao disparar evento).
func consume_disease_traumas() -> int:
	var count = 0
	var remaining: Array = []
	for card in permanent_traumas:
		if card.trauma_type == CardData.ThreatIcon.DISEASE:
			count += 1
		else:
			remaining.append(card)
	permanent_traumas = remaining
	return count


func get_total() -> int:
	return permanent_traumas.size()
