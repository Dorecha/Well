extends Node

const APP_NAME := "Museum 3D"
const ROOT_DIR := "user://museum_projects"
const PROJECTS_DIR := ROOT_DIR + "/projects"
const PIN := "0000"

var projects: Array = []
var current_project: Dictionary = {}
var current_exhibit_index := -1
var mode := "home"
var dark_theme := false

var root_ui: Control
var content: Control
var title_label: Label
var status_label: Label
var file_dialog: FileDialog
var theme_button: Button
var model_root: Node3D
var camera: Camera3D
var model_pivot: Node3D
var info_title: Label
var info_body: RichTextLabel
var exhibit_list: VBoxContainer

var editing_name: LineEdit
var editing_code: LineEdit
var editing_title: LineEdit
var editing_author: LineEdit
var editing_date: LineEdit
var editing_material: LineEdit
var editing_inventory: LineEdit
var editing_description: TextEdit
var selected_file_label: Label

var orbiting := false
var last_pointer := Vector2.ZERO
var camera_distance := 4.0
var model_loaded := false
var model_error := ""

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROJECTS_DIR))
    _build_root()
    _load_projects()
    _show_home()

func _build_root() -> void:
    root_ui = Control.new()
    root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root_ui)

    var bg := ColorRect.new()
    bg.color = Color("#f4f0eb")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_ui.add_child(bg)

    content = Control.new()
    content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_ui.add_child(content)

    title_label = Label.new()
    title_label.position = Vector2(55, 32)
    title_label.add_theme_font_size_override("font_size", 30)
    title_label.add_theme_color_override("font_color", Color("#4a3b32"))
    root_ui.add_child(title_label)

    status_label = Label.new()
    status_label.position = Vector2(55, 82)
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color("#8b796d"))
    root_ui.add_child(status_label)

    file_dialog = FileDialog.new()
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.add_filter("*.glb", "3D models (GLB)")
    file_dialog.add_filter("*.gltf", "3D models (glTF)")
    file_dialog.file_selected.connect(_on_model_selected)
    root_ui.add_child(file_dialog)

    theme_button = Button.new()
    theme_button.position = Vector2(1635, 35)
    theme_button.size = Vector2(230, 52)
    theme_button.add_theme_font_size_override("font_size", 16)
    theme_button.pressed.connect(_toggle_theme)
    root_ui.add_child(theme_button)
    _apply_theme()

func _toggle_theme() -> void:
    dark_theme = not dark_theme
    _apply_theme()

func _theme_bg() -> Color:
    return Color("#171513") if dark_theme else Color("#f4f0eb")

func _theme_panel() -> Color:
    return Color("#24211e") if dark_theme else Color("#fffdf9")

func _theme_text() -> Color:
    return Color("#f2ebe4") if dark_theme else Color("#4a3b32")

func _theme_secondary() -> Color:
    return Color("#b9aaa0") if dark_theme else Color("#736357")

func _theme_border() -> Color:
    return Color("#463d37") if dark_theme else Color("#e1d7cf")

func _theme_button() -> Color:
    return Color("#3b3631") if dark_theme else Color("#6f6d6b")

func _theme_button_hover() -> Color:
    return Color("#504942") if dark_theme else Color("#85817d")

