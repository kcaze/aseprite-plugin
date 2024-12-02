@tool
extends EditorPlugin

const S_AsepriteBottomPanel = preload("res://addons/aseprite/AsepriteBottomPanel.tscn")
const EXT = ".asejson"

var panel : AsepriteBottomPanel
var filesystem : EditorFileSystem
var asejsons : Dictionary = {} # key = path, value = filename
var json : JSON

func _enter_tree():
	#TODO: Ensure that "asejson" is in the "TextFile Extensions" options under Editor preferences.
	panel = S_AsepriteBottomPanel.instantiate()
	panel.asejsons = asejsons
	panel.plugin = self
	filesystem = EditorInterface.get_resource_filesystem()
	json = JSON.new()
	
	filesystem.filesystem_changed.connect(self.on_filesystem_changed)
	add_control_to_bottom_panel(panel, "Aseprite")
	on_filesystem_changed()

func _exit_tree():
	filesystem.filesystem_changed.disconnect(self.on_filesystem_changed)
	remove_control_from_bottom_panel(panel)
	panel.queue_free()

func on_filesystem_changed():
	scanFilesystem()
	panel.refresh()

func scanFilesystem():
	asejsons.clear()
	var root = filesystem.get_filesystem()
	scanDirectory(root)
	# TODO: Compute minimally disambiguating keys for each filepath and use that.

func scanDirectory(directory : EditorFileSystemDirectory):
	for idx in directory.get_file_count():
		var file = directory.get_file(idx)
		if file.ends_with(EXT):
			var path = directory.get_file_path(idx)
			var asejson = Asejson.new()
			asejson.path = path
			asejson.content = parseAsejson(path)
			asejsons[path] = asejson
	for idx in directory.get_subdir_count():
		var subdirectory = directory.get_subdir(idx)
		scanDirectory(directory.get_subdir(idx))

func parseAsejson(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return json.parse_string(content)
