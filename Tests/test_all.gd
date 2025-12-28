extends GutTest

var factory_packed = preload("res://Factory/factory.tscn")
var factory: Factory

func before_all():
	pass
	#factory = factory_packed.instantiate()
	

# Single widget on conveyor
func test_conveyor_1():
	factory = factory_packed.instantiate()
	
	add_child(factory)
	
	var floor: FactoryFloor = factory.get_node("FactoryLayer/FactoryFloor")
	
	
	floor.make_belt(Vector2i(3, 3), Consts.UP)
	floor.make_belt(Vector2i(3, 2), Consts.UP)
	var assembly1: Assembly = floor.make_widget(Vector2i(3, 3), 1)
	
	floor._on_run_pressed()
	
	await wait_seconds(2)
	
	assert_eq(floor.local_to_map(assembly1.position), Vector2i(3, 1))
	
	remove_child(factory)
	factory.queue_free()
	
	# time to let cleanup happen
	await wait_seconds(0.05)
	

# Test crane repeatedly pushing long line of widgets
func test_crane_repeat():
	factory = factory_packed.instantiate()
	
	add_child(factory)
	
	var floor: FactoryFloor = factory.get_node("FactoryLayer/FactoryFloor")
	
	
	var track: Track = floor.make_track(Vector2i(3, 3))
	track.drag_to(Vector2i(4, 3))
	track.drag_to(Vector2i(5, 3))
	
	floor.make_dispenser(Vector2i(4, 3), 1)
	var crane: Crane = floor.make_crane(Vector2i(4, 3), track)
	
	var program: Array[int] = [Consts.GRAB,
							Consts.FORWARD, 
							Consts.RELEASE,
							Consts.BACKWARD,
							Consts.GRAB,
							Consts.BACKWARD,
							Consts.RELEASE,
							Consts.FORWARD]
	crane.set_program(program)
	
	floor._on_run_pressed()
	
	await wait_seconds(25)
	
	assert(not factory.floor.crashed)

	remove_child(factory)
	factory.queue_free()
	
	# time to let cleanup happen
	await wait_seconds(0.05)
	
	
	
