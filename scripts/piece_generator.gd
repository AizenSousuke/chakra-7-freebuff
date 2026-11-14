class_name PieceGenerator
extends RefCounted
## Two-number dominoes, biased a third of the time toward numbers that
## continue a chain already on the board, so full 1-7 runs stay reachable.

const BIAS_CHANCE := 0.32
const DOUBLE_CHANCE := 0.18

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func next_piece(model: BoardModel) -> Piece:
	var first := _pick_number(model)
	var second := first if rng.randf() < DOUBLE_CHANCE else _pick_number(model)
	return Piece.normal(first, second, rng.randi_range(0, 3))


func _pick_number(model: BoardModel) -> int:
	var options := model.extendable_numbers()
	if not options.is_empty() and rng.randf() < BIAS_CHANCE:
		return int(options[rng.randi_range(0, options.size() - 1)])
	return rng.randi_range(1, 7)
