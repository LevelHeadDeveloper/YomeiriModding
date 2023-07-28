extends Control

func log1(st):
	print(st)
	$HBoxContainer/TextEdit.text += "\n"+st
	$HBoxContainer/TextEdit.scroll_vertical = \
	$HBoxContainer/TextEdit.get_line_count()-1

class ASBDataSegment:
	var title = "Unknown"
	var rawData = PackedByteArray([])
	var length = 0
	var stringOffsetPositions = []
	var associatedString = ""
	func trim_offsets(a):
		var b = []
		for i in a:
			b.push_back(stringOffsetPositions[i])
		stringOffsetPositions = b
	func get_offsets():
		var r = []
		for i in stringOffsetPositions:
			r.push_back(rawData.decode_u32(i))
		return r
	func generate_string_offsets():
		stringOffsetPositions.clear()
		var t = get_type()
		if (t == -4):
			var index = 36
			while (index < length-1):
				stringOffsetPositions.push_back(index)
				index += 4
		elif (t == 990): #Voice Line
			title = "Play Voice Line"
			stringOffsetPositions = [17]
		elif (t == 331):
			title = "Show Dialogue"
			stringOffsetPositions = [7]
		elif (t == 810):
			title = "Show Options"
			var ignore = 0
			for i in range(length):
				if (ignore == 0) && (rawData[i] == 1):
					stringOffsetPositions.push_back(i+1)
					ignore = 4
				if (ignore != 0):
					ignore -= 1
		elif (t == 926):
			title = "Show 2-Shot"
			stringOffsetPositions = [20]
		elif (t == 201):
			title = "2-Shot Start"
			stringOffsetPositions = [12, 18]
		else:
			for i in range(length-9):
				if (rawData[i] == 40):
					var do = true
					for j in range(4):
						if (rawData[i+j+1] != 0):
							do = false
					if (do):
						title = "Command"
						stringOffsetPositions.push_back(i+5)
					pass
		var index = 1
		while (index < rawData.size()):
			var ind = rawData[index]
			if (ind == 1):
				stringOffsetPositions.push_back(index+1)
			index += 5
	func get_type():
		if (rawData[0] == 0):
			return -4
		if (length == 0) || (length < 3):
			return -1
		return (rawData[2]*256)+rawData[1]
	func push_back(b):
		rawData.push_back(b)
		length += 1
	func push_front(b):
		rawData.reverse()
		rawData.push_back(b)
		rawData.reverse()
		length += 1
	func clear():
		length = 0
		rawData.resize(length)
	func set_data(d):
		rawData = d
		length = rawData.size()

var filePath = ""
var savePath = ""
var vlDirectory = ""

func saveDirectories():
	var f = FileAccess.open("user://directories.txt", FileAccess.WRITE)
	f.store_line($FileDialog.current_dir)
	f.store_line($FileDialog2.current_dir)
	f.store_line($FileDialog3.current_dir)
	f.close()

func loadDirectories():
	var f = FileAccess.open("user://directories.txt", FileAccess.READ)
	$FileDialog.current_dir = f.get_line()
	$FileDialog2.current_dir = f.get_line()
	vlDirectory = f.get_line()
	$FileDialog3.current_dir = vlDirectory

func playVoiceLine(p2):
	if (vlDirectory == ""):
		$FileDialog3.show()
	else:
		p2 = p2.erase(0, 4)
		var fullpath = vlDirectory+"/"+p2+".aac"
		OS.shell_open(fullpath)

var headerData = PackedByteArray([])
var bodySegments = []
var stringdata = PackedByteArray([])

var displaySize = Vector2(482, 100)

func optimize_for_dialog(t):
	t.tooltip_text = "Shows this dialogue."
	t.add_theme_color_override("font_color", Color.BLACK)
	t.add_theme_constant_override("line_spacing", 12)
	t.add_theme_constant_override("outline_size", 1)
	t.add_theme_font_override("font", load("res://FOT-RodinNTLG Pro M.otf"))
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_stylebox_override("normal", load("res://dialog.tres"))
	t.add_theme_color_override("caret_color", Color.DARK_BLUE)
	t.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	t.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY

