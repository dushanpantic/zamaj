# Color exploration — Zamaj

A design deep-dive into the app's color system, plus four fully-specified
alternative palettes. This is an **exploration artifact**, not a spec — nothing
here is wired into the app. Every palette below maps 1:1 onto the tokens in
[app_colors.dart](mobile/lib/core/app_colors.dart), so any option can be dropped
in as a new `AppColors.dark` / `AppColors.light` pair without touching UI code.

---

## How to read this

- **Section 1** is the theory, applied specifically to a sweaty-handed gym
  logbook — not generic color-wheel trivia.
- **Section 2** is an honest critique of the palette you already have: what's
  genuinely good, and three small things that are worth fixing in *any*
  direction you pick.
- **Section 3** is the four candidate palettes (A–D), each with a full dark +
  light token table, accessibility notes, and tradeoffs.
- **Sections 4–6** compare them, give an opinionated recommendation, and show
  how to apply one.

---

## 1. Principles (color theory, aimed at this app)

### 1.1 Dark-first, but never pure black

Dark default is the right call: gyms are dimly lit, phones get glanced at from
arm's length on a bench, and OLED screens save battery on dark pixels. But pure
black (`#000000`) is a trap — it produces harsh, "floating" contrast, smears on
OLED during scroll, and causes *halation* (a perceived glow) for users with
astigmatism. The current `#0B0B0E` near-black is exactly right.

The corollary, which the current palette under-uses, is **elevation through
tonal layers**. Good dark UIs build 4 steps — base background, primary surface,
elevated surface, and an overlay/dialog level — each a few percent lighter than
the last, so depth reads without heavy shadows (shadows barely register on
dark). Zamaj currently has three (`background → surface → surfaceVariant`); a
modal/sheet that sits *above* a card has nowhere lighter to go. Every palette
below keeps the three-token contract but spaces the steps so there's visible
separation, and notes where a 4th level would help.

Text should be **off-white, not pure white** (`#FFFFFF`). Bright white on
near-black blooms and fatigues the eye. The current `#E7E7EA` is a good value;
all options keep onSurface in the `#E5–#EC` range.

### 1.2 The 60-30-10 discipline — one loud accent

The classic ratio: ~60% dominant neutral (backgrounds/surfaces), ~30% secondary
tone (cards, muted text, outlines), ~10% accent. The accent only *reads* as an
accent if it's rationed. Zamaj's orange is used for `primary`, `loggableHint`,
**and** `restTimer` — that's disciplined (one accent, three roles), and worth
preserving as a principle whichever hue wins: **pick one hero color, let it own
the call-to-action, the rest timer, and the "look here" hint, and let nothing
else compete with it.**

### 1.3 Neutral temperature is a personality choice

Neutrals are never truly neutral, and the tiny hue you bias them toward sets the
whole app's mood:

- **Cool neutrals** (blue/violet-tinted grays) read as *technical, precise,
  clinical, data-forward.* Your current neutrals are subtly cool/violet.
- **Warm neutrals** (red/yellow-tinted graphite) read as *premium, physical,
  energetic, "analog."*

There's a subtle tension in the current scheme: a warm orange accent (`#F97316`)
sitting on cool, faintly-violet neutrals. It works, but the accent and the
canvas are pulling in opposite temperature directions. Each option below picks a
temperature *deliberately* and harmonizes the accent to it.

### 1.4 Contrast targets — the gym raises the bar

WCAG AA is the floor: **4.5:1 for body text, 3:1 for large/bold text and UI
components.** But this app is read in motion, at distance, with sweat on the lens
and the screen tilted. Treat AA as the minimum and push the **in-session numeric
readouts and primary actions toward AAA (7:1)** — those are the pixels that
decide whether someone re-racks correctly. The `numericLarge` (36px) planned/
actual values and the LOG SET button are where contrast matters most.

### 1.5 Planned vs. actual — separate by *value*, not just hue

The product's core data distinction (planned vs. actual) is currently expressed
as **muted gray (`planned`) vs. near-white (`actual`)** — a pure
*lightness/value* difference, not a hue difference. This is genuinely
sophisticated and worth defending:

- It survives color-blindness completely (no hue to confuse).
- It reads as "ghost target vs. the real thing I did" — a perfect metaphor.
- It never fights the hero accent for attention.

