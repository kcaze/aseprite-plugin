@tool
class_name AsepriteBottomPanel
extends Control

const NONE = "<None>"
const FRAME_MARGIN_H = 16
const FRAME_MARGIN_V = 8
const FRAME_MIN_SIZE = Vector2(64, 64)

var asejsons : Dictionary = {}
var selected_json : String = ""
var selected_slice : String = ""
var selected_tag : String = ""
var frames : Array[AtlasTexture] = []
@onready var filelist : ItemList = $Files/List
@onready var tagSelect : OptionButton = $Animations/Header/Filters/Tag/Select
@onready var sliceSelect : OptionButton = $Animations/Header/Filters/Slice/Select
@onready var frameContainer : Container = $Animations/Frames/Container

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var theme = EditorInterface.get_editor_theme()
	$Animations/Frames.add_theme_stylebox_override("panel", theme.get_stylebox("panel", "Panel"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func refresh():
	filelist.clear()
	for k in asejsons:
		filelist.add_item(k)

func on_filelist_item_selected(idx: int) -> void:
	sliceSelect.disabled = false
	tagSelect.disabled = false
	
	selected_json = filelist.get_item_text(idx)
	var content = asejsons[selected_json].content
	var meta = content["meta"]
	
	var slices = []
	for slice in meta["slices"]:
		slices.append(slice["name"])
	sliceSelect.clear()
	sliceSelect.add_item(NONE)
	for slice in slices:
		sliceSelect.add_item(slice)
	
	var tags = []
	for tag in meta["frameTags"]:
		tags.append(tag["name"])
	tagSelect.clear()
	tagSelect.add_item(NONE)
	for tag in tags:
		tagSelect.add_item(tag)
	
	refresh_frames()

func on_tag_selected(index: int) -> void:
	if index == 0:
		selected_tag = NONE
	else:
		index -= 1
		selected_tag = asejsons[selected_json].content["meta"]["frameTags"][index]["name"]
	refresh_frames()

func on_slice_selected(index: int) -> void:
	if index == 0:
		selected_slice = NONE
	else:
		index -= 1
		selected_slice = asejsons[selected_json].content["meta"]["slices"][index]["name"]
	refresh_frames()

# Parse the "frames" field in Aseprite's spritesheet json.
# The data is encoded as "<filename> <frame_number>.<extension>".
func parse_frames(frame_data):
	var ret = []
	
	for i in range(len(frame_data)):
		ret.append(null)
	
	for s in frame_data:
		var i = s.split(".")[0]
		i = i.split(" ")[1]
		i = int(i)
		ret[i] = frame_data[s]
	
	return ret

func refresh_frames():
	for frame in frameContainer.get_children():
		frame.queue_free()
	frames.clear()
	
	var texture_path = asejsons[selected_json].path.split(".")[0] + ".png"
	var atlas : Texture2D = load(texture_path)
	var json = asejsons[selected_json].content
	var frames = parse_frames(json["frames"])
	var meta = json["meta"]
	var frame_tags = meta["frameTags"]
	var slices = meta["slices"]
	
	var frame_from = 0
	var frame_to = len(frames)
	for tag in frame_tags:
		if tag["name"] == selected_tag:
			frame_from = tag["from"]
			frame_to = tag["to"]+1
	
	var slice_rect = null
	for slice in slices:
		if slice["name"] == selected_slice:
			var bounds = slice["keys"][0]["bounds"]
			slice_rect = Rect2(bounds["x"], bounds["y"], bounds["w"], bounds["h"])
	
	for f in range(frame_from, frame_to):
		var frameRect = frames[f]["frame"]
		var region = Rect2(frameRect["x"], frameRect["y"], frameRect["w"], frameRect["h"])
		
		if slice_rect:
			region.position += slice_rect.position
			region.size = slice_rect.size
		
		var frame = AtlasTexture.new()
		frame.atlas = atlas
		frame.region = region
		frame.filter_clip = true
		
		var textureRect = TextureRect.new()
		textureRect.texture = frame
		textureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		textureRect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		var marginContainer = MarginContainer.new()
		marginContainer.add_theme_constant_override("margin_top", FRAME_MARGIN_V)
		marginContainer.add_theme_constant_override("margin_left", FRAME_MARGIN_H)
		marginContainer.add_theme_constant_override("margin_bottom", FRAME_MARGIN_V)
		marginContainer.add_theme_constant_override("margin_right", FRAME_MARGIN_H)
		marginContainer.custom_minimum_size = FRAME_MIN_SIZE
		marginContainer.add_child(textureRect)
		
		frameContainer.add_child(marginContainer)
