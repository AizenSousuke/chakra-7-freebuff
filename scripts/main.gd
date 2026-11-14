extends Control
## Chainfall — falling number-chain puzzle.
##
## Two-number dominoes fall into a 7x16 well. A chain clears when it covers
## 1-7, 7-1 or a full 1-7-1 palindrome. Every seventh piece is a star block: a
## single cell that drops like any other piece and deletes the joined group it
## lands on.

const Pal := preload("res://scripts/palette.gd")
const Finder := preload("res://scripts/sequence_finder.gd")

const SPECIAL_EVERY := 7
const BASE_GRAVITY := 0.85
const MIN_GRAVITY := 0.14
const GRAVITY_STEP := 0.055
const LOCK_DELAY := 0.42
const SAVE_PATH := "user://chainfall.cfg"

## Rotation slides the pivot to the first spot that fits, so a piece can turn
## against a wall or the floor.
const ROTATION_KICKS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1),
	Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1),
]

var model := BoardModel.new()
var generator := PieceGenerator.new()

var view: BoardView
var hud: Hud
var overlay: Overlay
var touch_bar: HBoxContainer

var piece: Piece
var upcoming: Piece
var piece_pos := Vector2i(3, 0)

var score := 0
var best := 0
var level := 1
var clears := 0
var pieces_since_special := 0

var fall_timer := 0.0
var lock_timer := 0.0
var resolving := false
var paused := false
var game_over := false

var _run_id := 0
var _drag := Vector2.ZERO
var _touch_travel := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	best = _load_best()
	_build_ui()
	resized.connect(_layout)
	_layout()
	_restart()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0a0c12")
	add_child(background)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	view = BoardView.new()
	view.model = model
	add_child(view)
	view.gui_input.connect(_on_board_input)

	hud = Hud.new()
	add_child(hud)

	touch_bar = _build_touch_bar()
	add_child(touch_bar)

	overlay = Overlay.new()
	overlay.visible = false
	add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.gui_input.connect(_on_overlay_input)


func _build_touch_bar() -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

	var specs := [
		["<", func() -> void: _move(-1)],
		["CCW", func() -> void: _rotate(-1)],
		["CW", func() -> void: _rotate(1)],
		[">", func() -> void: _move(1)],
		["DROP", func() -> void: _hard_drop()],
		["II", func() -> void: _toggle_pause()],
	]
	for spec in specs:
		var button := Button.new()
		button.text = spec[0]
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Pal.TEXT)
		button.add_theme_color_override("font_pressed_color", Pal.CELL_TEXT)
		button.add_theme_stylebox_override("normal", _button_style(Pal.PANEL))
		button.add_theme_stylebox_override("hover", _button_style(Pal.PANEL_EDGE))
		button.add_theme_stylebox_override("pressed", _button_style(Pal.SPECIAL))
		button.pressed.connect(spec[1])
		box.add_child(button)
	return box


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _layout() -> void:
	if view == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var wide := size.x > size.y * 1.15
	hud.landscape = wide
	var margin := 14.0
	var touch_visible := touch_bar.visible

	if wide:
		var hud_width: float = clampf(size.x * 0.22, 190.0, 280.0)
		var available: float = size.y - margin * 2.0
		if touch_visible:
			available -= 96.0
		var board_width: float = minf(size.x * 0.42, available * float(BoardView.COLS) / float(BoardView.ROWS))
		var board_height: float = board_width * float(BoardView.ROWS) / float(BoardView.COLS)
		var gap := 26.0
		var total_width := board_width + gap + hud_width
		var start_x: float = maxf(margin, (size.x - total_width) * 0.5)
		view.size = Vector2(board_width, board_height)
		view.position = Vector2(start_x, (size.y - board_height) * 0.5)
		hud.size = Vector2(hud_width, size.y - margin * 2.0)
		hud.position = Vector2(start_x + board_width + gap, margin)
		if touch_visible:
			touch_bar.size = Vector2(board_width, 76.0)
			touch_bar.position = Vector2(start_x, size.y - 88.0)
	else:
		var top := 100.0
		var bottom := 128.0 if touch_visible else 18.0
		var available: float = size.y - top - bottom
		var board_width: float = minf(size.x - margin * 2.0, available * float(BoardView.COLS) / float(BoardView.ROWS))
		var board_height: float = board_width * float(BoardView.ROWS) / float(BoardView.COLS)
		view.size = Vector2(board_width, board_height)
		view.position = Vector2((size.x - board_width) * 0.5, top + (available - board_height) * 0.5)
		hud.size = Vector2(size.x - margin * 2.0, top - 12.0)
		hud.position = Vector2(margin, 6.0)
		if touch_visible:
			var bar_width: float = minf(size.x - margin * 2.0, 560.0)
			touch_bar.size = Vector2(bar_width, 104.0)
			touch_bar.position = Vector2((size.x - bar_width) * 0.5, size.y - 116.0)

	overlay.position = Vector2.ZERO
	overlay.size = size
	hud.queue_redraw()