The only enhancement worth considering: let `actual` carry a *whisper* of the
palette's warmth/accent so a logged value feels "alive" versus the desaturated
plan — but keep the dominant cue as value. All four options keep planned/actual
as a value pair; some tint `actual` a few degrees toward the hero.

### 1.6 Color-blind safety and the "never color alone" rule

~8% of men have a red-green color vision deficiency (relevant for a male-leaning
strength-training audience). Two facts drive the palettes below:

1. **Blue↔orange is the most universally distinguishable hue pair** across
   protan/deutan/tritan vision (the basis of the Wong scientific palette). Where
   an option needs a primary + a strong secondary, blue/orange beats any
   red/green pairing.
2. **Never rely on hue alone for state.** `completed`/`skipped`/`replaced` must
   each pair with a distinct *icon and luminance*, not just a color — a green
   check, a gray dash, a swap glyph. This is already partly true in the UI; it's
   a hard requirement for any palette.

---

## 2. The current palette — what works, what to fix

**What's genuinely good** (keep all of this):

- Near-black `#0B0B0E` background — correct, not pure black.
- Off-white `#E7E7EA` text — no halation.
- Planned-vs-actual as a value pair — elegant and CVD-proof (§1.5).
- One rationed accent across primary/hint/timer — disciplined (§1.2).
- Orange as the hero — strong psychological fit (orange = energy, drive,
  motivation; the literal OrangeTheory thesis). It's a defensible identity.

**Four things worth fixing in any direction:**

| # | Issue | Why it matters | Fix applied below |
|---|-------|----------------|-------------------|
| 1 | **The amber collision.** `warning` (`#F59E0B`), `exerciseReplaced` (`#F59E0B`) are *identical*, and `primary` orange (`#F97316`) is right next to them on the wheel. | Three warm yellow-orange signals compete; a "replaced" badge, a "warning," and a primary button can read as the same thing — and all three blur further under deuteranopia. | Give each a distinct slot: hero owns one hue; `warning` → a *purer yellow*; `exerciseReplaced` → its own hue (violet, or orange when the hero is cool). |
| 2 | **Temperature clash.** Warm orange accent on cool violet-gray neutrals (§1.3). | Subtle, but the canvas and the accent disagree; the orange never feels fully "at home." | Each option harmonizes neutral temperature to its accent. |
| 3 | **Only three surface levels.** A sheet over a card has nowhere lighter to sit (§1.1). | Modals/bottom-sheets in-session don't separate cleanly from the cards behind them. | Steps re-spaced for visible separation; a 4th overlay level noted. |
| 4 | **`warmup` blue is an orphan.** It's the lone cool note in a warm system. | Not wrong, but it reads as "imported from elsewhere" rather than part of the family. | Each option places warmup deliberately within its hue spacing. |

---

## 3. Four directions

Each spans a different region of the color wheel so you can feel the full range:
**A** stays warm (orange), **B** goes yellow-green (volt), **C** goes cool-cyan,
**D** goes blue-violet. All four respect §1.1–§1.6.

> Token order in each table follows `app_colors.dart`. Hex values lean on the
> Tailwind ramp the current palette already uses, so they'll feel familiar.

---

### Option A — "Ember" · refined evolution

**Concept:** keep the orange identity you like — just fix the four issues. Warm
the neutrals so the accent feels at home, separate the amber cluster, and give
`actual` a faint warm life. This is the **low-risk pick**: the app still looks
like itself, only more resolved.

**Who it's for:** you, if the answer to "I like the current scheme" is "so make
it the best version of itself."

**Feel:** warm graphite, molten orange, focused and physical.

#### Dark
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#100E0C` | warm near-black (graphite, not violet) |
| surface | `#1B1815` | card |
| surfaceVariant | `#272320` | elevated card / input |
| outline | `#3D3833` | hairline borders |
| onBackground | `#ECEAE6` | warm off-white |
| onSurface | `#ECEAE6` | |
| onSurfaceMuted | `#A39E96` | warm muted gray |
| primary | `#F97316` | **hero** — orange-500, unchanged |
| onPrimary | `#1A1005` | dark warm; ~6.5:1 on the orange fill |
| error | `#EF4444` | red-500 |
| onError | `#1A0A0A` | |
| success | `#22C55E` | green-500 |
| warning | `#FACC15` | **yellow-400 — pulled away from orange** |
| planned | `#A39E96` | muted (= onSurfaceMuted) |
| actual | `#F4EFE8` | off-white with a warm whisper (alive vs. plan) |
| exerciseCompleted | `#22C55E` | green |
| exerciseSkipped | `#78716C` | stone-500 (warm gray) |
| exerciseReplaced | `#C084FC` | **violet — its own hue, CVD-distinct from green** |
| warmup | `#38BDF8` | sky-400 (cool = "warming up before the work") |
| warmupBg | `#13262B` | deep teal-slate, low-alpha friendly |
| loggableHint | `#F97316` | = hero |
| restTimer | `#F97316` | = hero |
| scrim | `#CC000000` | |

