extends GutTest

var factory_packed = preload("res://Factory/factory.tscn")
var factory: Factory

func before_all():
	pass
	#factory = factory_packed.instantiate()
	

# Single widget on conveyor
func test_passes():
	factory = factory_packed.instantiate()
	add_child(factory)
	
	var floor: FactoryFloor = factory.get_node("FactoryLayer/FactoryFloor")
	
	
	floor.make_belt(Vector2i(3, 3), Consts.UP)
	var assembly1: Assembly = floor.make_widget(Vector2i(3, 3), 1)
	
	floor._on_run_pressed()
	
	await wait_seconds(2)
	
	assert_eq(floor.local_to_map(assembly1.position), Vector2i(3, 2))
	
	
