class_name BoardModel
extends RefCounted
## Pure grid data. No nodes, no rendering — the view and the game both read it.

const COLS := 7
const ROWS := 16

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

## Vector2i -> int (1..7)
var cells: Dictionary = {}


func reset() -> void:
	cells.clear()


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS


func can_place(shape: Array) -> bool:
	for cell in shape:
		var c: Vector2i = cell
		if not in_bounds(c) or cells.has(c):
			return false
	return true


func place(cell: Vector2i, value: int) -> void:
	cells[cell] = value


func erase(cell: Vector2i) -> void:
	cells.erase(cell)


## Compacts every column downwards. Returns true when anything moved.
func settle() -> bool:
	var moved := false
	for x in COLS:
		var write_y := ROWS - 1
		for y in range(ROWS - 1, -1, -1):
			var from := Vector2i(x, y)
			if not cells.has(from):
				continue
			if write_y != y:
				cells[Vector2i(x, write_y)] = cells[from]
				cells.erase(from)
				moved = true
			write_y -= 1
	return moved


## All cells joined to `start` by +/-1 steps.
func group_at(start: Vector2i) -> Array:
	var out: Array = []
	if not cells.has(start):
		return out
	var seen := {start: true}
	var stack: Array = [start]
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		out.append(cell)
		var value := int(cells[cell])
		for dir in DIRS:
			var neighbour: Vector2i = cell + dir
			if not cells.has(neighbour) or seen.has(neighbour):
				continue
			if absi(int(cells[neighbour]) - value) != 1:
				continue
			seen[neighbour] = true
			stack.append(neighbour)
	return out


## Distinct joined groups touching an empty cell (the star block bridges them).
func linkage_groups(around: Vector2i) -> Array:
	var groups: Array = []
	var claimed := {}
	for dir in DIRS:
		var neighbour: Vector2i = around + dir
		if not cells.has(neighbour) or claimed.has(neighbour):
			continue
		var group := group_at(neighbour)
		for cell in group:
			claimed[cell] = true
		groups.append(group)
	return groups


## Numbers that would extend an existing chain at an open edge.
func extendable_numbers() -> Array[int]:
	var out: Array[int] = []
	var seen := {}
	for cell in cells.keys():
		var value := int(cells[cell])
		for dir in DIRS:
			if cells.has(cell + dir):
				continue
			for candidate in [value - 1, value + 1]:
				var number := int(candidate)
				if number < 1 or number > 7 or seen.has(number):
					continue
				seen[number] = true
				out.append(number)
	return out