func optimize_for_command(t):
	t.add_theme_color_override("font_color", Color.WHITE)
	t.add_theme_constant_override("line_spacing", 16)
	t.add_theme_constant_override("outline_size", 1)
	t.tooltip_text = "A miscellaneous utility string."
	t.add_theme_font_override("font", load("res://Cutive_Mono/CutiveMono-Regular.ttf"))
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_stylebox_override("normal", load("res://command.tres"))
	t.add_theme_color_override("caret_color", Color.DARK_BLUE)
	return t

func optimize_for_voice(v):
	var p = v.get_parent()
	var t = Button.new()
	t.tooltip_text = "Plays a voice line."
	p.add_child(t)
	t.set_owner(p)
	t.add_theme_color_override("font_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 1)
	t.add_theme_font_override("font", load("res://Cutive_Mono/CutiveMono-Regular.ttf"))
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_stylebox_override("normal", load("res://vooice.tres"))
	t.text = v.text
	v.queue_free()
	t.pressed.connect(playVoiceLine.bind(t.text))
	return t

func optimize_for_branch(v):
	var p = v.get_parent()
	var t = LineEdit.new()
	t.tooltip_text = "Marks the beginning of a scene branch."
	p.add_child(t)
	t.set_owner(p)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.add_theme_constant_override("line_spacing", 20)
	t.add_theme_constant_override("outline_size", 1)
	t.add_theme_font_override("font", load("res://FOT-RodinNTLG Pro M.otf"))
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_stylebox_override("normal", load("res://branch.tres"))
	t.add_theme_stylebox_override("read_only", load("res://branch.tres"))
	t.add_theme_color_override("caret_color", Color.DARK_OLIVE_GREEN)
	t.custom_minimum_size.x = v.custom_minimum_size.x
	t.editable = false
	t.text = v.text
	v.queue_free()
	return t

func optimize_for_choice(v):
	var p = v.get_parent()
	var t = LineEdit.new()
	t.tooltip_text = "A dialogue choice presented to the player."
	p.add_child(t)
	t.set_owner(p)
	t.add_theme_color_override("font_color", Color.BLACK)
	t.add_theme_constant_override("line_spacing", 20)
	t.add_theme_constant_override("outline_size", 1)
	t.add_theme_font_override("font", load("res://FOT-RodinNTLG Pro M.otf"))
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_stylebox_override("normal", load("res://choice.tres"))
	t.add_theme_color_override("caret_color", Color.DARK_BLUE)
	t.custom_minimum_size.y = 68
	t.custom_minimum_size.x = v.custom_minimum_size.x
	t.alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size.y = 68
	t.text = v.text
	v.queue_free()
	return t

func optimize_for_prompt(v):
	var p = v.get_parent()
	var t = LineEdit.new()
	t.tooltip_text = "Shows the prompt at the very start of a 2-shot challenge"
	p.add_child(t)
	t.set_owner(p)
	t.add_theme_color_override("font_color", Color.BLACK)
	t.add_theme_constant_override("line_spacing", 20)
	t.add_theme_constant_override("outline_size", 1)
	t.add_theme_font_override("font", load("res://FOT-RodinNTLG Pro M.otf"))
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_stylebox_override("normal", load("res://choice.tres"))
	t.add_theme_color_override("caret_color", Color.DARK_BLUE)
	t.custom_minimum_size.y = 68
	t.custom_minimum_size.x = v.custom_minimum_size.x
	t.alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size.y = 68
	t.text = v.text
	v.queue_free()
	return t

func clearDisplay():
	for i in $HBoxContainer/ScrollContainer/VBoxContainer.get_children():
		i.get_parent().remove_child(i)
		i.queue_free()

func addEmptyDisplaySegment():
	var hb = HBoxContainer.new()
	hb.name = "Empty"
	$HBoxContainer/ScrollContainer/VBoxContainer.add_child(hb)
	hb.set_owner($HBoxContainer/ScrollContainer/VBoxContainer)

func addDisplaySegment(text, nm, type):
	addEmptyDisplaySegment()
	replaceDisplaySegmentAt($HBoxContainer/ScrollContainer.get_child_count()-1, text, nm, type)

func replaceDisplaySegmentAt(index, text, nm, type):
	var hb = $HBoxContainer/ScrollContainer/VBoxContainer.get_child(index)
	for i in hb.get_children():
		hb.remove_child(i)
		i.queue_free()
	hb.name = nm
	var t1 = TextEdit.new()
	t1.text = text
	var t2 = TextEdit.new()
	t2.text = text
	hb.add_child(t1)
	t1.set_owner(hb)
	hb.add_child(t2)
	t2.set_owner(hb)
	if (type == "Show Dialogue"):
		optimize_for_dialog(t1)
		optimize_for_dialog(t2)
	elif (type == "Show 2-Shot"):
		t1 = optimize_for_prompt(t1)
		t2 = optimize_for_prompt(t2)
	elif (type == "Play Voice Line"):
		t1 = optimize_for_voice(t1)
		t2 = optimize_for_voice(t2)
	elif (type == "Show Options"):
		t1 = optimize_for_choice(t1)
		t2 = optimize_for_choice(t2)
	elif (type == "Header"):
		t1 = optimize_for_branch(t1)
		t2 = optimize_for_branch(t2)
	else:
		t1 = optimize_for_command(t1)
		t2 = optimize_for_command(t2)
	if (t2.has_signal("text_changed")):
		t2.text_changed.connect(updateBlock.bind(index))
	t2.focus_entered.connect(updateBlock.bind(index))
	if t1.get("editable") != null:
		t1.editable = false
	t1.custom_minimum_size = displaySize
	t2.custom_minimum_size = displaySize

func validateOffsets(bodySegment):
	var s = bodySegment.get_offsets()
	var v = []
	for i in range(s.size()):
		if (s[i] > 0) && (stringdata.size() > s[i]-1) && (stringdata[s[i]-1] == 0):
			v.push_back(i)
	bodySegment.trim_offsets(v)

func getStringNumberFromOffset(o):
	var st = 0
	for i in range(o):
		if (stringdata[i] == 0):
			st += 1
	return st

func getAssociatedStrings(bodySegment):
	var rv = []
	for i in bodySegment.get_offsets():
		var pck = PackedByteArray([])
		var j = i
		var b = -1
		while (b != 0) && (j < stringdata.size()):
			b = stringdata[j]
			pck.push_back(b)
			j += 1
		rv.push_back(pck.get_string_from_utf8())
	return rv

func findAssociatedStringOffsetLocations(loc):
	var rv = []
	for i in $HBoxContainer/ScrollContainer/VBoxContainer.get_children():
		var n = i.name.replace("[", ",").replace("]", "")
		var ar = n.split(",")
		if (ar.size() > 1) && (ar[1].to_int() == loc):
			var a = ar[0].to_int()
			var b = ar[2].to_int()
			rv.push_back([a, b])
	return rv

func getStrings():
	var rv = PackedStringArray(["__main"])
	for i in $HBoxContainer/ScrollContainer/VBoxContainer.get_children():
		rv.push_back(i.get_child(1).text)
	return rv

func getOffsetOfStringAt(index, fromwhere):
	var ret = 0
	for i in range(index-1):
		ret += fromwhere[i].to_utf8_buffer().size()+1
		if (blockPadding.has(i)):
			ret += blockPadding[i]
	return ret

func intToBytes(i):
	var dd = var_to_bytes(i)
	return dd.slice(4)

var stringList = []
var stringOrder = []
var usedOffsets = []

var editableBlocks = []
var blockPadding = {}

func isScenePointer(s):
	if (s == "init.asb") || (s == "common.asb"):
		return true
	var sceneBeginnings = ["@all_", "@bad_", "@hol_", "@day_", "@dwn_", "@pro_",\
	"@snk_", "@ctg_", "@ksk_", "@mrk_", "@ssr_", "@rak_", "@rur_", "@otm_"]
	for i in sceneBeginnings:
		if s.begins_with(i):
			return true
	return false

func reloadEditableBlocks():
	var bl = []
	for i in $HBoxContainer/ScrollContainer/VBoxContainer.get_children():
		var n = i.name.replace("[", ",").replace("]", ",").split(",")
		if (n.size() >= 2):
			if isScenePointer((i.get_child(1).text)):
				bl.push_back(false)
			else:
				bl.push_back(n[1] != "-1")
		else:
			bl.push_back(false)
	var position1 = 0
	var length1 = 0
	for i in bl:
		if i == false:
			if length1 != 0:
				editableBlocks.push_back([position1, length1])
				position1 += length1+1
				length1 = 0
			else:
				position1 += 1
		else:
			length1 += 1
	for j in range(editableBlocks.size()):
		var i = editableBlocks[j]
		var top_pos = 0
		var bottom_pos = i[1]-1
		var middle_pos = floor((i[1]-1)/2)
		for k in range(i[1]):
			var c = $HBoxContainer/ScrollContainer/VBoxContainer.get_child(i[0]+k)
			var tex_path = "block"
			if (k == top_pos):
				if (k == middle_pos):
					tex_path = "block_top_middle"
				else:
					tex_path = "block_top"
			elif (k == bottom_pos):
				if (k == middle_pos):
					tex_path = "block_bottom_middle"
				else:
					tex_path = "block_bottom"
			elif (k == middle_pos):
				tex_path = "block_middle"
			var texr = TextureRect.new()
			texr.texture = load("res://"+tex_path+".png")
			texr.custom_minimum_size = Vector2(58.536, 100)
			c.add_child(texr)
			texr.set_owner(c)
			if (k == middle_pos):
				var l = Label.new()
				texr.add_child(l)
				l.set_owner(texr)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				l.custom_minimum_size = Vector2(58.536, 100)
				l.text = "1000\n100"
				editableBlocks[j].push_back(l.get_path())
	for i in editableBlocks:
		updateBlock(i[0])
	pass

func updateBlock(index):
	var l = 0
	var m = 0
	for i in editableBlocks:
		if (index < i[0]):
			break
		else:
			l = m
		m += 1
	var label = get_node(editableBlocks[l][2])
	var maxBytes = 0
	var currentBytes = 0
	var isFound = false
	for i in range(editableBlocks[l][1]):
		var found = editableBlocks[l][0]+i
		if (index == found):
			isFound = true
		var block = $HBoxContainer/ScrollContainer/VBoxContainer.get_child(found)
		maxBytes += block.get_child(0).text.to_utf8_buffer().size()
		currentBytes += block.get_child(1).text.to_utf8_buffer().size()
	if (currentBytes > maxBytes):
		var d = $HBoxContainer/ScrollContainer/VBoxContainer.get_child(index).get_child(1)
		while (currentBytes > maxBytes):
			var str = d.text
			if (str.length() != 0):
				var lastChar = str.substr(str.length()-1, 1)
				currentBytes -= lastChar.to_utf8_buffer().size()
				str = str.erase(str.length()-1, 1)
			else:
				break
			d.text = str
		currentBytes = maxBytes
		blockPadding.erase(editableBlocks[l][1]+editableBlocks[l][0])
	else:
		if (currentBytes < maxBytes):
			blockPadding[editableBlocks[l][1]+editableBlocks[l][0]] = maxBytes-currentBytes
		else:
			blockPadding.erase(editableBlocks[l][1]+editableBlocks[l][0])
		label.add_theme_color_override("font_color", Color.WHITE)
	if (isFound):
		label.text = str(maxBytes)+"\n"+str(currentBytes)
	$Label.text = "Bytes: "+str(currentBytes)+" out of "+str(maxBytes)+" used\n("+\
	str(maxBytes-currentBytes)+" remaining)"

func saveMemoryToFile():
	var s = getStrings()
	var f = FileAccess.open(savePath, FileAccess.WRITE)
	var f2 = FileAccess.open(savePath+".txt", FileAccess.WRITE)
	var headerOffsets = findAssociatedStringOffsetLocations(-1)
	var b = headerData.rawData
	f.store_buffer(b)
	var idx = 0
	for p in bodySegments:
		var offsets = []
		var b0 = p.rawData.duplicate()
		var c0 = p.stringOffsetPositions
		var index = 0
		for i in c0:
			var mah_b0i = b0[i]+(256*b0[i+1])+(256*256*b0[i+2])+(256*256*256*b0[i+3])
			var d0 = usedOffsets.find(mah_b0i)
			if (d0 != -1):
				print(str(idx)+": "+str(i)+", "+str(d0)+", "+str(mah_b0i))
				offsets.push_back([getOffsetOfStringAt(d0+1, s), index])
			index += 1
		for i in offsets:
			var ll = i[0]
			print(ll)
			var bytes = intToBytes(ll)
			var o = c0[i[1]]
			for j in range(bytes.size()):
				b0[o+j] = bytes[j]
		f.store_buffer(b0)
		idx += 1
	var stringIndex = 0
	for st in s:
		f.store_string(st)
		f2.store_line(st)
		if (st.length() > 0):
			f.store_8(0)
		if (blockPadding.has(stringIndex)) && (blockPadding[stringIndex] > 0):
			for i in range(blockPadding[stringIndex]-1):
				f.store_8(255)
			f.store_8(0)
		stringIndex += 1
	f.close()
	f2.close()

func removeEmptyBodySegments():
	for i in $HBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if (i.get_child_count() == 0):
			$HBoxContainer/ScrollContainer/VBoxContainer.remove_child(i)
			i.queue_free()

func readFileIntoMemory():
	clearDisplay()
	bodySegments.clear()
	stringdata.clear()
	stringList.clear()
	usedOffsets.clear()
	stringOrder.clear()
	editableBlocks.clear()
	blockPadding.clear()
	savePath = ""
	var f = FileAccess.open(filePath, FileAccess.READ)
	headerData = ASBDataSegment.new()
	headerData.set_data(f.get_buffer(133))
	var endOfBody = headerData.rawData.decode_u32(52)
	var index = 133
	var rawData1 = PackedByteArray([])
	var pck = PackedByteArray([])
	while (index != endOfBody):
		rawData1.push_back(f.get_8())
		index += 1
	index = 0
	while (index < rawData1.size()):
		pck.push_back(rawData1[index])
		var isEnd = false
		if (rawData1[index] == 41):
			isEnd = true
		if (pck.size() < 3):
			isEnd = false
		elif (pck[1] == 222) && (pck[2] == 3) && isEnd:
			if (pck.size() < 21):
				if (rawData1[index+1] == 75) && (rawData1[index+2] == 1):
					isEnd = true
				else:
					isEnd = false
		elif (pck[1] == 75) && (pck[2] == 1) && isEnd:
			isEnd = (pck.size() >= 16)
		if isEnd:
			pck.remove_at(pck.size()-1)
			var a = ASBDataSegment.new()
			a.set_data(pck)
			a.generate_string_offsets()
			bodySegments.push_back(a)
			pck = PackedByteArray([])
			pck.push_back(41)
		index += 1
	var a = ASBDataSegment.new()
	a.set_data(pck)
	a.generate_string_offsets()
	bodySegments.push_back(a)
	if (bodySegments[0].rawData[0] != 41):
		headerData.rawData.append_array(bodySegments[0].rawData)
		headerData.length = headerData.rawData.size()
		bodySegments.remove_at(0)
	stringdata = f.get_buffer(f.get_length()-f.get_position())
	refreshStringList()
	for i in stringList:
		addEmptyDisplaySegment()
	headerData.generate_string_offsets()
	validateOffsets(headerData)
	var sind0 = 0
	var m0 = getAssociatedStrings(headerData)
	var n0 = headerData.get_offsets()
	for k in range(m0.size()):
		var j = m0[k]
		var stringBeginning = getStringNumberFromOffset(n0[k])
		replaceDisplaySegmentAt(usedOffsets.find(n0[k]), j, str(stringBeginning)+\
		"[-1, "+str(sind0)+"]", "Header")
		sind0 += 1
	var ind = 0
	for i in bodySegments:
		validateOffsets(i)
		var s = str(ind)+" "+i.title+": "
		var sind = 0
		var m = getAssociatedStrings(i)
		var n = i.get_offsets()
		for k in range(m.size()):
			var j = m[k]
			var stringBeginning = getStringNumberFromOffset(n[k])
			replaceDisplaySegmentAt(usedOffsets.find(n[k]), j, str(stringBeginning)+\
			"["+str(ind)+", "+str(sind)+"]", i.title)
			s += j
			s += ", "
			sind += 1
		s = s.erase(s.length()-2, 2)
		ind += 1
		_process(.1)
	f.close()
	lookForOrphanedStrings()
	removeEmptyBodySegments()
	reloadEditableBlocks()

func customUiSort(a, b):
	if (a[0] != b[0]):
		return a[0] < b[0]
	else:
		return a[1] < b[1]

func refreshStringList():
	stringList.clear()
	usedOffsets.clear()
	usedOffsets.push_back(0)
	var bu = PackedByteArray([])
	var index = 0
	for i in stringdata:
		bu.push_back(i)
		if (i == 0):
			var s = bu.get_string_from_utf8()
			stringList.push_back(s)
			if (index < stringdata.size()):
				usedOffsets.push_back(index+1)
			bu.clear()
		index += 1

func sortUi():
	refreshStringList()

func lookForOrphanedStrings():
	var offsetsFound = []
	for i in bodySegments:
		offsetsFound.append_array(i.get_offsets())
	offsetsFound.append_array(headerData.get_offsets())
	var stix = 1
	for i in range(stringdata.size()):
		if (i != 0) && (stringdata[i] == 0):
			if (!offsetsFound.has(i+1)):
				var text = PackedByteArray([])
				var idx = i+1
				while true:
					if (idx == stringdata.size()):
						break
					else:
						text.push_back(stringdata[idx])
						idx += 1
						if (text[text.size()-1] == 0):
							break
				if (text.size() != 0):
					var tex = text.get_string_from_utf8()
					replaceDisplaySegmentAt(usedOffsets.find(i+1), tex, \
					str(stix), "Orphan")
			stix += 1

func _process(delta):
	var scale1 = (get_viewport_rect().size/Vector2(1920, 1080))
	if (scale1.y < scale1.x):
		scale1.x = scale1.y
	elif (scale1.x < scale1.y):
		scale1.y = scale1.x
	scale = scale1
	$HBoxContainer/ScrollContainer.custom_minimum_size.y = get_viewport_rect().size.y-10

func _ready():
	loadDirectories()
	pass


func _on_load_pressed():
	$FileDialog.popup_centered()
	pass # Replace with function body.


func _on_file_dialog_confirmed():
	$HBoxContainer/TextEdit.clear()
	log1("Opening file "+$FileDialog.current_file)
	filePath = $FileDialog.current_path
	await readFileIntoMemory()
	saveDirectories()
	pass # Replace with function body.


func _on_file_dialog_canceled():
	log1("Operation cancelled.")
	pass # Replace with function body.


func _on_file_dialog_2_confirmed():
	savePath = $FileDialog2.current_path
	log1("Saving "+savePath.get_file())
	saveMemoryToFile()
	saveDirectories()
	pass # Replace with function body.


func _on_file_dialog_3_confirmed():
	vlDirectory = $FileDialog3.current_path
	saveDirectories()
	pass # Replace with function body.


func _on_save_pressed():
	if (savePath == ""):
		$FileDialog2.show()
	else:
		log1("Saving "+savePath.get_file())
		saveMemoryToFile()
		saveDirectories()
	pass # Replace with function body.


func _on_save_2_pressed():
	$FileDialog2.show()
	pass # Replace with function body.
