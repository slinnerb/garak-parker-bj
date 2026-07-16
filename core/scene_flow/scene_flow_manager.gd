extends Node
## Scene navigation (autoload singleton: `SceneFlow`).
##
## Single choke point for swapping the active scene. Centralizing this keeps
## transitions consistent and gives one place to later add fade/loading
## overlays without touching callers. UI code calls these named helpers rather
## than poking get_tree() directly.

## Canonical scene paths. Keep the rest of the game from hard-coding res:// URIs.
const MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const BOOT := "res://scenes/boot/boot.tscn"
const COMBAT := "res://scenes/combat/combat_scene.tscn"
const ATTUNEMENT := "res://scenes/hub/attunement_scene.tscn"
const MAP := "res://scenes/map/map_scene.tscn"
const RECALL := "res://scenes/death/recall_scene.tscn"


func goto_main_menu() -> void:
	GameState.set_state(GameState.State.MAIN_MENU)
	change_scene(MAIN_MENU)


## Opens the attunement screen (choose the loadout, i.e. the deck) before a
## fight. Currently the demo entry point from the main menu.
func goto_attunement() -> void:
	GameState.set_state(GameState.State.RUN)
	change_scene(ATTUNEMENT)


## The run map — the hub of a life, where you choose the next encounter.
func goto_map() -> void:
	GameState.set_state(GameState.State.RUN)
	change_scene(MAP)


## The Moment of Recall — the death sequence where the soul remembers.
func goto_recall() -> void:
	GameState.set_state(GameState.State.DEATH)
	change_scene(RECALL)


## Enters combat. Combat is part of a life, so the coarse state is RUN. The fight
## to build comes from the active run (RunManager) if one is in progress, else
## from CombatRequest (attunement screen), else the default demo.
func goto_combat() -> void:
	GameState.set_state(GameState.State.RUN)
	change_scene(COMBAT)


## Swaps to the scene at `path`. Logs and announces via EventBus.
func change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		Log.error(Log.Cat.SCENE, "Scene does not exist: %s" % path)
		return
	Log.info(Log.Cat.SCENE, "Changing scene -> %s" % path)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		Log.error(Log.Cat.SCENE, "change_scene_to_file failed (err %d) for %s" % [err, path])
		return
	EventBus.emit_signal("scene_changed", path)


func quit_game() -> void:
	Log.info(Log.Cat.BOOT, "Quit requested")
	get_tree().quit()
