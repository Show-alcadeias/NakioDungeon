extends Control
const Game = preload("res://scripts/game.gd")
var game = Game.new()
var status: Label
var story: RichTextLabel
var dice_label: Label
var buttons: VBoxContainer
var journal: RichTextLabel
var journal_panel: PanelContainer

func _ready() -> void:
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 20
	theme_resource.default_font = preload("res://fonts/NotoSansCJKjp-Regular.otf")
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#25314b")
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	theme_resource.set_stylebox("normal", "Button", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("#3b5077")
	theme_resource.set_stylebox("hover", "Button", hover)
	theme_resource.set_stylebox("pressed", "Button", hover)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#ffdb7a")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(8)
	theme_resource.set_stylebox("focus", "Button", focus)
	theme = theme_resource
	var background := ColorRect.new()
	background.color = Color("#101726")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	var help := Label.new()
	help.text = "Tab / ↑↓：選択   Enter / Space：決定   マウス：クリック   記録：全文を確認"
	help.add_theme_font_size_override("font_size", 15)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(help)
	story = RichTextLabel.new()
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.bbcode_enabled = false
	story.add_theme_constant_override("line_separation", 8)
	layout.add_child(story)
	dice_label = Label.new()
	dice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice_label.add_theme_color_override("font_color", Color("#ffdb7a"))
	dice_label.add_theme_font_size_override("font_size", 17)
	layout.add_child(dice_label)
	var choice_scroll := ScrollContainer.new()
	choice_scroll.custom_minimum_size.y = 230
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(choice_scroll)
	buttons = VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 8)
	choice_scroll.add_child(buttons)
	var log_button := Button.new()
	log_button.text = "冒険の記録を開く / 閉じる"
	log_button.pressed.connect(toggle_journal)
	layout.add_child(log_button)
	journal_panel = PanelContainer.new()
	journal_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	journal_panel.offset_left = 24
	journal_panel.offset_top = 24
	journal_panel.offset_right = -24
	journal_panel.offset_bottom = -24
	add_child(journal_panel)
	var log_layout := VBoxContainer.new()
	journal_panel.add_child(log_layout)
	journal = RichTextLabel.new()
	journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_layout.add_child(journal)
	var close := Button.new()
	close.text = "記録を閉じる"
	close.pressed.connect(toggle_journal)
	log_layout.add_child(close)
	journal_panel.hide()
	refresh()

func toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible
	if journal_panel.visible:
		journal.text = "\n\n──────────\n\n".join(game.history)
		journal_panel.get_child(0).get_child(1).grab_focus()
	else:
		buttons.get_child(0).grab_focus()

func refresh() -> void:
	var floor_text := "9階"
	if game.event_index >= 3:
		floor_text = "10階"
	if game.stage == "title":
		floor_text = "冒険前"
	var place := ""
	if game.event_index < 3 and game.stage != "title":
		place = " / " + game.Events.EVENTS[game.event_index].title
	status.text = "%s%s | ナキオ HP %d / 20 | 振り直し %d / 3\n攻撃8　耐久7　敏捷4　知力1　幸運5" % [floor_text, place, game.hp, game.rerolls]
	if game.event_index >= 3:
		status.text += " | 魔術師 HP %d / 30" % game.boss.hp
	story.text = game.text
	if game.stage == "title":
		story.text = "脳筋冒険者ナキオと陰険な魔術師\n\n剣は太く、知恵は細く。\n一階の転送罠で九階へ飛ばされた冒険者。下り階段はない。十階の魔術師を倒して帰ろう。\n\n1D20＋能力値で判定。出目20は自動成功、1は自動失敗。\n失敗にも迂回路あり。振り直しは1プレイ3回。\n予兆を読み、鍋と筋肉で生還せよ。\n\n想定10〜20分。短い周回も楽しめます。"
	story.scroll_to_line(0)
	dice_label.text = game.roll_text()
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	for choice in game.choices():
		var button := Button.new()
		button.text = choice.label
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 48
		button.pressed.connect(act.bind(choice.id))
		buttons.add_child(button)
	if buttons.get_child_count() > 0:
		buttons.get_child(0).grab_focus()

func act(id: String) -> void:
	game.choose(id)
	refresh()
