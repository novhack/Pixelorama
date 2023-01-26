extends Node
class_name BasePaletteTool

var palette_tool_button: Button
var palette_panel: PalettePanel

var button_texture: Texture
var toggled_button_texture: Texture

var tooltip: String

class PaletteToolButton extends Button:
	var texture_rect: TextureRect

	func _init(tooltip: String, button_texture: Texture, toggled_button_texture = null) -> void:
		# Automatically setups button as toggle button if toggled texture is present
		if toggled_button_texture != null:
			toggle_mode = true

		texture_rect = TextureRect.new()
		texture_rect.texture = button_texture
		add_child(texture_rect)
		add_to_group("UIButtons")
		hint_tooltip = tooltip
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup_palette_tool(_palette_panel: PalettePanel) -> void:
	palette_panel = _palette_panel
	palette_tool_button = PaletteToolButton.new(tooltip, button_texture, toggled_button_texture)
	palette_panel.add_palette_tool_button(palette_tool_button)
	connect_button()


func connect_button() -> void:
	if palette_tool_button.toggle_mode:
		palette_tool_button.connect("toggled", self, "_on_palette_button_toggled")
	else:
		palette_tool_button.connect("pressed", self, "_on_palette_button_pressed")
	print("connected")


func _on_palette_button_pressed() -> void:
	start()


func _on_palette_button_toggled(toggled: bool) -> void:
	if toggled:
		activate()
		palette_tool_button.texture_rect.texture = toggled_button_texture
	else:
		deactivate()
		palette_tool_button.texture_rect.texture = button_texture


func activate() -> void:
	printerr("Palette tool activate behaviour not implemented!")


func deactivate() -> void:
	printerr("Palette tool deactivate behaviour not implemented!")


func start() -> void:
	printerr("Palette tool start behaviour not implemented!")
