extends SceneTree
const Main = preload("res://main.tscn")
var screen
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func verify(value: bool, label_text: String) -> void:
	if not value:
		failures += 1
		push_error(label_text)
func run() -> void:
	screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	verify(screen.buttons.get_child_count() == 1, "Title start button")
	screen.buttons.get_child(0).pressed.emit()
	verify(screen.game.stage == "event", "Actual start button connects")
	verify(screen.buttons.get_child_count() == 3, "Event choices visible")
	screen.buttons.get_child(0).pressed.emit()
	verify(screen.game.stage == "roll", "Actual event button connects")
	verify(screen.dice_label.text.contains("1D20"), "Dice result visible")
	screen.toggle_journal()
	verify(screen.journal_panel.visible and not screen.journal.text.is_empty(), "History opens")
	screen.toggle_journal()
	for i in range(3):
		screen.game.event_index = i
		screen.game.stage = "event"
		screen.game.show_event()
		screen.refresh()
		await process_frame
		verify(screen.buttons.get_child_count() == screen.game.Events.EVENTS[i].choices.size(), "All event buttons")
	for state in ["boss", "round", "over", "ending"]:
		screen.game.stage = state
		screen.game.event_index = 3
		screen.refresh()
		await process_frame
		verify(screen.buttons.get_child_count() > 0, "State buttons: " + state)
	root.size = Vector2i(640, 720)
	screen.refresh()
	await process_frame
	verify(screen.story.size.y > 40, "Story has space at small viewport")
	verify(screen.buttons.get_child(0).has_focus(), "Keyboard focus assigned")
	print("UI TESTS: 15 checks, %d failures" % failures)
	screen.queue_free()
	quit(1 if failures else 0)
