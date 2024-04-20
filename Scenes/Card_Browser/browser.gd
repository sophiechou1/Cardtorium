extends Control
@onready var back_button = $Back as Button
@onready var items = $ScrollContainer/Items
var card_scene = preload ("res://Scenes/Card_Renderer/Card.tscn")
var cardsize = Vector2(1205, 1576)
var max_cards_per_hbox = 4
var current_hbox: HBoxContainer = null
var hbox_count = 0
var card_scale: float = 0.2

signal exit_browser


## Called when the node enters the scene tree for the first time.
func _ready():
	back_button.button_down.connect(on_exit_browser_pressed)
	set_process(false)
	var scroll = $ScrollContainer
	scroll.scale = Vector2(card_scale, card_scale)
	scroll.size /= card_scale
	load_and_display_cards()


## Connects to the exit_brower button
func on_exit_browser_pressed():
	exit_browser.emit()
	set_process(false)

## Adds a card to the currently processed hbox
func add_card(card_data: Resource, card_index: int):
	if current_hbox == null or current_hbox.get_child_count() >= max_cards_per_hbox:
		new_hbox()
	var card = card_scene.instantiate()
	current_hbox.add_child(card)
	current_hbox.add_theme_constant_override("separation", 30)
	card.setup(card_data, card_index)

## Creates a new hbox
func new_hbox():
	current_hbox = HBoxContainer.new()
	items.add_child(current_hbox)
	hbox_count += 1

## Displays every Cardtorium card in the browser
func load_and_display_cards():
	var dir = DirAccess.open("res://Cards/Troops/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var card_data = load("res://Cards/Troops/" + file_name)
				add_card(card_data, hbox_count * max_cards_per_hbox)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
