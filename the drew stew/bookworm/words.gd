extends RichTextLabel

#Establish filepath for fillword dictionary, and open the file.
var filepath = "res://the drew stew/bookworm/fillwords.txt"
var file = FileAccess.open(filepath, FileAccess.READ)
var dump = file.get_as_text()
var fillwords : Array = dump.split("\n")

#var available_keywords: Array[Array] = [ 
	#["flip", 10],
	#["madness", 1],
	#["ignorance", 5],
	#["wisdom", 5],
#]

var available_keywords: Array[Array]

var keyword_code: Dictionary = {
	"flip": "[pulse freq=0.2 color=purple ease=2]flip[/pulse]",
	"madness": "[pulse freq=0.2 color=red ease=2]madness[/pulse]",
	"ignorance": "[pulse freq=0.2 color=yellow ease=2]ignorance[/pulse]",
	"widsom": "[pulse freq=0.2 color=green ease=2]wisdom[/pulse]"
}

var fill_weights := [10, 1]

func make_spread():

	#Initialize output.
	var output = ""
	var i = 0
	var hover_index = 0

	while i <= 500:
		#Select a fillword from the dictionary and reverse it.
		var rng = RandomNumberGenerator.new()
		var unclean = fillwords.pick_random()
		var cleaned = unclean.strip_edges()
		var fillword = cleaned.reverse()
		
		var key_weights: Array
		
		for array in available_keywords:
			key_weights.append(array[1])
		
		#Select a keyword from the array.
		var keyword = available_keywords[rng.rand_weighted(key_weights)][0]
		
		#Append either keyword or fillword to output.
		var selections := [fillword, keyword]
		var selection = selections[rng.rand_weighted(fill_weights)]
			
		if keyword_code.has(selection):
			self.custom_effects.append(RichTextHover.new())
			self.custom_effects[hover_index].bbcode = "hover" + str(hover_index)
			selection = "[url="+selection+str(hover_index)+"][hover"+str(hover_index)+"]"+keyword_code[selection]+"[/hover"+str(hover_index)+"][/url]"
			hover_index += 1
		
		output += selection
		i += 1
		
	text = output

func setup(keywords: Array[Array])->void:
	available_keywords = keywords
	make_spread()

func add_keyword(keyword: Array, code: String)->void:
	available_keywords.append(keyword)
	keyword_code[keyword[0]] = code

func _on_meta_hover_started(meta: Variant) -> void:
	if str(meta) == "":
		return
	var hover_index = str(meta).to_int()
	self.custom_effects[hover_index]._on_meta_hover_started(meta)

func _on_meta_hover_ended(meta: Variant) -> void:
	if str(meta) == "":
		return
	var hover_index = str(meta).to_int()
	self.custom_effects[hover_index]._on_meta_hover_ended(meta)

#Output a spread on click of "flip."
func _on_meta_clicked(meta):
	if str(meta).rstrip("0123456789") == "flip":
		self.custom_effects = []
		make_spread()
