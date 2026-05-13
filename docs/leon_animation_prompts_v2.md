# LEON アニメーション生成プロンプト集 v2

## 方針

**idle のみ 4 フレーム、それ以外は 1 フレーム静止ポーズ**。

AI 生成スプライトで多フレームの滑らかな動きを作るのは現実的に難しいため、「ポーズ × ゲーム側の移動」で動きを表現する古典的アプローチを採用。

| アニメ | フレーム数 | 補足 |
|---|---|---|
| idle | 4 | 呼吸ループ |
| walk_f | 6 | 歩行サイクル（2 ステップ分、1 フレーム 1 ファイル） |
| walk_b | 1 | 後ろ歩きのミッドストップポーズ |
| crouch | 1 | しゃがみポーズ |
| jump | 1 | 空中ポーズ |
| atk_5a | 1 | 弱パンチのインパクト瞬間 |
| atk_5b | 1 | 中キックのインパクト瞬間 |
| atk_5c | 1 | 強斬りのインパクト瞬間 |
| atk_5d | 1 | 突進のピーク瞬間 |
| guard | 1 | ガード保持ポーズ |
| hit_stand | 1 | のけぞりポーズ |
| knockdown | 1 | 倒れているポーズ |

合計 **20 ファイル**（idle 4 + walk_f 6 + 他 10）。

---

## ワークフロー

1. ChatGPT で **新規チャット**
2. `image/レオン.png` を添付 + 「セッション開始文」を送信
3. ChatGPT が「了解」と返したら、アニメ単位で生成
4. 各画像を `fighter/assets/sprites/leon/<anim>/00.png` に保存
   - idle のみ `00.png ~ 03.png` の 4 枚
5. **`idle/00.png` から作る**（全アニメの x 軸基準になる）

### 重要

- 1 リクエスト = **1 枚の画像**
- 同じセッションを維持
- 各アニメで前フレーム or `idle/00.png` を再添付して連続性確保
- 不満なら **そのアニメだけ 1 枚再生成すれば良い**

---

## セッション開始文（最初に送る）

```
[Attach: レオン.png]

This is the canonical character design for "Leon" — memorize his exact appearance
(silver-white short hair, dark navy military jacket with gold trim, black pants and boots).

I'm building a 2D fighting game. Each request asks for ONE single 256×384 PNG
image (one pose / one animation frame). NOT a sprite sheet, NOT a strip.

== HARD RULES (apply to EVERY image) ==

1. SIZE: exactly 256w × 384h, single image.
2. GROUND LINE: the BOTTOM EDGE of the image is the ground.
3. ANCHOR: the character's feet rest exactly on the bottom edge,
   horizontally centered (around x = 128).
   - Standing/walking poses: feet at bottom-center, NEVER float higher.
   - Extended poses (kick/lunge/slash): SUPPORTING foot stays at bottom-center;
     limbs extend sideways only.
   - Airborne poses (only jump and knockdown frame 1): exception — character
     drawn in the UPPER 60% of the frame, lower 40% transparent.
4. SCALE: character height (head-to-foot) is identical across ALL images.
   Match the reference image's character height exactly.
5. CAMERA: pure side view, character faces right.
6. BACKGROUND: fully transparent — verify with the bottom-right corner pixel.
   NO ground line, NO floor shadow disc, NO horizontal lines anywhere.
7. STYLE / COLOR: identical to the reference — clean cel-shaded illustration.
   Skin tone, lighting, and color saturation must match the reference EXACTLY
   in every frame. No warm/tan drift between frames.

== CONTINUITY ==

When I send a new pose request, I will attach a previous image as the anchor
(usually idle/00.png). Use it as the immediate reference:
  - Same x position of feet
  - Same body height
  - Same costume rendering
  - Same skin tone, lighting, color saturation

Confirm understanding before I send pose requests.
```

---

## 各アニメのプロンプト

### idle (4 frames) → `leon/idle/`

**最重要アニメ**。`idle/00.png` の足元 x が **全アニメの基準**になるので、これだけは妥協せず納得いくまで再生成。

#### `idle/00.png` ★全アニメの基準フレーム★

```
Generate ONE 256×384 PNG image: Leon's idle stance, neutral pose.
- Both feet planted at bottom-center (x ≈ 128, y = 384).
- Arms relaxed at sides, slight elbow bend.
- Chest at neutral height (mid-breath).
- Eyes looking forward (rightward).
- Transparent background.

This is the MASTER ANCHOR for ALL future images in this session.
The exact x position of the feet defines the global character anchor —
all subsequent images must place feet at the same x.
```