func _style_box(bg: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    if border.a > 0.0:
        s.border_width_left = 1
        s.border_width_top = 1
        s.border_width_right = 1
        s.border_width_bottom = 1
        s.border_color = border
    return s

func _apply_theme() -> void:
    if root_ui == null:
        return
    var bg := root_ui.get_child(0) as ColorRect
    if bg:
        bg.color = _theme_bg()
    title_label.add_theme_color_override("font_color", _theme_text())
    status_label.add_theme_color_override("font_color", _theme_secondary())

    if theme_button:
        theme_button.text = "☀  Светлая тема" if dark_theme else "☾  Тёмная тема"
        theme_button.add_theme_color_override("font_color", _theme_text())
        theme_button.add_theme_stylebox_override("normal", _style_box(_theme_panel(), 12, _theme_border()))
        theme_button.add_theme_stylebox_override("hover", _style_box(_theme_button_hover(), 12, _theme_border()))
        theme_button.add_theme_stylebox_override("pressed", _style_box(_theme_button_hover(), 12, _theme_border()))

    _apply_theme_recursive(content)

func _apply_theme_recursive(node: Node) -> void:
    for child in node.get_children():
        if child is Panel:
            var panel := child as Panel
            panel.add_theme_stylebox_override("panel", _style_box(_theme_panel(), 24, _theme_border()))
        elif child is Button:
            var button := child as Button
            button.add_theme_color_override("font_color", _theme_text())
            button.add_theme_color_override("font_hover_color", _theme_text())
            button.add_theme_color_override("font_pressed_color", _theme_text())
            button.add_theme_stylebox_override("normal", _style_box(_theme_button(), 8))
            button.add_theme_stylebox_override("hover", _style_box(_theme_button_hover(), 8))
            button.add_theme_stylebox_override("pressed", _style_box(_theme_button_hover(), 8))
        elif child is Label:
            var label := child as Label
            label.add_theme_color_override("font_color", _theme_secondary())
        elif child is RichTextLabel:
            var rich := child as RichTextLabel
            rich.add_theme_color_override("default_color", _theme_secondary())
        elif child is LineEdit:
            var line := child as LineEdit
            line.add_theme_color_override("font_color", _theme_text())
            line.add_theme_color_override("caret_color", _theme_text())
            line.add_theme_stylebox_override("normal", _style_box(_theme_panel(), 8, _theme_border()))
            line.add_theme_stylebox_override("focus", _style_box(_theme_panel(), 8, _theme_secondary()))
        elif child is TextEdit:
            var edit := child as TextEdit
            edit.add_theme_color_override("font_color", _theme_text())
            edit.add_theme_color_override("caret_color", _theme_text())
            edit.add_theme_stylebox_override("normal", _style_box(_theme_panel(), 8, _theme_border()))
            edit.add_theme_stylebox_override("focus", _style_box(_theme_panel(), 8, _theme_secondary()))
        if child is Control:
            _apply_theme_recursive(child)

func _clear_content() -> void:
    for child in content.get_children():
        child.queue_free()

func _button(text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 20)
    b.add_theme_color_override("font_color", Color("#4a3b32"))
    b.pressed.connect(callback)
    content.add_child(b)
    return b

func _panel(pos: Vector2, size: Vector2) -> Panel:
    var p := Panel.new()
    p.position = pos
    p.size = size
    var style := StyleBoxFlat.new()
    style.bg_color = _theme_panel()
    style.corner_radius_top_left = 24
    style.corner_radius_top_right = 24
    style.corner_radius_bottom_left = 24
    style.corner_radius_bottom_right = 24
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = _theme_border()
    p.add_theme_stylebox_override("panel", style)
    content.add_child(p)
    return p

func _show_home() -> void:
    _clear_viewer_3d()
    _set_3d_background_visible(false)
    mode = "home"
    _clear_content()
    title_label.text = APP_NAME
    status_label.text = ""

    var panel := _panel(Vector2(620, 285), Vector2(680, 360))

    var head := Label.new()
    head.text = "Музейная экспозиция"
    head.position = Vector2(55, 45)
    head.add_theme_font_size_override("font_size", 32)
    head.add_theme_color_override("font_color", Color("#4a3b32"))
    panel.add_child(head)

    var open := Button.new()
    open.text = "Открыть проект"
    open.position = Vector2(55, 125)
    open.size = Vector2(570, 70)
    open.add_theme_font_size_override("font_size", 23)
    open.pressed.connect(_open_project_dialog)
    panel.add_child(open)

    var newb := Button.new()
    newb.text = "Создать новый проект"
    newb.position = Vector2(55, 215)
    newb.size = Vector2(570, 70)
    newb.add_theme_font_size_override("font_size", 23)
    newb.pressed.connect(_show_new_project)
    panel.add_child(newb)

func _show_new_project() -> void:
    _clear_viewer_3d()
    _set_3d_background_visible(false)
    mode = "new"
    _clear_content()
    title_label.text = "Новый проект"
    status_label.text = "Введите название и код проекта"

    var panel := _panel(Vector2(610, 240), Vector2(700, 500))
    _label_on(panel, "Название проекта", Vector2(55, 55), 18)
    editing_name = _line_on(panel, Vector2(55, 90), Vector2(590, 55), "Например: Древности Приморья")
    _label_on(panel, "Код проекта", Vector2(55, 170), 18)
    editing_code = _line_on(panel, Vector2(55, 205), Vector2(590, 55), "Например: PRIMORYE-01")

    var create := Button.new()
    create.text = "Создать"
    create.position = Vector2(55, 310)
    create.size = Vector2(285, 65)
    create.add_theme_font_size_override("font_size", 21)
    create.pressed.connect(_create_project)
    panel.add_child(create)

    var back := Button.new()
    back.text = "Назад"
    back.position = Vector2(360, 310)
    back.size = Vector2(285, 65)
    back.add_theme_font_size_override("font_size", 21)
    back.pressed.connect(_show_home)
    panel.add_child(back)
    _apply_theme()

func _create_project() -> void:
    var name := editing_name.text.strip_edges()
    var code := editing_code.text.strip_edges()
    if name.is_empty() or code.is_empty():
        _set_status("Заполните оба поля")
        return
    current_project = {
        "name": name,
        "code": code,
        "exhibits": []
    }
    projects.append(current_project)
    _save_project(current_project)
    current_project = projects[projects.size() - 1]
    _show_editor()

func _show_editor() -> void:
    _clear_viewer_3d()
    _set_3d_background_visible(false)
    mode = "editor"
    _clear_content()
    title_label.text = str(current_project.get("name", "Проект"))
    status_label.text = "Редактор экспонатов"

    var left := _panel(Vector2(45, 135), Vector2(390, 830))
    var list_head := Label.new()
    list_head.text = "ЭКСПОНАТЫ"
    list_head.position = Vector2(25, 25)
    list_head.add_theme_font_size_override("font_size", 20)
    left.add_child(list_head)

    exhibit_list = VBoxContainer.new()
    exhibit_list.position = Vector2(20, 70)
    exhibit_list.size = Vector2(350, 670)
    exhibit_list.add_theme_constant_override("separation", 8)
    left.add_child(exhibit_list)

    var add := Button.new()
    add.text = "+ Добавить экспонат"
    add.position = Vector2(25, 755)
    add.size = Vector2(340, 55)
    add.add_theme_font_size_override("font_size", 18)
    add.pressed.connect(_new_exhibit)
    left.add_child(add)

    var back := Button.new()
    back.text = "← Главное меню"
    back.position = Vector2(45, 985)
    back.size = Vector2(180, 50)
    back.pressed.connect(_show_home)
    content.add_child(back)

    var view := _panel(Vector2(455, 135), Vector2(1415, 830))
    var editor_title := Label.new()
    editor_title.text = "Данные экспоната"
    editor_title.position = Vector2(35, 25)
    editor_title.add_theme_font_size_override("font_size", 24)
    view.add_child(editor_title)

    _build_editor_form(view)
    _refresh_exhibit_list()
    _apply_theme()

func _build_editor_form(panel: Panel) -> void:
    _label_on(panel, "Название", Vector2(35, 80), 17)
    editing_title = _line_on(panel, Vector2(35, 112), Vector2(600, 48), "")
    _label_on(panel, "Автор / культура", Vector2(35, 180), 17)
    editing_author = _line_on(panel, Vector2(35, 212), Vector2(600, 48), "")
    _label_on(panel, "Дата", Vector2(35, 280), 17)
    editing_date = _line_on(panel, Vector2(35, 312), Vector2(600, 48), "")
    _label_on(panel, "Материал", Vector2(35, 380), 17)
    editing_material = _line_on(panel, Vector2(35, 412), Vector2(600, 48), "")
    _label_on(panel, "Инвентарный номер", Vector2(35, 480), 17)
    editing_inventory = _line_on(panel, Vector2(35, 512), Vector2(600, 48), "")
    _label_on(panel, "Описание", Vector2(680, 80), 17)
    editing_description = TextEdit.new()
    editing_description.position = Vector2(680, 112)
    editing_description.size = Vector2(680, 300)
    editing_description.add_theme_font_size_override("font_size", 17)
    panel.add_child(editing_description)

    _label_on(panel, "3D-модель", Vector2(680, 455), 17)
    selected_file_label = Label.new()
    selected_file_label.text = "Файл не выбран"
    selected_file_label.position = Vector2(680, 490)
    selected_file_label.size = Vector2(620, 40)
    selected_file_label.add_theme_color_override("font_color", Color("#736357"))
    panel.add_child(selected_file_label)

    var choose := Button.new()
    choose.text = "Выбрать GLB"
    choose.position = Vector2(680, 540)
    choose.size = Vector2(300, 58)
    choose.add_theme_font_size_override("font_size", 19)
    choose.pressed.connect(func(): file_dialog.popup_centered_ratio(0.8))
    panel.add_child(choose)

    var save := Button.new()
    save.text = "Сохранить экспонат"
    save.position = Vector2(1000, 540)
    save.size = Vector2(360, 58)
    save.add_theme_font_size_override("font_size", 19)
    save.pressed.connect(_save_current_exhibit)
    panel.add_child(save)

    var preview := Button.new()
    preview.text = "Открыть просмотр"
    preview.position = Vector2(680, 625)
    preview.size = Vector2(680, 62)
    preview.add_theme_font_size_override("font_size", 20)
    preview.pressed.connect(_show_viewer)
    panel.add_child(preview)

func _refresh_exhibit_list() -> void:
    for c in exhibit_list.get_children():
        c.queue_free()
    for i in range(current_project.get("exhibits", []).size()):
        var ex: Dictionary = current_project.exhibits[i]
        var b := Button.new()
        b.text = "%02d  %s" % [i + 1, str(ex.get("title", "Без названия"))]
        b.custom_minimum_size = Vector2(350, 52)
        b.add_theme_font_size_override("font_size", 16)
        b.pressed.connect(func(idx=i): _select_exhibit(idx))
        exhibit_list.add_child(b)

func _select_exhibit(index: int) -> void:
    current_exhibit_index = index
    var ex: Dictionary = current_project.exhibits[index]
    editing_title.text = str(ex.get("title", ""))
    editing_author.text = str(ex.get("author", ""))
    editing_date.text = str(ex.get("date", ""))
    editing_material.text = str(ex.get("material", ""))
    editing_inventory.text = str(ex.get("inventory", ""))
    editing_description.text = str(ex.get("description", ""))
    selected_file_label.text = str(ex.get("model_name", "Файл не выбран"))
    _set_status("Редактируется экспонат %d" % (index + 1))

func _new_exhibit() -> void:
    var ex := {
        "title": "Новый экспонат",
        "author": "",
        "date": "",
        "material": "",
        "inventory": "",
        "description": "",
        "model_path": "",
        "model_name": ""
    }
    current_project.exhibits.append(ex)
    _save_project(current_project)
    current_exhibit_index = current_project.exhibits.size() - 1
    _refresh_exhibit_list()
    _select_exhibit(current_exhibit_index)

func _save_current_exhibit() -> void:
    if current_exhibit_index < 0:
        _set_status("Сначала добавьте экспонат")
        return
    var ex: Dictionary = current_project.exhibits[current_exhibit_index]
    ex.title = editing_title.text.strip_edges()
    ex.author = editing_author.text.strip_edges()
    ex.date = editing_date.text.strip_edges()
    ex.material = editing_material.text.strip_edges()
    ex.inventory = editing_inventory.text.strip_edges()
    ex.description = editing_description.text
    current_project.exhibits[current_exhibit_index] = ex
    _save_project(current_project)
    _refresh_exhibit_list()
    _set_status("Сохранено")

func _open_project_dialog() -> void:
    if projects.is_empty():
        _set_status("Проектов пока нет")
        return
    var popup := AcceptDialog.new()
    popup.title = "Выберите проект"
    popup.size = Vector2(600, 450)
    var list := VBoxContainer.new()
    list.position = Vector2(25, 25)
    list.size = Vector2(540, 330)
    popup.add_child(list)
    for i in range(projects.size()):
        var b := Button.new()
        b.text = "%s  [%s]" % [projects[i].name, projects[i].code]
        b.custom_minimum_size = Vector2(530, 55)
        b.pressed.connect(func(idx=i, p=popup): p.queue_free(); current_project = projects[idx]; _show_editor())
        list.add_child(b)
    root_ui.add_child(popup)
    popup.popup_centered()

func _on_model_selected(path: String) -> void:
    if current_exhibit_index < 0:
        _set_status("Сначала создайте экспонат")
        return
    var source := FileAccess.open(path, FileAccess.READ)
    if source == null:
        _set_status("Не удалось открыть файл")
        return
    var data := source.get_buffer(source.get_length())
    source.close()
    var safe_name := path.get_file().replace(" ", "_")
    var project_dir := PROJECTS_DIR + "/" + _safe_folder(str(current_project.code))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    var target := project_dir + "/" + safe_name
    var out := FileAccess.open(target, FileAccess.WRITE)
    if out == null:
        _set_status("Не удалось сохранить модель")
        return
    out.store_buffer(data)
    out.close()
    var ex: Dictionary = current_project.exhibits[current_exhibit_index]
    ex.model_path = target
    ex.model_name = path.get_file()
    current_project.exhibits[current_exhibit_index] = ex
    _save_project(current_project)
    selected_file_label.text = path.get_file()
    _set_status("3D-модель добавлена")

func _show_viewer() -> void:
    _clear_viewer_3d()
    _set_3d_background_visible(true)
    if current_exhibit_index < 0 and current_project.get("exhibits", []).size() > 0:
        current_exhibit_index = 0
    if current_project.get("exhibits", []).is_empty():
        _set_status("Добавьте хотя бы один экспонат")
        return
    mode = "viewer"
    _clear_content()
    title_label.text = str(current_project.get("name", "Экспозиция"))
    status_label.text = "Режим просмотра"
    _build_viewer()
    _load_current_model()

func _build_viewer() -> void:
    # 3D теперь рендерится непосредственно в корневой Viewport Godot.
    # SubViewport/ViewportTexture здесь больше не используется.
    var model_panel := _panel(Vector2(45, 135), Vector2(1030, 830))
    var transparent_style := _style_box(Color(0, 0, 0, 0), 24, _theme_border())
    model_panel.add_theme_stylebox_override("panel", transparent_style)

    var info_panel := _panel(Vector2(1100, 135), Vector2(775, 830))

    # Отдельный SubViewport даёт настоящую обрезку по рамке модели
    # и автоматически передаёт мышь/тач в область 3D.
    var model_host := SubViewportContainer.new()
    model_host.position = Vector2(1, 1)
    model_host.size = Vector2(1028, 828)
    model_host.stretch = true
    model_host.mouse_filter = Control.MOUSE_FILTER_STOP
    model_panel.add_child(model_host)

    var viewport := SubViewport.new()
    viewport.transparent_bg = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.world_3d = World3D.new()
    model_host.add_child(viewport)
    model_host.gui_input.connect(_on_model_gui_input)

    model_root = Node3D.new()
    viewport.add_child(model_root)

    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#f6f1eb")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#fff8ef")
    environment.ambient_light_energy = 1.0
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    model_root.add_child(env)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -25, 0)
    light.light_energy = 1.5
    light.shadow_enabled = true
    model_root.add_child(light)

    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20, 145, 20)
    fill.light_energy = 0.7
    model_root.add_child(fill)

    model_pivot = Node3D.new()
    model_root.add_child(model_pivot)

    # Диагностический куб: должен быть строго внутри области 3D.
    var test_mesh := MeshInstance3D.new()
    var test_box := BoxMesh.new()
    test_box.size = Vector3(0.8, 0.8, 0.8)
    test_mesh.mesh = test_box
    test_mesh.position = Vector3(-1.2, -0.5, 0.0)
    var test_material := StandardMaterial3D.new()
    test_material.albedo_color = Color(0.85, 0.08, 0.08, 1.0)
    test_material.roughness = 0.45
    test_mesh.material_override = test_material
    model_root.add_child(test_mesh)

    camera = Camera3D.new()
    camera.position = Vector3(0, 0.2, camera_distance)
    camera.fov = 45.0
    camera.near = 0.01
    camera.far = 10000.0
    model_root.add_child(camera)
    camera.look_at_from_position(camera.position, Vector3.ZERO)
    camera.make_current()

    info_title = Label.new()
    info_title.position = Vector2(35, 35)
    info_title.size = Vector2(705, 70)
    info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_title.add_theme_font_size_override("font_size", 30)
    info_title.add_theme_color_override("font_color", Color("#4a3b32"))
    info_panel.add_child(info_title)

    info_body = RichTextLabel.new()
    info_body.position = Vector2(35, 120)
    info_body.size = Vector2(705, 500)
    info_body.bbcode_enabled = true
    info_body.fit_content = false
    info_body.add_theme_font_size_override("normal_font_size", 19)
    info_body.add_theme_color_override("default_color", Color("#736357"))
    info_panel.add_child(info_body)

    var prev := Button.new()
    prev.text = "‹"
    prev.position = Vector2(35, 670)
    prev.size = Vector2(75, 75)
    prev.add_theme_font_size_override("font_size", 35)
    prev.pressed.connect(_prev_exhibit)
    info_panel.add_child(prev)

    var next := Button.new()
    next.text = "›"
    next.position = Vector2(130, 670)
    next.size = Vector2(75, 75)
    next.add_theme_font_size_override("font_size", 35)
    next.pressed.connect(_next_exhibit)
    info_panel.add_child(next)

    var hint := Label.new()
    hint.text = "Проведите пальцем по модели — вращение • щипок — масштаб"
    hint.position = Vector2(80, 745)
    hint.size = Vector2(900, 35)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", Color("#8b796d"))
    model_panel.add_child(hint)

    model_panel.gui_input.connect(_on_model_gui_input)
    _apply_theme()
    # _apply_theme() стилизует Panel заново, поэтому возвращаем прозрачность области 3D.
    model_panel.add_theme_stylebox_override("panel", transparent_style)


