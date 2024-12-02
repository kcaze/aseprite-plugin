@tool
class_name AsepriteBottomPanel
extends Control

const NONE = "<None>"
const FRAME_MARGIN_H = 16
const FRAME_MARGIN_V = 8
const FRAME_MIN_SIZE = Vector2(64, 64)

var asejsons : Dictionary = {}
var selectedJson : String = NONE
var selectedSlice : String = NONE
var selectedTag : String = NONE
var selectedSpriteFrames : String = NONE
var frameTextures : Array[AtlasTexture] = []
var spriteFrameSelectDialog : EditorFileDialog = EditorFileDialog.new()
var plugin : EditorPlugin

@onready var filelist : ItemList = $Files/List
@onready var spriteFrameLabel : Label = $Animations/Header/SpriteFrame/Label
@onready var spriteFrameAdd : Button = $Animations/Header/SpriteFrame/Add
@onready var spriteFrameSelect : MenuButton = $Animations/Header/SpriteFrame/Select
@onready var spriteFrameSelectMenu : PopupMenu = $Animations/Header/SpriteFrame/Select.get_popup()
@onready var tagSelect : OptionButton = $Animations/Header/Filters/Tag/Select
@onready var sliceSelect : OptionButton = $Animations/Header/Filters/Slice/Select
@onready var frameContainer : Container = $Animations/Frames/Container

func _ready() -> void:
	spriteFrameSelectMenu.index_pressed.connect(self.onSpriteFrameSelectMenuPressed)
	initializeTheme()
	initializeSpriteFrameSelectDialog()

func initializeTheme():
	var theme = EditorInterface.get_editor_theme()
	$Animations/Frames.add_theme_stylebox_override("panel", theme.get_stylebox("panel", "Panel"))
	spriteFrameSelect.add_theme_stylebox_override("normal", theme.get_stylebox("panel", "Panel"))
	spriteFrameSelectMenu.set_item_icon(0, theme.get_icon("New", "EditorIcons"))
	spriteFrameSelectMenu.set_item_icon(1, theme.get_icon("Load", "EditorIcons"))
	spriteFrameAdd.icon = theme.get_icon("Add", "EditorIcons")

func initializeSpriteFrameSelectDialog():
	var dialog = spriteFrameSelectDialog
	dialog.title = "Select SpriteFrames file"
	dialog.add_filter("*.tres, *.res", "SpriteFrames Resources")
	dialog.file_selected.connect(self.onSpriteFrameSelectDialogSelected)
	add_child(spriteFrameSelectDialog)

func onFilelistItemSelected(idx: int) -> void:
	sliceSelect.disabled = false
	tagSelect.disabled = false
	
	selectedJson = filelist.get_item_text(idx)
	var content = asejsons[selectedJson].content
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
	
	var path = asejsons[selectedJson]["path"]
	path = path.split(".")[0] + ".tres"
	spriteFrameSelectDialog.current_path = path
	spriteFrameSelect.disabled = false
	
	refresh()

func onTagSelected(index: int) -> void:
	if index == 0:
		selectedTag = NONE
	else:
		index -= 1
		selectedTag = asejsons[selectedJson].content["meta"]["frameTags"][index]["name"]
	refresh()

func onSliceSelected(index: int) -> void:
	if index == 0:
		selectedSlice = NONE
	else:
		index -= 1
		selectedSlice = asejsons[selectedJson].content["meta"]["slices"][index]["name"]
	refresh()

func onSpriteFrameSelectMenuPressed(index: int) -> void:
	if index == 0:
		spriteFrameSelectDialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	else:
		spriteFrameSelectDialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	spriteFrameSelectDialog.popup_file_dialog()

func onSpriteFrameSelectDialogSelected(path: String) -> void:
	selectedSpriteFrames = path
	spriteFrameLabel.text = path.get_file()
	spriteFrameAdd.disabled = false
	spriteFrameAdd.visible = true
	
	var spriteFrames : SpriteFrames
	if spriteFrameSelectDialog.file_mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		spriteFrames = SpriteFrames.new()
		ResourceSaver.save(spriteFrames, path)
		# NOTE: The following line is crucial in ensuring that the SpriteFrames
		# resource is updated correctly in the SpriteFrames Editor Bottom Panel when
		# an existing sprite frame is chosen.
		spriteFrames.take_over_path(path)
	else:
		spriteFrames = ResourceLoader.load(path)
	refresh()

func onSpriteFrameAddPressed() -> void:
	var spriteFrames : SpriteFrames = ResourceLoader.load(selectedSpriteFrames)
	var animationName = selectedTag if selectedTag != NONE else "default"
	if selectedSlice != NONE:
		animationName += "_" + selectedSlice
	if not spriteFrames.has_animation(animationName):
		spriteFrames.add_animation(animationName)
	for texture in frameTextures:
		spriteFrames.add_frame(animationName, texture)
	ResourceSaver.save(spriteFrames, selectedSpriteFrames)
	refresh()

func refresh():
	filelist.clear()
	for k in asejsons:
		filelist.add_item(k)
	refreshSpriteFrameTextures()
	refreshSpriteFrames()

func refreshSpriteFrameTextures():
	for frame in frameContainer.get_children():
		frame.queue_free()
	frameTextures.clear()
	
	if selectedJson == NONE:
		return
	
	var texture_path = asejsons[selectedJson].path.get_basename() + ".png"
	var atlas : Texture2D = load(texture_path)
	var json = asejsons[selectedJson].content
	var frames = parseFrames(json["frames"])
	var meta = json["meta"]
	var frame_tags = meta["frameTags"]
	var slices = meta["slices"]
	
	var frameFrom = 0
	var frameTo = len(frames)
	for tag in frame_tags:
		if tag["name"] == selectedTag:
			frameFrom = tag["from"]
			frameTo = tag["to"]+1
	
	var sliceRect = null
	for slice in slices:
		if slice["name"] == selectedSlice:
			var bounds = slice["keys"][0]["bounds"]
			sliceRect = Rect2(bounds["x"], bounds["y"], bounds["w"], bounds["h"])
	
	for f in range(frameFrom, frameTo):
		var frameRect = frames[f]["frame"]
		var region = Rect2(frameRect["x"], frameRect["y"], frameRect["w"], frameRect["h"])
		
		if sliceRect:
			region.position += sliceRect.position
			region.size = sliceRect.size
		
		var frame = AtlasTexture.new()
		frame.atlas = atlas
		frame.region = region
		frame.filter_clip = true
		frameTextures.append(frame)
		
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

func refreshSpriteFrames():
	if ResourceLoader.exists(selectedSpriteFrames):
		var spriteFrames = ResourceLoader.load(selectedSpriteFrames)
		EditorInterface.edit_resource(spriteFrames)
		plugin.make_bottom_panel_item_visible(self)

# Parse the "frames" field in Aseprite's spritesheet json.
# The data is encoded as "<filename> <frame_number>.<extension>".
func parseFrames(frame_data):
	var ret = []
	
	for i in range(len(frame_data)):
		ret.append(null)
	
	for s in frame_data:
		var i = s.split(".")[0]
		i = i.split(" ")[1]
		i = int(i)
		ret[i] = frame_data[s]
	
	return ret