#### Light
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#FBF8F4` | warm off-white |
| surface | `#FFFFFF` | |
| surfaceVariant | `#F4F1EC` | |
| outline | `#DDD7CE` | |
| onBackground | `#1C1A17` | warm near-black |
| onSurface | `#1C1A17` | |
| onSurfaceMuted | `#76706A` | |
| primary | `#EA580C` | orange-600 (deeper, legible on white) |
| onPrimary | `#FFFFFF` | |
| error | `#DC2626` | |
| onError | `#FFFFFF` | |
| success | `#16A34A` | |
| warning | `#CA8A04` | yellow-600 (legible on white) |
| planned | `#76706A` | |
| actual | `#1C1A17` | |
| exerciseCompleted | `#16A34A` | |
| exerciseSkipped | `#A8A29E` | stone-400 |
| exerciseReplaced | `#9333EA` | violet-600 |
| warmup | `#0284C7` | sky-600 |
| warmupBg | `#E0F2FE` | |
| loggableHint | `#EA580C` | |
| restTimer | `#EA580C` | |
| scrim | `#99000000` | |

**A11y:** onPrimary on primary ≈ 6.5:1 (AAA-large). Text on bg ≈ 14:1. `warning`
yellow vs `primary` orange now differ in both hue *and* luminance; `replaced`
violet vs `completed` green are unambiguous under deuteranopia.

**Tradeoffs:** smallest visual change — exciting if you want refinement, anticlimactic if
you wanted a new identity. Orange is also "Strava's color" in the fitness space
(irrelevant while single-user, mildly relevant if you go public).

---

### Option B — "Volt" · athletic performance

**Concept:** near-black canvas with a single electric lime-yellow accent — the
Nike-Volt / Whoop / performance-wearable language. Volt is almost unusable
anywhere *except* on dark, which makes it feel earned and reserved for the
moments that matter (LOG SET, the running rest timer).

**Who it's for:** you, if you want the app to feel like training gear — loud,
kinetic, unmistakably athletic.

**Feel:** blackout gym, one neon stripe.

