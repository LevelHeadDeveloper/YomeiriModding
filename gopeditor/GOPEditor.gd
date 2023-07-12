extends Control

onready var font = load("res://Noto_Sans_JP/static/NotoSansJP-Medium.ttf")

var editingFile = ""
var saveFile = ""
var directoryToScan = ""
var directoryToSave = ""
var headers = PoolByteArray([])
var footers = PoolByteArray([])
var paddingData = PoolByteArray([])
var stringBuffer = PoolByteArray([])
var offsets = []
var strings = []

func isAllZeroes(array):
	for i in array:
		if i != 0:
			return false
	return true

func bytesToInt(f):
	var g = PoolByteArray([2, 0, 0, 0])
	g.append_array(f)
	return bytes2var(g)

func intToBytes(i):
	var b = var2bytes(i)
	return b.subarray(4, 7)

var difference = 0

func copyStrings():
	strings.clear()
	for i in $Main/ScrollContainer/VBoxContainer.get_children():
		strings.push_back(i.text)
	var nsl = 2
	for i in strings:
		nsl += i.to_utf8().size()+1
	if (nsl > stringBuffer.size()-8):
		difference = nsl - (stringBuffer.size()-8)
		return false
	else:
		difference = (stringBuffer.size()-8) - nsl
	return true

func regenerateOffsets():
	for i in range(strings.size()):
		if (i != 0):
			var bf = offsets[i-1]
			var of = bytesToInt(bf)
			var of2 = of+strings[i-1].to_utf8().size()+1
			offsets[i] = intToBytes(of2)

func saveFile():
	if (!copyStrings()):
		OS.alert("File too big! Remove at least "+str(difference)+" bytes of data.")
		return
	var f = File.new()
	f.open(saveFile, File.WRITE)
	f.store_buffer(headers)
	regenerateOffsets()
	for i in offsets:
		f.store_buffer(i)
	f.store_buffer(paddingData)
	f.store_8(0)
	for k in range(strings.size()):
		var i = strings[k]
		if (k == strings.size()-1):
			print(difference)
			for j in range(difference):
				f.store_8(0)
		f.store_buffer(i.to_utf8())
		f.store_8(0)
	f.store_8(0)
	f.store_buffer(footers)
	f.close()

func readFileIntoMemory():
	for i in $Main/ScrollContainer/VBoxContainer.get_children():
		i.get_parent().remove_child(i)
		i.queue_free()
	headers.resize(0)
	footers.resize(0)
	stringBuffer.resize(0)
	offsets.clear()
	strings.clear()
	var f = File.new()
	f.open(editingFile, File.READ)
	var whereToPut = 0
	var magicNumber = "GOP GFIN"
	var startReading = "GENESTRT"
	var genestrtFound = false
	var until1 = 28
	var currentArray = PoolByteArray([])
	var amountOfOffsets = 0
	while !f.eof_reached():
		if (whereToPut == 0):
			var b = f.get_buffer(1)[0]
			headers.push_back(b)
			if (headers.size() == 8) && (headers.get_string_from_ascii() != magicNumber):
				OS.alert("Not a valid GOP file.")
				headers.resize(0)
				f.close()
				break
			if (genestrtFound):
				until1 -= 1
				if (until1 == 19):
					amountOfOffsets += b
				if (until1 == 18):
					amountOfOffsets += b*256
			if (b == 84) && (headers.size() > 8):
				var string = headers.subarray(\
				headers.size()-8, headers.size()-1).get_string_from_ascii()
				if (string == startReading):
					genestrtFound = true
			if (until1 <= 0):
				whereToPut = 1
		elif (whereToPut == 1):
			amountOfOffsets -= 1
			offsets.push_back(f.get_buffer(4))
			if amountOfOffsets == 0:
				whereToPut = 2
		elif (whereToPut == 2):
			var readUntil = true
			while readUntil:
				var l = f.get_buffer(1)[0]
				stringBuffer.append(l)
				if (stringBuffer.size() > 0) &&\
				 (l == 84) && (stringBuffer.subarray(stringBuffer.size()-8, \
				stringBuffer.size()-1).get_string_from_utf8() == "GOP GDAT"):
					readUntil = false
			var extra = stringBuffer.find(83)-1
			for i in range(extra):
				paddingData.push_back(stringBuffer[0])
				stringBuffer.remove(0)
			for i in offsets:
				var l = PoolByteArray([])
				var j = i[0]
				j += i[1]*256
				j += i[2]*256*256
				j += i[3]*256*256*256
				while (stringBuffer[j] != 0):
					l.push_back(stringBuffer[j])
					j += 1
				strings.push_back(l.get_string_from_utf8())
				var textEdit = LineEdit.new()
				textEdit.text = strings[strings.size()-1]
				textEdit.rect_min_size.x = 500
				textEdit.set("custom_fonts/font", font)
				$Main/ScrollContainer/VBoxContainer.add_child(textEdit)
				textEdit.set_owner($Main/ScrollContainer/VBoxContainer)
				textEdit.name = str(strings.size()-1)
			whereToPut = 3
			footers.append_array("GOP GDAT".to_utf8())
		elif (whereToPut == 3):
			footers.append_array(f.get_buffer(1))
	footers.remove(footers.size()-1)
	f.close()

# Called when the node enters the scene tree for the first time.
func _ready():
	loadPaths()
	pass # Replace with function body.

func savePaths():
	var f = File.new()
	f.open("user://paths.txt", File.WRITE)
	f.store_line(directoryToScan)
	f.store_line(directoryToSave)
	f.close()

func loadPaths():
	var f = File.new()
	if (!f.file_exists("user://paths.txt")):
		return
	f.open("user://paths.txt", File.READ)
	directoryToScan = f.get_line()
	directoryToSave = f.get_line()
	$OpenFile.current_dir = directoryToScan
	$SaveFile.current_dir = directoryToSave
	f.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var windowSize = get_viewport_rect().size
	$Main.rect_min_size = windowSize
	$Main/ScrollContainer.rect_size = windowSize - Vector2(0, 75)
	pass


func _on_File_pressed():
	$Main/TitleBar/File/PopupMenu.popup()
	pass # Replace with function body.


func _on_FileOpen_pressed():
	if (directoryToScan != ""):
		$OpenFile.current_dir = directoryToScan
	$OpenFile.popup_centered()
	$Main/TitleBar/File/PopupMenu.hide()
	pass # Replace with function body.


func _on_FileSave_pressed():
	if (saveFile == ""):
		_on_FileSaveAs_pressed()
	else:
		saveFile()
		savePaths()
	pass # Replace with function body.


func _on_FileSaveAs_pressed():
	if (directoryToSave != ""):
		$SaveFile.current_dir = directoryToSave
	elif (directoryToScan != ""):
		$SaveFile.current_dir = directoryToScan
	$SaveFile.popup_centered()
	$Main/TitleBar/File/PopupMenu.hide()
	pass # Replace with function body.


func _on_OpenFile_confirmed():
	directoryToScan = $OpenFile.current_dir
	editingFile = $OpenFile.current_path
	readFileIntoMemory()
	savePaths()
	pass # Replace with function body.


func _on_SaveFile_confirmed():
	directoryToSave = $SaveFile.current_dir
	saveFile = $SaveFile.current_path
	saveFile()
	savePaths()
	pass # Replace with function body.
