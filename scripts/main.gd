extends Node3D

const PLAYER_SPEED := 6.0
const ISLAND_SIZE := 50.0
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var quick_menu: PanelContainer
var menu_resources: Label
var resources := {"Pedra": 0, "Galho": 0, "Fruta vermelha": 0, "Folha": 0}

func _ready() -> void:
    _build_world()
    _build_player()
    _build_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#8fd3ff")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color.WHITE
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.2
    add_child(sun)

    _add_box("Ilha", Vector3(0, -1, 0), Vector3(ISLAND_SIZE, 2, ISLAND_SIZE), Color("#69a84f"))
    _add_box("Lago", Vector3(-12, 0.05, -10), Vector3(12, 0.12, 9), Color("#318fca"))

    for i in range(10):
        var x := -20.0 + float((i * 17) % 38)
        var z := -18.0 + float((i * 23) % 38)
        if abs(x + 12.0) < 8.0 and abs(z + 10.0) < 6.0:
            continue
        _add_resource(Vector3(x, 0.9, z), "Árvore", Color("#24733d"), 1.2)

    for i in range(8):
        var x := -19.0 + float((i * 13) % 37)
        var z := -17.0 + float((i * 19) % 35)
        _add_resource(Vector3(x, 0.45, z), "Arbusto de frutas", Color("#b52c42"), 0.7)

    for i in range(8):
        var x := -18.0 + float((i * 11) % 35)
        var z := -18.0 + float((i * 29) % 36)
        _add_resource(Vector3(x, 0.35, z), "Pedra", Color("#777b80"), 0.8)

func _add_box(node_name: String, position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = position
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = _material(color)
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return body

func _add_resource(position: Vector3, resource_name: String, color: Color, radius: float) -> void:
    var area := Area3D.new()
    area.position = position
    area.set_meta("resource_name", resource_name)
    area.add_to_group("collectible")
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh.mesh = sphere
    mesh.material_override = _material(color)
    area.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = radius
    collision.shape = shape
    area.add_child(collision)
    add_child(area)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 2, 8)
    add_child(player)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    collision.shape = shape
    collision.position.y = 0.9
    player.add_child(collision)
    camera = Camera3D.new()
    camera.position = Vector3(0, 1.55, 0)
    player.add_child(camera)
    camera.current = true

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    hud = Label.new()
    hud.position = Vector2(24, 20)
    hud.add_theme_font_size_override("font_size", 18)
    hud.add_theme_color_override("font_color", Color("#fff7d6"))
    canvas.add_child(hud)

    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.position = Vector2(636, 345)
    crosshair.add_theme_font_size_override("font_size", 24)
    crosshair.add_theme_color_override("font_color", Color("#fff7d6"))
    canvas.add_child(crosshair)

    quick_menu = PanelContainer.new()
    quick_menu.position = Vector2(330, 105)
    quick_menu.size = Vector2(620, 510)
    quick_menu.visible = false
    quick_menu.add_theme_stylebox_override("panel", _panel_style(Color("#173c3a"), Color("#e7c875"), 18, 3))
    canvas.add_child(quick_menu)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_bottom", 22)
    quick_menu.add_child(margin)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    margin.add_child(content)

    var title := Label.new()
    title.text = "OFICINA DE SOBREVIVÊNCIA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("#ffe6a1"))
    content.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Ferramentas, abrigo e vida sustentável"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 15)
    subtitle.add_theme_color_override("font_color", Color("#b8e1c4"))
    content.add_child(subtitle)

    var separator := HSeparator.new()
    content.add_child(separator)

    var section := Label.new()
    section.text = "ITENS RÁPIDOS"
    section.add_theme_font_size_override("font_size", 16)
    section.add_theme_color_override("font_color", Color("#ffd27d"))
    content.add_child(section)

    var cards := GridContainer.new()
    cards.columns = 3
    cards.add_theme_constant_override("h_separation", 10)
    cards.add_theme_constant_override("v_separation", 10)
    content.add_child(cards)
    _add_menu_card(cards, "1", "PICAreta", "Pedra + Galho")
    _add_menu_card(cards, "2", "MACHADO", "Pedra + Galho")
    _add_menu_card(cards, "3", "MARTELO", "Pedra + Galho")
    _add_menu_card(cards, "4", "PÁ DE AREIA", "Galho + Pedra")
    _add_menu_card(cards, "5", "ENXADA", "Galho + Pedra")
    _add_menu_card(cards, "6", "VARA DE PESCA", "Galho + Folha")

    var inventory_title := Label.new()
    inventory_title.text = "MOCHILA"
    inventory_title.add_theme_font_size_override("font_size", 16)
    inventory_title.add_theme_color_override("font_color", Color("#ffd27d"))
    content.add_child(inventory_title)

    menu_resources = Label.new()
    menu_resources.add_theme_font_size_override("font_size", 16)
    menu_resources.add_theme_color_override("font_color", Color("#f4f1d0"))
    content.add_child(menu_resources)

    var footer := Label.new()
    footer.text = "F fechar   •   WASD mover   •   E coletar   •   ESC liberar mouse"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 14)
    footer.add_theme_color_override("font_color", Color("#b8e1c4"))
    content.add_child(footer)
    _update_hud()

