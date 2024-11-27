@tool
class_name AsepriteBottomPanel
extends Control

var asejsons = {}
@onready var filelist : ItemList = $Files/List
@onready var tagSelect : OptionButton = $Animations/Header/Filters/Tag/Select
@onready var sliceSelect : OptionButton = $Animations/Header/Filters/Slice/Select

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func refresh():
	filelist.clear()
	for k in asejsons:
		filelist.add_item(k)

func on_filelist_item_selected(idx: int) -> void:
	var key = filelist.get_item_text(idx)
	var content = asejsons[key].content
	var meta = content["meta"]
	
	var slices = []
	for slice in meta["slices"]:
		slices.append(slice["name"])
	sliceSelect.clear()
	for slice in slices:
		sliceSelect.add_item(slice)
	
	var tags = []
	for tag in meta["frameTags"]:
		tags.append(tag["name"])
	tagSelect.clear()
	for tag in tags:
		tagSelect.add_item(tag)
