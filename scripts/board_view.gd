class_name BoardView
extends Control
## Draws the well with _draw(): the grid, locked numbers, glowing connectors
## between numbers that are one step apart, the falling piece and its landing
## ghost, and the star block.

const Pal := preload("res://scripts/palette.gd")

const COLS := 7
const ROWS := 16
const FLASH_TIME := 0.28

var model: BoardModel

var piece_cells: Array[Vector2i] = []
var piece_numbers: Array[int] = []
var ghost_cells: Array[Vector2i] = []
var flash_cells: Array[Vector2i] = []
var flash_time := 0.0

var cell_size := 40.0
var origin := Vector2.ZERO

var _font: Font
var _styles_cell_px := -1.0
var _number_styles: Array[StyleBoxFlat] = []
var _board_style: StyleBoxFlat
var _grid_style: StyleBoxFlat
var _ghost_style: StyleBoxFlat
var _flash_style: StyleBoxFlat
var _star_style: StyleBoxFlat
var _link_bar: StyleBoxFlat
var _link_glow: StyleBoxFlat


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time = maxf(0.0, flash_time - delta)
		if flash_time == 0.0:
			flash_cells.clear()
	queue_redraw()


func flash(cells: Array) -> void:
	flash_cells.clear()
	for cell in cells:
		flash_cells.append(cell)
	flash_time = FLASH_TIME


func cell_at(point: Vector2) -> Vector2i:
	if cell_size <= 0.0:
		return Vector2i(-1, -1)
	var local := (point - origin) / cell_size
	var cell := Vector2i(floori(local.x), floori(local.y))
	if cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
		return Vector2i(-1, -1)
	return cell


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0 or model == null:
		return
	cell_size = minf(size.x / float(COLS), size.y / float(ROWS))
	origin = (size - Vector2(COLS, ROWS) * cell_size) * 0.5
	_ensure_styles()

	var ci := get_canvas_item()
	var board_size := Vector2(COLS, ROWS) * cell_size
	_board_style.draw(ci, Rect2(origin - Vector2(6, 6), board_size + Vector2(12, 12)))

	for y in ROWS:
		for x in COLS:
			_grid_style.draw(ci, _cell_rect(Vector2i(x, y)))

	for cell in ghost_cells:
		if not model.cells.has(cell):
			_ghost_style.draw(ci, _cell_rect(cell))

	var flashing := {}
	var pulse := 0.0
	if flash_time > 0.0:
		pulse = flash_time / FLASH_TIME
		for cell in flash_cells:
			flashing[cell] = true

	for cell in model.cells.keys():
		_draw_number(cell, int(model.cells[cell]), flashing.has(cell), pulse)

	_draw_links()

	for i in piece_cells.size():
		var number := 1
		if i < piece_numbers.size():
			number = piece_numbers[i]
		if number == 0:
			_draw_star_cell(piece_cells[i])
		else:
			_draw_number(piece_cells[i], number, false, 0.0)


## A connector between two neighbouring numbers that step by one, so runs
## already built on the board are obvious at a glance.
func _draw_links() -> void:
	var breathe := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 650.0)
	_link_bar.bg_color.a = 0.62 + 0.20 * breathe
	_link_glow.bg_color.a = 0.10 + 0.12 * breathe
	var ci := get_canvas_item()
	for cell in model.cells.keys():
		var value := int(model.cells[cell])
		var east: Vector2i = cell + Vector2i(1, 0)
		if model.cells.has(east) and absi(int(model.cells[east]) - value) == 1:
			_draw_link(ci, cell, east)
		var south: Vector2i = cell + Vector2i(0, 1)
		if model.cells.has(south) and absi(int(model.cells[south]) - value) == 1:
			_draw_link(ci, cell, south)


