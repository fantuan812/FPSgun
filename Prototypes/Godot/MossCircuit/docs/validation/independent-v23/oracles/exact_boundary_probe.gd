extends SceneTree
const Shot=preload("res://scripts/gameplay/boundary_shot.gd")
func _initialize()->void:
 var b=Shot.spawn(Vector2(860,320),Vector2.RIGHT,{"width":960,"height":640},18,470,1260,0,true)
 var events=[]
 Shot.advance(b,100.0/470.0,[],Callable(),func(e):events.append(e))
 print("FIRST ",JSON.stringify(b))
 Shot.advance(b,960.0/470.0,[{"id":1,"pos":Vector2(40,380),"hp":1000,"scale":1}],Callable(),func(e):events.append(e))
 print("SECOND ",JSON.stringify(b))
 print("EVENTS ",JSON.stringify(events))
 Shot.advance(b,.000000001,[],Callable(),func(e):events.append(e))
 print("AFTER_TINY ",JSON.stringify(b))
 quit()
