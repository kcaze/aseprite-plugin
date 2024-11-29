@tool
class_name AsepriteBottomPanel
extends Control

const NONE = "<None>"

var asejsons : Dictionary = {}
var selected_json : String = ""
var selected_slice : String = ""
var selected_tag : String = ""
var frames : Array[AtlasTexture] = []
@onready var filelist : ItemList = $Files/List
@onready var tagSelect : OptionButton = $Animations/Header/Filters/Tag/Select
@onready var sliceSelect : OptionButton = $Animations/Header/Filters/Slice/Select
@onready var frameContainer : GridContainer = $Animations/Frames/Container

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
	for frame in frames:
		frame.queue_free()
	frames.clear()
	
	
	var texture_path = asejsons[selected_json].path.split(".")[0] + ".png"
	var atlas : Texture2D = load(texture_path)
	var json = asejsons[selected_json].content
	var frames = parse_frames(json["frames"])
	var meta = json["meta"]
	var frame_tags = meta["frameTags"]
	var slices = meta["slices"]
	
	var frame_from = frame_tags[selected_tag]["from"] if selected_tag in frame_tags else 0
	var frame_to = frame_tags[selected_tag]["to"] if selected_tag in frame_tags else len(frames)
	
	var slice_rect = null
	if selected_slice in slices:
		var bounds = slices[selected_slice]["keys"][0]["bounds"]
		slice_rect = Rect2(bounds["x"], bounds["y"], bounds["w"], bounds["h"])
	
	for f in range(frame_from, frame_to+1):
		var frameRect = frames[f]["frame"]
		var region = Rect2(frameRect["x"], frameRect["y"], frameRect["w"], frameRect["h"])
		
		if slice_rect:
			region.position += slice_rect.position
			region.size = slice_rect.size
		
		var frame = AtlasTexture.new()
		frame.atlas = atlas
		frame.region = region
		
		var textureRect = TextureRect.new()
		textureRect.texture = frame
		frameContainer.add_child(textureRect)
		
