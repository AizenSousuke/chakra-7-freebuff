class_name Overlay
extends Control

const Pal := preload("res://scripts/palette.gd")

var title := ""
var lines: Array = []
var hint := ""

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	if _font == null or size.x <= 0.0 or size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.05, 0.82))

	var width := minf(size.x - 48.0, 460.0)
	var height := 250.0
	var rect := Rect2((size - Vector2(width, height)) * 0.5, Vector2(width, height))

	var panel := StyleBoxFlat.new()
	panel.bg_color = Pal.PANEL
	panel.set_corner_radius_all(18)
	panel.border_color = Pal.PANEL_EDGE
	panel.set_border_width_all(2)
	panel.draw(get_canvas_item(), rect)

	draw_string(_font, Vector2(rect.position.x, rect.position.y + 58), title, HORIZONTAL_ALIGNMENT_CENTER, width, 30, Pal.TEXT)

	var y := rect.position.y + 116
	for line in lines:
		draw_string(_font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_CENTER, width, 19, Color("#c7d2e3"))
		y += 32

	draw_string(_font, Vector2(rect.position.x, rect.end.y - 34), hint, HORIZONTAL_ALIGNMENT_CENTER, width, 15, Pal.SPECIAL)