#### `idle/01.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon idle, mid-inhale.
- Chest raised very slightly (~1.5% of frame height) vs the attached frame.
- Shoulders slightly raised.
- FEET POSITION UNCHANGED — overlay test against idle/00 must show
  identical foot pixels.
```

#### `idle/02.png`

```
[Attach: idle/01.png]

Generate ONE 256×384 PNG image: Leon idle, full inhale.
- Chest at peak height (~2% above idle/00).
- FEET UNCHANGED.
```

#### `idle/03.png`

```
[Attach: idle/02.png]

Generate ONE 256×384 PNG image: Leon idle, mid-exhale.
- Chest descending (~1% above idle/00).
- FEET UNCHANGED.
```

---

### walk_f (6 frames) → `leon/walk_f/`

**重要**: 6 フレームは **2 ステップ分の歩行サイクル**（前半 00–02 = 右足ステップ、後半 03–05 = 左足ステップ）。
AI は半サイクルで止まりがちなので、**03 から先は明示的に「脚の役割を入れ替える」** と強調する。

#### `walk_f/00.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon walking forward, frame 1 of 6.

This is the START of a 6-frame walk cycle that contains TWO full steps.
- LEFT foot forward (slightly ahead of x=128), planted.
- RIGHT foot back, heel just lifting (about to start swinging forward).
- Body's center-of-mass at x ≈ 128 (same as idle).
- Coat flowing slightly back.
```

#### `walk_f/01.png`

```
[Attach: walk_f/00.png]

Frame 2 of 6 — RIGHT leg is the moving leg.
- RIGHT foot lifted, knee bent forward (mid-swing).
- LEFT foot still planted near body center.
- Body center x unchanged.
```

#### `walk_f/02.png`

```
[Attach: walk_f/01.png]

Frame 3 of 6 — RIGHT leg is the moving leg, completing first step.
- RIGHT foot reaching forward, about to land.
- LEFT foot starting to push off (heel lifting).
- Body center x unchanged.
```

#### `walk_f/03.png`

```
[Attach: idle/00.png AND walk_f/02.png]

Generate walk_f/03.png — frame 4 of 6 of Leon's walk forward cycle.

== ART STYLE BASE ==

Use idle/00 as the absolute reference for:
  - Character proportions, head-to-foot height
  - Skin tone, lighting, color saturation
  - Costume rendering, line weight

== STATE TRANSITION FROM walk_f/02 ==

walk_f/02 (attached, previous frame) shows:
  - One foot reaching forward in mid-air, about to land.
  - The other foot is back, heel lifted (pushing off).

walk_f/03 (this frame, the next moment):
  - The reaching foot has NOW LANDED — it is planted on the ground in
    front of the body.
  - The previously pushing-off foot has fully lifted its heel
    (it is now the back foot, about to swing forward in F04).

So the only change from F02 to F03 is: the airborne foot has touched
down and become the new planted-front foot. The other foot continues
its push-off motion (heel fully up).

== VISUAL CHECKLIST ==

✅ Front foot: planted on the ground.
✅ Back foot: heel fully lifted, about to swing forward.
✅ Body center x ≈ 128.
✅ Face pointing right.
✅ Transparent background, no ground line, no shadow disc.

❌ DO NOT keep the previous airborne foot in mid-air — it has landed now.
❌ DO NOT change the face direction or character height.
```

#### `walk_f/04.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon mid-walking, mid-stride pose.

== POSE DESCRIPTION ==

Leon is mid-step in a walking cycle. Specifically:

- ONE foot is planted firmly on the ground at the bottom-center of the
  frame (x ≈ 128, y = 384). This is the supporting leg.
- The OTHER foot is LIFTED IN THE AIR, with the knee BENT FORWARD at
  approximately 90 degrees, and the foot tucked up beneath the body
  (NOT reaching forward yet — just lifted in a mid-swing pose).
- Body weight is centered over the supporting (planted) leg.
- Slight forward lean of the upper body.
- Arms swinging naturally: one arm slightly forward, the other slightly back.

== KEY DETAIL — DEPTH ORDERING ==

The LIFTED leg is drawn IN THE FOREGROUND, in front of the body's
silhouette, fully visible and unobstructed by the coat.
The PLANTED leg is drawn slightly BEHIND the body, partially occluded
by the lifted leg or the coat.

This depth ordering (lifted = foreground, planted = background) gives
the pose its sense of motion and is the KEY visual cue.

== ART STYLE ==