func _set_3d_background_visible(viewer: bool) -> void:
    if root_ui == null or root_ui.get_child_count() == 0:
        return
    var bg := root_ui.get_child(0) as ColorRect
    if bg:
        bg.visible = not viewer


func _clear_viewer_3d() -> void:
    if model_root != null and is_instance_valid(model_root):
        model_root.queue_free()
    model_root = null
    model_pivot = null
    camera = null
    model_loaded = false
    model_error = ""


func _load_current_model() -> void:
    # Удаляем только предыдущую импортированную модель.
    if model_pivot == null or camera == null:
        _set_status("Ошибка: 3D-сцена не создана")
        return
    for child in model_pivot.get_children():
        child.queue_free()

    model_pivot.position = Vector3.ZERO
    model_pivot.rotation = Vector3.ZERO
    model_pivot.scale = Vector3.ONE
    model_loaded = false

    var ex: Dictionary = current_project.exhibits[current_exhibit_index]
    info_title.text = str(ex.get("title", "Экспонат"))

    var body := ""
    if not str(ex.get("author", "")).is_empty():
        body += "[b]Автор / культура:[/b] " + str(ex.author) + "\n\n"
    if not str(ex.get("date", "")).is_empty():
        body += "[b]Дата:[/b] " + str(ex.date) + "\n\n"
    if not str(ex.get("material", "")).is_empty():
        body += "[b]Материал:[/b] " + str(ex.material) + "\n\n"
    if not str(ex.get("inventory", "")).is_empty():
        body += "[b]Инвентарный номер:[/b] " + str(ex.inventory) + "\n\n"
    body += str(ex.get("description", ""))
    info_body.text = body

    var path := str(ex.get("model_path", ""))
    if path.is_empty() or not FileAccess.file_exists(path):
        _set_status("У экспоната нет 3D-модели")
        return

    # Внешний GLB нельзя загрузить через ResourceLoader как PackedScene:
    # Godot импортирует такие файлы только когда они лежат внутри проекта.
    # Для файлов, которые сотрудник выбирает с диска, используем GLTFDocument
    # и импортируем GLB прямо во время работы приложения.
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var error: Error = document.append_from_file(path, state)

    if error != OK:
        model_error = error_string(error)
        _add_viewer_test_object()
        _set_status("Ошибка GLB: %s" % model_error)
        return

    var generated: Node = document.generate_scene(state)
    if generated == null or not generated is Node3D:
        model_error = "generate_scene() не вернул Node3D"
        _add_viewer_test_object()
        _set_status("Ошибка GLB: " + model_error)
        return

    var scene_3d: Node3D = generated as Node3D
    model_pivot.add_child(scene_3d)
    await get_tree().process_frame

    var mesh_count := _count_meshes(scene_3d)
    if mesh_count == 0:
        model_error = "В сгенерированной сцене 0 MeshInstance3D"
        _add_viewer_test_object()
        _set_status("Ошибка GLB: " + model_error)
        return

    _fit_model(scene_3d)
    model_loaded = true
    _set_status("Модель загружена")


