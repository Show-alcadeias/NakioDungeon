class_name NakioDice
extends RefCounted
var rng := RandomNumberGenerator.new()
func _init() -> void:
	rng.randomize()
func roll(bonus: int, target: int) -> Dictionary:
	return evaluate(rng.randi_range(1, 20), bonus, target)
static func evaluate(face: int, bonus: int, target: int) -> Dictionary:
	return {"face": face, "bonus": bonus, "total": face + bonus, "target": target,
		"success": face == 20 or (face != 1 and face + bonus >= target)}
