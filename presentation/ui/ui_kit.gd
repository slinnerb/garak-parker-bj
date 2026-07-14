class_name UiKit
extends RefCounted
## Shared UI vocabulary (Phase 3b/4): the drowned-coast palette and a few small
## builders for labels, styleboxes, and buttons, so every screen speaks one
## visual language instead of re-deriving colours and paddings. Pure helpers —
## no state, no nodes retained.

# --- Palette (deep petrol dusk with a lantern-amber accent) ---
const BG := Color(0.055, 0.07, 0.092)
const PANEL := Color(0.10, 0.13, 0.15)
const PANEL_HI := Color(0.14, 0.18, 0.20)
const BORDER := Color(0.20, 0.27, 0.29)
const AMBER := Color(0.87, 0.64, 0.32)
const INK := Color(0.91, 0.89, 0.83)
const MUTED := Color(0.60, 0.68, 0.65)
const DANGER := Color(0.80, 0.40, 0.34)
const GOOD := Color(0.55, 0.72, 0.55)


static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func stylebox(bg: Color, border: Color, border_w: int = 1, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Applies normal/hover/pressed/disabled/focus styleboxes to a Button.
## `emphasized` thickens the border (selection / targetable highlight).
static func style_button(btn: Button, bg: Color, border: Color, emphasized: bool = false) -> void:
	var w := 2 if emphasized else 1
	btn.add_theme_stylebox_override("normal", stylebox(bg, border, w))
	btn.add_theme_stylebox_override("hover", stylebox(bg.lightened(0.06), border.lightened(0.15), maxi(w, 2)))
	btn.add_theme_stylebox_override("pressed", stylebox(bg.darkened(0.08), border, w))
	btn.add_theme_stylebox_override("disabled", stylebox(bg.darkened(0.10), BORDER.darkened(0.2), 1))
	btn.add_theme_stylebox_override("focus", stylebox(bg, border, w))
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", MUTED.darkened(0.1))


## Full-rect background rectangle for a screen root.
static func background(color: Color = BG) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return bg


## Recursively makes a control tree transparent to the mouse, so clicks fall
## through label/box children to the Button that owns them.
static func ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		ignore_mouse(child)
