# FIGHTERS2 クラス設計書

## 1. プロジェクト要件

| 項目 | 内容 |
|---|---|
| ジャンル | 2D 横スクロール対戦格闘（KOF 系） |
| エンジン | Godot 4.5（Forward Plus） |
| キャラクター | レオン / ミナト（2名、共通アニメ12種） |
| 視点 | サイドビュー固定、右向き基準 |
| 攻撃ボタン | A（弱P）/ B（中K）/ C（強斬）/ D（特殊）の 4 ボタン式 |
| スプライト | 64×128 px / フレーム、ピクセルアート |

ファイル命名 `atk_5a` 〜 `atk_5d` は KOF 系の数値入力（5 = ニュートラル）＋ボタン規約。

### 状態一覧（12種）

| 状態 | フレーム数 | 用途 |
|---|---|---|
| idle | 4 | 立ち待機 |
| walk_f | 6 | 前歩き |
| walk_b | 4 | 後ろ歩き |
| crouch | 2 | しゃがみ |
| jump | 3 | 踏切〜空中〜着地 |
| atk_5a | 3 | 弱パンチ |
| atk_5b | 3 | 中キック |
| atk_5c | 4 | 強斬り |
| atk_5d | 3 | 特殊技（突進） |
| guard | 2 | ガード |
| hit_stand | 2 | 被弾（立ち） |
| knockdown | 3 | ダウン〜起き上がり |

---

## 2. シーン構成

```
Main (Node2D)
├─ Stage (Node2D)
├─ Fighter "P1" (CharacterBody2D)
├─ Fighter "P2" (CharacterBody2D)
├─ MatchManager (Node)
└─ HUD (CanvasLayer)
```

---

## 3. クラス階層

```
[Resource] CharacterData          ← .tres でレオン/ミナトのパラメータを定義
[Resource] AttackData             ← 攻撃ごとのフレームデータ
[Resource] HitboxFrame            ← 1フレームのヒット/ハートボックス

[Node]     Fighter (CharacterBody2D)   ← 共通の土台。継承せず Composition
   ├─ AnimatedSprite2D
   ├─ StateMachine (Node)
   │    └─ FighterState (Node) [基底]
   │         ├─ IdleState / WalkState / CrouchState / JumpState
   │         ├─ AttackState (atk_5a~5d を1クラスで data 駆動)
   │         ├─ GuardState / HitState / KnockdownState
   ├─ InputBuffer (Node)               ← 先行入力60F保持
   ├─ HitboxComponent (Area2D)         ← 攻撃判定
   ├─ HurtboxComponent (Area2D)        ← 被弾判定
   └─ HealthComponent (Node)

[Node, Autoload] InputManager        ← P1/P2 デバイス振り分け
[Node]           MatchManager        ← ラウンド・タイマー・KO 判定
[Control]        HUD                 ← HP バー、ラウンドランプ、タイマー
```

---

## 4. 各クラスの責務

### 4.1 Resource 層（データ）

| クラス | 責務 | 主要プロパティ |
|---|---|---|
| `CharacterData` | キャラ固有パラメータ | `max_hp, walk_f_speed, walk_b_speed, jump_power, gravity, attacks: Dictionary` |
| `AttackData` | 攻撃のフレームデータ | `startup, active, recovery, damage, hit_stun, block_stun, frames: HitboxFrame[]` |
| `HitboxFrame` | 1フレームの判定情報 | `hitbox_rect, hurtbox_rect, cancellable: bool` |

### 4.2 Fighter 系

| クラス | 責務 | 主要 API |
|---|---|---|
| `Fighter` | 物理・向き・ステート遷移の入口 | `take_damage(amount), set_facing(dir), play_anim(name)` |
| `FighterState` | ステート毎の処理（基底） | `enter(), exit(), physics_update(delta), handle_input(buffer)` |
| `IdleState` | 待機 | 入力監視、各状態へ遷移 |
| `WalkState` | 前後歩行 | 速度適用、入力で攻撃/しゃがみ/ジャンプへ |
| `CrouchState` | しゃがみ | しゃがみガード・しゃがみ攻撃の起点 |
| `JumpState` | ジャンプ | 重力適用、空中攻撃可、着地で Idle |
| `AttackState` | 攻撃（汎用） | `data: AttackData` 注入、active 中だけ Hitbox ON |
| `GuardState` | ガード | 後ろ入力中に被弾→ block_stun |
| `HitState` | 被弾（立ち） | hit_stun 経過で Idle、ダウン値超で Knockdown |
| `KnockdownState` | ダウン | 起き上がりまで無敵、終了で Idle |

### 4.3 コンポーネント

| クラス | 責務 | シグナル / API |
|---|---|---|
| `InputBuffer` | コマンド入力のリングバッファ（60F） | `is_pressed(btn, within=8), match_command(seq)` |
| `HitboxComponent` | active フレームだけ collision 有効化 | signal `hit(target, attack_data)` |
| `HurtboxComponent` | 被弾を Fighter に通知 | signal `hurt(attack_data)` |
| `HealthComponent` | HP 管理・KO 判定 | signal `defeated()`, `hp_changed(new, max)` |

