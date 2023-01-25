class_name PalettePanel
extends PanelContainer

var palettes_path_id := {}
var palettes_id_path := {}

var edited_swatch_index := -1
var edited_swatch_color := Color.transparent
var swatch_was_edited := false

var palette_tools := []

onready var palette_select := $"%PaletteSelect"
onready var palette_grid := $"%PaletteGrid"
onready var palette_scroll := $"%PaletteScroll"

onready var add_color_button := $"%AddColor"
onready var delete_color_button := $"%DeleteColor"

onready var edit_palette_dialog := $"%EditPaletteDialog"
onready var create_palette_dialog := $"%CreatePaletteDialog"

# Color picker button itself is hidden but it's popup is used to edit color swatches
onready var hidden_color_picker := $"%HiddenColorPickerButton"

onready var palette_tools_buttons := $"%PaletteToolsButtons"

onready var palettes_logic = load("res://src/Palette/Palettes.gd").new()

func _ready() -> void:
	palettes_logic.load_palettes()

	edit_palette_dialog.palettes_logic = palettes_logic
	create_palette_dialog.palettes_logic = palettes_logic
	palette_grid.palettes_logic = palettes_logic

	Tools.connect("color_changed", self, "_color_changed")

	setup_palettes_selector()
	redraw_current_palette()

	# Hide presets from color picker
	hidden_color_picker.get_picker().presets_visible = false


# Setup palettes selector with available palettes
func setup_palettes_selector() -> void:
	# Clear selector
	palettes_path_id.clear()
	palettes_id_path.clear()
	palette_select.clear()

	var id := 0
	for palette_path in palettes_logic.get_palettes():
		# Add palette selector item
		palette_select.add_item(palettes_logic.get_palettes()[palette_path].name, id)

		# Map palette paths to item id's and otherwise
		palettes_path_id[palette_path] = id
		palettes_id_path[id] = palette_path
		id += 1


func select_palette(palette_path: String) -> void:
	var palette_id = palettes_path_id.get(palette_path)
	if palette_id != null:
		palette_select.selected = palette_id
		palettes_logic.select_palette(palette_path)
		palette_grid.set_palette(palettes_logic.get_current_palette())
		palette_scroll.resize_grid()
		palette_scroll.set_sliders(palettes_logic.get_current_palette(), palette_grid.grid_window_origin)

		var left_selected = palettes_logic.current_palette_get_selected_color_index(BUTTON_LEFT)
		var right_selected = palettes_logic.current_palette_get_selected_color_index(BUTTON_RIGHT)
		palette_grid.select_swatch(BUTTON_LEFT, left_selected, left_selected)
		palette_grid.select_swatch(BUTTON_RIGHT, right_selected, right_selected)

		toggle_add_delete_buttons()


# Has to be called on every Pixelorama theme change
func reset_empty_palette_swatches_color() -> void:
	palette_grid.reset_empty_swatches_color()


func redraw_current_palette() -> void:
	# Select and display current palette
	var current_palette = palettes_logic.get_current_palette()
	if current_palette:
		select_palette(current_palette.resource_path)
		add_color_button.show()
		delete_color_button.show()
	else:
		add_color_button.hide()
		delete_color_button.hide()


func toggle_add_delete_buttons() -> void:
	add_color_button.disabled = palettes_logic.current_palette_is_full()
	if add_color_button.disabled:
		add_color_button.mouse_default_cursor_shape = CURSOR_FORBIDDEN
	else:
		add_color_button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	delete_color_button.disabled = palettes_logic.current_palette_is_empty()
	if delete_color_button.disabled:
		delete_color_button.mouse_default_cursor_shape = CURSOR_FORBIDDEN
	else:
		delete_color_button.mouse_default_cursor_shape = CURSOR_POINTING_HAND


func add_palette_tool_button(button):
	palette_tools_buttons.add_child(button)


func _on_AddPalette_pressed() -> void:
	create_palette_dialog.open(palettes_logic.current_palette)


func _on_EditPalette_pressed() -> void:
	edit_palette_dialog.open(palettes_logic.current_palette)


func _on_PaletteSelect_item_selected(index: int) -> void:
	select_palette(palettes_id_path.get(index))


