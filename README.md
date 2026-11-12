# 脳筋冒険者ナキオと陰険な魔術師

日本語テキストRPGのMVP。GDScriptのみ。画像・音声・外部サービス不要。
9階の3つの罠を抜け、10階の魔術師を倒すとエンディングです。

## 起動

Godot 4.7系の標準版で `project.godot` をインポートし、F6ではなく **F5（プロジェクト実行）**。
依頼の対象は4.7.2。クラウドで実行確認したバージョンは **4.7.stable.official.5b4e0cb0f** です。
4.7.2そのものでの動作確認は未実施です。

コマンドライン：

```sh
godot --path .
```

クラウドの実行環境ではシステムの古いGodotを避け、以下を使用します。

```sh
export XDG_DATA_HOME=/workspace/.godot-env/data
export XDG_CONFIG_HOME=/workspace/.godot-env/config
export XDG_CACHE_HOME=/workspace/.godot-env/cache
/workspace/.godot-env/bin/Godot_v4.7-stable_linux.x86_64 --path /workspace/NakioDungeon
```

GUI起動にはデスクトップが必要です。ヘッドレスの場合は後述の検証を実行できます。

## 操作とルール

- マウスで選択肢をクリック。Tab / Shift+Tabまたは上下キーで移動、Enter / Spaceで決定。
- 中央本文と長い選択肢はそれぞれスクロール可能。冒険の記録から過去の本文と判定を確認できます。
- 1D20＋能力値。出目20は自動成功、1は自動失敗。ダイスは毎回実乱数です。
- 結果表示後に「確定」または「振り直し」。確定前にはダメージ等が発生しません。
- 振り直しは冒険全体で3回。新しい結果を必ず採用します。
- 罠失敗後は別の選択肢を試すか、判定不要の迂回で前進できます。繰り返し危険を冒すとHPが尽きます。
- 各イベント後に4回復。HP上限20。ボスHP30。
- ボスの魔法は攻撃の好機。床スイッチの罠には防御。防御は失敗でも軽減、観察も失敗でも軽減＋次の攻撃強化。
- 攻撃は失敗でも風圧で削れます。最悪の出目が続いても、予兆に合わせた攻撃・防御で勝利可能。
- ゲームオーバー後は無制限に最初から再挑戦。HP・振り直し・敵・イベントはリセット。
- セーブや成長要素はありません。読書・試行を含め10〜20分を目標にしていますが、最短経路は短めです。実測のプレイ時間調整は未実施です。

## 構成

- `main.tscn` / `scripts/main.gd`：画面、スクロール、フォーカス、ログ
- `scripts/events.gd`：能力値とイベントデータ（選択肢、目標値、成功・失敗文、迂回文）
- `scripts/dice.gd`：乱数と純粋な出目評価関数
- `scripts/combat.gd`：敵の予兆、ダメージ、防御、観察
- `scripts/game.gd`：状態遷移、HP、振り直し、再挑戦
- `tests/`：独立ロジックとUI接続の自動検証

イベント追加は `EVENTS` 配列へ同じ形式で追加してください。現在の階層表示は3イベント構成に合わせているので、イベント数変更時はUIの階層境界も調整してください。

## 検証

プロジェクトルートで実行（クラウドでは上記の環境変数とGodotの絶対パスを利用）。

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_ui.gd
godot --headless --path . --quit-after 3
```

テストには出目を明示した純粋関数検証と結果注入を使います。ゲーム本体の乱数を固定する機能はありません。
全イベントの全選択肢の成功・失敗、迂回、振り直し制限、全戦闘行動、勝利、敗北、再挑戦を検証します。

検証結果（Godot 4.7 stable、ヘッドレス）：ロジック637項目、UI接続15項目が成功。
エディタの読み込みとメインシーンの起動も成功しました。GUIの目視確認は未実施です。

## Web

Compatibilityレンダラーとスレッド無効のWebプリセットを同梱。
日本語フォントも同梱しているため、OSのフォントやCDNへの依存はありません。
Godotの対応するWebエクスポートテンプレートをインストールしてから：

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

HTMLを直接開かずHTTPで配信してください。Web出力はWebGL 2対応ブラウザが必要です。
本MVPではWebエクスポートとブラウザでの実機検証は未実施です。

## フォント

日本語表示用に環境に導入済みのNoto Sans CJK JP Regularを同梱。
SIL Open Font License 1.1。著作権・ライセンス全文は `fonts/LICENSE.txt`。
ゲーム用画像・音声の追加取得は不要です。