func _draw_link(ci: RID, from_cell: Vector2i, to_cell: Vector2i) -> void:
	var center := (_cell_rect(from_cell).get_center() + _cell_rect(to_cell).get_center()) * 0.5
	var along := cell_size * 0.34
	var across := cell_size * 0.20
	var glow := across * 2.1
	if from_cell.y == to_cell.y:
		_link_glow.draw(ci, Rect2(center - Vector2(along * 0.5, glow * 0.5), Vector2(along, glow)))
		_link_bar.draw(ci, Rect2(center - Vector2(along * 0.5, across * 0.5), Vector2(along, across)))
	else:
		_link_glow.draw(ci, Rect2(center - Vector2(glow * 0.5, along * 0.5), Vector2(glow, along)))
		_link_bar.draw(ci, Rect2(center - Vector2(across * 0.5, along * 0.5), Vector2(across, along)))


func _ensure_styles() -> void:
	if is_equal_approx(_styles_cell_px, cell_size):
		return
	_styles_cell_px = cell_size
	var radius := int(maxf(3.0, cell_size * 0.18))
	var bar_radius := int(maxf(2.0, cell_size * 0.09))

	_number_styles.clear()
	for color in Pal.NUMBER_COLORS:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(radius)
		_number_styles.append(style)

	_board_style = StyleBoxFlat.new()
	_board_style.bg_color = Pal.BOARD_BG
	_board_style.set_corner_radius_all(radius + 6)
	_board_style.border_color = Pal.PANEL_EDGE
	_board_style.set_border_width_all(2)

	_grid_style = StyleBoxFlat.new()
	_grid_style.bg_color = Pal.GRID_CELL
	_grid_style.set_corner_radius_all(radius)

	_ghost_style = StyleBoxFlat.new()
	_ghost_style.bg_color = Pal.GHOST
	_ghost_style.set_corner_radius_all(radius)
	_ghost_style.border_color = Pal.GHOST_EDGE
	_ghost_style.set_border_width_all(2)

	_flash_style = StyleBoxFlat.new()
	_flash_style.bg_color = Color(1, 1, 1, 0)
	_flash_style.set_corner_radius_all(radius)

	_star_style = StyleBoxFlat.new()
	_star_style.bg_color = Pal.SPECIAL
	_star_style.set_corner_radius_all(radius)

	_link_bar = StyleBoxFlat.new()
	_link_bar.bg_color = Pal.LINK_BAR
	_link_bar.set_corner_radius_all(bar_radius)

	_link_glow = StyleBoxFlat.new()
	_link_glow.bg_color = Pal.LINK_GLOW
	_link_glow.set_corner_radius_all(bar_radius * 2)


func _cell_rect(cell: Vector2i, grow := 0.0) -> Rect2:
	var inset := cell_size * 0.055
	var pos := origin + Vector2(cell) * cell_size + Vector2(inset, inset)
	var side := cell_size - inset * 2.0
	return Rect2(pos - Vector2(grow, grow), Vector2(side + grow * 2.0, side + grow * 2.0))


func _draw_number(cell: Vector2i, number: int, flashing: bool, pulse: float) -> void:
	if number < 1 or number > 7:
		return
	var rect := _cell_rect(cell)
	_number_styles[number - 1].draw(get_canvas_item(), rect)
	if flashing:
		_flash_style.bg_color = Color(1, 1, 1, 0.85 * pulse)
		_flash_style.draw(get_canvas_item(), rect.grow(cell_size * 0.06 * pulse))
	var font_size := int(rect.size.y * 0.56)
	var text := str(number)
	var text_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		_font,
		Vector2(rect.get_center().x - text_width * 0.5, rect.get_center().y + font_size * 0.36),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Pal.CELL_TEXT
	)


func _draw_star_cell(cell: Vector2i) -> void:
	var rect := _cell_rect(cell)
	_star_style.draw(get_canvas_item(), rect)
	_draw_star(rect.get_center(), cell_size * 0.22, Pal.CELL_TEXT)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.36, -radius * 0.36),
		center + Vector2(radius, 0),
		center + Vector2(radius * 0.36, radius * 0.36),
		center + Vector2(0, radius),
		center + Vector2(-radius * 0.36, radius * 0.36),
		center + Vector2(-radius, 0),
		center + Vector2(-radius * 0.36, -radius * 0.36),
	])
	draw_colored_polygon(points, color)