func _add_viewer_test_object() -> void:
    if model_root == null:
        return
    var test_mesh := MeshInstance3D.new()
    var test_box := BoxMesh.new()
    test_box.size = Vector3(0.8, 0.8, 0.8)
    test_mesh.mesh = test_box
    test_mesh.position = Vector3(0.0, 0.0, 0.0)
    var test_material := StandardMaterial3D.new()
    test_material.albedo_color = Color(0.85, 0.08, 0.08, 1.0)
    test_material.roughness = 0.45
    test_mesh.material_override = test_material
    model_root.add_child(test_mesh)


func _count_meshes(node: Node) -> int:
    var count := 0
    for child in node.get_children():
        if child is MeshInstance3D:
            count += 1
        count += _count_meshes(child)
    return count


func _fit_model(scene: Node3D) -> void:
    # Сначала считаем реальные границы всей импортированной сцены.
    var bounds := _calculate_bounds(scene)
    if bounds.size.length() <= 0.001:
        _set_status("GLB загружен, но в нём не найдена геометрия")
        return

    # Центрируем и масштабируем весь импортированный объект через pivot.
    # Это надёжнее, чем менять position корневого узла GLTF-сцены:
    # у некоторых GLB корневой узел имеет собственную трансформацию.
    var center: Vector3 = bounds.position + bounds.size * 0.5
    var diameter: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
    var scale_factor: float = 2.4 / maxf(diameter, 0.001)

    model_pivot.position = -center
    model_pivot.scale = Vector3.ONE * scale_factor
    model_pivot.rotation = Vector3.ZERO

    camera_distance = 4.0
    camera.position = Vector3(0.0, 0.2, camera_distance)
    camera.look_at(Vector3.ZERO)
    camera.make_current()
    _set_status("Модель загружена")


