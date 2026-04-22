extends Node

const MAIN_MENU: int = 0
const FACTORY: int = 1
const REWARD: int = 2

const VERSION_MAJOR = 0
const VERSION_MINOR = 1
const VERSION_BUILD = 3


const SCENE_FILES: Dictionary = {
	Consts.MAIN_MENU: "res://Menu/main_menu.tscn",
	Consts.FACTORY: "res://Factory/factory.tscn",
	Consts.REWARD: "res://Rewards/reward_screen.tscn"
}

const SCENE_FROM_CLASS: Dictionary = { 
	"MainMenu": Consts.MAIN_MENU,
	"Factory": Consts.FACTORY,
	"RewardScreen": Consts.REWARD
}

# values for click mode
const NONE = 0
const PLACE_CONVEYOR = 1
const PLACE_THING = 2
const PLACE_COMBINER = 3
const PLACE_DISPENSER = 4
const PLACE_WALL = 5
const PLACE_TRACK = 6
const PLACE_CRANE = 7
const PLACE_STAR_MAKER = 8
const PLACE_GOAL = 9
const DELETE = -1


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

# TODO: When save system becomes more robust, this should go away probably
const SAVE_FILENAME = "default.sav"


const UPGRADES_FILENAME = "res://Rewards/upgrades.json"
const PATTERNS_FILENAME = "res://Singletons/PuzzleManager/goalDefs.json"

func _init():
	COMMAND_IMAGES.resize(NUM_CRANE_COMMANDS)
	COMMAND_IMAGES[NO_COMMAND] = null
	COMMAND_IMAGES[FORWARD] = load("res://Factory/UI/assets/forward.png")
	COMMAND_IMAGES[BACKWARD] = load("res://Factory/UI/assets/backward.png")
	COMMAND_IMAGES[GRAB] = load("res://Factory/UI/assets/grab.png")
	COMMAND_IMAGES[RELEASE] = load("res://Factory/UI/assets/release.png")
	COMMAND_IMAGES[RAISE] = load("res://Factory/UI/assets/raise.png")
	COMMAND_IMAGES[LOWER] = load("res://Factory/UI/assets/lower.png")
	
