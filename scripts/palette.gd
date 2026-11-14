extends RefCounted
## Shared palette. Preloaded rather than given a class_name so it can be
## referenced from any script without depending on the class-name cache.

const NUMBER_COLORS: Array[Color] = [
	Color("#ff6b6b"),
	Color("#ffa94d"),
	Color("#ffd43b"),
	Color("#69db7c"),
	Color("#38d9a9"),
	Color("#4dabf7"),
	Color("#b197fc"),
]

const BOARD_BG := Color("#101420")
const GRID_CELL := Color("#181e2b")
const GHOST := Color(1.0, 1.0, 1.0, 0.09)
const GHOST_EDGE := Color(1.0, 1.0, 1.0, 0.20)
const LINK_BAR := Color(0.93, 0.97, 1.0, 0.55)
const LINK_GLOW := Color(0.72, 0.88, 1.0, 0.12)
const CELL_TEXT := Color("#0d1016")
const SPECIAL := Color("#ffe066")
const TARGET := Color(1.0, 0.88, 0.4, 0.12)
const TEXT := Color("#e8edf7")
const DIM := Color("#7f8a9e")
const PANEL := Color("#151a24")
const PANEL_EDGE := Color("#2b3444")