func _calculate_bounds(node: Node) -> AABB:
    var found := false
    var result := AABB()

    for child in node.get_children():
        if child is MeshInstance3D:
            var mesh_child: MeshInstance3D = child as MeshInstance3D
            var local_box: AABB = mesh_child.get_aabb()

            var corners: Array[Vector3] = [
                local_box.position,
                local_box.position + Vector3(local_box.size.x, 0.0, 0.0),
                local_box.position + Vector3(0.0, local_box.size.y, 0.0),
                local_box.position + Vector3(0.0, 0.0, local_box.size.z),
                local_box.position + Vector3(local_box.size.x, local_box.size.y, 0.0),
                local_box.position + Vector3(local_box.size.x, 0.0, local_box.size.z),
                local_box.position + Vector3(0.0, local_box.size.y, local_box.size.z),
                local_box.end
            ]

            for corner: Vector3 in corners:
                var world_point: Vector3 = mesh_child.global_transform * corner
                if not found:
                    result = AABB(world_point, Vector3.ZERO)
                    found = true
                else:
                    result = result.expand(world_point)

        if child is Node:
            var sub: AABB = _calculate_bounds(child)
            if sub.size.length() > 0.001:
                if not found:
                    result = sub
                    found = true
                else:
                    result = result.merge(sub)

    return result


