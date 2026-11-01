extends RichTextLabel

#Establish filepath for fillword dictionary, and open the file.
var filepath = "res://the drew stew/bookworm/fillwords.txt"
var file = FileAccess.open(filepath, FileAccess.READ)
var dump = file.get_as_text()
var fillwords : Array = dump.split("\n")

var available_keywords: Dictionary[String, Keyword]

var fill_weights := [10, 1]

func make_spread():

	#Initialize output.
	var output = ""
	var i = 0
	var hover_index = 0
	self.custom_effects = []
	
	while i <= 500:
		#Select a fillword from the dictionary and reverse it.
		var rng = RandomNumberGenerator.new()
		var unclean = fillwords.pick_random()
		var cleaned = unclean.strip_edges()
		var fillword = cleaned.reverse()
		
		var key_weights: Array
		var key_tags: Array
		
		for tag in available_keywords:
			key_weights.append(available_keywords[tag].key_weight)
			key_tags.append(available_keywords[tag].tag)
		
		#Select a keyword from the array.
		var keyword = key_tags[rng.rand_weighted(key_weights)]
		
		#Append either keyword or fillword to output.
		var selections := [fillword, keyword]
		var selection = selections[rng.rand_weighted(fill_weights)]
			
		if available_keywords.has(selection):
			if available_keywords[selection].hoverable:
				self.custom_effects.append(RichTextHover.new())
				self.custom_effects[hover_index].bbcode = "hover" + str(hover_index)
				selection = "[url="+selection+str(hover_index)+"][hover"+str(hover_index)+"]"+available_keywords[selection].tag_code+"[/hover"+str(hover_index)+"][/url]"
				hover_index += 1
			else:
				selection = "[url="+selection+"]"+available_keywords[selection].tag_code+"][/url]"
		output += selection
		i += 1
		
	text = output

func setup(keywords: Array[Keyword])->void:
	for keyword in keywords:
		available_keywords[keyword.tag] = keyword
	make_spread()

func _on_meta_hover_started(meta: Variant) -> void:
	if str(meta) == "":
		return
	if not available_keywords.has(str(meta).rstrip("0123456789")):
		return	
	if not available_keywords[str(meta).rstrip("0123456789")].hoverable:
		return
	
	var hover_index = str(meta).to_int()
	self.custom_effects[hover_index]._on_meta_hover_started(meta)

func _on_meta_hover_ended(meta: Variant) -> void:
	if str(meta) == "":
		return
	if not available_keywords.has(str(meta).rstrip("0123456789")):
		return
	if not available_keywords[str(meta).rstrip("0123456789")].hoverable:
		return

	var hover_index = str(meta).to_int()
	self.custom_effects[hover_index]._on_meta_hover_ended(meta)

#Output a spread on click of "flip."
func _on_meta_clicked(meta):
	
	if str(meta) == "":
		return
	if not available_keywords.has(str(meta).rstrip("0123456789")):
		return
	if not available_keywords[str(meta).rstrip("0123456789")].clickable:
		return
	
	var on_click = available_keywords[str(meta).rstrip("0123456789")].on_click()
	
	if on_click == "make_spread":
		make_spread()
