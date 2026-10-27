extends SceneTree
var g
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);g._start_run(3402);g.build.weapons=["rail_lance"];g._recompute();g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5);g.hero.position=g.player_pos
 var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(55,0));e.hp=1000
 g._fire_weapon("rail_lance",0);var pose:Dictionary=g.weapon_rig.last_shot.pose;var toward:Vector2=(e.pos-pose.muzzle).normalized()
 print(JSON.stringify({"mount":[pose.mount.x,pose.mount.y],"muzzle":[pose.muzzle.x,pose.muzzle.y],"direction":[pose.direction.x,pose.direction.y],"target":[e.pos.x,e.pos.y],"ray_dot":toward.dot(pose.direction)}))
 g.queue_free();await process_frame;quit()