func _on_model_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            orbiting = event.pressed
            last_pointer = event.position
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = max(1.5, camera_distance - 0.3)
            camera.position.z = camera_distance
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = min(10.0, camera_distance + 0.3)
            camera.position.z = camera_distance
    elif event is InputEventMouseMotion and orbiting:
        _orbit(event.relative)
    elif event is InputEventScreenTouch:
        if event.index == 0:
            orbiting = event.pressed
            last_pointer = event.position
    elif event is InputEventScreenDrag and event.index == 0:
        _orbit(event.relative)
    elif event is InputEventMagnifyGesture:
        camera_distance = clamp(camera_distance / event.factor, 1.5, 10.0)
        camera.position.z = camera_distance

func _input(event: InputEvent) -> void:
    if mode == "viewer" and event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            _show_editor()
            get_viewport().set_input_as_handled()

func _orbit(delta: Vector2) -> void:
    if model_pivot == null:
        return
    model_pivot.rotate_y(-delta.x * 0.01)
    model_pivot.rotate_x(-delta.y * 0.006)
    model_pivot.rotation.x = clamp(model_pivot.rotation.x, -1.3, 1.3)

func _prev_exhibit() -> void:
    if current_project.exhibits.is_empty(): return
    current_exhibit_index = (current_exhibit_index - 1 + current_project.exhibits.size()) % current_project.exhibits.size()
    _load_current_model()