#### Dark
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#0B0C0B` | near-black, faint neutral-green |
| surface | `#161816` | |
| surfaceVariant | `#21241F` | |
| outline | `#383B36` | |
| onBackground | `#ECEEEA` | |
| onSurface | `#ECEEEA` | |
| onSurfaceMuted | `#989C94` | |
| primary | `#C7F432` | **hero** — volt (lime, brightened toward yellow) |
| onPrimary | `#0B0F00` | near-black; ~13:1 on volt — superb legibility |
| error | `#FF5C5C` | warmer red, separated from volt |
| onError | `#1A0606` | |
| success | `#34D399` | **emerald (bluer green) — pulled away from volt** |
| warning | `#FBBF24` | amber-400 (now free; hero isn't orange) |
| planned | `#989C94` | |
| actual | `#ECEEEA` | kept pure neutral (volt would shout) |
| exerciseCompleted | `#34D399` | emerald |
| exerciseSkipped | `#6B7280` | gray-500 |
| exerciseReplaced | `#A78BFA` | violet-400 |
| warmup | `#38BDF8` | sky-400 |
| warmupBg | `#0E2A33` | |
| loggableHint | `#C7F432` | = hero |
| restTimer | `#C7F432` | = hero |
| scrim | `#D9000000` | a hair darker — volt wants a black stage |

#### Light
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#FAFAF7` | |
| surface | `#FFFFFF` | |
| surfaceVariant | `#F1F2EC` | |
| outline | `#D7D9CF` | |
| onBackground | `#15170F` | |
| onSurface | `#15170F` | |
| onSurfaceMuted | `#6B6F62` | |
| primary | `#4D7C0F` | **lime-700** — see caveat |
| onPrimary | `#FFFFFF` | |
| error | `#DC2626` | |
| onError | `#FFFFFF` | |
| success | `#059669` | emerald-600 |
| warning | `#CA8A04` | |
| planned | `#6B6F62` | |
| actual | `#15170F` | |
| exerciseCompleted | `#059669` | |
| exerciseSkipped | `#9CA3AF` | |
| exerciseReplaced | `#7C3AED` | violet-600 |
| warmup | `#0284C7` | |
| warmupBg | `#E0F2FE` | |
| loggableHint | `#4D7C0F` | |
| restTimer | `#4D7C0F` | |
| scrim | `#99000000` | |

**A11y / big caveat:** **volt is a dark-mode hero and does not survive light
mode.** Volt text/icons on white fail contrast badly, so light mode falls back
to a dark olive-lime (`#4D7C0F`) and loses the neon entirely — the two themes
won't feel like siblings. Also watch CVD: volt (yellow-green), `warning` amber,
and `success` emerald sit in the same broad region; they're separated here by
luminance and by volt being reserved for actioned buttons (with labels), never
as a bare status dot. Given the app is dark-default and gym-bound, this is
*mostly* acceptable — but it's the riskiest light-mode story of the four.

---

### Option C — "Instrument" · cool precision

**Concept:** position the app as a precise measuring instrument — which is what
it *is* (planned-vs-actual obsession, honest retros, no fluff). Cool slate
neutrals with a cyan hero. Calm, clinical, quantified-self. Less "bro gym," more
"the engineer who lifts."

**Who it's for:** you, if the product's soul is *honest data* more than *hype* —
this palette is the truest match to the two pillars in
[product-context.md](product-context.md).

**Feel:** lab instrument, cold light, exact.

#### Dark
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#0B0F14` | deep blue-slate near-black |
| surface | `#121821` | |
| surfaceVariant | `#1B2430` | |
| outline | `#2E3B49` | |
| onBackground | `#E5EBF1` | cool off-white |
| onSurface | `#E5EBF1` | |
| onSurfaceMuted | `#8896A6` | slate muted |
| primary | `#22D3EE` | **hero** — cyan-400 |
| onPrimary | `#04222A` | dark cyan-black; ~8:1 on cyan |
| error | `#F87171` | soft red (red-400, fits the cool canvas) |
| onError | `#1B0707` | |
| success | `#4ADE80` | green-400 — clearly *green*, not cyan |
| warning | `#FBBF24` | amber-400 |
| planned | `#8896A6` | |
| actual | `#E5EBF1` | |
| exerciseCompleted | `#4ADE80` | |
| exerciseSkipped | `#64748B` | slate-500 |
| exerciseReplaced | `#E879F9` | fuchsia-400 (far from cyan + green) |
| warmup | `#818CF8` | indigo-400 |
| warmupBg | `#1E2440` | deep indigo-slate |
| loggableHint | `#22D3EE` | = hero |
| restTimer | `#22D3EE` | = hero |
| scrim | `#CC000000` | |

#### Light
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#F7F9FB` | cool off-white |
| surface | `#FFFFFF` | |
| surfaceVariant | `#EEF2F6` | |
| outline | `#CFD8E3` | |
| onBackground | `#101820` | |
| onSurface | `#101820` | |
| onSurfaceMuted | `#5E6B7A` | |
| primary | `#0891B2` | cyan-600 (legible on white) |
| onPrimary | `#FFFFFF` | |
| error | `#DC2626` | |
| onError | `#FFFFFF` | |
| success | `#16A34A` | |
| warning | `#CA8A04` | |
| planned | `#5E6B7A` | |
| actual | `#101820` | |
| exerciseCompleted | `#16A34A` | |
| exerciseSkipped | `#64748B` | |
| exerciseReplaced | `#C026D3` | fuchsia-600 |
| warmup | `#4F46E5` | indigo-600 |
| warmupBg | `#E0E7FF` | |
| loggableHint | `#0891B2` | |
| restTimer | `#0891B2` | |
| scrim | `#99000000` | |

**A11y:** cyan hero is high-luminance — onPrimary dark text ≈ 8:1. The hue spread
(cyan 187° · green 142° · fuchsia 292° · indigo 245° · amber 45° · red 0°) is
well-separated and translates cleanly across CVD types. Light mode is
fully viable (unlike Volt). 

**Tradeoffs:** cyan can read "cool/medical" — less primal-gym energy than orange
or volt. Cyan is also adjacent to `warmup` indigo and to `success` green if you
later brighten either; keep the spacing above.

---

### Option D — "Indigo Night" · calm premium  ⟵ *designer's pick*

**Concept:** deep blue-violet hero on a faintly blue graphite — the
calm-athletic, premium register (think ASICS' deep-blue language). Its signature
move: because the hero is cool, **orange is freed up to become the secondary
accent.** Indigo↔orange is a near-complementary, blue/orange pairing — the most
CVD-safe high-contrast duo there is (§1.6) — so `exerciseReplaced` and the rest-
timer-overtime state can glow warm against the cool field. You keep the orange
you love, just demoted from hero to accent.

**Who it's for:** you, if you want a *new, more grown-up* identity that still has
energy — without throwing the orange away.

**Feel:** focused, premium, twilight; warm sparks on a cool field.

#### Dark
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#0C0C12` | blue-graphite near-black |
| surface | `#16161F` | |
| surfaceVariant | `#20212C` | |
| outline | `#353748` | |
| onBackground | `#E8E8F0` | |
| onSurface | `#E8E8F0` | |
| onSurfaceMuted | `#9494A6` | |
| primary | `#6366F1` | **hero** — indigo-500 |
| onPrimary | `#FFFFFF` | ~3.9:1 → use for **bold/large labels** (LOG SET is 18px w700, OK); see note |
| error | `#F87171` | soft red |
| onError | `#1B0707` | |
| success | `#34D399` | emerald-400 |
| warning | `#FBBF24` | amber-400 |
| planned | `#9494A6` | |
| actual | `#E8E8F0` | |
| exerciseCompleted | `#34D399` | |
| exerciseSkipped | `#71717A` | zinc-500 |
| exerciseReplaced | `#FB923C` | **orange-400 — the complementary spark** |
| warmup | `#38BDF8` | sky-400 |
| warmupBg | `#102338` | deep blue |
| loggableHint | `#6366F1` | = hero |
| restTimer | `#6366F1` | = hero (overtime → use the orange `#FB923C`) |
| scrim | `#CC000000` | |

#### Light
| Token | Hex | Role / note |
|-------|-----|-------------|
| background | `#F8F8FC` | |
| surface | `#FFFFFF` | |
| surfaceVariant | `#F0F0F7` | |
| outline | `#D7D7E3` | |
| onBackground | `#16161F` | |
| onSurface | `#16161F` | |
| onSurfaceMuted | `#6B6B82` | |
| primary | `#4F46E5` | indigo-600 (≈ 6:1 with white — comfortable) |
| onPrimary | `#FFFFFF` | |
| error | `#DC2626` | |
| onError | `#FFFFFF` | |
| success | `#16A34A` | |
| warning | `#CA8A04` | |
| planned | `#6B6B82` | |
| actual | `#16161F` | |
| exerciseCompleted | `#16A34A` | |
| exerciseSkipped | `#71717A` | |
| exerciseReplaced | `#EA580C` | orange-600 |
| warmup | `#0284C7` | sky-600 |
| warmupBg | `#E0F2FE` | |
| loggableHint | `#4F46E5` | |
| restTimer | `#4F46E5` | |
| scrim | `#99000000` | |

**A11y note on the hero fill:** indigo-500 with white text is ≈ 3.9:1 — that
clears AA **large/bold** (the LOG SET label is bold 18px, so it passes) but *not*
AA normal. Two clean fixes if you adopt this: (a) deepen the dark-mode hero to
`#5457E5`/`#4F46E5` to reach ~4.5:1 with white, or (b) keep `#6366F1` and ensure
any text on an indigo fill is always ≥18px bold. Everything else clears AA/AAA.
The indigo/orange pairing is the most robust on the page for color-blind users.

**Tradeoffs:** the biggest identity shift of the four — but it *keeps* orange in
the family, so it's a re-balancing rather than a goodbye. Indigo/violet is also
the most common accent in 2025–26 product design, so it's a touch less
distinctive than volt.

---

## 4. Side by side

| | Current | A · Ember | B · Volt | C · Instrument | D · Indigo Night |
|--|--|--|--|--|--|
| **Hero** | orange `#F97316` | orange `#F97316` | volt `#C7F432` | cyan `#22D3EE` | indigo `#6366F1` |
| **Neutrals** | cool/violet | **warm** graphite | neutral-green black | **cool** slate | cool blue-graphite |
| **Mood** | energetic | energetic, resolved | kinetic, loud | precise, clinical | premium, calm |
| **Amber collision fixed** | ✗ | ✓ | ✓ | ✓ | ✓ |
| **Light mode** | good | good | **weak** (volt dies) | good | good |
| **CVD safety** | moderate | good | moderate | good | **best** (blue/orange) |
| **Fits product soul** | good | good | hype-forward | **best match** | strong |
| **Identity change** | — | minimal | large | large | large (keeps orange) |
| **Risk** | — | lowest | highest | medium | medium |

---

## 5. Recommendation

There's no single winner — it depends on what you want the app to *say*:

- **Want refinement, not a redesign? → A (Ember).** It keeps everything you like
  about today's look, fixes the four real issues (the amber collision above all),
  and harmonizes the temperature. Lowest risk, immediate payoff.
- **Want the truest expression of the product? → C (Instrument).** The cool,
  precise register matches the two pillars — *planned-vs-actual honesty* and a
  no-hype logbook — better than any other option, and it's clean in both themes.
- **Want a more grown-up identity without abandoning orange? → D (Indigo
  Night)** is my **designer's pick.** The indigo hero + orange spark is
  sophisticated, energetic, and the single most color-blind-safe scheme here.
- **B (Volt)** is the most exciting on the gym floor but carries a real
  light-mode liability — choose it only if you're comfortable being
  dark-mode-first to the point of dark-mode-mostly.

If I had to pick one to build next: **A if you're attached to the current feel,
D if you're ready to level up the identity.**

---

## 6. Applying a palette

Each table above is a complete `AppColors` token set. To try one:

1. In [app_colors.dart](mobile/lib/core/app_colors.dart), replace the values in
   `AppColors.dark` and `AppColors.light` with the chosen option's Dark/Light
   tables. The constructor and token names are unchanged, so no UI code touches.
2. If you adopt **D**, either deepen the dark hero to `#4F46E5` or keep on-indigo
   text bold/large (§Option D a11y note).
3. The token set has no `restTimerOvertime` slot today; options A/D assume the
   overtime state reuses `warning`/the orange spark. If you want a dedicated
   overtime color, add it to `AppColors` (both palettes) per the CLAUDE.md
   convention — don't hard-code it.
4. Visual sign-off is yours — load the app and live with the in-session surfaces
   ([workout_overview](mobile/lib/modules/workout_overview/),
   [focus_mode](mobile/lib/modules/focus_mode/)) for a real session before
   committing to one.

These are exploration palettes, not a product-context change, so
[product-context.md](product-context.md) is intentionally left untouched.

---

## Sources

- [Muzli — Mobile App Design Trends 2026](https://muz.li/blog/whats-changing-in-mobile-app-design-ui-patterns-that-matter-in-2026/)
- [UpDivision — UI Color Trends to Watch in 2026](https://updivision.com/blog/post/ui-color-trends-to-watch-in-2026)
- [FiveJars — Mastering Dark Mode UI](https://fivejars.com/insights/dark-mode-ui-9-design-considerations-you-cant-ignore/)
- [Onething — 10 Best Practices for Dark Mode UI Design](https://www.onething.design/post/best-practices-for-dark-mode-ui-design)
- [AccessibilityChecker — The Designer's Guide to Dark Mode Accessibility](https://www.accessibilitychecker.org/blog/dark-mode-accessibility/)
- [Lyssna — Color Blind-Friendly Palette](https://www.lyssna.com/blog/color-blind-friendly-palette/)
- [Colorblind.io — Colorblind-Safe Palettes for Designers](https://colorblind.io/guides/colorblind-safe-palettes) (Wong palette)
- [Think Design — Inclusive UI Design for Colorblindness](https://think.design/blog/inclusive-ui-design-for-colorblindness/)
- [Stellen Design — Colors for Fitness Branding](https://www.stellendesign.com/colors-for-fitness-branding/)
- [Treefrog — Color Psychology: Orange](https://treefrogmarketing.com/color-psychology-orange/)
