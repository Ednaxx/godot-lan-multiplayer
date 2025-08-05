extends Label
    
func _ready():
    var gm = get_tree().get_current_scene().get_node("GameManager")
    if gm:
        gm.connect("score_updated", Callable(self, "_on_score_updated"))
        _on_score_updated(gm.get_score())

func _on_score_updated(new_score):
    text = str(new_score) + " Points"