func _process(delta: float) -> void:
	if piece == null or resolving or paused or game_over:
		return
	if _is_grounded():
		lock_timer += delta
		if lock_timer >= LOCK_DELAY:
			_lock_piece_and_resolve()
	else:
		lock_timer = 0.0
		fall_timer += delta
		if fall_timer >= _gravity_interval():
			fall_timer = 0.0
			_step_down()
			if _is_grounded():
				lock_timer = 0.0
			_sync_view()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_LEFT, KEY_A:
			_move(-1)
		KEY_RIGHT, KEY_D:
			_move(1)
		KEY_DOWN, KEY_S:
			_soft_drop()
		KEY_UP, KEY_W:
			_rotate(1)
		KEY_X:
			_rotate(1)
		KEY_Z:
			_rotate(-1)
		KEY_SPACE:
			_hard_drop()
		KEY_P, KEY_ESCAPE:
			_toggle_pause()
		KEY_R:
			_restart()


# --- flow ---------------------------------------------------------------

func _restart() -> void:
	_run_id += 1
	model.reset()
	score = 0
	level = 1
	clears = 0
	pieces_since_special = 0
	upcoming = null
	piece = null
	fall_timer = 0.0
	lock_timer = 0.0
	resolving = false
	paused = false
	game_over = false
	_drag = Vector2.ZERO

	if overlay != null:
		overlay.visible = false
	if view != null:
		view.flash_cells.clear()
		view.flash_time = 0.0

	_spawn()


func _spawn() -> void:
	if pieces_since_special >= SPECIAL_EVERY:
		pieces_since_special = 0
		piece = Piece.star()
		piece_pos = piece.spawn_origin()
		fall_timer = 0.0
		lock_timer = 0.0
		if not model.can_place(piece.cells_at(piece_pos)):
			_sync_view()
			_end_game()
			return
		_sync_view()
		return

	if upcoming == null:
		upcoming = generator.next_piece(model)
	piece = upcoming
	upcoming = generator.next_piece(model)
	pieces_since_special += 1
	piece_pos = piece.spawn_origin()
	fall_timer = 0.0
	lock_timer = 0.0

	if not model.can_place(piece.cells_at(piece_pos)):
		_sync_view()
		_end_game()
		return
	_sync_view()


func _lock_piece_and_resolve() -> void:
	if resolving or piece == null:
		return
	resolving = true
	var run := _run_id

	if piece.is_special:
		await _lock_star(run)
		return

	var offsets := piece.offsets()
	for i in offsets.size():
		model.place(piece_pos + offsets[i], piece.numbers[i])
	piece = null
	_sync_view()

	await _resolve_board(run)
	if run != _run_id:
		return
	_spawn()
	resolving = false


func _lock_star(run: int) -> void:
	var removed := {}
	for group in model.linkage_groups(piece_pos):
		for member in group:
			removed[member] = true
	piece = null
	_sync_view()

	if removed.is_empty():
		# Nothing joined underneath: the star fizzles out instead of clogging
		# the well with an inert block.
		await _wait(0.12)
		if run != _run_id:
			return
		_spawn()
		resolving = false
		return

	score += 150 * removed.size() * level
	clears += 1
	level = 1 + int(clears / 3.0)
	view.flash(removed.keys())
	_update_hud()

	await _wait(0.24)
	if run != _run_id:
		return
	for member in removed:
		model.erase(member)
	_sync_view()

	await _resolve_board(run)
	if run != _run_id:
		return
	_spawn()
	resolving = false


func _resolve_board(run: int) -> void:
	var cascade := 0
	while true:
		if model.settle():
			_sync_view()
			await _wait(0.09)
			if run != _run_id:
				return

		var chain := Finder.find_best(model.cells)
		if chain.is_empty():
			break

		cascade += 1
		var base := 2100 if chain.size() >= 13 else 700
		score += base * level * cascade
		clears += 1
		level = 1 + int(clears / 3.0)
		if view != null:
			view.flash(chain)
		_update_hud()
		await _wait(0.24)
		if run != _run_id:
			return

		for cell in chain:
			model.erase(cell)
		_sync_view()

	_update_hud()


func _end_game() -> void:
	game_over = true
	piece = null
	_sync_view()
	if score > best:
		best = score
		_save_best()
	overlay.title = "GAME OVER"
	overlay.lines = ["Score  %d" % score, "Best  %d" % best, "Level  %d" % level]
	overlay.hint = "Press R or tap to play again"
	overlay.visible = true
	_update_hud()


