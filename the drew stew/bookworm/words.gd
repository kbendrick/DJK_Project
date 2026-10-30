extends RichTextLabel

#Establish filepath for fillword dictionary, and open the file.
var filepath = "res://fillwords.txt"
var file = FileAccess.open(filepath, FileAccess.READ)
var dump = file.get_as_text()
var fillwords : Array = dump.split("\n")
var keywords := [ 
	"[url][hover][pulse freq=0.2 color=purple ease=2]flip[/pulse][/hover][/url]",
	"[url][pulse freq=0.2 color=red ease=2]madness[/pulse][/url]",
	"[url][pulse freq=0.2 color=green ease=2]wisdom[/pulse][/url]",
	"[url][pulse freq=0.2 color=yellow ease=2]ignorance[/pulse][/url]"
]
var key_weights := [10, 1, 5, 5]
var fill_weights := [10, 1]

func make_spread():

	#Initialize output.
	var output = ""
	var i = 0

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
		output += selection
		i += 1
		
	text = output

#Output a spread on click of "flip."
func _on_meta_clicked(meta):
	make_spread()

#Output a spread when this node is instanced.
func _ready():
	make_spread()


func _on_meta_hover_started(meta: Variant) -> void:
	pass # Replace with function body.


func _on_meta_hover_ended(meta: Variant) -> void:
	pass # Replace with function body.
