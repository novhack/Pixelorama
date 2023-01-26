extends BasePaletteTool

var color_select_mask_shader: Shader = preload("res://src/Shaders/ColorSelectMask.gdshader")
var color_replace_mask_shader: Shader = preload("res://src/Shaders/ColorReplaceMask.gdshader")

var masks := []

func _init(_palette_panel: PalettePanel) -> void:
	tooltip = tr("Color Matching Mode")
	button_texture = load("res://assets/graphics/palette/color_matching_mode_off.png")
	toggled_button_texture = load("res://assets/graphics/palette/color_matching_mode_on.png")
	setup_palette_tool(_palette_panel)


func activate() -> void:
	palette_panel.palette_grid.connect("swatch_double_clicked", self, "_swatch_double_clicked")
	palette_panel.hidden_color_picker.connect("color_changed", self, "_palette_color_changed")


func deactivate() -> void:
	palette_panel.palette_grid.disconnect("swatch_double_clicked", self, "_swatch_double_clicked")
	palette_panel.hidden_color_picker.disconnect("color_changed", self, "_palette_color_changed")


func _swatch_double_clicked(_mb: int, index: int, _click_position: Vector2) -> void:
	var color = palette_panel.palettes_logic.current_palette_get_color(index)
	var params := { "color": color }
	masks.clear()
	var gen := ShaderImageEffect.new()
	for i in range(Global.current_project.frames.size()):
		masks.push_back([])
		var frame = Global.current_project.frames[i]
		for j in range(frame.cels.size()):
			var cel = frame.cels[j]
			var mask_image = Image.new()
			mask_image.copy_from(cel.get_image())
			gen.generate_image(mask_image, color_select_mask_shader, params, Global.current_project.size)
			masks[i].push_back(mask_image)


func _palette_color_changed(color: Color) -> void:
	var gen := ShaderImageEffect.new()
	for i in range(Global.current_project.frames.size()):
		var frame = Global.current_project.frames[i]
		for j in range(frame.cels.size()):
			var cel = frame.cels[j]
			var texture = ImageTexture.new()
			texture.create_from_image(masks[i][j])
			var image = cel.get_image()
			var params := {
				"new_color": color,
				"mask": texture,
			}
			gen.generate_image(image, color_replace_mask_shader, params, Global.current_project.size)
			Global.current_project.frames[i].cels[j].image_changed(image)
