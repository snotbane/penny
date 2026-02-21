
## Super simple class that ensures [Deco]s get registered properly. If you wish to use custom decors, they must be added to one.
class_name DecorRegistry extends Resource

const BUILTIN_BBCODE_DECORS : PackedStringArray = [
	"b",
	"i",
	"u",
	"s",
	"code",
	"char",
	"p",
	"br",
	"hr",
	"center",
	"left",
	"right",
	"fill",
	"indent",
	"url",
	"hint",
	"img",
	"font",
	"font_size",
	"dropcap",
	"opentype_features",
	"lang",
	"color",
	"bgcolor",
	"fgcolor",
	"outline_size",
	"outline_color",
	"table",
	"cell",
	"ul",
	"ol",
	"lb",
	"rb",
	"lrm",
	"rlm",
	"lre",
	"rle",
	"lro",
	"rlo",
	"pdf",
	"alm",
	"lri",
	"rli",
	"fsi",
	"pdi",
	"zwj",
	"zwnj",
	"wj",
	"shy",
]

@export var decors : Array[Decor]

func register_all_decors() -> void:
	for decor in decors:
		Decor.register_in_master(decor)