### 4.4 マッチ進行

| クラス | 責務 | シグナル / API |
|---|---|---|
| `InputManager` (Autoload) | P1/P2 デバイス振り分け、入力正規化 | `get_input(player_id) -> Dictionary` |
| `MatchManager` | 2 of 3 ラウンド・タイマー・勝敗 | signal `round_end(winner)`, `match_end(winner)` |
| `HUD` | HP バー、ラウンドランプ、タイマー描画 | `update_hp(p1, p2), set_timer(sec)` |

---

## 5. キャラクター差分の実装方針

**継承ではなく Resource 注入** を採用する。

```
Fighter (汎用)
  ├─ character_data: CharacterData   ← leon.tres / minato.tres を差し替え
  └─ sprite_frames: SpriteFrames     ← レオン用 / ミナト用を差し替え
```

### メリット

- 12 アニメが共通なのでロジックを 1 本化できる
- 新キャラ追加が `.tres` 作成だけで済む
- バランス調整がコード変更不要

### 例外

固有技や固有挙動を持つキャラのみ `LeonFighter extends Fighter` のような派生を作る。
最初から派生させない（YAGNI）。

---

## 6. ステートマシン遷移図

```
       ┌──────────────────────────────────────┐
       │                                      │
       ▼                                      │
     Idle ──walk入力──▶ Walk ──┐              │
       │                       │              │
       │◀──攻撃終了──── Attack ◀┴── 攻撃ボタン │
       │                                      │
       ├──↓入力──▶ Crouch                    │
       ├──↑入力──▶ Jump                      │
       ├──後ろ入力＋被弾──▶ Guard             │
       └──被弾──▶ Hit ──ダウン値超──▶ Knockdown ──起き上り──┘
```

### 遷移ルール

- `Attack` 中は `cancellable: true` のフレームのみ別 Attack へキャンセル可
- `Hit` は被弾時のみ突入、無敵時間あり
- `Knockdown` 中は完全無敵
- `Guard` は後ろ入力ホールド中の被弾でのみ突入

---

## 7. 推奨ファイル配置

```
fighter/
├─ scenes/
│   ├─ main.tscn
│   ├─ fighter.tscn               ← Fighter ベースシーン
│   └─ stage.tscn
├─ scripts/
│   ├─ fighter/
│   │   ├─ fighter.gd
│   │   ├─ input_buffer.gd
│   │   ├─ hitbox_component.gd
│   │   ├─ hurtbox_component.gd
│   │   ├─ health_component.gd
│   │   └─ states/
│   │       ├─ fighter_state.gd
│   │       ├─ idle_state.gd
│   │       ├─ walk_state.gd
│   │       ├─ crouch_state.gd
│   │       ├─ jump_state.gd
│   │       ├─ attack_state.gd
│   │       ├─ guard_state.gd
│   │       ├─ hit_state.gd
│   │       └─ knockdown_state.gd
│   ├─ match/
│   │   ├─ match_manager.gd
│   │   └─ input_manager.gd
│   └─ data/
│       ├─ character_data.gd
│       ├─ attack_data.gd
│       └─ hitbox_frame.gd
├─ resources/
│   ├─ characters/
│   │   ├─ leon.tres
│   │   └─ minato.tres
│   └─ attacks/
│       ├─ leon_5a.tres ... leon_5d.tres
│       └─ minato_5a.tres ... minato_5d.tres
└─ assets/sprites/
    ├─ leon/
    └─ minato/
```

---

## 8. 設計上のキモ

1. **State パターンで状態爆発を防ぐ** — `if state == ...` の山にしない
2. **攻撃は Resource 駆動** — フレームデータだけ書き換えれば新技追加可
3. **Hit/Hurtbox は Area2D を on/off** — 1 フレーム単位で有効化制御
4. **InputBuffer は最初から作る** — 後付けは難しい
5. **キャラ固有処理は最後** — まず汎用 Fighter で殴り合えるところまで作る

---

## 9. 実装フェーズ案

| フェーズ | 内容 | 完了条件 |
|---|---|---|
| Phase 1 | スプライトインポート + AnimatedSprite2D | レオンの12アニメが再生できる |
| Phase 2 | Fighter + StateMachine 骨格（Idle/Walk/Crouch/Jump） | キャラを動かせる |
| Phase 3 | InputBuffer + AttackState + Hitbox/Hurtbox | 攻撃が当たる |
| Phase 4 | HealthComponent + HitState + KnockdownState | KO まで成立 |
| Phase 5 | GuardState + ガード硬直 | 防御が成立 |
| Phase 6 | MatchManager + HUD | 1 試合が完結 |
| Phase 7 | ミナト追加（Resource 差し替えのみ） | 2 キャラ対戦 |

---