func _on_AddColor_gui_input(event: InputEvent) -> void:
	if palettes_logic.is_any_palette_selected():
		if (
			event is InputEventMouseButton
			and event.pressed
			and (event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT)
		):
			# Gets the grid index that corresponds to the top left of current grid window
			# Color will be added at the start of the currently scrolled part of palette
			# - not the absolute beginning of palette
			var start_index = palette_grid.convert_grid_index_to_palette_index(0)
			palettes_logic.current_palette_add_color(event.button_index, start_index)
			redraw_current_palette()
			toggle_add_delete_buttons()


func _on_DeleteColor_gui_input(event: InputEvent) -> void:
	if palettes_logic.is_any_palette_selected():
		if event is InputEventMouseButton and event.pressed:
			var selected_color_index = palettes_logic.current_palette_get_selected_color_index(
				event.button_index
			)

			if selected_color_index != -1:
				palettes_logic.current_palette_delete_color(selected_color_index)
				redraw_current_palette()
				toggle_add_delete_buttons()


func _on_CreatePaletteDialog_saved(
	preset: int,
	name: String,
	comment: String,
	width: int,
	height: int,
	add_alpha_colors: bool,
	colors_from: int
) -> void:
	palettes_logic.create_new_palette(preset, name, comment, width, height, add_alpha_colors, colors_from)
	setup_palettes_selector()
	redraw_current_palette()


func _on_EditPaletteDialog_saved(name: String, comment: String, width: int, height: int) -> void:
	palettes_logic.current_palette_edit(name, comment, width, height)
	setup_palettes_selector()
	redraw_current_palette()


func _on_PaletteGrid_swatch_double_clicked(_mb: int, index: int, click_position: Vector2) -> void:
	var color = palettes_logic.current_palette_get_color(index)
	edited_swatch_index = index
	hidden_color_picker.color = color

	# Open color picker popup with it's right bottom corner next to swatch
	var popup = hidden_color_picker.get_popup()
	popup.rect_position = click_position - popup.rect_size
	popup.popup()


func _on_PaletteGrid_swatch_dropped(source_index: int, target_index: int) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		palettes_logic.current_palette_insert_color(source_index, target_index)
	elif Input.is_key_pressed(KEY_CONTROL):
		palettes_logic.current_palette_copy_colors(source_index, target_index)
	else:
		palettes_logic.current_palette_swap_colors(source_index, target_index)

	redraw_current_palette()


func _on_PaletteGrid_swatch_pressed(mouse_button: int, index: int) -> void:
	# Gets previously selected color index
	var old_index = palettes_logic.current_palette_get_selected_color_index(mouse_button)
	palettes_logic.current_palette_select_color(mouse_button, index)
	palette_grid.select_swatch(mouse_button, index, old_index)


func _on_ColorPicker_color_changed(color: Color) -> void:
	if edited_swatch_index != -1:
		swatch_was_edited = true
		edited_swatch_color = color
		palette_grid.set_swatch_color(edited_swatch_index, color)

		if edited_swatch_index == palettes_logic.current_palette_get_selected_color_index(BUTTON_LEFT):
			Tools.assign_color(color, BUTTON_LEFT)
		if edited_swatch_index == palettes_logic.current_palette_get_selected_color_index(BUTTON_RIGHT):
			Tools.assign_color(color, BUTTON_RIGHT)


func _on_HiddenColorPickerButton_popup_closed():
	# Saves edited swatch to palette file when color selection dialog is closed
	if swatch_was_edited:
		palettes_logic.current_palette_set_color(edited_swatch_index, edited_swatch_color)
	swatch_was_edited = false


func _on_EditPaletteDialog_deleted() -> void:
	palettes_logic.current_palete_delete()
	setup_palettes_selector()
	redraw_current_palette()


func _color_changed(_color: Color, button: int) -> void:
	if hidden_color_picker.get_popup().visible == false and palettes_logic.get_current_palette():
		# Unselect swatches when tools color is changed
		var swatch_to_unselect = -1

		if button == BUTTON_LEFT:
			swatch_to_unselect = palettes_logic.left_selected_color
			palettes_logic.left_selected_color = -1
		elif button == BUTTON_RIGHT:
			swatch_to_unselect = palettes_logic.right_selected_color
			palettes_logic.right_selected_color = -1

		palette_grid.unselect_swatch(button, swatch_to_unselect)
