class_name Piece
extends RefCounted
## A two-number domino. The first cell is the pivot (the left block): it stays
## put while the second cell swings around it in 90-degree steps, like a clock.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # 0: second block to the right
	Vector2i(0, 1),   # 1: below
	Vector2i(-1, 0),  # 2: to the left
	Vector2i(0, -1),  # 3: above
]

var numbers: Array = [1, 1]
var orientation := 0
var is_special := false


static func normal(first: int, second: int, facing := 0) -> Piece:
	var piece := Piece.new()
	piece.numbers = [first, second]
	piece.orientation = wrapi(facing, 0, 4)
	return piece


static func star() -> Piece:
	var piece := Piece.new()
	piece.is_special = true
	piece.numbers = [0, 0]
	return piece


## Positive turns clockwise, negative turns anticlockwise.
func rotate(step: int) -> void:
	orientation = wrapi(orientation + step, 0, 4)


func offsets() -> Array[Vector2i]:
	var out: Array[Vector2i] = [Vector2i.ZERO]
	if is_special:
		return out
	out.append(DIRECTIONS[orientation])
	return out


func cells_at(origin: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for offset in offsets():
		out.append(origin + offset)
	return out


## Where the pivot must spawn so both cells start inside the well.
func spawn_origin() -> Vector2i:
	if is_special:
		return Vector2i(3, 0)
	match orientation:
		2:
			return Vector2i(4, 0)
		3:
			return Vector2i(3, 1)
		_:
			return Vector2i(3, 0)
