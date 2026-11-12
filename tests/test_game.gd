extends SceneTree
const Dice = preload("res://scripts/dice.gd")
const Game = preload("res://scripts/game.gd")
const Combat = preload("res://scripts/combat.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func force(game, face: int) -> void:
	game.last_roll = Dice.evaluate(face, Game.Events.STATS[game.pending.stat], game.pending.target)
	game.choose("accept")

func reach_boss(game) -> void:
	game.choose("begin")
	for i in range(3):
		game.choose("0")
		force(game, 1)
		game.choose("fallback")
		game.choose("rest")
		game.choose("next")

func _initialize() -> void:
	check(Dice.evaluate(20, 1, 25).success, "Natural 20")
	check(not Dice.evaluate(1, 8, 10).success, "Natural 1")
	check(Dice.evaluate(7, 8, 15).success, "Threshold inclusive")
	check(not Dice.evaluate(6, 8, 15).success, "Below threshold")
	var dice := Dice.new()
	var faces := {}
	for i in range(500):
		var result := dice.roll(4, 15)
		check(result.face >= 1 and result.face <= 20, "Random range")
		faces[result.face] = true
	check(faces.size() > 1, "Real changing random rolls")
	# Every event choice: both natural outcomes, recovery, forward progress.
	for index in range(3):
		for option in range(Game.Events.EVENTS[index].choices.size()):
			for face in [1, 20]:
				var game := Game.new()
				game.begin()
				game.event_index = index
				game.show_event()
				game.choose(str(option))
				check(game.stage == "roll", "Choice produces roll")
				var before: int = game.hp
				force(game, face)
				if face == 1:
					check(game.stage == "failed" and game.hp < before, "Failure damage")
					game.choose("retry_event")
					check(game.stage == "event", "Retry choice works")
					game.choose(str(option))
					force(game, 1)
					game.choose("fallback")
				check(game.stage == "cleared", "Success or fallback clears")
				game.choose("rest")
				check(game.hp <= 20, "Healing cap")
				game.choose("next")
				check(game.stage in ["event", "boss"], "Progress after event")
	var game := Game.new()
	game.begin()
	game.choose("0")
	var hp_before: int = game.hp
	for i in range(3):
		game.choose("reroll")
	check(game.rerolls == 0 and game.hp == hp_before, "Rerolls do not apply effects")
	var last: Dictionary = game.last_roll.duplicate()
	game.choose("reroll")
	check(game.rerolls == 0 and game.last_roll == last, "No fourth reroll")
	game.choose("accept")
	var state: String = game.stage
	game.choose("accept")
	check(game.stage == state, "Cannot accept twice")
	# Worst rolls: attack during magic, defend on traps guarantees victory.
	game = Game.new()
	reach_boss(game)
	check(game.hp == 20 and game.stage == "boss", "All event failures still reach boss healthy")
	for i in range(40):
		if game.stage == "ending":
			break
		var action := "defend" if game.boss.intent().kind == "trap" else "attack"
		game.choose(action)
		force(game, 1)
		if game.stage == "round":
			game.choose("round")
	check(game.stage == "ending" and game.hp > 0, "Worst rolls still winnable with tactics")
	game.choose("title")
	check(game.stage == "title", "Ending title button")
	# Every combat action/outcome; mitigation and observation.
	for action in ["attack", "defend", "observe"]:
		for face in [1, 20]:
			game = Game.new()
			reach_boss(game)
			game.hp = 10
			game.choose(action)
			force(game, face)
			check(game.stage == "round", "Combat action resolves")
	var boss := Combat.new()
	boss.turn = 1
	boss.player_action("defend", false)
	check(boss.enemy_action().damage == 0, "Trap guard even on failure")
	boss = Combat.new()
	boss.player_action("observe", false)
	check(boss.enemy_action().damage == 2, "Observe mitigation")
	var before: int = boss.hp
	boss.player_action("attack", false)
	check(before - boss.hp == 7, "Observation bonus retained")
	# Repeated risky decisions cause game over, unlimited resets restore resources.
	game = Game.new()
	reach_boss(game)
	for i in range(20):
		if game.stage == "over":
			break
		game.choose("observe")
		force(game, 1)
		if game.stage == "round":
			game.choose("round")
	check(game.stage == "over", "Game over reachable")
	game.choose("begin")
	check(game.hp == 20 and game.rerolls == 3 and game.event_index == 0, "Retry resets run")
	for i in range(5):
		game.stage = "over"
		game.choose("begin")
		check(game.hp == 20, "Unlimited retry")
	print("TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