func _add_menu_card(parent: GridContainer, hotkey: String, item_name: String, recipe: String) -> void:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(175, 72)
    card.add_theme_stylebox_override("panel", _panel_style(Color("#24534b"), Color("#6ba878"), 10, 1))
    parent.add_child(card)
    var label := Label.new()
    label.text = "[%s] %s\n      %s" % [hotkey, item_name, recipe]
    label.add_theme_font_size_override("font_size", 14)
    label.add_theme_color_override("font_color", Color("#fff7d6"))
    card.add_child(label)

func _panel_style(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(radius)
    return style

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if quick_menu.visible:
            return
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event is InputEventKey and event.pressed and event.keycode == KEY_F:
        quick_menu.visible = not quick_menu.visible
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if quick_menu.visible else Input.MOUSE_MODE_CAPTURED
    if event is InputEventKey and event.pressed and event.keycode == KEY_E:
        _collect_nearest()
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_y(-event.relative.x * 0.002)
        camera.rotation.x = clamp(camera.rotation.x - event.relative.y * 0.002, -1.4, 1.4)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    if not player:
        return
    var input_vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_A):
        input_vector.x -= 1.0
    if Input.is_key_pressed(KEY_D):
        input_vector.x += 1.0
    if Input.is_key_pressed(KEY_W):
        input_vector.y -= 1.0
    if Input.is_key_pressed(KEY_S):
        input_vector.y += 1.0
    input_vector = input_vector.normalized()
    var direction := (player.transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    player.velocity.x = direction.x * PLAYER_SPEED
    player.velocity.z = direction.z * PLAYER_SPEED
    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    else:
        player.velocity.y = 0
    player.move_and_slide()

func _collect_nearest() -> void:
    var nearest: Area3D
    var distance := 3.0
    for node in get_tree().get_nodes_in_group("collectible"):
        var current_distance: float = player.global_position.distance_to(node.global_position)
        if current_distance < distance:
            nearest = node
            distance = current_distance
    if nearest:
        var resource_name: String = nearest.get_meta("resource_name")
        var key := "Pedra" if resource_name == "Pedra" else ("Fruta vermelha" if resource_name == "Arbusto de frutas" else "Galho")
        resources[key] += 2 if key == "Fruta vermelha" else 1
        nearest.queue_free()
        _update_hud()

func _update_hud() -> void:
    if hud:
        hud.text = "ILHA SURVIVAL  |  WASD mover   E coletar   F oficina\nPedra: %d   Galhos: %d   Frutas: %d   Folhas: %d" % [resources["Pedra"], resources["Galho"], resources["Fruta vermelha"], resources["Folha"]]
    if menu_resources:
        menu_resources.text = "Pedra  %d     Galhos  %d     Frutas vermelhas  %d     Folhas  %d" % [resources["Pedra"], resources["Galho"], resources["Fruta vermelha"], resources["Folha"]]
