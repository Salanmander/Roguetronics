extends Node

const MAIN_MENU: int = 0
const FACTORY: int = 1


const FACTORY_CONVEYOR_ID: int = 4

const GRID_SIZE: float = 128

const BELT: int = 0
const COMBINER: int = 1
const DISPENSER: int = 2
const CRANE: int = 3

const UP: float = 0
const DOWN: float = PI
const RIGHT: float = PI/2
const LEFT: float = 3*PI/2

const NUM_CRANE_COMMANDS: int = 7
const NO_COMMAND: int = 0
const FORWARD: int = 1
const BACKWARD: int = 2
const GRAB: int = 3
const RELEASE: int = 4
const RAISE: int = 5
const LOWER: int = 6
var COMMAND_IMAGES: Array = []

const POW_BELT = 0
const POW_CRANE = 1

func _init():
	COMMAND_IMAGES.resize(NUM_CRANE_COMMANDS)
	COMMAND_IMAGES[NO_COMMAND] = null
	COMMAND_IMAGES[FORWARD] = load("res://Factory/UI/assets/forward.png")
	COMMAND_IMAGES[BACKWARD] = load("res://Factory/UI/assets/backward.png")
	COMMAND_IMAGES[GRAB] = load("res://Factory/UI/assets/grab.png")
	COMMAND_IMAGES[RELEASE] = load("res://Factory/UI/assets/release.png")
	COMMAND_IMAGES[RAISE] = load("res://Factory/UI/assets/raise.png")
	COMMAND_IMAGES[LOWER] = load("res://Factory/UI/assets/lower.png")
	
