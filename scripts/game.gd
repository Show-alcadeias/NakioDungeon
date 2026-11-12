class_name NakioGame
extends RefCounted
const Dice = preload("res://scripts/dice.gd")
const Events = preload("res://scripts/events.gd")
const Combat = preload("res://scripts/combat.gd")
var dice := Dice.new()
var hp := 20
var rerolls := 3
var stage := "title"
var event_index := 0
var attempts := 0
var pending: Dictionary = {}
var last_roll: Dictionary = {}
var boss = Combat.new()
var text := ""
var history: Array[String] = []

func begin() -> void:
	hp = 20
	rerolls = 3
	event_index = 0
	attempts = 0
	pending = {}
	last_roll = {}
	boss = Combat.new()
	history.clear()
	show_event()

func say(value: String) -> void:
	text = value
	history.append(value)

func show_event() -> void:
	stage = "event"
	say(Events.EVENTS[event_index].story)

func choices() -> Array:
	match stage:
		"title": return [{"label": "冒険を始める", "id": "begin"}]
		"event":
			var result: Array = []
			var source: Array = Events.EVENTS[event_index].choices
			for i in range(source.size()):
				var c: Dictionary = source[i]
				result.append({"label": "%s  [%s+%d / 目標%d]" % [c.label, c.stat, Events.STATS[c.stat], c.target], "id": str(i)})
			return result
		"roll":
			var result: Array = [{"label": "この結果を確定する", "id": "accept"}]
			if rerolls > 0:
				result.append({"label": "振り直す（残り%d回）" % rerolls, "id": "reroll"})
			return result
		"failed":
			var result: Array = [{"label": "別の方法を試す", "id": "retry_event"},
				{"label": "筋肉と機転で迂回する（判定不要）", "id": "fallback"}]
			if attempts >= 2:
				result[0].label = "もう一度挑む（危険あり）"
			return result
		"cleared": return [{"label": "ひと息ついて先へ進む", "id": "rest"}]
		"rest": return [{"label": "次へ進む", "id": "next"}]
		"boss":
			return [{"label": "攻撃  [攻撃+8 / 目標15]", "id": "attack"},
				{"label": "防御  [耐久+7 / 目標10]", "id": "defend"},
				{"label": "観察  [知力+1 / 目標15]", "id": "observe"}]
		"round": return [{"label": "次の予兆を確認する", "id": "round"}]
		"over", "ending": return [{"label": "最初から再挑戦する", "id": "begin"}, {"label": "タイトルへ", "id": "title"}]
	return []

func choose(id: String) -> void:
	# Reject stale/unknown UI commands; all transitions use the same public interface.
	var valid := false
	for c in choices():
		if c.id == id:
			valid = true
	if not valid:
		return
	match stage:
		"title", "over", "ending":
			if id == "begin":
				begin()
			else:
				stage = "title"
		"event":
			pending = Events.EVENTS[event_index].choices[int(id)].duplicate()
			pending["kind"] = "event"
			roll_pending()
		"roll":
			if id == "reroll":
				rerolls -= 1
				roll_pending()
			else:
				resolve()
		"failed":
			if id == "fallback":
				stage = "cleared"
				say(Events.EVENTS[event_index].fallback)
			else:
				show_event()
		"cleared":
			hp = mini(20, hp + 4)
			stage = "rest"
			say(Events.EVENTS[event_index].after)
		"rest":
			event_index += 1
			attempts = 0
			if event_index < Events.EVENTS.size():
				show_event()
			else:
				show_boss(true)
		"boss":
			var stats := {"attack": "攻撃", "defend": "耐久", "observe": "知力"}
			pending = {"kind": "combat", "action": id, "stat": stats[id], "target": 10 if id == "defend" else 15}
			roll_pending()
		"round": show_boss(false)

func roll_pending() -> void:
	last_roll = dice.roll(Events.STATS[pending.stat], pending.target)
	stage = "roll"
	say("判定結果が出た。確定するまでは効果は発生しない。\n\n%s\n\n振り直すと新しい出目を必ず採用する。振り直しは冒険全体で3回まで。" % roll_text())

func roll_text() -> String:
	if last_roll.is_empty():
		return "まだ判定していません"
	var special := ""
	if last_roll.face == 20:
		special = "（出目20：自動成功）"
	elif last_roll.face == 1:
		special = "（出目1：自動失敗）"
	return "1D20：%d + %s補正%d = %d / 目標%d → %s%s" % [last_roll.face, pending.stat, last_roll.bonus, last_roll.total, last_roll.target, "成功" if last_roll.success else "失敗", special]

func resolve() -> void:
	var success: bool = last_roll.success
	if pending.kind == "event":
		attempts += 1
		if success:
			stage = "cleared"
			say(pending.win)
		else:
			hp = maxi(0, hp - int(pending.damage))
			stage = "failed"
			say("%s\n\nHPに%dダメージ。再挑戦するか、判定不要の迂回路で前進できる。" % [pending.lose, pending.damage])
	else:
		var report: String = boss.player_action(pending.action, success)
		if pending.action == "observe" and success:
			hp = mini(20, hp + 3)
		if boss.hp <= 0:
			stage = "ending"
			say("最後の一撃が杖を折った。\n『私の緻密な計画が……！』\n「すごい罠だったぞ。次は出口も作ってくれ」\n\n魔術師の契約が解け、塔の中央に帰還門が開く。ナキオは壊した壁の片付けを手伝ってから門をくぐった。\n\n地上の酒場。『九階で何を学んだ？』\n「箱は噛む。鍋は強い。弁当は三つ持て」\n\n脳筋冒険者ナキオと陰険な魔術師 ― 完\n\n残りHP：%d / 残り振り直し：%d" % [hp, rerolls])
			return
		var enemy: Dictionary = boss.enemy_action()
		hp = maxi(0, hp - int(enemy.damage))
		stage = "round"
		say(report + "\n\n" + enemy.text + "\n\n『計算上はもう倒れているはずだ！』\n「計算ってすごいな。俺はまだ立ってるぞ」")
	if hp <= 0:
		stage = "over"
		say("ナキオは膝をついた。\n『ついに私の知略が勝った！』\n\n目を覚ますと冒険者組合の救護室だった。魔術師の自慢話の間に救助隊が来たらしい。\n「次は弁当を増やそう」\n\nゲームオーバー。何度でも最初から再挑戦できる。HPと振り直しは全回復する。")

func show_boss(first: bool) -> void:
	stage = "boss"
	var intro := ""
	if first:
		intro = "十階。魔術師ネチリウスが豪華な椅子から立ち上がる。\n『ようこそ、私の完璧な罠を壊した野蛮人！』\n「褒められた！」\n\n出口の鍵は魔術師の杖。倒せば帰還門が開く。\n攻撃は失敗しても最低3ダメージ。防御と観察の軽減も判定に関係なく働く。\n\n"
	say(intro + "【敵の予兆】\n" + boss.intent().tell + "\n\n攻撃：敵を削る。防御：罠を無効化、魔法を軽減。観察：被害軽減と次の攻撃強化、成功時は回復。")
