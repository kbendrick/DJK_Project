extends RichTextLabel

#Establish filepath for fillword dictionary, and open the file.
var filepath = "res://fillwords.txt"
var file = FileAccess.open(filepath, FileAccess.READ)
var dump = file.get_as_text()
var fillwords : Array = dump.split("\n")
var keywords := [ 
	"[pulse freq=0.2 color=purple ease=2]flip[/pulse]",
	"[pulse freq=0.2 color=red ease=2]madness[/pulse]",
	"[pulse freq=0.2 color=yellow ease=2]ignorance[/pulse]",
	"[pulse freq=0.2 color=green ease=2]wisdom[/pulse]",
]
var key_weights := [10, 1, 5, 5]
var fill_weights := [10, 1]
var flip_indices := []

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
		
		#Select a keyword from the array.
		var keyword = keywords[rng.rand_weighted(key_weights)]
		
		#Append either keyword or fillword to output.
		var selections := [fillword, keyword]
		var selection = selections[rng.rand_weighted(fill_weights)]
		
		if selection == keywords[0]:
			flip_indices.append(str(hover_index))
			
		if keywords.has(selection):
			self.custom_effects.append(RichTextHover.new())
			self.custom_effects[hover_index].bbcode = "hover" + str(hover_index)
			selection = "[url="+str(hover_index)+"][hover"+str(hover_index)+"]"+selection+"[/hover"+str(hover_index)+"][/url]"
			hover_index += 1
		
		output += selection
		i += 1
		
	text = output

#Output a spread when this node is instanced.
func _ready():
	make_spread()

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
	if not flip_indices.has(str(meta)):
		return
	self.custom_effects = []
	flip_indices = []
	make_spread()