func _toggle_pause() -> void:
	if game_over:
		return
	paused = not paused
	if paused:
		overlay.title = "PAUSED"
		overlay.lines = ["Score  %d" % score, "Level  %d" % level]
		overlay.hint = "Press P or tap to resume"
		overlay.visible = true
	else:
		overlay.visible = false


func _on_overlay_input(event: InputEvent) -> void:
	var pressed := false
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		pressed = true
	if not pressed:
		return
	if game_over:
		_restart()
	elif paused:
		_toggle_pause()


# --- movement -----------------------------------------------------------

func _move(delta_x: int) -> void:
	if paused or game_over or resolving or piece == null:
		return
	var target := piece_pos + Vector2i(delta_x, 0)
	if model.can_place(piece.cells_at(target)):
		piece_pos = target
		if _is_grounded():
			lock_timer = 0.0
		_sync_view()


func _rotate(step: int) -> void:
	if paused or game_over or resolving or piece == null or piece.is_special:
		return
	piece.rotate(step)
	for kick in ROTATION_KICKS:
		var target: Vector2i = piece_pos + kick
		if model.can_place(piece.cells_at(target)):
			piece_pos = target
			if _is_grounded():
				lock_timer = 0.0
			_sync_view()
			return
	piece.rotate(-step)


func _soft_drop() -> void:
	if paused or game_over or resolving or piece == null:
		return
	if _step_down():
		score += 1
		fall_timer = 0.0
		_update_hud()
		_sync_view()


func _hard_drop() -> void:
	if paused or game_over or resolving or piece == null:
		return
	var steps := 0
	while _step_down():
		steps += 1
	score += steps * 2
	lock_timer = LOCK_DELAY
	_update_hud()
	_sync_view()


func _step_down() -> bool:
	if piece == null:
		return false
	var target := piece_pos + Vector2i(0, 1)
	if model.can_place(piece.cells_at(target)):
		piece_pos = target
		return true
	return false


func _is_grounded() -> bool:
	if piece == null:
		return false
	return not model.can_place(piece.cells_at(piece_pos + Vector2i(0, 1)))


func _gravity_interval() -> float:
	return maxf(MIN_GRAVITY, BASE_GRAVITY - float(level - 1) * GRAVITY_STEP)


func _ghost_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if piece == null or piece.is_special:
		return out
	var drop := 0
	while model.can_place(piece.cells_at(piece_pos + Vector2i(0, drop + 1))):
		drop += 1
	for cell in piece.cells_at(piece_pos + Vector2i(0, drop)):
		out.append(cell)
	return out


# --- view ---------------------------------------------------------------

func _sync_view() -> void:
	if view == null:
		return
	view.model = model
	view.piece_cells.clear()
	view.piece_numbers.clear()
	view.ghost_cells = _ghost_cells()
	if piece != null:
		var offsets := piece.offsets()
		for i in offsets.size():
			view.piece_cells.append(piece_pos + offsets[i])
			view.piece_numbers.append(piece.numbers[i])
	view.queue_redraw()
	_update_hud()


func _update_hud() -> void:
	if hud == null:
		return
	hud.score = score
	hud.best = best
	hud.level = level
	hud.clears = clears
	hud.special_progress = pieces_since_special
	hud.special_ready = pieces_since_special >= SPECIAL_EVERY
	hud.special_active = piece != null and piece.is_special
	hud.next_is_special = pieces_since_special >= SPECIAL_EVERY
	if upcoming != null:
		hud.next_numbers = upcoming.numbers.duplicate()
		hud.next_orientation = upcoming.orientation
	else:
		hud.next_numbers = [1, 2]
		hud.next_orientation = 0
	hud.queue_redraw()


# --- touch / mouse ------------------------------------------------------

func _on_board_input(event: InputEvent) -> void:
	if game_over or paused or resolving:
		return

	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_rotate(1)
		return

	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_touch_travel = 0.0
			_drag = Vector2.ZERO
		elif _touch_travel < 20.0:
			_rotate(1)
		return

	var drag := event as InputEventScreenDrag
	if drag != null:
		_drag += drag.relative
		_touch_travel += drag.relative.length()
		var step := maxf(18.0, view.cell_size * 0.55)
		while absf(_drag.x) >= step:
			var direction := 1 if _drag.x > 0.0 else -1
			_move(direction)
			_drag.x -= direction * step
		while _drag.y >= step:
			_soft_drop()
			_drag.y -= step


# --- persistence --------------------------------------------------------

func _load_best() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		return int(config.get_value("scores", "best", 0))
	return 0


func _save_best() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("scores", "best", best)
	config.save(SAVE_PATH)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
