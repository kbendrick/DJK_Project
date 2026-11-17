extends RichTextLabel

#Establish filepath for fillword dictionary, and open the file.
var filepath = "res://the drew stew/bookworm/fillwords.txt"
var file = FileAccess.open(filepath, FileAccess.READ)
var dump = file.get_as_text()
var fillwords : Array = dump.split("\n")

var available_keywords: Dictionary[String, Keyword]
var spread_keywords: Dictionary[String, Keyword]

var fill_weights := [10, 1]

var hovered_meta: String = ""

func make_spread():

	#Initialize output.
	var output = ""
	var output_check: String = ""
	var output_not_enough:bool = true
	var hover_index = 0
	self.custom_effects = []
	
	while output_not_enough:
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
		var selection_check = selection
			
		if available_keywords.has(selection):
			if available_keywords[selection].hoverable:
				self.custom_effects.append(RichTextHover.new())
				self.custom_effects[hover_index].bbcode = "hover" + str(hover_index)
				
				var keyword_holder: Keyword = available_keywords[selection].duplicate()
				keyword_holder.bbcode_tag = selection+str(hover_index)
				spread_keywords[selection+str(hover_index)] = keyword_holder
				
				selection = "[url="+selection+str(hover_index)+"][hover"+str(hover_index)+"]"+available_keywords[selection].tag_code+"[/hover"+str(hover_index)+"][/url]"
				hover_index += 1
			else:
				var keyword_holder: Keyword = available_keywords[selection].duplicate()
				keyword_holder.bbcode_tag = selection+str(hover_index)
				spread_keywords[selection+str(hover_index)] = keyword_holder
				
				selection = "[url="+selection+"]"+available_keywords[selection].tag_code+"][/url]"
				
		if output_check.length() + selection_check.length() > 1660:
			#print("Output:" + str(output_check.length()))
			#print("Broke at: " + str(output_check.length() + selection_check.length()))
			#print("Selection: " + selection_check)
			break
			
		output_check += selection_check
		output += selection
			
		
	text = output

func setup(keywords: Array[Keyword])->void:
	for keyword in keywords:
		add_child(keyword)
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
	if spread_keywords[str(meta)].disabled:
		return
	self.custom_effects[hover_index]._on_meta_hover_started(meta)
	self.get_parent().get_parent().hover_text = spread_keywords[str(meta)]

func _on_meta_hover_ended(meta: Variant) -> void:
	if str(meta) == "":
		return
	if not available_keywords.has(str(meta).rstrip("0123456789")):
		return
	if not available_keywords[str(meta).rstrip("0123456789")].hoverable:
		return
	if not str(meta).to_int() < self.custom_effects.size():
		return

	var hover_index = str(meta).to_int()
	if spread_keywords[str(meta)].disabled:
		return
	self.custom_effects[hover_index]._on_meta_hover_ended(meta)
	self.get_parent().get_parent().hover_text = null

#Output a spread on click of "flip."
func _on_meta_clicked(meta):
	
	if str(meta) == "":
		return
	if not available_keywords.has(str(meta).rstrip("0123456789")):
		return
	if not available_keywords[str(meta).rstrip("0123456789")].clickable:
		return
	
	available_keywords[str(meta).rstrip("0123456789")].on_click()

func meta_disabled(meta):
	if str(meta) == "":
		return
	if not available_keywords.has(str(meta).rstrip("0123456789")):
		return
	if not available_keywords[str(meta).rstrip("0123456789")].hoverable:
		return
	
	spread_keywords[str(meta)].disabled = true