func _next_exhibit() -> void:
    if current_project.exhibits.is_empty(): return
    current_exhibit_index = (current_exhibit_index + 1) % current_project.exhibits.size()
    _load_current_model()

func _label_on(parent: Control, text: String, pos: Vector2, font_size: int) -> void:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color("#736357"))
    parent.add_child(l)

func _line_on(parent: Control, pos: Vector2, size: Vector2, placeholder: String) -> LineEdit:
    var e := LineEdit.new()
    e.position = pos
    e.size = size
    e.placeholder_text = placeholder
    e.add_theme_font_size_override("font_size", 18)
    parent.add_child(e)
    return e

func _set_status(text: String) -> void:
    status_label.text = text

func _safe_folder(s: String) -> String:
    var out := s
    for c in ["/", ":", "*", "?", "<", ">", "|", " "]:
        out = out.replace(c, "_")
    out = out.replace("\\", "_")
    return out

func _project_file(code: String) -> String:
    return PROJECTS_DIR + "/" + _safe_folder(code) + ".json"

func _save_project(project: Dictionary) -> void:
    var f := FileAccess.open(_project_file(str(project.code)), FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(project, "\t"))
        f.close()
    _load_projects()

func _load_projects() -> void:
    projects.clear()
    var dir := DirAccess.open(PROJECTS_DIR)
    if dir == null:
        return
    dir.list_dir_begin()
    var file := dir.get_next()
    while not file.is_empty():
        if not dir.current_is_dir() and file.ends_with(".json"):
            var f := FileAccess.open(PROJECTS_DIR + "/" + file, FileAccess.READ)
            if f:
                var parsed = JSON.parse_string(f.get_as_text())
                if parsed is Dictionary:
                    projects.append(parsed)
                f.close()
        file = dir.get_next()
    dir.list_dir_end()
