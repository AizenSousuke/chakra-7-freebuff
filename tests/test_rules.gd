extends SceneTree
## Headless rule checks: godot --headless --path . --script tests/test_rules.gd

const Finder := preload("res://scripts/sequence_finder.gd")
const Model := preload("res://scripts/board_model.gd")
const PieceType := preload("res://scripts/piece.gd")

var failures := 0


func _initialize() -> void:
	_test_ascending()
	_test_descending()
	_test_palindrome()
	_test_partial_run_does_not_clear()
	_test_noise_does_not_block_chain()
	_test_settle()
	_test_star_groups()
	_test_rotation()
	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)


func _expect(label: String, condition: bool) -> void:
	if condition:
		print("  ok   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)


func _values(cells: Dictionary, path: Array) -> Array:
	var out := []
	for cell in path:
		out.append(int(cells[cell]))
	return out


func _test_ascending() -> void:
	var cells := {}
	for i in 7:
		cells[Vector2i(i, 0)] = i + 1
	cells[Vector2i(0, 1)] = 4
	cells[Vector2i(1, 1)] = 2
	var path := Finder.find_best(cells)
	_expect("ascending 1-7 is found", path.size() == 7)
	_expect("ascending path is ordered", _values(cells, path) == [1, 2, 3, 4, 5, 6, 7])


func _test_descending() -> void:
	var cells := {}
	for i in 7:
		cells[Vector2i(i, 3)] = 7 - i
	var path := Finder.find_best(cells)
	var values := _values(cells, path)
	_expect("descending 7-1 is found", path.size() == 7)
	_expect("descending run clears in either direction", values == [7, 6, 5, 4, 3, 2, 1] or values == [1, 2, 3, 4, 5, 6, 7])


func _test_palindrome() -> void:
	var cells := {}
	for i in 7:
		cells[Vector2i(i, 0)] = i + 1
	for i in 6:
		cells[Vector2i(6 - i, 1)] = 6 - i
	var path := Finder.find_best(cells)
	_expect("1-7-1 palindrome is found", path.size() == 13)
	_expect("palindrome path is ordered", _values(cells, path) == [1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1])


func _test_partial_run_does_not_clear() -> void:
	var cells := {}
	for i in 5:
		cells[Vector2i(i, 0)] = i + 1
	_expect("1-5 partial run does not clear", Finder.find_best(cells).is_empty())


func _test_noise_does_not_block_chain() -> void:
	var cells := {}
	for i in 7:
		cells[Vector2i(i, 5)] = i + 1
	cells[Vector2i(3, 4)] = 3
	cells[Vector2i(3, 6)] = 5
	var path := Finder.find_best(cells)
	_expect("chain still found with extra neighbours", path.size() == 7)


func _test_settle() -> void:
	var model := Model.new()
	model.place(Vector2i(2, 3), 4)
	model.place(Vector2i(2, 9), 5)
	model.place(Vector2i(2, 15), 6)
	model.settle()
	_expect("column compacted to the floor", model.cells.has(Vector2i(2, 15)) and model.cells.has(Vector2i(2, 14)) and model.cells.has(Vector2i(2, 13)) and model.cells.size() == 3)


func _test_rotation() -> void:
	var piece := PieceType.normal(3, 4, 0)
	var pivot := Vector2i(5, 5)
	_expect("second block starts to the right of the pivot", piece.cells_at(pivot) == [pivot, pivot + Vector2i(1, 0)])
	piece.rotate(1)
	_expect("clockwise: second block swings below", piece.cells_at(pivot) == [pivot, pivot + Vector2i(0, 1)])
	piece.rotate(1)
	_expect("clockwise: second block swings left", piece.cells_at(pivot) == [pivot, pivot + Vector2i(-1, 0)])
	piece.rotate(1)
	_expect("clockwise: second block swings above", piece.cells_at(pivot) == [pivot, pivot + Vector2i(0, -1)])
	piece.rotate(1)
	_expect("four turns return to the original facing", piece.cells_at(pivot) == [pivot, pivot + Vector2i(1, 0)])
	piece.rotate(-1)
	_expect("anticlockwise swings the other way", piece.cells_at(pivot) == [pivot, pivot + Vector2i(0, -1)])
	_expect("pivot is always the first cell", piece.cells_at(pivot)[0] == pivot)
	_expect("spawn origins keep both cells in the well", PieceType.normal(1, 2, 2).spawn_origin() == Vector2i(4, 0) and PieceType.normal(1, 2, 3).spawn_origin() == Vector2i(3, 1))


func _test_star_groups() -> void:
	var model := Model.new()
	model.place(Vector2i(2, 15), 3)
	model.place(Vector2i(3, 15), 4)
	model.place(Vector2i(5, 15), 7)
	var bridging := model.linkage_groups(Vector2i(4, 15))
	_expect("star touching two runs finds both groups", bridging.size() == 2)
	var landing := model.linkage_groups(Vector2i(3, 14))
	_expect("star landing on a run finds that group", landing.size() == 1 and landing[0].size() == 2)
	_expect("star on bare floor finds nothing", model.linkage_groups(Vector2i(6, 10)).is_empty())