Use idle/00 (attached) as the EXACT reference for:
- Character proportions and head-to-foot height
- Skin tone, lighting, color saturation
- Costume rendering, jacket details, hair shape
- Line weight

== REQUIREMENTS ==

✅ Frame size: exactly 256×384 pixels.
✅ Body center-of-mass at x ≈ 128.
✅ Face pointing right (same as idle/00).
✅ Transparent background.
✅ No ground line, no floor shadow disc, no horizontal lines.

❌ DO NOT keep both feet on the ground.
❌ DO NOT change the face direction.
❌ DO NOT zoom in/out — character height must match idle/00.
❌ DO NOT have the lifted foot reaching far forward (it's tucked under
   the knee, not extended).
```

#### `walk_f/05.png`

```
[Attach: idle/00.png AND walk_f/04.png]

Generate walk_f/05.png — frame 6 of 6.

== ART STYLE BASE ==

Use idle/00 as the absolute reference for character proportions, skin
tone, lighting, costume, and line weight.

== STATE TRANSITION FROM walk_f/04 ==

walk_f/04 (attached, previous frame) shows:
  - One foot planted (supporting)
  - The other foot lifted in mid-air, knee bent (mid-swing)

walk_f/05 (this frame, the next moment):
  - The previously planted foot has BEGUN TO LIFT ITS HEEL
    (it's about to push off the ground).
  - The previously airborne foot is now REACHING FORWARD AND DOWN,
    about to land in front of the body.

So the swinging foot is no longer overhead with knee bent — it's now
extending forward toward the ground. The supporting foot is starting
to push off (heel lifting).

== VISUAL CHECKLIST ==

✅ One foot reaching forward in mid-air, nearly touching the ground.
✅ The other foot is back, heel lifted (pushing off).
✅ Body center x ≈ 128.
✅ Face pointing right.
✅ Transparent background, no ground line.

❌ DO NOT keep the airborne foot in the same overhead/knee-bent position
   from F04 (it must reach down and forward now).
❌ DO NOT plant both feet (the reaching foot is still in mid-air).
❌ DO NOT change the face direction or character height.

This frame loops back into walk_f/00.
```

---

### walk_b (1 frame) → `leon/walk_b/00.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon walking backward — mid-step pose.
Character STILL faces right (only the world position will move leftward).

Pose should READ as "currently retreating":
  - Left leg planted at bottom-center.
  - Right leg back (toward viewer's right of frame), knee slightly bent.
  - Body weight on the back leg, slight crouch.
  - Cautious posture, arms held in mild guard.
  - Eyes still looking forward (rightward).

Match idle/00's character height and skin tone exactly.
```

---

### crouch (1 frame) → `leon/crouch/00.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's full crouch / low guard pose.

  - Both feet planted at bottom-center (UNCHANGED from idle).
  - Knees fully bent, thighs near calves.
  - Head LOWER than idle's head by ~30% of frame height.
  - Hands held in tight low guard in front of the body.

The character's feet x position must MATCH idle/00 exactly.
```

---

### jump (1 frame) → `leon/jump/00.png` ★例外フレーム★

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's mid-air jump pose.

EXCEPTION TO ANCHOR RULE: this is an airborne pose.
  - Character drawn in the UPPER 60% of the frame.
  - LOWER 40% of the frame is fully transparent — no character pixels there.
  - Knees tucked or extended downward.
  - Coat flowing up.
  - Arms can be slightly raised.

The character's body x must remain at ≈ 128 (horizontally centered).
```

---

### atk_5a (1 frame) → `leon/atk_5a/00.png` 弱パンチ

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's light jab — IMPACT moment.

  - Right arm fully extended to the right (fist near right edge of frame).
  - Right shoulder rotated forward.
  - LEFT foot planted at bottom-center.
  - Right foot may shift slightly forward but stays at bottom edge.
  - Body weight forward but the character does NOT translate horizontally.

Match idle/00's character height and skin tone exactly.
```

---

### atk_5b (1 frame) → `leon/atk_5b/00.png` 中キック

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's middle kick — IMPACT moment.

  - Right leg fully extended to the right at waist height.
  - LEFT foot planted at bottom-center (supporting leg).
  - Body's vertical position UNCHANGED from idle.
  - Arms balanced for stability.

Match idle/00's character height and skin tone exactly.
```

---

### atk_5c (1 frame) → `leon/atk_5c/00.png` 強斬り

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's heavy slash — IMPACT moment.

  - Right arm fully extended to the right at shoulder height (sword-hand slash).
  - Slight torso rotation following the swing.
  - Both feet planted at bottom-center.
  - Coat flowing behind from the swing momentum.

Match idle/00's character height and skin tone exactly.
```

---

### atk_5d (1 frame) → `leon/atk_5d/00.png` 突進

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's lunge strike — peak posture.

  - Heavy forward lean (upper body tilted ~30 degrees rightward).
  - Right shoulder leading, like a tackle.
  - LEFT foot still planted at bottom-center (the lunge is body lean,
    NOT horizontal displacement).
  - Right foot may be slightly forward but stays at the bottom edge.

Match idle/00's character height and skin tone exactly.
```

---

### guard (1 frame) → `leon/guard/00.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's held guard pose.

  - Both forearms crossed in front of face / chest.
  - Body slightly hunched forward defensively.
  - Both feet planted at bottom-center.

Match idle/00's character height and skin tone exactly.
```

---

### hit_stand (1 frame) → `leon/hit_stand/00.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon's hit reaction — recoil pose.

  - Head snapped back from impact (impact came from the right).
  - Upper body leaning slightly backward.
  - Both feet planted at bottom-center (NOT pushed back — feet stay still).
  - Pained expression.
  - Arms slightly flailed.

Match idle/00's character height and skin tone exactly.
```

---

### knockdown (1 frame) → `leon/knockdown/00.png`

```
[Attach: idle/00.png]

Generate ONE 256×384 PNG image: Leon lying on the ground (knockdown).

  - Body horizontal, lying on his back.
  - The SIDE of the body rests on the bottom edge (the ground line).
  - Body fills the lower half of the frame horizontally.
  - Head can be on either side; legs extended somewhat.

The bottom edge of the frame = the ground.
Match idle/00's character height (when standing) — the lying body should
appear proportionally the same scale.
Match idle/00's skin tone exactly.
```

---

## DALL-E が指示通りにならないとき

### 寸法が違う

```
The image must be exactly 256×384 pixels. Crop or pad to this size.
No other dimensions are acceptable.
```

### 足元 x がずれる

```
The character's feet must occupy the SAME x position as the attached
idle/00.png. Overlay the two images — the foot pixels must stack horizontally.
Do not shift the body left or right.
```

### キャラのサイズがバラつく

```
Look at the reference image of Leon again. The character's head-to-foot
height must match the reference exactly. Do not zoom in or out.
```

### 肌色や色味が変わった

```
The skin tone, lighting, and color saturation must match idle/00.png
EXACTLY. No warm/tan drift, no shading change, no saturation difference.
```

### 謎の地面ライン・床影が入る

```
Remove ALL horizontal lines, ground lines, floor shadows, and shadow discs.
The background and the area below the feet must be fully transparent
(verify with the bottom-right corner pixel).
```

### キャラデザインがブレた

```
Refer back to the original Leon reference image I sent at the start of this session.
The hair color, jacket design, and pose details must match the reference exactly.
```

---

## 後処理（必要なら）

各 PNG を Aseprite / Photoshop / GIMP で確認：

1. **キャンバスサイズ確認** — 256×384 になっていなければリサイズ/クロップ
2. **不要なノイズ除去** — フレーム外の薄い色や白背景を完全透過に
3. **足元 x が idle/00 と揃っているか** — 全画像を重ねて目視チェック
4. **PNG（透過保持）で保存**

---

## ファイル保存先

```
fighter/assets/sprites/leon/
├─ idle/
│   ├─ 00.png
│   ├─ 01.png
│   ├─ 02.png
│   └─ 03.png
├─ walk_f/
│   ├─ 00.png
│   ├─ 01.png
│   ├─ 02.png
│   ├─ 03.png
│   ├─ 04.png
│   └─ 05.png
├─ walk_b/00.png
├─ crouch/00.png
├─ jump/00.png
├─ atk_5a/00.png
├─ atk_5b/00.png
├─ atk_5c/00.png
├─ atk_5d/00.png
├─ guard/00.png
├─ hit_stand/00.png
└─ knockdown/00.png
```

合計 **20 ファイル**（idle 4 + walk_f 6 + 他 10）。

---

## 将来的に攻撃にフレーム追加したくなったら

格闘ゲームらしい打撃感を出すには、攻撃に **構え→インパクト→戻し** の 2-3 フレームが欲しい。後で追加する場合：

1. `atk_5a/01.png`（戻し）, `atk_5a/02.png`（さらに戻し）等を生成
2. `leon.tres` の `atk_5a` の `frames` を 1 → 2 or 3 に変更
3. インパクト瞬間（00.png）は **active フレーム**として最も重要なのでそのまま

per-frame モードのおかげで、後付けでフレーム追加が容易。
