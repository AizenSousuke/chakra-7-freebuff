extends RefCounted
## Finds number chains on the board.
##
## A chain is a path of orthogonally adjacent cells whose values step by
## exactly one, covering a whole sequence:
##   1-2-3-4-5-6-7, 7-6-5-4-3-2-1, or a palindrome through seven
##   (1-7-1, and its mirror 7-1-7).
## Only the cells on the chain are cleared; neighbouring cells stay.

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


static func patterns() -> Array:
	var up: Array[int] = [1, 2, 3, 4, 5, 6, 7]
	var down: Array[int] = [7, 6, 5, 4, 3, 2, 1]
	var up_pal: Array[int] = [1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1]
	var down_pal: Array[int] = [7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7]
	return [up, down, up_pal, down_pal]


## Returns the longest complete chain path found on the board, or [] if none.
static func find_best(cells: Dictionary) -> Array:
	var best: Array = []
	for pattern in patterns():
		if pattern.size() <= best.size():
			continue
		for key in cells.keys():
			if int(cells[key]) != int(pattern[0]):
				continue
			var path := _walk(cells, key, pattern, 0, {})
			if path.size() > best.size():
				best = path
				if best.size() == 13:
					return best
	return best


static func _walk(cells: Dictionary, cell: Vector2i, pattern: Array, index: int, visited: Dictionary) -> Array:
	if visited.has(cell):
		return []
	if int(cells.get(cell, 0)) != int(pattern[index]):
		return []
	if index == pattern.size() - 1:
		return [cell]
	visited[cell] = true
	for dir in DIRS:
		var next: Vector2i = cell + dir
		if not cells.has(next):
			continue
		if int(cells[next]) != int(pattern[index + 1]):
			continue
		var tail := _walk(cells, next, pattern, index + 1, visited)
		if not tail.is_empty():
			visited.erase(cell)
			return [cell] + tail
	visited.erase(cell)
	return []


## True when the cell has a neighbour it forms a +/-1 step with.
static func has_link(cells: Dictionary, cell: Vector2i) -> bool:
	var value := int(cells.get(cell, 0))
	if value == 0:
		return false
	for dir in DIRS:
		var other := int(cells.get(cell + dir, 0))
		if other != 0 and absi(other - value) == 1:
			return true
	return false
