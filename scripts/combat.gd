class_name NakioCombat
extends RefCounted
const PATTERNS := [
	{"kind": "magic", "tell": "長い詠唱。杖に紫の火球が集まる。懐に隙がある。", "hit": "火球の魔法", "damage": 3},
	{"kind": "trap", "tell": "魔術師が床のスイッチに足を置く。頭上の金具が鳴る。防御の好機。", "hit": "天井の鉄球罠", "damage": 5},
	{"kind": "magic", "tell": "袖から詠唱メモを出す。冷気が集まるが腕は無防備だ。", "hit": "氷の魔法", "damage": 3}]
var hp := 30
var turn := 0
var insight := false
var guard := false
var exposure := false
func intent() -> Dictionary:
	return PATTERNS[turn % PATTERNS.size()]
func player_action(action: String, success: bool) -> String:
	match action:
		"attack":
			var damage := 8 if success else 3
			if intent().kind == "magic":
				damage += 2
			if exposure:
				damage += 4
				exposure = false
			hp = maxi(0, hp - damage)
			return "ナキオの一撃！ %dダメージ。%s" % [damage, "外れても風圧が当たる。" if not success else "筋肉は詠唱不要！"]
		"defend":
			guard = true
			if success:
				hp = maxi(0, hp - 3)
			return "防御を固め、次の被害を軽減。" + ("破片を跳ね返し敵に3ダメージ！" if success else "失敗しても防御は有効。")
		"observe":
			insight = true
			exposure = true
			return "危険な場所を見抜く。次の被害を軽減し、次の攻撃に+4ダメージ。" + ("安全な足場でHPが3回復。" if success else "難しい理屈は分からないが、危険は分かった。")
	return ""
func enemy_action() -> Dictionary:
	var pattern := intent()
	var damage: int = pattern.damage
	if guard:
		damage = 1 if pattern.kind == "magic" else 0
	elif insight:
		damage = 2
	var message := "%s！ ナキオに%dダメージ。" % [pattern.hit, damage]
	if guard and pattern.kind == "trap":
		message += " 罠を完全に防いだ！"
	guard = false
	insight = false
	turn += 1
	return {"damage": damage, "text": message}
